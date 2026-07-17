#!/bin/bash
# Userdata: write the setup script then launch it detached so cloud-init
# exits immediately and its 5-min timeout never kills our long build.

cat > /opt/setup-petclinic.sh << 'END_OF_SCRIPT'
#!/bin/bash
exec >> /var/log/userdata.log 2>&1
set -euxo pipefail

echo "=== Starting PetClinic setup $(date) ==="

# ---------- packages ----------
for i in 1 2 3; do apt-get update -y && break || sleep 15; done
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git curl openjdk-17-jdk apache2 wget jq maven

java -version

# ---------- CloudWatch Agent ----------
echo "=== Installing CloudWatch Agent ==="
cd /tmp
wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f ./amazon-cloudwatch-agent.deb

mkdir -p /opt/petclinic           # ensure log target exists early

cat > /opt/cloudwatch-agent-config.json << 'CWEOF'
{
  "agent": { "metrics_collection_interval": 60, "run_as": "root" },
  "metrics": {
    "metrics_collected": {
      "cpu":  { "totalcpu": true, "measurement": ["cpu_usage_idle","cpu_usage_user"], "metrics_collection_interval": 60 },
      "mem":  { "measurement": ["mem_used_percent"], "metrics_collection_interval": 60 },
      "disk": { "resources": ["/"], "measurement": ["used_percent"], "metrics_collection_interval": 60 }
    },
    "append_dimensions": { "InstanceId": "${aws:InstanceId}" }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/userdata.log",             "log_group_name": "petclinic/userdata-logs",      "log_stream_name": "{instance_id}-userdata" },
          { "file_path": "/var/log/apache2/petclinic-access.log", "log_group_name": "petclinic/apache-access-logs", "log_stream_name": "{instance_id}-apache-access" },
          { "file_path": "/var/log/apache2/petclinic-error.log",  "log_group_name": "petclinic/apache-error-logs",  "log_stream_name": "{instance_id}-apache-error" },
          { "file_path": "/opt/petclinic/application.log",    "log_group_name": "petclinic/application-logs",   "log_stream_name": "{instance_id}-app" }
        ]
      }
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -c file:/opt/cloudwatch-agent-config.json -a fetch-config
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# ---------- clone & build ----------
echo "=== Cloning PetClinic ==="
cd /opt
git clone https://github.com/suresh-osi/petclinic.git
cd /opt/petclinic

chmod +x mvnw
export HOME=/root
export MAVEN_OPTS="-Xmx768m -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

echo "=== Building PetClinic ==="
./mvnw package -DskipTests --no-transfer-progress

# ---------- systemd service ----------
echo "=== Creating systemd service ==="
# Find the actual jar file name (glob not supported in ExecStart)
JAR_FILE=$(ls /opt/petclinic/target/spring-petclinic-*.jar 2>/dev/null | head -1)
echo "JAR file found: ${JAR_FILE}"

cat > /etc/systemd/system/petclinic.service << SVCEOF
[Unit]
Description=Spring PetClinic
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/petclinic
ExecStart=/usr/bin/java -Xmx512m -jar ${JAR_FILE} --server.port=8080
Restart=on-failure
RestartSec=10
StandardOutput=append:/opt/petclinic/application.log
StandardError=append:/opt/petclinic/application.log

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable petclinic
systemctl start petclinic

# ---------- wait for app ----------
echo "=== Waiting for PetClinic on :8080 ==="
for i in $(seq 1 60); do
  if curl -sf --max-time 5 http://localhost:8080/ > /dev/null 2>&1; then
    echo "PetClinic UP after ${i} attempts"
    break
  fi
  echo "  attempt ${i}/60, sleeping 10s..."
  sleep 10
done

# ---------- Apache reverse proxy ----------
echo "=== Configuring Apache ==="
a2enmod proxy proxy_http

cat > /etc/apache2/sites-available/petclinic.conf << 'APACHEEOF'
<VirtualHost *:80>
    ProxyPreserveHost On
    ProxyPass        / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
    ErrorLog  ${APACHE_LOG_DIR}/petclinic-error.log
    CustomLog ${APACHE_LOG_DIR}/petclinic-access.log combined
</VirtualHost>
APACHEEOF

a2dissite 000-default.conf || true
a2ensite petclinic.conf
systemctl restart apache2

# ---------- final check ----------
echo "=== Final verification ==="
systemctl is-active petclinic  && echo "petclinic: active"  || echo "petclinic: FAILED"
systemctl is-active apache2    && echo "apache2:   active"  || echo "apache2:   FAILED"
curl -sf --max-time 5 http://localhost:8080/ > /dev/null \
  && echo "Health check on :8080 PASSED" \
  || echo "Health check on :8080 FAILED"

echo "=== PetClinic setup complete $(date) ==="
END_OF_SCRIPT

chmod +x /opt/setup-petclinic.sh

# Detach completely from cloud-init process tree
nohup setsid /opt/setup-petclinic.sh < /dev/null > /var/log/userdata-boot.log 2>&1 &
disown $!

echo "Setup launched in background, PID $!"
