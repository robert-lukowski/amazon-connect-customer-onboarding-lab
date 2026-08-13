output "customer_resources" {
  description = "Amazon Connect resource IDs grouped by type and stable logical key."
  value = {
    hours_of_operation = module.customer.hours_of_operation_ids
    queues             = module.customer.queue_ids
    routing_profiles   = module.customer.routing_profile_ids
    security_profiles  = module.customer.security_profile_ids
  }
}
