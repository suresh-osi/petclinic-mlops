variable "newrelic_license_key" {
  description = "NewRelic Ingest License Key for log forwarding"
  type        = string
  sensitive   = true
  default     = ""
}

variable "newrelic_account_id" {
  description = "NewRelic Account ID"
  type        = string
  default     = "8131360"
}

variable "newrelic_external_id" {
  description = "NewRelic CloudWatch Integration External ID"
  type        = string
  default     = "12345678-1234-1234-1234-123456789012"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "alb_name" {
  description = "Application Load Balancer name"
  type        = string
  default     = "petclinic-alb"
}

variable "app_port" {
  description = "Application server port"
  type        = number
  default     = 8080
}

variable "alb_listener_port" {
  description = "ALB listener port (external-facing)"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/"
}

variable "ssh_port" {
  description = "SSH port for EC2 instances"
  type        = number
  default     = 22
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  description = "Availability zone for subnet 1"
  type        = string
  default     = "ap-south-1a"
}

variable "availability_zone_2" {
  description = "Availability zone for subnet 2"
  type        = string
  default     = "ap-south-1b"
}

variable "internet_route_cidr" {
  description = "Destination CIDR for internet route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "alb_security_group_name" {
  description = "Name of ALB security group"
  type        = string
  default     = "petclinic-alb-sg"
}

variable "alb_ingress_cidr" {
  description = "CIDR block allowed for ALB HTTP ingress"
  type        = string
  default     = "0.0.0.0/0"
}

variable "alb_egress_cidr" {
  description = "CIDR block allowed for ALB egress"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ec2_security_group_name" {
  description = "Name of EC2 security group"
  type        = string
  default     = "petclinic-ec2-sg"
}

variable "ec2_egress_cidr" {
  description = "CIDR block allowed for EC2 egress"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ec2_name_tag" {
  description = "Name tag for EC2 instance"
  type        = string
  default     = "petclinic-server"
}

variable "ubuntu_ami_owner" {
  description = "AWS account ID of the Ubuntu AMI owner"
  type        = string
  default     = "099720109477"
}

variable "ubuntu_ami_filter" {
  description = "Name filter for Ubuntu AMI lookup"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ssh_cidr" {
  description = "CIDR allowed for SSH access to EC2"
  type        = string
  default     = "0.0.0.0/0"
}

variable "target_group_name" {
  description = "Name of the ALB target group"
  type        = string
  default     = "petclinic-tg"
}
variable "newrelic_user_api_key" {
  description = "NewRelic User API Key for log forwarding"
  type        = string
  sensitive   = true
  default     = ""
}