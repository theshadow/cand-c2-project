# Designate a cloud provider, region, and credentials
provider "aws" {
  profile = "sandbox-xander-guzman"
  region = "us-west-2"
}

# Convert the src python file to a zip before uploading it as lambda function.
data "archive_file" "dir_hash_zip" {
  type        = "zip"
  source_dir  = "${path.cwd}/src"
  output_path = "${path.module}/lambda_function.zip"
}


resource "aws_lambda_function" "lambda" {
  filename         = "lambda_function.zip"
  description      = "Udacity Greet Lambda function"
  function_name    = "greet_lambda"
  handler          = "greet_lambda.lambda_handler"
  runtime          = "python3.6"
  role             = aws_iam_role.lambda_exec.arn
  source_code_hash = data.archive_file.dir_hash_zip.output_base64sha256

  environment {
    variables = {
      greeting = "Hello"
    }
  }
}

# Create an IAM role which determines which other AWS services the Lambda function can access.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

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

# Making sure that Lambda function is able to write CloudWatch logs.
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

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
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Attaching the policy with the role.
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# Invoking the Lambda function. Our function doesn't require any input however.
data "aws_lambda_invocation" "test" {
  function_name = aws_lambda_function.lambda.function_name
  input = <<JSON
{
  "irrelevant": "sample",
  "input": "values"
}
JSON
}

# Collecting the output inside a variable which will be printed out during Terraform Apply phase.
output "Lambda-Execution-Result" {
  description = "Greeting output"
  value       = data.aws_lambda_invocation.test.result
}

