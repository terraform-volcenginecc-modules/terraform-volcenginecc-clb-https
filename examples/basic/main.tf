terraform {
  required_version = "= 1.5.7"

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.73"
    }
  }
}

provider "volcenginecc" {}

module "https" {
  source = "../.."

  load_balancer_id           = var.load_balancer_id
  default_server_group_id    = var.default_server_group_id
  certificate_source         = var.certificate_source
  certificate_id             = var.certificate_id
  cert_center_certificate_id = var.cert_center_certificate_id
  https_listener_name        = var.https_listener_name
  security_policy_id         = var.security_policy_id
  health_check               = var.health_check
}

output "https_listener_id" {
  value = module.https.https_listener_id
}
