output "state_bucket_name" {
  description = "Name of the S3 bucket prepared for Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket prepared for Terraform state."
  value       = aws_s3_bucket.terraform_state.arn
}

output "github_deployment_role_arn" {
  description = "ARN assumed by the GitHub Actions DEV deployment workflow."
  value       = aws_iam_role.github_deployment.arn
}
