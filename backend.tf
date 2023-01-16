terraform {
    backend "s3" {
        region         = "ca-central-1"
        bucket         = "woladodo"
        key            = "lambda/terraform.tfstate"
        # dynamodb_table = ""
        # profile        = ""
        # role_arn       = ""
        # encrypt        = true
    }
}