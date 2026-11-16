# BASIC CLB HTTPS 示例

## 1. 概述

本示例在已有 CLB 上创建一个 HTTPS 443 监听器，绑定已有证书，配置 TLS 策略、HTTP/2 和健康检查，并将请求交给已有默认后端组。调用方需要准备 CLB、证书、后端组和可访问的 HTTP 后端。与 complete 相比，本示例不增加 HTTP 跳转或自定义 HTTPS 分流规则。

## 2. 用法

使用 Terraform 1.5.7，在 `examples/basic` 目录操作。确认 CLB 的 443 端口可用，默认后端组属于该 CLB，证书可在同一地域绑定。默认健康检查访问后端的 `/healthz`，该地址应返回 2xx。

通过运行环境提供 `VOLCENGINE_ACCESS_KEY`、`VOLCENGINE_SECRET_KEY` 和 `VOLCENGINE_REGION`。`provider.tf` 已单独声明 Provider 和版本，无需在 `main.tf` 重复配置。

在本目录的 `terraform.tfvars` 中填写已有资源 ID，替换下列示例值：

```hcl
load_balancer_id        = "clb-..."
default_server_group_id = "rsp-..."
certificate_source      = "clb"
certificate_id          = "cert-..."
```

使用证书中心证书时，配置 `certificate_source = "cert_center"` 和 `cert_center_certificate_id`，并移除 `certificate_id`。服务域名应解析到 CLB，且由证书覆盖。

按顺序执行以下命令。首次 Plan 应只新增一个 HTTPS 监听器；Apply 后再次 Plan 应无变化。最后一条仅在需要移除该监听器、并确认删除范围后执行：

```shell
terraform init
terraform plan -parallelism=1
terraform apply -parallelism=1
terraform plan -parallelism=1
terraform destroy -parallelism=1
```

部署后使用 `https_listener_id` 确认监听器，并通过业务域名访问 HTTPS 服务。

## 3. 依赖要求

| 名称 | 版本 |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `= 0.0.73` |

版本约束均由本目录的 `provider.tf` 声明。

## 4. Providers

| 名称 | 来源 |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

默认 Provider 由本示例配置并传入 `module.https`，不使用 alias。

## 5. 资源

| 名称 | 说明 |
|---|---|
| `module.https` | 调用 `source = "terraform-volcenginecc-modules/clb-https/volcenginecc"`、`version = "~> 1.0"`，创建 HTTPS 监听器并配置证书和健康检查。 |

本示例根配置不直接声明 Resource 或 Data Source。

## 6. 输入

| 名称 | 说明 |
|---|---|
| `load_balancer_id` | 必填。已有 CLB ID，以 `clb-` 开头；该 CLB 需有可用的 443 端口。 |
| `default_server_group_id` | 必填。属于该 CLB 的已有后端组 ID，以 `rsp-` 开头，组内需有可访问的 HTTP 后端。 |
| `certificate_source` | 必填。选择 `clb` 或 `cert_center`，决定填写哪一种证书 ID。 |
| `certificate_id` | 默认 `null`。来源为 `clb` 时必填；与证书中心 ID 互斥，不能填写空白字符串。 |
| `cert_center_certificate_id` | 默认 `null`。来源为 `cert_center` 时必填；与 CLB 证书 ID 互斥，不能填写空白字符串。 |
| `https_listener_name` | 默认 `"tf-module-basic-https"`，用于识别本示例创建的监听器。 |
| `security_policy_id` | 默认 `"tls_cipher_policy_1_2"`，指定 HTTPS 的 TLS 策略。 |
| `health_check` | 默认对象如下。自定义时提供全部九个字段，应用于 HTTPS 监听器。 |

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

阈值、间隔、超时和端口为 `number`，方法、URI 和响应码为 `string`。健康及不健康阈值均为 2–10 次，间隔为 1–300 秒，超时为 1–60 秒；方法为 `GET` 或 `HEAD`，URI 以 `/` 开头。端口的模块校验范围为 0–65535，`0` 复用后端成员端口；具体端口和 `http_code` 还需满足 CLB 服务要求。

## 7. 输出

| 名称 | 说明 |
|---|---|
| `https_listener_id` | `string`，本示例创建的 HTTPS 监听器 ID，可用于查询监听配置或关联下游资源。 |

## 8. 示例

本目录即为 basic 示例，适用于只需要 HTTPS 入口、由默认后端组处理请求的服务。需要 HTTP 跳转或按域名、路径分流时，可使用 complete 示例。

## 9. 说明

- 凭据通过 Provider 支持的运行环境传入，不写入源码或参数文件；地域与已有资源保持一致。
- 所有 Plan、Apply、Destroy 均加上 `-parallelism=1`；通过平台执行时，并发度也设置为 1。
- Apply 后再次执行 `terraform plan -parallelism=1`，结果应无变化，以确认幂等性。
- `terraform destroy` 只删除本示例管理的 HTTPS 监听器；已有 CLB、证书、后端组、服务器和 DNS 继续保留。
- HTTP/2 默认开启。本示例固定使用 HTTPS 443，不暴露监听端口或 HTTP 跳转开关。
- 证书更换通过更新所选来源对应的证书 ID 完成；证书申请、续期和域名解析由调用方维护。
