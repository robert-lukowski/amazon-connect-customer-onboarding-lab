locals {
  customer_config_path   = "${path.root}/../customers/${var.customer_key}/customer.yaml"
  customer_config_exists = fileexists(local.customer_config_path)

  customer_configuration = local.customer_config_exists ? yamldecode(file(local.customer_config_path)) : {
    tags               = {}
    hours_of_operation = {}
    queues             = {}
    routing_profiles   = {}
    security_profiles  = {}
  }
}
