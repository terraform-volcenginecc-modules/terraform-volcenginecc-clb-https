# BASIC CLB HTTPS Example

## 1. Overview

This example creates one HTTPS port 443 listener on an existing CLB, binds an existing certificate, and configures TLS, HTTP/2, and health checks. Requests use the existing default backend group. The caller supplies the CLB, certificate, backend group, and reachable HTTP backend. Unlike complete, basic adds no HTTP redirect or custom HTTPS forwarding rules.

## 2. Usage

Use Terraform 1.5.7 and work from `examples/basic`. Confirm that port 443 is available, the default backend group belongs to the CLB, and the certificate can be bound in the same region. The default health check requests `/healthz` from the backend, which must return a 2xx response.

Supply `VOLCENGINE_ACCESS_KEY`, `VOLCENGINE_SECRET_KEY`, and `VOLCENGINE_REGION` through the runtime environment. `provider.tf` already declares the provider and version constraints; do not duplicate them in `main.tf`.

Create `terraform.tfvars` in this directory with existing resource IDs, replacing the sample values:

```hcl
load_balancer_id        = "clb-..."
default_server_group_id = "rsp-..."
certificate_source      = "clb"
certificate_id          = "cert-..."
```

For a Certificate Center certificate, set `certificate_source = "cert_center"`, supply `cert_center_certificate_id`, and remove `certificate_id`. Resolve the service domain to the CLB and use a certificate covering that domain.

Run these commands in order. The initial Plan should add only one HTTPS listener, and the Plan after Apply should show no changes. Run the final command only when removing the listener, after reviewing the deletion scope:

```shell
terraform init
terraform plan -parallelism=1
terraform apply -parallelism=1
terraform plan -parallelism=1
terraform destroy -parallelism=1
```

After deployment, use `https_listener_id` to locate the listener and access the HTTPS service through its domain.

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
| `module.https` | Uses `source = "terraform-volcenginecc-modules/clb-https/volcenginecc"` and `version = "~> 1.0"` to create an HTTPS listener with certificate binding and health checks. |

The example root declares no resources or data sources directly.

## 6. Inputs

| Name | Description |
|---|---|
| `load_balancer_id` | Required. Existing CLB ID beginning with `clb-`; port 443 must be available. |
| `default_server_group_id` | Required. Existing backend group ID beginning with `rsp-`, belonging to the CLB and containing a reachable HTTP backend. |
| `certificate_source` | Required. Select `clb` or `cert_center` to determine which certificate ID to supply. |
| `certificate_id` | Defaults to `null`. Required for the `clb` source, mutually exclusive with the Certificate Center ID, and cannot be blank. |
| `cert_center_certificate_id` | Defaults to `null`. Required for the `cert_center` source, mutually exclusive with the CLB certificate ID, and cannot be blank. |
| `https_listener_name` | Defaults to `"tf-module-basic-https"`; identifies the listener created by this example. |
| `security_policy_id` | Defaults to `"tls_cipher_policy_1_2"`; selects the HTTPS TLS policy. |
| `health_check` | Defaults to the object below. Supply all nine fields when customizing it; applied to the HTTPS listener. |

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

Thresholds, interval, timeout, and port are `number` values; method, URI, and response codes are `string` values. Healthy and unhealthy thresholds are 2–10 checks, the interval is 1–300 seconds, and the timeout is 1–60 seconds. Use `GET` or `HEAD` and a URI beginning with `/`. The module validates ports from 0 to 65535; `0` reuses the backend member's port. Specific ports and `http_code` values must also meet CLB service requirements.

## 7. Outputs

| Name | Description |
|---|---|
| `https_listener_id` | `string`. ID of the created HTTPS listener, for querying its configuration or connecting downstream resources. |

## 8. Example

This directory contains the basic example for services that need an HTTPS entry with requests handled by the default backend group. Use complete when HTTP redirects or domain/path forwarding are needed.

## 9. Notes

- Supply credentials through the provider-supported runtime environment, not source or variable files. Match the region to the existing resources.
- Use `-parallelism=1` for every Plan, Apply, and Destroy; set platform execution parallelism to 1 as well.
- Run `terraform plan -parallelism=1` again after Apply and confirm no changes to check idempotence.
- `terraform destroy` removes only the HTTPS listener managed by this example. Existing CLB, certificates, backend groups, servers, and DNS remain.
- HTTP/2 is enabled by default. This example uses HTTPS port 443 and does not expose a listener port or HTTP redirect switch.
- To replace a certificate, update the ID matching the selected source. The caller maintains certificate issuance, renewal, and DNS.
