# Cloudwatch event rule
resource "aws_cloudwatch_event_rule" "populate_nlb_tg_with_rds_event" {
  name                = "populate-nlb-tg-with-rds-event"
  description         = "populate_nlb_tg_with_rds-event"
  schedule_expression = var.schedule_expression
  depends_on          = [
                  aws_lambda_function.populate_nlb_tg_with_rds_updater_80,
                  aws_lambda_function.populate_nlb_tg_with_rds_updater_443
                ]
}

# Cloudwatch event target
resource "aws_cloudwatch_event_target" "populate_nlb_tg_with_rds_event_lambda_80_target" {
  target_id = "populate-nlb-tg-with-rds-event-lambda-80-target"
  rule      = aws_cloudwatch_event_rule.populate_nlb_tg_with_rds_event.name
  arn       = aws_lambda_function.populate_nlb_tg_with_rds_updater_80.arn
}

resource "aws_cloudwatch_event_target" "populate_nlb_tg_with_rds_event_lambda_443_target" {
  target_id = "populate-nlb-tg-with-rds-event-lambda-443-target"
  rule      = aws_cloudwatch_event_rule.populate_nlb_tg_with_rds_event.name
  arn       = aws_lambda_function.populate_nlb_tg_with_rds_updater_443.arn
}

# permissions to each Lambda function to allow them to be triggered by Cloudwatch
resource "aws_lambda_permission" "allow_cloudwatch_80" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.populate_nlb_tg_with_rds_updater_80.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.populate_nlb_tg_with_rds_event.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_443" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.populate_nlb_tg_with_rds_updater_443.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.populate_nlb_tg_with_rds_event.arn
}


# IAM Role for Lambda function
resource "aws_iam_role_policy" "populate_nlb_tg_with_rds_lambda" {
  name = "static-lb-lambda"
  role = aws_iam_role.populate_nlb_tg_with_rds_lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ],
      "Effect": "Allow",
      "Sid": "LambdaLogging"
    },
    {
      "Action": [
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ],
      "Resource": [
        "${var.nlb_tg_arn}"
      ],
      "Effect": "Allow",
      "Sid": "ChangeTargetGroups"
    },
    {
      "Action": [
        "elasticloadbalancing:DescribeTargetHealth"
      ],
      "Resource": "*",
      "Effect": "Allow",
      "Sid": "DescribeTargetGroups"
    },
    {
      "Action": [
        "cloudwatch:putMetricData"
      ],
      "Resource": "*",
      "Effect": "Allow",
      "Sid": "CloudWatch"
    }
  ]
}
EOF
}

resource "aws_iam_role" "populate_nlb_tg_with_rds_lambda" {
  name        = "populate-nlb-tg-with-rds-lambda"
  description = "Managed by Terraform"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# AWS Lambda need a zip file
data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/lambda_function.zip"
}

# AWS Lambda function
resource "aws_lambda_function" "populate_nlb_tg_with_rds_updater_80" {
  filename         = data.archive_file.lambda_function.output_path
  function_name    = "populate_nlb_tg_with_rds_updater_80"
  role             = aws_iam_role.populate_nlb_tg_with_rds_lambda.arn
  handler          = "populate_nlb_tg_with_rds.handler"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  runtime          = "python3.8"
  memory_size      = 128
  timeout          = 300

  environment {
    variables = {
      RDS_DNS_NAME                      = var.rds_dns_name
      NLB_TG_ARN                        = var.nlb_tg_arn
      MAX_LOOKUP_PER_INVOCATION         = var.max_lookup_per_invocation
    }
  }
}


resource "aws_lambda_function" "populate_nlb_tg_with_rds_updater_443" {
  filename         = data.archive_file.lambda_function.output_path
  function_name    = "populate_nlb_tg_with_rds_updater_443"
  role             = aws_iam_role.populate_nlb_tg_with_rds_lambda.arn
  handler          = "populate_nlb_tg_with_rds.handler"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  runtime          = "python3.8"
  memory_size      = 128
  timeout          = 300

  environment {
    variables = {
      RDS_DNS_NAME                      = var.rds_dns_name
      NLB_TG_ARN                        = var.nlb_tg_arn
      MAX_LOOKUP_PER_INVOCATION         = var.max_lookup_per_invocation
    }
  }
}

