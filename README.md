# terraform-volcenginecc-clb-https

> Status: `draft`. The module requires Terraform `1.5.7` and
> `volcengine/volcenginecc v0.0.73`. Default-parallel Rule operations are not
> ready for InfraManager until the Provider/API handles CLB configuration state.

## Overview

This module manages HTTPS and optional HTTP CLB listeners on a caller-owned
CLB. It binds a caller-owned CLB or Certificate Center certificate, configures
the TLS policy and health check, creates an optional HTTP-to-HTTPS redirect,
and creates HTTPS domain/path forwarding rules.

The module does not create or import the CLB, certificate, DNS record, backend
server groups, or backend servers.

## Usage

After the module is published, use its Registry address:

```hcl
module "https" {
  source = "terraform-volcenginecc-modules/clb-https/volcenginecc"

  load_balancer_id           = "clb-..."
  default_server_group_id    = "rsp-..."
  certificate_source         = "clb"
  certificate_id             = "cert-..."
  security_policy_id         = "tls_cipher_policy_1_2"
  enable_http_redirect       = true
  redirect_domain            = "app.example.com"
  forwarding_rules = {
    api = {
      domain          = "app.example.com"
      url             = "/api"
      server_group_id = "rsp-..."
    }
  }
}
```

Before publication, use the repository checkout as the module source in a
calling root configuration. Provider credentials, region, and backend
configuration belong to that calling root module.

## Requirements

| Name | Version |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `= 0.0.73` |

## Providers

| Name | Source | Version |
|---|---|---|
| `volcenginecc` | `volcengine/volcenginecc` | `= 0.0.73` |

## Resources

| Resource | Purpose |
|---|---|
| `volcenginecc_clb_listener.https` | HTTPS listener, certificate, TLS policy, health check |
| `volcenginecc_clb_listener.http` | Optional HTTP listener |
| `volcenginecc_clb_rule.http_redirect` | Optional permanent HTTP-to-HTTPS redirect |
| `volcenginecc_clb_rule.https_forward` | HTTPS domain/path forwarding rules |

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `load_balancer_id` | `string` | Yes | n/a | Existing CLB ID. |
| `default_server_group_id` | `string` | Yes | n/a | Existing default backend server group ID. |
| `certificate_source` | `string` | Yes | n/a | `clb` or `cert_center`. |
| `certificate_id` | `string` | Conditional | `null` | CLB certificate ID when source is `clb`. |
| `cert_center_certificate_id` | `string` | Conditional | `null` | Certificate Center ID when source is `cert_center`. |
| `security_policy_id` | `string` | No | `tls_cipher_policy_1_2` | TLS policy for HTTPS. |
| `health_check` | `object` | No | See `variables.tf` | Listener health-check configuration. |
| `enable_http_redirect` | `bool` | No | `false` | Create HTTP Listener and permanent redirect. |
| `redirect_domain` | `string` | Conditional | `null` | Required when redirect is enabled. |
| `forwarding_rules` | `map(object)` | No | `{}` | Stable-keyed HTTPS forwarding rules. |

## Outputs

| Name | Type | Description |
|---|---|
| `https_listener_id` | `string` | HTTPS listener ID. |
| `http_listener_id` | `string` | HTTP listener ID, or `null` when disabled. |
| `http_redirect_rule_id` | `string` | Redirect Rule ID, or `null` when disabled. |
| `https_forwarding_rule_ids` | `map(string)` | Forwarding Rule IDs by stable input key. |

## Examples

- [`examples/basic`](examples/basic): HTTPS port 443, certificate binding, TLS
  policy, backend group binding, and health check.
- [`examples/complete`](examples/complete): adds HTTP redirect and two
  domain/path rules for separate backend groups.

Both examples require caller-owned IDs and can be initialized independently.

## Notes

- Changing `load_balancer_id`, `protocol`, or listener port replaces the
  listener. Changing the certificate ID performs an in-place certificate
  rotation.
- Rule keys are stable Terraform addresses. Changing a rule key replaces that
  rule; changing a domain or URL may also require replacement.
- CLB requires `health_check.port = 0` to reuse the backend server port in
  this tested HTTP/HTTPS scenario.
- The CLB API can reject simultaneous Rule creates or deletes with
  `InvalidLoadBalancer.InvalidStatus`. Do not rely on default InfraManager
  parallelism until the Provider/API serializes or retries this operation.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
