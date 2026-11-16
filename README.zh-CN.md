# terraform-volcenginecc-clb-https

为已有 CLB 配置 HTTPS 入口、证书绑定、HTTP 跳转和按域名、路径分流的转发规则。

## 1. 概述（Overview）

本模块适用于需要 HTTPS 访问、HTTP 跳转 HTTPS 或多个后端组路径分流的服务。在调用方已有的 CLB 上创建 HTTPS 监听器，绑定已有证书并配置 TLS、HTTP/2 和健康检查；按需增加 HTTP 监听器、301 重定向和 HTTPS 转发规则。CLB、证书、DNS、后端组及后端服务器由调用方准备和维护。

## 2. 用法（Usage）

准备同一地域内的 CLB、属于该 CLB 的后端组，以及可绑定的 CLB 或证书中心证书。后端组应已有可访问的 HTTP 服务，监听端口应未被其他监听器占用。访问域名需要解析到 CLB，且与证书覆盖的域名一致。

在调用方的 `main.tf` 中配置最小 HTTPS 入口，将示例 ID 替换为已有资源 ID：

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

使用证书中心证书时，配置 `certificate_source = "cert_center"` 和 `cert_center_certificate_id`，并移除 `certificate_id`。两类证书 ID 只能填写与来源对应的一项。

在调用方的 `provider.tf` 中单独配置版本和 Provider：

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

通过运行环境提供 `VOLCENGINE_ACCESS_KEY`、`VOLCENGINE_SECRET_KEY` 和 `VOLCENGINE_REGION`。账号需要具备管理 CLB 监听器、规则及绑定证书的权限。地域应与已有资源一致，例如：

```shell
export VOLCENGINE_REGION="cn-beijing"
```

在调用方根目录执行以下命令。前四条用于部署和确认幂等性；需要移除模块管理的入口时，核对删除范围后再执行最后一条。所有 Plan、Apply、Destroy 均使用 `-parallelism=1`：

```shell
terraform init
terraform plan -parallelism=1
terraform apply -parallelism=1
terraform plan -parallelism=1
terraform destroy -parallelism=1
```

## 3. 示例（Examples）

- basic：在 `examples/basic` 目录运行，使用已有 CLB、一个后端组和证书创建 HTTPS 443 监听器，配置 TLS 策略及健康检查。
- complete：在 `examples/complete` 目录运行，使用已有 CLB、证书和转发规则引用的后端组，增加 HTTP 80 到 HTTPS 443 的 301 跳转，并按输入的域名和路径创建 HTTPS 分流规则。

两个示例均独立配置参数。Provider 和版本约束位于各自的 `provider.tf`，资源 ID 通过各自目录的 `terraform.tfvars` 或运行环境传入。

## 4. 版本要求（Requirements）

| 名称 | 版本 |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `= 0.0.73` |

## 5. Providers（Providers）

| 名称 | 来源 |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

模块使用调用方传入的默认 Provider，不声明 alias。

## 6. 资源（Resources）

| 模式 | 类型 | 名称 |
|---|---|---|
| 创建 | `volcenginecc_clb_listener` | `volcenginecc_clb_listener.https` |
| 条件创建 | `volcenginecc_clb_listener` | `volcenginecc_clb_listener.http` |
| 条件创建 | `volcenginecc_clb_rule` | `volcenginecc_clb_rule.http_redirect` |
| 按映射创建 | `volcenginecc_clb_rule` | `volcenginecc_clb_rule.https_forward` |

始终创建一个 HTTPS 监听器。开启 `enable_http_redirect` 时增加一个 HTTP 监听器和一条重定向规则；`forwarding_rules` 每个 key 对应一条 HTTPS 转发规则。模块不声明 Data Source。

## 7. 输入（Inputs）

| 名称 | 类型 | 默认值 | 创建模式下是否必填 | 说明 |
|---|---|---|---|---|
| `load_balancer_id` | `string` | 无 | 是 | 已有 CLB ID，以 `clb-` 开头；修改会替换监听器。 |
| `default_server_group_id` | `string` | 无 | 是 | 属于该 CLB 的默认后端组 ID，以 `rsp-` 开头，供 HTTPS 和可选 HTTP 监听器使用。 |
| `certificate_source` | `string` | 无 | 是 | 证书来源，只能为 `clb` 或 `cert_center`。 |
| `certificate_id` | `string` | `null` | 条件必填 | 来源为 `clb` 时填写已有 CLB 证书 ID，同时保持证书中心 ID 为 `null`；非空值不能是空白字符串。 |
| `cert_center_certificate_id` | `string` | `null` | 条件必填 | 来源为 `cert_center` 时填写已有证书中心证书 ID，同时保持 CLB 证书 ID 为 `null`；非空值不能是空白字符串。 |
| `https_listener_name` | `string` | `"module-https"` | 否 | HTTPS 监听器名称。 |
| `https_listener_port` | `number` | `443` | 否 | HTTPS 监听端口，范围 1–65535；修改会替换监听器。 |
| `security_policy_id` | `string` | `"tls_cipher_policy_1_2"` | 否 | HTTPS 监听器使用的 TLS 策略 ID。 |
| `http_2_enabled` | `bool` | `true` | 否 | 是否开启 HTTPS 监听器的 HTTP/2。 |
| `health_check` | `object` | 本节所列默认对象 | 否 | 同时应用于 HTTPS 和可选 HTTP 监听器；自定义时提供下列全部字段。 |
| `enable_http_redirect` | `bool` | `false` | 否 | 是否增加 HTTP 监听器和 HTTP 到 HTTPS 的 301 重定向规则。 |
| `http_listener_name` | `string` | `"module-http-redirect"` | 否 | 可选 HTTP 监听器名称。 |
| `http_listener_port` | `number` | `80` | 否 | HTTP 监听端口，范围 1–65535；修改会替换监听器。 |
| `redirect_domain` | `string` | `null` | 条件必填 | 开启 HTTP 跳转时必填；精确域名，同时作为 HTTP 匹配域名和 HTTPS 跳转目标域名，不使用通配符。 |
| `redirect_path` | `string` | `"/"` | 否 | 以 `/` 开头，同时用于 HTTP 路径匹配和重定向目标路径；默认跳到 HTTPS 根路径。修改会替换重定向规则。 |
| `forwarding_rules` | `map(object({ domain = string, url = string, server_group_id = string }))` | `{}` | 否 | key 为规则标识；每项提供精确域名、以 `/` 开头的匹配路径和以 `rsp-` 开头的已有后端组 ID。 |

`health_check` 的完整类型为：

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

其默认值为：

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

连续健康和不健康阈值均为 2–10 次，探测间隔为 1–300 秒，超时为 1–60 秒；方法为 `GET` 或 `HEAD`，URI 以 `/` 开头。端口的模块校验范围为 0–65535，`0` 表示复用各后端成员的端口；具体端口及 `http_code` 取值还需满足 CLB 服务要求。默认健康检查要求后端的 `/healthz` 返回 2xx。

例如，开启 HTTP 跳转并增加 API 分流时，在 Module 调用中补充：

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

`forwarding_rules` 每项的三个字段均必填，后端组应属于 `load_balancer_id` 指定的 CLB。HTTP 跳转的目标路径由 `redirect_path` 决定；HTTPS 转发规则的匹配路径由各项 `url` 决定，两者应按业务分别配置。

## 8. 输出（Outputs）

| 名称 | 类型 | 说明 |
|---|---|---|
| `https_listener_id` | `string` | 模块创建的 HTTPS 监听器 ID，可用于查询监听器或关联下游配置。 |
| `http_listener_id` | `string` 或 `null` | 模块创建的 HTTP 监听器 ID；未开启 HTTP 跳转时为 `null`。 |
| `http_redirect_rule_id` | `string` 或 `null` | HTTP 到 HTTPS 的重定向规则 ID；未开启 HTTP 跳转时为 `null`。 |
| `https_forwarding_rule_ids` | `map(string)` | 按 `forwarding_rules` 的 key 返回 HTTPS 转发规则 ID；未配置规则时为 `{}`。 |

## 9. 其他说明（Notes）

- 创建、更新和删除同一 CLB 的监听器及规则时，使用 `-parallelism=1` 串行执行；通过平台运行时，也将 Terraform 并发度设置为 1。
- CLB、证书、DNS、后端组及服务器由调用方维护。模块只管理新建的监听器和规则，`terraform destroy` 仅删除这些对象。
- HTTPS 与 HTTP 监听端口应互不冲突，且不能占用已有监听端口。变更 CLB ID 或监听端口会替换监听器，可能影响已有入口流量。
- 保持 `forwarding_rules` 的 key 稳定；修改 key、域名或匹配路径会替换相应规则。
- `redirect_path = "/"` 会把匹配的 HTTP 请求跳转到 HTTPS 根路径，包括原请求为 `/api` 的情况。需要跳到指定业务路径时，配置相应的目标路径和 HTTPS 转发规则。
- 更换证书时更新与 `certificate_source` 对应的证书 ID。模块更新证书绑定，证书申请和续期由调用方负责。
- Apply 后再次执行 `terraform plan -parallelism=1`，确认结果为无变化；这是部署的幂等要求。
- 本项目采用 MIT 许可证，许可证文件为 `LICENSE`。
