variable "aws_region" {
  description = "AWS DEV region for the Terraform state bucket."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = var.aws_region == "eu-central-1"
    error_message = "Phase 1 supports only eu-central-1."
  }
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for DEV Terraform state. The caller must include a globally unique suffix, such as an account identifier or GUID."
  type        = string

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name)) &&
      !strcontains(var.state_bucket_name, "..") &&
      !can(regex("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$", var.state_bucket_name)) &&
      alltrue([
        for prefix in ["xn--", "sthree-", "amzn-s3-demo-"] :
        !startswith(var.state_bucket_name, prefix)
      ]) &&
      alltrue([
        for suffix in ["-s3alias", "--ol-s3", ".mrap", "--x-s3", "--table-s3", "-an"] :
        !endswith(var.state_bucket_name, suffix)
      ])
    )
    error_message = "state_bucket_name must satisfy the AWS general-purpose S3 bucket naming rules and include a caller-provided globally unique suffix."
  }
}

variable "tags" {
  description = "Additional tags for the Terraform state bucket."
  type        = map(string)
  default     = {}
}
