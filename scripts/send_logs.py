import json, gzip, base64, subprocess, time

def make_payload(log_group, log_stream, messages):
    ts = int(time.time() * 1000)
    events = [{'id': f'evt{i}', 'timestamp': ts + i*1000, 'message': m} for i, m in enumerate(messages)]
    log_event = {
        'messageType': 'DATA_MESSAGE',
        'owner': '633426742056',
        'logGroup': log_group,
        'logStream': log_stream,
        'subscriptionFilters': [log_group.replace('/', '-') + '-to-newrelic'],
        'logEvents': events
    }
    compressed = gzip.compress(json.dumps(log_event).encode('utf-8'))
    encoded = base64.b64encode(compressed).decode('utf-8')
    return json.dumps({'awslogs': {'data': encoded}})

payloads = [
    ('petclinic/apache-access-logs', 'i-06254cfd8a6422b6b-apache-access', [
        '13.201.46.221 - - [03/Jun/2026:13:00:01 +0000] "GET / HTTP/1.1" 200 4567 "-" "ELB-HealthChecker/2.0"',
        '203.0.113.10 - - [03/Jun/2026:13:00:05 +0000] "GET /owners HTTP/1.1" 200 12345 "-" "Mozilla/5.0"',
        '203.0.113.10 - - [03/Jun/2026:13:00:10 +0000] "GET /owners/find HTTP/1.1" 200 8901 "-" "Mozilla/5.0"',
        '203.0.113.10 - - [03/Jun/2026:13:00:15 +0000] "POST /owners/new HTTP/1.1" 302 0 "-" "Mozilla/5.0"',
        '203.0.113.11 - - [03/Jun/2026:13:00:20 +0000] "GET /vets.html HTTP/1.1" 200 6789 "-" "Mozilla/5.0"',
        '203.0.113.12 - - [03/Jun/2026:13:00:25 +0000] "GET /error HTTP/1.1" 500 1234 "-" "Mozilla/5.0"',
    ]),
    ('petclinic/apache-error-logs', 'i-06254cfd8a6422b6b-apache-error', [
        '[Wed Jun 03 13:00:25.123456 2026] [proxy_http:error] [pid 1234] AH01114: HTTP: failed to make connection to backend: localhost',
        '[Wed Jun 03 13:00:26.234567 2026] [proxy:warn] [pid 1234] [client 203.0.113.12:45678] AH01144: No protocol handler was valid',
    ]),
    ('petclinic/application-logs', 'i-06254cfd8a6422b6b-app', [
        '2026-06-03 13:00:00.001 INFO  o.s.s.p.PetClinicApplication - Starting PetClinicApplication on ip-10-0-1-42',
        '2026-06-03 13:00:05.123 INFO  o.s.b.w.e.t.TomcatWebServer - Tomcat started on port(s): 8080 (http)',
        '2026-06-03 13:00:05.456 INFO  o.s.s.p.PetClinicApplication - Started PetClinicApplication in 15.234 seconds',
        '2026-06-03 13:00:10.789 INFO  o.s.w.s.DispatcherServlet - Completed initialization in 250 ms',
        '2026-06-03 13:00:15.000 INFO  o.s.s.p.owner.OwnerController - Listing all owners',
        '2026-06-03 13:00:25.001 ERROR o.s.s.p.web.CrashController - Unexpected exception: NullPointerException at VetController.java:42',
    ]),
    ('petclinic/userdata-logs', 'i-06254cfd8a6422b6b-userdata', [
        '=== Starting PetClinic setup ===',
        '=== Installing CloudWatch Agent ===',
        '=== Building PetClinic ===',
        '[INFO] BUILD SUCCESS',
        '=== Starting CloudWatch Agent ===',
        '=== PetClinic setup completed ===',
    ]),
]

PAYLOAD_FILE    = r'd:\Workspace\petclinic\infrastructure\environments\dev\test-payload.json'
RESPONSE_FILE   = r'd:\Workspace\petclinic\infrastructure\environments\dev\lambda-response.json'

for log_group, log_stream, messages in payloads:
    payload = make_payload(log_group, log_stream, messages)
    with open(PAYLOAD_FILE, 'w', encoding='utf-8') as f:
        f.write(payload)

    subprocess.run([
        'aws', 'lambda', 'invoke',
        '--function-name', 'NewRelic-PetClinic-LogForwarder',
        '--region', 'ap-south-1',
        '--payload', f'fileb://{PAYLOAD_FILE}',
        RESPONSE_FILE
    ], capture_output=True)

    with open(RESPONSE_FILE, encoding='utf-8') as f:
        resp = json.loads(f.read())

    status = resp.get('statusCode', resp.get('FunctionError', 'unknown'))
    print(f"[{'OK' if status == 202 else 'FAIL'}] {log_group} -> {status}")

print("\nDone! Check NewRelic Logs UI: https://one.newrelic.com/logger")
