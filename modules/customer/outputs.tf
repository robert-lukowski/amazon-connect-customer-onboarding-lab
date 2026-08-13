output "hours_of_operation_ids" {
  description = "Hours-of-operation IDs keyed by stable logical key."
  value = {
    for key, resource in aws_connect_hours_of_operation.this :
    key => resource.hours_of_operation_id
  }
}

output "queue_ids" {
  description = "Queue IDs keyed by stable logical key."
  value = {
    for key, resource in aws_connect_queue.this :
    key => resource.queue_id
  }
}

output "routing_profile_ids" {
  description = "Routing profile IDs keyed by stable logical key."
  value = {
    for key, resource in aws_connect_routing_profile.this :
    key => resource.routing_profile_id
  }
}

output "security_profile_ids" {
  description = "Security profile IDs keyed by stable logical key."
  value = {
    for key, resource in aws_connect_security_profile.this :
    key => resource.security_profile_id
  }
}
