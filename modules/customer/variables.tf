variable "customer_key" {
  description = "Stable lowercase customer identifier used as the resource-name prefix."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*$", var.customer_key))
    error_message = "customer_key must contain lowercase letters, numbers, and single hyphens only."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = var.environment == "dev"
    error_message = "Phase 1 supports only the dev environment."
  }
}

variable "instance_id" {
  description = "Identifier of the existing Amazon Connect instance."
  type        = string
}

variable "configuration" {
  description = "Customer business configuration decoded from customer.yaml."
  type = object({
    tags = optional(map(string), {})
    hours_of_operation = map(object({
      name        = string
      description = string
      time_zone   = string
      schedule = map(list(object({
        start = string
        end   = string
      })))
    }))
    queues = map(object({
      name                   = string
      description            = string
      hours_of_operation_key = string
    }))
    routing_profiles = map(object({
      name                       = string
      description                = string
      default_outbound_queue_key = string
      media_concurrencies = map(object({
        channel                = string
        concurrency            = number
        cross_channel_behavior = string
      }))
      queue_configs = map(object({
        queue_key = string
        channel   = string
        delay     = number
        priority  = number
      }))
    }))
    security_profiles = map(object({
      name        = string
      description = string
      permissions = set(string)
    }))
  })

  validation {
    condition = alltrue([
      for queue in values(var.configuration.queues) :
      contains(keys(var.configuration.hours_of_operation), queue.hours_of_operation_key)
    ])
    error_message = "Every queue hours_of_operation_key must reference a defined hours_of_operation key."
  }

  validation {
    condition = alltrue([
      for profile in values(var.configuration.routing_profiles) :
      contains(keys(var.configuration.queues), profile.default_outbound_queue_key)
    ])
    error_message = "Every routing profile default_outbound_queue_key must reference a defined queue key."
  }

  validation {
    condition = alltrue(flatten([
      for profile in values(var.configuration.routing_profiles) : [
        for queue_config in values(profile.queue_configs) :
        contains(keys(var.configuration.queues), queue_config.queue_key)
      ]
    ]))
    error_message = "Every routing profile queue_config queue_key must reference a defined queue key."
  }

  validation {
    condition = alltrue([
      for hours in values(var.configuration.hours_of_operation) :
      length(hours.schedule) > 0
    ])
    error_message = "Every hours-of-operation schedule must contain at least one day."
  }

  validation {
    condition = alltrue(flatten([
      for hours in values(var.configuration.hours_of_operation) : [
        for day, intervals in hours.schedule :
        contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], upper(day)) &&
        length(intervals) > 0 &&
        alltrue([
          for interval in intervals :
          can(regex("^(?:[01][0-9]|2[0-3]):[0-5][0-9]$", interval.start)) &&
          can(regex("^(?:[01][0-9]|2[0-3]):[0-5][0-9]$", interval.end)) &&
          try(
            (
              tonumber(split(":", interval.start)[0]) * 60 +
              tonumber(split(":", interval.start)[1])
              ) < (
              tonumber(split(":", interval.end)[0]) * 60 +
              tonumber(split(":", interval.end)[1])
            ),
            false,
          )
        ])
      ]
    ]))
    error_message = "Schedules require valid day names and non-empty HH:MM intervals whose start is before end."
  }

  validation {
    condition = alltrue([
      for profile in values(var.configuration.routing_profiles) :
      length(profile.media_concurrencies) > 0
    ])
    error_message = "Every routing profile must define at least one media concurrency."
  }

  validation {
    condition = alltrue([
      for profile in values(var.configuration.routing_profiles) :
      length(distinct([
        for media in values(profile.media_concurrencies) :
        upper(media.channel)
      ])) == length(profile.media_concurrencies)
    ])
    error_message = "Media concurrency channels must be unique within each routing profile."
  }

  validation {
    condition = alltrue(flatten([
      for profile in values(var.configuration.routing_profiles) : [
        for queue_config in values(profile.queue_configs) :
        contains(
          [
            for media in values(profile.media_concurrencies) :
            upper(media.channel)
          ],
          upper(queue_config.channel),
        )
      ]
    ]))
    error_message = "Every routing profile queue-config channel must also exist in media_concurrencies."
  }

  validation {
    condition = alltrue(flatten([
      for profile in values(var.configuration.routing_profiles) : concat(
        [
          for media in values(profile.media_concurrencies) :
          contains(["VOICE", "CHAT", "TASK"], upper(media.channel)) &&
          contains(["ROUTE_CURRENT_CHANNEL_ONLY", "ROUTE_ANY_CHANNEL"], upper(media.cross_channel_behavior)) &&
          media.concurrency >= 1 &&
          media.concurrency <= (upper(media.channel) == "VOICE" ? 1 : 10)
        ],
        [
          for queue_config in values(profile.queue_configs) :
          contains(["VOICE", "CHAT", "TASK"], upper(queue_config.channel)) &&
          queue_config.delay >= 0 &&
          queue_config.priority >= 1
        ],
      )
    ]))
    error_message = "Routing channels, concurrency, cross-channel behavior, delay, or priority are invalid."
  }
}
