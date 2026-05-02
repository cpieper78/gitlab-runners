# Remote state backend.
#
# Local state is the default while bootstrapping. To switch to S3+DynamoDB:
#   1. Create the bucket and lock table out-of-band (see README "Bootstrap").
#   2. Uncomment the block below and fill in the values.
#   3. Run: terraform init -migrate-state
#
# terraform {
#   backend "s3" {
#     bucket         = "REPLACE-ME-tfstate-bucket"
#     key            = "gitlab-runners/eks/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "REPLACE-ME-tfstate-locks"
#     encrypt        = true
#   }
# }
