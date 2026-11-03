# terraform-volcenginecc-clb-https

> Status: `partial-validated`. With Terraform `1.5.7` and Registry Provider
> `volcengine/volcenginecc v0.0.73`, the basic HTTPS listener lifecycle has
> passed. The complete scenario is blocked by concurrent CLB rule creation in
> the Provider/API and is not ready for InfraManager default parallelism.

## Overview

This module manages HTTPS and optional HTTP CLB listeners on a caller-owned
CLB. It binds a caller-owned CLB or Certificate Center certificate, configures
the TLS policy and health check, creates an optional HTTP-to-HTTPS redirect,
and creates HTTPS domain/path forwarding rules.

The module does not create or import the CLB, certificate, DNS record, backend
server groups, or backend servers.

## Usage

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

Provider credentials, region, and backend configuration belong to the calling
root module.

## Requirements

| Name | Version |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `= 0.0.73` |

## Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## Resources

| Resource | Purpose |
|---|---|
| `volcenginecc_clb_listener.https` | HTTPS listener, certificate, TLS policy, health check |
| `volcenginecc_clb_listener.http` | Optional HTTP listener |
| `volcenginecc_clb_rule.http_redirect` | Optional permanent HTTP-to-HTTPS redirect |
| `volcenginecc_clb_rule.https_forward` | HTTPS domain/path forwarding rules |

## Inputs

| Name | Required | Description |
|---|---|---|
| `load_balancer_id` | Yes | Existing CLB ID |
| `default_server_group_id` | Yes | Existing default backend server group |
| `certificate_source` | Yes | `clb` or `cert_center` |
| `certificate_id` | Conditional | CLB certificate ID when source is `clb` |
| `cert_center_certificate_id` | Conditional | Certificate Center ID when source is `cert_center` |
| `security_policy_id` | No | HTTPS TLS policy; default `tls_cipher_policy_1_2` |
| `health_check` | No | HTTPS/HTTP health-check configuration |
| `enable_http_redirect` | No | Create HTTP listener and 301 redirect |
| `redirect_domain` | Conditional | Required when HTTP redirect is enabled |
| `forwarding_rules` | No | Stable-keyed HTTPS domain/path rules |

## Outputs

| Name | Description |
|---|---|
| `https_listener_id` | HTTPS listener ID |
| `http_listener_id` | HTTP listener ID or `null` |
| `http_redirect_rule_id` | Redirect rule ID or `null` |
| `https_forwarding_rule_ids` | Forwarding rule IDs by input key |

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
- `basic` passed `plan -> apply -> independent read-back -> second plan with
  no changes -> destroy`. The certificate was detached and all test resources
  were absent after destroy.
- `complete` failed under normal Terraform concurrency: simultaneous CLB Rule
  creates returned `InvalidLoadBalancer.InvalidStatus`. Do not claim
  InfraManager default-parallelism support until the Provider/API serializes
  rule operations or supports concurrent creation.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
