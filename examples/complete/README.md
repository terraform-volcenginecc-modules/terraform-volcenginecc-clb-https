# COMPLETE CLB HTTPS Example

## 1. Overview

This example creates HTTPS port 443 and HTTP port 80 listeners on an existing CLB, binds an existing certificate, and configures TLS, HTTP/2, and health checks. It adds a 301 redirect to HTTPS and forwarding rules matching domains and paths. The caller supplies the CLB, certificate, default backend group, and groups referenced by the rules. Compared with basic, complete adds HTTP redirects and routing to multiple backend groups.

## 2. Usage

Use Terraform 1.5.7 and work from `examples/complete`. Confirm that ports 80 and 443 are available, all backend groups belong to the CLB, and the certificate can be bound in the same region. Each group must contain a reachable HTTP service returning a 2xx response for the default `/healthz` check.

Supply `VOLCENGINE_ACCESS_KEY`, `VOLCENGINE_SECRET_KEY`, and `VOLCENGINE_REGION` through the runtime environment. This directory's `provider.tf` already declares the provider and version constraints.

Configure `terraform.tfvars` in this directory, replacing the resource IDs and service domain:

```hcl
load_balancer_id        = "clb-..."
default_server_group_id = "rsp-default..."
certificate_source      = "clb"
certificate_id          = "cert-..."
redirect_domain         = "app.example.com"
redirect_path           = "/"

forwarding_rules = {
  root = {
    domain          = "app.example.com"
    url             = "/"
    server_group_id = "rsp-default..."
  }
  api = {
    domain          = "app.example.com"
    url             = "/api"
    server_group_id = "rsp-api..."
  }
}
```

For a Certificate Center certificate, set `certificate_source = "cert_center"`, supply `cert_center_certificate_id`, and remove `certificate_id`. Resolve the domain to the CLB and use a certificate covering that domain.

This configuration creates two listeners, one redirect rule, and two HTTPS forwarding rules. HTTPS `/api` requests use the API backend group. Matching HTTP requests redirect to the HTTPS root because `redirect_path = "/"`, then use the group selected by the root-path rule. Adjust domains, paths, and groups for the service; `forwarding_rules` determines the number of forwarding rules.

Run these commands in order. Review the initial Plan's additions before Apply. The Plan after Apply should show no changes. Run the final command only when removing the example's entry, after reviewing the deletion scope:

```shell
terraform init
terraform plan -parallelism=1
terraform apply -parallelism=1
terraform plan -parallelism=1
terraform destroy -parallelism=1
```

After deployment, locate the listeners and rules using their output IDs, then access the service domain to check HTTPS forwarding and the HTTP redirect destination.

## 3. Requirements

| Name | Version |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `= 0.0.73` |

Both constraints are declared in this directory's `provider.tf`.

## 4. Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

This example configures the default provider and passes it to `module.https`. No aliases are used.

## 5. Resources

| Name | Description |
|---|---|
| `module.https` | Uses `source = "terraform-volcenginecc-modules/clb-https/volcenginecc"` and `version = "~> 1.0"` to create HTTP/HTTPS listeners, a 301 redirect rule, and HTTPS rules for the supplied map entries. |

The example root declares no resources or data sources directly.

## 6. Inputs

| Name | Description |
|---|---|
| `load_balancer_id` | Required. Existing CLB ID beginning with `clb-`; ports 80 and 443 must be available. |
| `default_server_group_id` | Required. Existing default backend group belonging to the CLB, with an ID beginning with `rsp-`; used by both listeners. |
| `certificate_source` | Required. Select `clb` or `cert_center` to determine which certificate ID to supply. |
| `certificate_id` | Defaults to `null`. Required for the `clb` source, mutually exclusive with the Certificate Center ID, and cannot be blank. |
| `cert_center_certificate_id` | Defaults to `null`. Required for the `cert_center` source, mutually exclusive with the CLB certificate ID, and cannot be blank. |
| `https_listener_name` | Defaults to `"tf-module-complete-https"`; identifies the HTTPS listener. |
| `http_listener_name` | Defaults to `"tf-module-complete-http"`; identifies the HTTP listener. |
| `security_policy_id` | Defaults to `"tls_cipher_policy_1_2"`; selects the HTTPS TLS policy. |
| `redirect_domain` | Required. Exact domain for HTTP matching and the HTTPS redirect destination, without wildcards. Supply forwarding-rule domains separately. |
| `redirect_path` | Defaults to `"/"`. HTTP match path and redirect target, beginning with `/`; the default redirects to the HTTPS root. Changing it replaces the redirect rule. |
| `health_check` | Defaults to the object below. Supply all nine fields when customizing it; applied to both HTTP and HTTPS listeners. |
| `forwarding_rules` | Required `map(object)`; `{}` is allowed. Each key identifies an HTTPS rule. Supply `domain`, `url`, and `server_group_id` for every entry. |

All three `forwarding_rules` fields are `string` values: `domain` is an exact domain without wildcards, `url` is a match path beginning with `/`, and `server_group_id` is an existing backend group ID beginning with `rsp-` and belonging to this CLB.

The default `health_check` value is:

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

Thresholds, interval, timeout, and port are `number` values; method, URI, and response codes are `string` values. Healthy and unhealthy thresholds are 2–10 checks, the interval is 1–300 seconds, and the timeout is 1–60 seconds. Use `GET` or `HEAD` and a URI beginning with `/`. The module validates ports from 0 to 65535; `0` reuses each backend member's port. Specific ports and `http_code` values must also meet CLB service requirements.

## 7. Outputs

| Name | Description |
|---|---|
| `https_listener_id` | `string`. HTTPS listener ID, for querying certificates, TLS, health checks, and forwarding configuration. |
| `http_listener_id` | `string`. HTTP listener ID; this example always enables HTTP redirects. |
| `http_redirect_rule_id` | `string`. ID of the HTTP-to-HTTPS 301 redirect rule, for querying its destination configuration. |
| `https_forwarding_rule_ids` | `map(string)`. Rule IDs keyed by `forwarding_rules`; `{}` when the input map is `{}`. |

## 8. Example

This directory contains the complete example for services requiring both HTTP-to-HTTPS redirects and forwarding to multiple backend groups. Use basic when only an HTTPS entry with a default backend group is needed.

## 9. Notes

- Supply credentials through the provider-supported runtime environment, not source or variable files. Match the region to the existing resources.
- Use `-parallelism=1` for every Plan, Apply, and Destroy; set platform execution parallelism to 1 as well.
- Run `terraform plan -parallelism=1` again after Apply and confirm no changes to check idempotence.
- `terraform destroy` removes the two listeners, redirect rule, and HTTPS forwarding rules managed by this example. Existing CLB, certificates, backend groups, servers, and DNS remain.
- Keep forwarding-rule keys stable and avoid duplicate domain/path conditions. Changing a key, domain, or path replaces the corresponding rule.
- Configure the HTTP redirect destination and HTTPS path matching separately. The default target `/` uses the backend selected by the root-path rule. To redirect to another service path, configure `redirect_path` and the corresponding HTTPS rules.
- To replace a certificate, update the ID matching the selected source. The caller maintains certificate issuance and renewal.
