variable "load_balancer_id" {
  type        = string
  description = "Existing CLB ID."
}

variable "default_server_group_id" {
  type        = string
  description = "Existing server group ID with a healthy HTTP backend."
}

variable "certificate_source" {
  type        = string
  description = "Certificate source: clb or cert_center."
}

variable "certificate_id" {
  type        = string
  default     = null
  description = "CLB certificate ID when certificate_source is clb."
}

variable "cert_center_certificate_id" {
  type        = string
  default     = null
  description = "Certificate Center certificate ID when certificate_source is cert_center."
}

variable "https_listener_name" {
  type        = string
  default     = "tf-module-basic-https"
  description = "HTTPS listener name."
}

variable "security_policy_id" {
  type        = string
  default     = "tls_cipher_policy_1_2"
  description = "TLS policy ID."
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
  description = "Health-check settings."
}
