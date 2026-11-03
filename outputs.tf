output "https_listener_id" {
  description = "ID of the module-managed HTTPS listener."
  value       = volcenginecc_clb_listener.https.listener_id
}

output "http_listener_id" {
  description = "ID of the module-managed HTTP listener, or null when redirect is disabled."
  value       = try(volcenginecc_clb_listener.http[0].listener_id, null)
}

output "http_redirect_rule_id" {
  description = "ID of the HTTP-to-HTTPS redirect rule, or null when redirect is disabled."
  value       = try(volcenginecc_clb_rule.http_redirect[0].rule_id, null)
}

output "https_forwarding_rule_ids" {
  description = "HTTPS forwarding rule IDs by stable input key."
  value = {
    for key, rule in volcenginecc_clb_rule.https_forward :
    key => rule.rule_id
  }
}
