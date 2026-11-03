# Complete HTTPS Entry

Extends the basic scenario with an HTTP port 80 listener, a 301 redirect to
HTTPS, and stable-keyed HTTPS path rules directed at caller-owned backend
groups.

Provide an existing CLB, certificate, default backend group, and all backend
groups referenced by `forwarding_rules`.

```shell
terraform init
terraform plan
terraform apply
terraform destroy
```

The configuration supports certificate rotation by changing the selected
certificate ID. Real-cloud validation confirmed listener and certificate
behavior but found that concurrent Rule creation fails in the current
Provider/API. This example is therefore not approved for InfraManager default
parallelism until that issue is fixed.
