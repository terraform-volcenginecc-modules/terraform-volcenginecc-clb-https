# COMPLETE CLB HTTPS 示例

## 1. 概述

本示例在已有 CLB 上创建 HTTPS 443 和 HTTP 80 监听器，绑定已有证书，配置 TLS、HTTP/2 和健康检查，并创建 HTTP 到 HTTPS 的 301 重定向及按域名、路径分流的 HTTPS 规则。调用方准备 CLB、证书、默认后端组及各转发规则引用的后端组。与 basic 相比，本示例增加 HTTP 跳转和多个后端组的规则转发。

## 2. 用法

使用 Terraform 1.5.7，在 `examples/complete` 目录操作。确认 CLB 的 80 和 443 端口可用，所有后端组属于该 CLB，证书可在同一地域绑定。各后端组应已有可访问的 HTTP 服务，默认健康检查路径 `/healthz` 应返回 2xx。

通过运行环境提供 `VOLCENGINE_ACCESS_KEY`、`VOLCENGINE_SECRET_KEY` 和 `VOLCENGINE_REGION`。本目录的 `provider.tf` 已单独声明 Provider 和版本。

在本目录的 `terraform.tfvars` 中配置参数，替换资源 ID 和业务域名：

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

使用证书中心证书时，配置 `certificate_source = "cert_center"` 和 `cert_center_certificate_id`，并移除 `certificate_id`。域名应解析到 CLB，且由证书覆盖。

上述配置创建两个监听器、一个重定向规则和两条 HTTPS 转发规则。HTTPS `/api` 请求进入 API 后端组；匹配 HTTP 重定向的请求按 `redirect_path = "/"` 跳到 HTTPS 根路径，再进入根路径规则对应的后端组。域名、路径和后端组可按业务调整，转发规则数量由 `forwarding_rules` 决定。

按顺序执行以下命令。先检查首次 Plan 的新增范围，再 Apply；Apply 后再次 Plan 应无变化。最后一条仅在需要移除本示例入口、并确认删除范围后执行：

```shell
terraform init
terraform plan -parallelism=1
terraform apply -parallelism=1
terraform plan -parallelism=1
terraform destroy -parallelism=1
```

部署后通过输出 ID 确认监听器和规则，再访问业务域名检查 HTTPS 转发及 HTTP 跳转的目标地址。

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
| `module.https` | 调用 `source = "terraform-volcenginecc-modules/clb-https/volcenginecc"`、`version = "~> 1.0"`，创建 HTTP/HTTPS 监听器、301 重定向规则及输入映射对应的 HTTPS 转发规则。 |

本示例根配置不直接声明 Resource 或 Data Source。

## 6. 输入

| 名称 | 说明 |
|---|---|
| `load_balancer_id` | 必填。已有 CLB ID，以 `clb-` 开头，80 和 443 端口需可用。 |
| `default_server_group_id` | 必填。属于该 CLB 的已有默认后端组 ID，以 `rsp-` 开头，供两个监听器使用。 |
| `certificate_source` | 必填。选择 `clb` 或 `cert_center`，决定填写哪一种证书 ID。 |
| `certificate_id` | 默认 `null`。来源为 `clb` 时必填；与证书中心 ID 互斥，不能填写空白字符串。 |
| `cert_center_certificate_id` | 默认 `null`。来源为 `cert_center` 时必填；与 CLB 证书 ID 互斥，不能填写空白字符串。 |
| `https_listener_name` | 默认 `"tf-module-complete-https"`，用于识别 HTTPS 监听器。 |
| `http_listener_name` | 默认 `"tf-module-complete-http"`，用于识别 HTTP 监听器。 |
| `security_policy_id` | 默认 `"tls_cipher_policy_1_2"`，指定 HTTPS 的 TLS 策略。 |
| `redirect_domain` | 必填。精确域名，同时用于 HTTP 匹配和 HTTPS 跳转目标，不使用通配符；转发规则的域名需单独填写。 |
| `redirect_path` | 默认 `"/"`。以 `/` 开头，同时用于 HTTP 路径匹配和重定向目标；默认跳到 HTTPS 根路径。修改会替换重定向规则。 |
| `health_check` | 默认对象如下。自定义时提供全部九个字段，同时应用于 HTTP 和 HTTPS 监听器。 |
| `forwarding_rules` | 必填的 `map(object)`，可填 `{}`。每个 key 标识一条 HTTPS 规则；每项完整填写 `domain`、`url` 和 `server_group_id`。 |

`forwarding_rules` 的三个子字段均为 `string`：`domain` 是不使用通配符的精确域名，`url` 是以 `/` 开头的匹配路径，`server_group_id` 是以 `rsp-` 开头、属于当前 CLB 的已有后端组 ID。

`health_check` 的默认值为：

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

阈值、间隔、超时和端口为 `number`，方法、URI 和响应码为 `string`。健康及不健康阈值均为 2–10 次，间隔为 1–300 秒，超时为 1–60 秒；方法为 `GET` 或 `HEAD`，URI 以 `/` 开头。端口的模块校验范围为 0–65535，`0` 复用各后端成员端口；具体端口和 `http_code` 还需满足 CLB 服务要求。

## 7. 输出

| 名称 | 说明 |
|---|---|
| `https_listener_id` | `string`，HTTPS 监听器 ID，可用于查询证书、TLS、健康检查和转发配置。 |
| `http_listener_id` | `string`，HTTP 监听器 ID；本示例始终开启 HTTP 跳转。 |
| `http_redirect_rule_id` | `string`，HTTP 到 HTTPS 的 301 重定向规则 ID，可用于查询目标配置。 |
| `https_forwarding_rule_ids` | `map(string)`，按 `forwarding_rules` 的 key 返回转发规则 ID；传入 `{}` 时输出 `{}`。 |

## 8. 示例

本目录即为 complete 示例，适用于同时需要 HTTP 跳转 HTTPS 和多个后端组分流的服务。仅需要默认后端组上的 HTTPS 入口时，可使用 basic 示例。

## 9. 说明

- 凭据通过 Provider 支持的运行环境传入，不写入源码或参数文件；地域与已有资源保持一致。
- 所有 Plan、Apply、Destroy 均加上 `-parallelism=1`；通过平台执行时，并发度也设置为 1。
- Apply 后再次执行 `terraform plan -parallelism=1`，结果应无变化，以确认幂等性。
- `terraform destroy` 删除本示例管理的两个监听器、重定向规则和 HTTPS 转发规则；已有 CLB、证书、后端组、服务器和 DNS 继续保留。
- 保持转发规则 key 稳定，避免重复的域名、路径匹配条件；修改 key、域名或路径会替换对应规则。
- HTTP 重定向目标与 HTTPS 路径匹配分别配置。默认目标 `/` 会进入根路径对应的后端；需要跳到其他业务路径时，同时配置 `redirect_path` 和相应 HTTPS 规则。
- 证书更换通过更新所选来源对应的证书 ID 完成；证书申请和续期由调用方维护。
