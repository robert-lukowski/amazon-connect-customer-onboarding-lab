variable "aws_region" {
  description = "AWS region for Phase 1 DEV resources."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = var.aws_region == "eu-central-1"
    error_message = "Phase 1 supports only eu-central-1."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "Phase 1 supports only the dev environment."
  }
}

variable "connect_instance_alias" {
  description = "Alias of the existing Amazon Connect instance."
  type        = string
  default     = "robert-support"

  validation {
    condition     = var.connect_instance_alias == "robert-support"
    error_message = "Phase 1 targets the existing robert-support instance only."
  }
}

variable "customer_key" {
  description = "Stable customer key used for names and module identity."
  type        = string
  default     = "demo-a"

  validation {
    condition     = can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*$", var.customer_key))
    error_message = "customer_key must contain lowercase letters, numbers, and single hyphens only."
  }

  validation {
    condition     = fileexists("${path.root}/../customers/${var.customer_key}/customer.yaml")
    error_message = "Customer configuration customers/${var.customer_key}/customer.yaml does not exist."
  }
}
