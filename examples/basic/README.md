# Basic HTTPS Listener

Creates a module-managed HTTPS listener on an existing CLB.

Provide an existing CLB ID, backend group ID, and certificate ID. The backend
group must already contain a reachable HTTP backend. Use either
`certificate_id` with `certificate_source = "clb"` or
`cert_center_certificate_id` with `certificate_source = "cert_center"`.

```shell
terraform init
terraform plan
terraform apply
terraform destroy
```

The example covers port 443, certificate binding, TLS policy
`tls_cipher_policy_1_2`, backend-group binding, and an explicit health check.
It does not create DNS, certificates, CLB instances, server groups, or servers.
