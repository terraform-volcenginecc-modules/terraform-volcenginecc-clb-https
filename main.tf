resource "volcenginecc_clb_listener" "https" {
  load_balancer_id = var.load_balancer_id
  listener_name    = var.https_listener_name
  protocol         = "HTTPS"
  port             = var.https_listener_port
  server_group_id  = var.default_server_group_id

  certificate_source         = var.certificate_source
  certificate_id             = var.certificate_source == "clb" ? var.certificate_id : null
  cert_center_certificate_id = var.certificate_source == "cert_center" ? var.cert_center_certificate_id : null
  security_policy_id         = var.security_policy_id
  http_2_enabled             = var.http_2_enabled ? "on" : "off"

  health_check = {
    enabled             = "on"
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
    interval            = var.health_check.interval
    timeout             = var.health_check.timeout
    method              = var.health_check.method
    uri                 = var.health_check.uri
    http_code           = var.health_check.http_code
    port                = var.health_check.port
  }

  lifecycle {
    precondition {
      condition = (
        var.certificate_source == "clb" &&
        var.certificate_id != null &&
        var.cert_center_certificate_id == null
        ) || (
        var.certificate_source == "cert_center" &&
        var.cert_center_certificate_id != null &&
        var.certificate_id == null
      )
      error_message = "Set exactly one certificate ID matching certificate_source."
    }
  }
}

resource "volcenginecc_clb_listener" "http" {
  count = var.enable_http_redirect ? 1 : 0

  load_balancer_id = var.load_balancer_id
  listener_name    = var.http_listener_name
  protocol         = "HTTP"
  port             = var.http_listener_port
  server_group_id  = var.default_server_group_id

  health_check = {
    enabled             = "on"
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
    interval            = var.health_check.interval
    timeout             = var.health_check.timeout
    method              = var.health_check.method
    uri                 = var.health_check.uri
    http_code           = var.health_check.http_code
    port                = var.health_check.port
  }

  lifecycle {
    precondition {
      condition     = var.redirect_domain != null
      error_message = "redirect_domain is required when enable_http_redirect is true."
    }
  }
}

resource "volcenginecc_clb_rule" "http_redirect" {
  count = var.enable_http_redirect ? 1 : 0

  listener_id = volcenginecc_clb_listener.http[0].listener_id
  action_type = "Redirect"
  domain      = var.redirect_domain
  url         = var.redirect_path

  redirect_config = {
    protocol    = "HTTPS"
    host        = var.redirect_domain
    path        = var.redirect_path
    port        = tostring(var.https_listener_port)
    status_code = "301"
  }

  depends_on = [volcenginecc_clb_listener.https]
}

resource "volcenginecc_clb_rule" "https_forward" {
  for_each = var.forwarding_rules

  listener_id     = volcenginecc_clb_listener.https.listener_id
  action_type     = "Forward"
  domain          = each.value.domain
  url             = each.value.url
  server_group_id = each.value.server_group_id

  depends_on = [volcenginecc_clb_rule.http_redirect]
}
