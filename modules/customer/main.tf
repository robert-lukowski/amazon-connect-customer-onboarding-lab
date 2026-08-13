locals {
  name_prefix = "${var.customer_key}-${var.environment}"
  common_tags = merge(
    var.configuration.tags,
    {
      Customer    = var.customer_key
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
  )
}

resource "aws_connect_hours_of_operation" "this" {
  for_each = var.configuration.hours_of_operation

  instance_id = var.instance_id
  name        = "${local.name_prefix}-${each.value.name}"
  description = each.value.description
  time_zone   = each.value.time_zone

  dynamic "config" {
    for_each = {
      for period in flatten([
        for day, intervals in each.value.schedule : [
          for index, interval in intervals : {
            key   = "${upper(day)}-${index}"
            day   = upper(day)
            start = interval.start
            end   = interval.end
          }
        ]
      ]) : period.key => period
    }

    content {
      day = config.value.day

      start_time {
        hours   = tonumber(split(":", config.value.start)[0])
        minutes = tonumber(split(":", config.value.start)[1])
      }

      end_time {
        hours   = tonumber(split(":", config.value.end)[0])
        minutes = tonumber(split(":", config.value.end)[1])
      }
    }
  }

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-${each.value.name}" },
  )
}

resource "aws_connect_queue" "this" {
  for_each = var.configuration.queues

  instance_id           = var.instance_id
  name                  = "${local.name_prefix}-${each.value.name}"
  description           = each.value.description
  hours_of_operation_id = aws_connect_hours_of_operation.this[each.value.hours_of_operation_key].hours_of_operation_id

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-${each.value.name}" },
  )
}

resource "aws_connect_routing_profile" "this" {
  for_each = var.configuration.routing_profiles

  instance_id               = var.instance_id
  name                      = "${local.name_prefix}-${each.value.name}"
  description               = each.value.description
  default_outbound_queue_id = aws_connect_queue.this[each.value.default_outbound_queue_key].queue_id

  dynamic "media_concurrencies" {
    for_each = each.value.media_concurrencies

    content {
      channel     = upper(media_concurrencies.value.channel)
      concurrency = media_concurrencies.value.concurrency

      cross_channel_behavior {
        behavior_type = upper(media_concurrencies.value.cross_channel_behavior)
      }
    }
  }

  dynamic "queue_configs" {
    for_each = each.value.queue_configs

    content {
      channel  = upper(queue_configs.value.channel)
      delay    = queue_configs.value.delay
      priority = queue_configs.value.priority
      queue_id = aws_connect_queue.this[queue_configs.value.queue_key].queue_id
    }
  }

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-${each.value.name}" },
  )
}

resource "aws_connect_security_profile" "this" {
  for_each = var.configuration.security_profiles

  instance_id = var.instance_id
  name        = "${local.name_prefix}-${each.value.name}"
  description = each.value.description
  permissions = each.value.permissions

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-${each.value.name}" },
  )
}
