# terraform-volcenginecc-clb-https

Configure HTTPS access, certificate binding, HTTP redirects, and domain/path forwarding on an existing CLB.

## 1. Overview

This module creates an HTTPS listener on an existing CLB, binds an existing certificate, and configures TLS, HTTP/2, and health checks. It can also add an HTTP listener, a 301 redirect to HTTPS, and forwarding rules for separate backend groups. It suits services that need HTTPS access or path-based routing. The caller supplies and maintains the CLB, certificates, DNS, backend groups, and servers.

## 2. Usage

Prepare a CLB, backend groups belonging to that CLB, and a compatible CLB or Certificate Center certificate in the same region. Backend groups must contain reachable HTTP services, and the listener ports must be available. Resolve the service domain to the CLB and use a certificate covering that domain.

Configure a minimal HTTPS entry in the caller's `main.tf`, replacing the sample IDs with existing resource IDs:

```hcl
module "https" {
  source  = "terraform-volcenginecc-modules/clb-https/volcenginecc"
  version = "~> 1.0"

  load_balancer_id        = "clb-..."
  default_server_group_id = "rsp-..."
  certificate_source      = "clb"
  certificate_id          = "cert-..."
}
```

For a Certificate Center certificate, set `certificate_source = "cert_center"`, supply `cert_center_certificate_id`, and remove `certificate_id`. Supply exactly one certificate ID matching the selected source.

Keep the version constraints and provider configuration in the caller's `provider.tf`:

```hcl
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
```

Supply `VOLCENGINE_ACCESS_KEY`, `VOLCENGINE_SECRET_KEY`, and `VOLCENGINE_REGION` through the runtime environment. The account must have permission to manage CLB listeners and rules and bind certificates. Choose the region containing the existing resources, for example:

```shell
export VOLCENGINE_REGION="cn-beijing"
```

Run these commands from the caller's root directory. The first four deploy the configuration and check idempotence. Run the last command only when removing the managed entry, after reviewing the deletion scope. Use `-parallelism=1` for every Plan, Apply, and Destroy:

```shell
terraform init
terraform plan -parallelism=1
terraform apply -parallelism=1
terraform plan -parallelism=1
terraform destroy -parallelism=1
```

## 3. Examples

- basic: Run from `examples/basic`. Supply an existing CLB, one backend group, and a certificate to create an HTTPS port 443 listener with a TLS policy and health checks.
- complete: Run from `examples/complete`. Supply an existing CLB, a certificate, and the backend groups referenced by the rules. Add a 301 redirect from HTTP port 80 to HTTPS port 443 and HTTPS rules matching the supplied domains and paths.

Configure each example independently. Its `provider.tf` declares the provider and version constraints; supply resource IDs through `terraform.tfvars` in that directory or through the runtime environment.

## 4. Requirements

| Name | Version |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `= 0.0.73` |

## 5. Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

The module uses the caller's default provider and declares no aliases.

## 6. Resources

| Mode | Type | Name |
|---|---|---|
| Create | `volcenginecc_clb_listener` | `volcenginecc_clb_listener.https` |
| Conditional create | `volcenginecc_clb_listener` | `volcenginecc_clb_listener.http` |
| Conditional create | `volcenginecc_clb_rule` | `volcenginecc_clb_rule.http_redirect` |
| Create per map entry | `volcenginecc_clb_rule` | `volcenginecc_clb_rule.https_forward` |

The module always creates one HTTPS listener. Enabling `enable_http_redirect` adds one HTTP listener and one redirect rule. Each `forwarding_rules` key creates one HTTPS forwarding rule. The module declares no data sources.

## 7. Inputs

| Name | Type | Default | Required in create mode | Description |
|---|---|---|---|---|
| `load_balancer_id` | `string` | None | Yes | Existing CLB ID beginning with `clb-`. Changing it replaces the listeners. |
| `default_server_group_id` | `string` | None | Yes | Default backend group belonging to the CLB, with an ID beginning with `rsp-`. Used by the HTTPS and optional HTTP listeners. |
| `certificate_source` | `string` | None | Yes | Certificate source: `clb` or `cert_center`. |
| `certificate_id` | `string` | `null` | Conditional | Existing CLB certificate ID when the source is `clb`; keep the Certificate Center ID `null`. A supplied value cannot be blank. |
| `cert_center_certificate_id` | `string` | `null` | Conditional | Existing Certificate Center certificate ID when the source is `cert_center`; keep the CLB certificate ID `null`. A supplied value cannot be blank. |
| `https_listener_name` | `string` | `"module-https"` | No | HTTPS listener name. |
| `https_listener_port` | `number` | `443` | No | HTTPS listener port, from 1 to 65535. Changing it replaces the listener. |
| `security_policy_id` | `string` | `"tls_cipher_policy_1_2"` | No | TLS policy ID for the HTTPS listener. |
| `http_2_enabled` | `bool` | `true` | No | Whether to enable HTTP/2 on the HTTPS listener. |
| `health_check` | `object` | Default object below | No | Applied to the HTTPS and optional HTTP listeners. Supply all fields below when customizing it. |
| `enable_http_redirect` | `bool` | `false` | No | Add an HTTP listener and a 301 redirect rule to HTTPS. |
| `http_listener_name` | `string` | `"module-http-redirect"` | No | Optional HTTP listener name. |
| `http_listener_port` | `number` | `80` | No | HTTP listener port, from 1 to 65535. Changing it replaces the listener. |
| `redirect_domain` | `string` | `null` | Conditional | Required when HTTP redirects are enabled. Exact domain used for both HTTP matching and the HTTPS redirect destination; no wildcards. |
| `redirect_path` | `string` | `"/"` | No | HTTP match path and redirect target path, beginning with `/`. The default redirects to the HTTPS root. Changing it replaces the redirect rule. |
| `forwarding_rules` | `map(object({ domain = string, url = string, server_group_id = string }))` | `{}` | No | Keys identify rules. Each entry provides an exact domain, a match path beginning with `/`, and an existing backend group ID beginning with `rsp-`. |

The full `health_check` type is:

```hcl
object({
  healthy_threshold   = number
  unhealthy_threshold = number
  interval            = number
  timeout             = number
  method              = string
  uri                 = string
  http_code           = string
  port                = number
})
```

Its default value is:

```hcl
health_check = {
  healthy_threshold   = 2
  unhealthy_threshold = 2
  interval            = 5
  timeout             = 2
  method              = "GET"
  uri                 = "/healthz"
  http_code           = "http_2xx"
  port                = 0
}
```

Healthy and unhealthy thresholds are 2–10 consecutive checks. The interval is 1–300 seconds, and the timeout is 1–60 seconds. Use `GET` or `HEAD` and a URI beginning with `/`. The module validates ports from 0 to 65535; `0` reuses each backend member's port. Specific ports and `http_code` values must also meet CLB service requirements. The default check requires `/healthz` to return a 2xx response.

For example, add these arguments to the module call to enable an HTTP redirect and API forwarding:

```hcl
enable_http_redirect = true
redirect_domain      = "app.example.com"
redirect_path        = "/"

forwarding_rules = {
  api = {
    domain          = "app.example.com"
    url             = "/api"
    server_group_id = "rsp-..."
  }
}
```

All three fields in each `forwarding_rules` entry are required. Backend groups must belong to the CLB identified by `load_balancer_id`. `redirect_path` determines the HTTP redirect destination; each rule's `url` determines HTTPS path matching. Configure them separately for the intended routing behavior.

## 8. Outputs

| Name | Type | Description |
|---|---|---|
| `https_listener_id` | `string` | ID of the created HTTPS listener, for querying the listener or connecting downstream configuration. |
| `http_listener_id` | `string` or `null` | ID of the created HTTP listener; `null` when HTTP redirects are disabled. |
| `http_redirect_rule_id` | `string` or `null` | ID of the HTTP-to-HTTPS redirect rule; `null` when HTTP redirects are disabled. |
| `https_forwarding_rule_ids` | `map(string)` | HTTPS forwarding rule IDs keyed by `forwarding_rules`; `{}` when no rules are configured. |

## 9. Notes

- Use `-parallelism=1` to create, update, and delete listeners and rules on the same CLB sequentially. Set Terraform parallelism to 1 when running through a platform as well.
- The caller maintains the CLB, certificates, DNS, backend groups, and servers. The module manages only newly created listeners and rules; `terraform destroy` removes only those objects.
- HTTP and HTTPS ports must differ and must not conflict with existing listeners. Changing the CLB ID or a listener port replaces listeners and can interrupt entry traffic.
- Keep `forwarding_rules` keys stable. Changing a key, domain, or match path replaces the corresponding rule.
- With `redirect_path = "/"`, matching HTTP requests redirect to the HTTPS root, including requests originally sent to `/api`. Configure the target path and HTTPS forwarding rules for the intended destination.
- To replace a certificate, update the certificate ID matching `certificate_source`. The module updates the binding; the caller handles certificate issuance and renewal.
- After Apply, run `terraform plan -parallelism=1` again and confirm no changes. This is the deployment's idempotence requirement.
- This project uses the MIT license, provided in `LICENSE`.
