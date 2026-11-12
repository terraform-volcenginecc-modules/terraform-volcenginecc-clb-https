variable "load_balancer_id" {
  type        = string
  description = "Existing CLB instance ID. The module does not create or import the CLB."

  validation {
    condition     = startswith(var.load_balancer_id, "clb-")
    error_message = "load_balancer_id must be a CLB ID beginning with clb-."
  }
}

variable "default_server_group_id" {
  type        = string
  description = "Existing backend server group ID used by the HTTPS listener and optional HTTP listener."

  validation {
    condition     = startswith(var.default_server_group_id, "rsp-")
    error_message = "default_server_group_id must be a server group ID beginning with rsp-."
  }
}

variable "certificate_source" {
  type        = string
  description = "Certificate source for the HTTPS listener: clb or cert_center."

  validation {
    condition     = contains(["clb", "cert_center"], var.certificate_source)
    error_message = "certificate_source must be clb or cert_center."
  }
}

variable "certificate_id" {
  type        = string
  default     = null
  description = "Existing CLB certificate ID. Set only when certificate_source is clb."

  validation {
    condition     = try(trimspace(var.certificate_id) != "", true)
    error_message = "certificate_id cannot be an empty string."
  }
}

variable "cert_center_certificate_id" {
  type        = string
  default     = null
  description = "Existing Certificate Center certificate ID. Set only when certificate_source is cert_center."

  validation {
    condition     = try(trimspace(var.cert_center_certificate_id) != "", true)
    error_message = "cert_center_certificate_id cannot be an empty string."
  }
}

variable "https_listener_name" {
  type        = string
  default     = "module-https"
  description = "Name for the module-managed HTTPS listener."
}

variable "https_listener_port" {
  type        = number
  default     = 443
  description = "HTTPS listener port. Changing it replaces the listener."

  validation {
    condition     = var.https_listener_port >= 1 && var.https_listener_port <= 65535
    error_message = "https_listener_port must be between 1 and 65535."
  }
}

variable "security_policy_id" {
  type        = string
  default     = "tls_cipher_policy_1_2"
  description = "TLS policy for the HTTPS listener."
}

variable "http_2_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable HTTP/2 on the HTTPS listener."
}

variable "health_check" {
  type = object({
    healthy_threshold   = number
    unhealthy_threshold = number
    interval            = number
    timeout             = number
    method              = string
    uri                 = string
    http_code           = string
    port                = number
  })
  default = {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 2
    method              = "GET"
    uri                 = "/healthz"
    http_code           = "http_2xx"
    port                = 0
  }
  description = "HTTPS and HTTP listener health-check configuration."

  validation {
    condition = (
      var.health_check.healthy_threshold >= 2 &&
      var.health_check.healthy_threshold <= 10 &&
      var.health_check.unhealthy_threshold >= 2 &&
      var.health_check.unhealthy_threshold <= 10 &&
      var.health_check.interval >= 1 &&
      var.health_check.interval <= 300 &&
      var.health_check.timeout >= 1 &&
      var.health_check.timeout <= 60 &&
      contains(["GET", "HEAD"], var.health_check.method) &&
      startswith(var.health_check.uri, "/") &&
      var.health_check.port >= 0 &&
      var.health_check.port <= 65535
    )
    error_message = "health_check values must meet CLB limits and uri must begin with /."
  }
}

variable "enable_http_redirect" {
  type        = bool
  default     = false
  description = "Whether to create an HTTP listener and a permanent redirect rule to HTTPS."
}

variable "http_listener_name" {
  type        = string
  default     = "module-http-redirect"
  description = "Name for the optional HTTP listener."
}

variable "http_listener_port" {
  type        = number
  default     = 80
  description = "HTTP listener port. Changing it replaces the listener."

  validation {
    condition     = var.http_listener_port >= 1 && var.http_listener_port <= 65535
    error_message = "http_listener_port must be between 1 and 65535."
  }
}

variable "redirect_domain" {
  type        = string
  default     = null
  description = "Exact domain matched by the HTTP redirect rule. Required when enable_http_redirect is true."

  validation {
    condition     = var.redirect_domain == null || can(regex("^[A-Za-z0-9][A-Za-z0-9.-]*\\.[A-Za-z0-9.-]+$", var.redirect_domain))
    error_message = "redirect_domain must be an exact domain name."
  }
}

variable "redirect_path" {
  type        = string
  default     = "/"
  description = "HTTP 重定向规则的匹配路径和目标路径；默认 / 会跳转到 HTTPS 根路径。"

  validation {
    condition     = startswith(var.redirect_path, "/")
    error_message = "redirect_path must begin with /."
  }
}

variable "forwarding_rules" {
  type = map(object({
    domain          = string
    url             = string
    server_group_id = string
  }))
  default     = {}
  description = "Stable-keyed HTTPS forwarding rules. Each rule sends a domain and path to an existing backend server group."

  validation {
    condition = alltrue([
      for rule in values(var.forwarding_rules) :
      can(regex("^[A-Za-z0-9][A-Za-z0-9.-]*\\.[A-Za-z0-9.-]+$", rule.domain)) &&
      startswith(rule.url, "/") &&
      startswith(rule.server_group_id, "rsp-")
    ])
    error_message = "Each forwarding rule requires an exact domain, a URL beginning with /, and an rsp- server group ID."
  }
}
