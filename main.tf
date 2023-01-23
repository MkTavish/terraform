# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

provider "archive" {}

# data "archive_file" "zip" {
#   type        = "zip"
#   source_file = "hello_lambda.py"
#   output_path = "hello_lambda.zip"
# }

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

# resource "aws_lambda_function" "lambda" {
#   function_name = "hello_lambda"

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

# data "external" "lambda_directories" {
#   program = ["bash", "-c", "find ./lambda_functions -type d -mindepth 1 -maxdepth 1"]
# }

# data "external" "zip_lambda_code" {
#   for_each = data.external.lambda_directories.result
#   program = ["bash", "-c", "cd ${each.value} && zip -r function_code.zip ."]
# }


# resource "aws_lambda_function" "lambda_function" {
#   for_each = data.external.lambda_directories.result
#   filename = "${data.external.zip_lambda_code[each.key].result}"
#   function_name = "${basename(each.value)}"
#   role = "${aws_iam_role.iam_for_lambda.arn}"
#   handler = "hello_lambda.lambda_handler"
#   runtime = "python3.9"
#   source_code_hash ="${filebase64sha256("${data.external.zip_lambda_code[each.key].result}")}"
#   #source_code_zip = "${data.external.zip_lambda_code[each.key].result}"
# }

# data "external" "lambda_directories" {
#   program = ["bash", "-c", "find ./lambda_functions -type d -mindepth 1 -maxdepth 1 -print0"]
# }

# resource "aws_lambda_function" "lambda_function" {
#   for_each = data.external.lambda_directories.result

#   function_name = "${basename(each.value)}"
#   role = ""
#   handler = "hello_lambda.lambda_handler"
#   runtime = "python3.9"
#   source_code_hash = "${data.archive_file.lambda_function_code[each.key].output_sha256}"
#   filename = "${data.archive_file.lambda_function_code[each.key].output_path}"
# }

# data "archive_file" "lambda_function_code" {
#   for_each = data.external.lambda_directories.result
#   type        = "zip"
#   source_dir  = "${each.value}"
#   output_path = "${each.value}/function_code.zip"
# }

resource "null_resource" "zip_lambda" {
  # triggers = {
  #   lambda_function_sha1 = sha1(file("${path.module}/lambda_functions/**"))
  # }
  provisioner "local-exec" {
    command = <<CMD
    for i in lambda_functions/*/; do zip -r "$${i%/}.zip" "$i"; done
    CMD
  }
}

resource "aws_lambda_function" "lambda_function" {
  #depends_on  = [null_resource.zip_lambda]
  for_each = fileset(path.module, "lambda_functions/*.zip")
  filename = "${each.key}"
  function_name = "${replace(replace(each.key, "lambda_functions/", ""), ".zip", "")}"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "hello_lambda.lambda_handler"
  runtime = "python3.9"
  source_code_hash = filebase64sha256("${each.key}")
}