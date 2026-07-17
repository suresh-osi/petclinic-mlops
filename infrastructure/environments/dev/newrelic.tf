# ============================================================
# NewRelic Log Forwarding - CloudWatch → NewRelic
# ============================================================
# Architecture:
#   EC2 (CloudWatch Agent)
#     → CloudWatch Log Groups
#       → Subscription Filter
#         → Lambda (NewRelic Forwarder)
#           → NewRelic Logs UI
# ============================================================

# ------------------------------------------------------------
# 1. CloudWatch Log Groups (pre-create so subscriptions work)
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "petclinic_app" {
  name              = "petclinic/application-logs"
  retention_in_days = 30

  tags = {
    Name        = "petclinic-application-logs"
    Environment = var.environment
    ForwardTo   = "newrelic"
  }
}

resource "aws_cloudwatch_log_group" "petclinic_apache_access" {
  name              = "petclinic/apache-access-logs"
  retention_in_days = 30

  tags = {
    Name        = "petclinic-apache-access-logs"
    Environment = var.environment
    ForwardTo   = "newrelic"
  }
}

resource "aws_cloudwatch_log_group" "petclinic_apache_error" {
  name              = "petclinic/apache-error-logs"
  retention_in_days = 30

  tags = {
    Name        = "petclinic-apache-error-logs"
    Environment = var.environment
    ForwardTo   = "newrelic"
  }
}

resource "aws_cloudwatch_log_group" "petclinic_userdata" {
  name              = "petclinic/userdata-logs"
  retention_in_days = 7

  tags = {
    Name        = "petclinic-userdata-logs"
    Environment = var.environment
    ForwardTo   = "newrelic"
  }
}

# ------------------------------------------------------------
# 2. IAM Role for NewRelic Log Forwarder Lambda
# ------------------------------------------------------------

resource "aws_iam_role" "newrelic_lambda_role" {
  name_prefix = "NewRelic-LogForwarder-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "NewRelic-LogForwarder-Lambda-Role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "newrelic_lambda_policy" {
  name = "NewRelic-LogForwarder-Policy"
  role = aws_iam_role.newrelic_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------
# 3. NewRelic Log Forwarder Lambda
#    Custom forwarder that sends CloudWatch logs to NewRelic
#    Log API via HTTP POST using the license key
# ------------------------------------------------------------

resource "aws_lambda_function" "newrelic_log_forwarder" {
  function_name = "NewRelic-PetClinic-LogForwarder"
  description   = "Forwards CloudWatch logs from PetClinic to NewRelic"
  role          = aws_iam_role.newrelic_lambda_role.arn

  filename         = "${path.module}/nr-log-forwarder.zip"
  source_code_hash = filebase64sha256("${path.module}/nr-log-forwarder.zip")

  handler = "function.lambda_handler"
  runtime = "python3.12"
  timeout = 30

  environment {
    variables = {
      LICENSE_KEY         = var.newrelic_license_key
      LOGGING_ENABLED     = "true"
      NR_LOGGING_ENDPOINT = "https://log-api.newrelic.com/log/v1"
    }
  }

  tags = {
    Name        = "NewRelic-PetClinic-LogForwarder"
    Environment = var.environment
  }
}

# Allow CloudWatch Logs to invoke the Lambda
resource "aws_lambda_permission" "allow_cloudwatch_app" {
  statement_id  = "AllowCWLogsApp"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.newrelic_log_forwarder.function_name
  principal     = "logs.ap-south-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.petclinic_app.arn}:*"
}

resource "aws_lambda_permission" "allow_cloudwatch_apache_access" {
  statement_id  = "AllowCWLogsApacheAccess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.newrelic_log_forwarder.function_name
  principal     = "logs.ap-south-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.petclinic_apache_access.arn}:*"
}

resource "aws_lambda_permission" "allow_cloudwatch_apache_error" {
  statement_id  = "AllowCWLogsApacheError"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.newrelic_log_forwarder.function_name
  principal     = "logs.ap-south-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.petclinic_apache_error.arn}:*"
}

resource "aws_lambda_permission" "allow_cloudwatch_userdata" {
  statement_id  = "AllowCWLogsUserdata"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.newrelic_log_forwarder.function_name
  principal     = "logs.ap-south-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.petclinic_userdata.arn}:*"
}

# ------------------------------------------------------------
# 4. CloudWatch Subscription Filters → Lambda (real-time forwarding)
# ------------------------------------------------------------

resource "aws_cloudwatch_log_subscription_filter" "petclinic_app_to_newrelic" {
  name            = "petclinic-app-to-newrelic"
  log_group_name  = aws_cloudwatch_log_group.petclinic_app.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.newrelic_log_forwarder.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch_app]
}

resource "aws_cloudwatch_log_subscription_filter" "petclinic_apache_access_to_newrelic" {
  name            = "petclinic-apache-access-to-newrelic"
  log_group_name  = aws_cloudwatch_log_group.petclinic_apache_access.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.newrelic_log_forwarder.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch_apache_access]
}

resource "aws_cloudwatch_log_subscription_filter" "petclinic_apache_error_to_newrelic" {
  name            = "petclinic-apache-error-to-newrelic"
  log_group_name  = aws_cloudwatch_log_group.petclinic_apache_error.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.newrelic_log_forwarder.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch_apache_error]
}

resource "aws_cloudwatch_log_subscription_filter" "petclinic_userdata_to_newrelic" {
  name            = "petclinic-userdata-to-newrelic"
  log_group_name  = aws_cloudwatch_log_group.petclinic_userdata.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.newrelic_log_forwarder.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch_userdata]
}
