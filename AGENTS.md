# Repository working agreement

## Phase 1 boundaries

- Work in this repository only.
- Target AWS DEV in `eu-central-1` and the existing Amazon Connect instance alias `robert-support`.
- Keep customer business configuration under `customers/<customer-key>/customer.yaml`.
- Put reusable Amazon Connect resources in `modules/customer` and environment wiring in `terraform`.
- Use stable YAML map keys and Terraform `for_each`; resource names must begin with the customer key.
- Use one S3 state key per customer: `customers/<customer-key>/dev/terraform.tfstate`.

## Safety rules

- Never run `terraform apply` or `terraform destroy` unless a later task explicitly changes this rule.
- Do not access AWS while validating Phase 1. `terraform init -backend=false` and `terraform validate` are the supported checks.
- Do not add AWS access keys. Future AWS authentication must use GitHub OIDC.
- Never commit Terraform state, plan files, credentials, or local `.terraform` directories.
- Do not add CAT/PROD deployment logic or split this design across repositories in Phase 1.
- Lambda, CloudWatch alarms, Connect users, phone numbers, and complex contact flows are out of scope.

## Required verification

Run the following before handing off Terraform changes:

```powershell
terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
```
