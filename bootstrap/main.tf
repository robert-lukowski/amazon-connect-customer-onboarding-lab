locals {
  github_repository = "robert-lukowski/amazon-connect-customer-onboarding-lab"
  github_role_name  = "github-amazon-connect-lab-dev"

  state_tags = merge(
    {
      Environment = "dev"
      ManagedBy   = "Terraform"
      Purpose     = "terraform-state"
      Repository  = "amazon-connect-customer-onboarding-lab"
    },
    var.tags,
  )
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = merge(local.state_tags, { Name = var.state_bucket_name })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.terraform_state]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  tags = merge(
    local.state_tags,
    { Name = "github-actions" },
  )
}

resource "aws_iam_role" "github_deployment" {
  name = local.github_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GitHubActionsMainBranch"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:robert-lukowski@207513888/amazon-connect-customer-onboarding-lab@1333003528:*"
          }
        }
      },
    ]
  })

  tags = merge(
    local.state_tags,
    { Name = local.github_role_name },
  )
}

resource "aws_iam_role_policy_attachment" "amazon_connect_full_access" {
  role       = aws_iam_role.github_deployment.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonConnect_FullAccess"
}

resource "aws_iam_role_policy" "terraform_state" {
  name = "terraform-state-customers"
  role = aws_iam_role.github_deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListTerraformStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "ManageCustomerTerraformState"
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/customers/*"
      },
    ]
  })
}
