data "aws_connect_instance" "existing" {
  instance_alias = var.connect_instance_alias
}

module "customer" {
  source = "../modules/customer"

  configuration = local.customer_configuration
  customer_key  = var.customer_key
  environment   = var.environment
  instance_id   = data.aws_connect_instance.existing.id
}
