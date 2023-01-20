# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "hello_lambda.py"
  output_path = "hello_lambda.zip"
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_lambda_function" "lambda" {
  function_name = "hello_lambda"

  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  role    = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "hello_lambda.lambda_handler"
  runtime = "python3.9"

  environment {
    variables = {
      greeting = "Hello"
    }
  }
}

data "external" "lambda_directories" {
  program = ["bash", "-c", "find ./lambda_functions -type d -mindepth 1 -maxdepth 1"]
}
resource "aws_lambda_function" "lambda_function" {
  for_each = data.external.lambda_directories.result
  #filename = "${each.value}/function.zip"
  function_name = "${basename(each.value)}"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "hello_lambda.lambda_handler"
  runtime = "python3.9"
  source_code_hash = "${zipfile("${each.value}/")}"
  source_code_zip = "${zipfile("${each.value}/")}"
}



# resource "aws_lambda_function" "lambda2" {
#   function_name = "hello_lambda2"

#   filename         = "${data.archive_file.zip.output_path}"
#   source_code_hash = "${data.archive_file.zip.output_base64sha256}"

#   role    = "${aws_iam_role.iam_for_lambda.arn}"
#   handler = "hello_lambda.lambda_handler"
#   runtime = "python3.9"

#   environment {
#     variables = {
#       greeting = "Hello"
#     }
#   }
# }