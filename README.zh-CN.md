# terraform-volcenginecc-clb-https

> 状态：`draft`。本模块要求 Terraform `1.5.7` 和
> `volcengine/volcenginecc v0.0.73`。Provider/API 尚未处理 CLB 配置状态
> 导致的默认并发 Rule 操作失败，因此当前不适用于 InfraManager 默认并发。

## 概述

本模块在调用方已有的 CLB 上管理 HTTPS Listener 和可选 HTTP Listener：
绑定调用方已有的 CLB 或证书中心证书，配置 TLS 策略和健康检查，可选创建
HTTP 跳转 HTTPS 规则，并创建按域名和路径分流到不同后端组的 HTTPS Rule。

模块不创建或导入 CLB、证书、DNS 记录、后端组及后端服务器。

## 使用方式

模块发布到 Registry 后，使用其 Registry 地址：

```hcl
module "https" {
  source = "terraform-volcenginecc-modules/clb-https/volcenginecc"

  load_balancer_id        = "clb-..."
  default_server_group_id = "rsp-..."
  certificate_source      = "clb"
  certificate_id          = "cert-..."
  security_policy_id      = "tls_cipher_policy_1_2"
  enable_http_redirect    = true
  redirect_domain         = "app.example.com"

  forwarding_rules = {
    api = {
      domain          = "app.example.com"
      url             = "/api"
      server_group_id = "rsp-..."
    }
  }
}
```

在模块发布前，请使用仓库检出的本地相对路径作为 `source`。Provider 凭据、
地域和 backend 配置均由调用方根模块管理。

## 依赖要求

| 名称 | 版本 |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `= 0.0.73` |

## Providers

| 名称 | 来源 | 版本 |
|---|---|---|
| `volcenginecc` | `volcengine/volcenginecc` | `= 0.0.73` |

## 资源

| 资源 | 用途 |
|---|---|
| `volcenginecc_clb_listener.https` | HTTPS Listener、证书、TLS 策略和健康检查 |
| `volcenginecc_clb_listener.http` | 可选 HTTP Listener |
| `volcenginecc_clb_rule.http_redirect` | 可选永久 HTTP 跳转 HTTPS Rule |
| `volcenginecc_clb_rule.https_forward` | HTTPS 域名和路径转发 Rule |

## 输入参数

| 名称 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `load_balancer_id` | `string` | 是 | 无 | 已有 CLB ID。 |
| `default_server_group_id` | `string` | 是 | 无 | 已有默认后端组 ID。 |
| `certificate_source` | `string` | 是 | 无 | `clb` 或 `cert_center`。 |
| `certificate_id` | `string` | 条件必填 | `null` | 来源为 `clb` 时的 CLB 证书 ID。 |
| `cert_center_certificate_id` | `string` | 条件必填 | `null` | 来源为 `cert_center` 时的证书中心 ID。 |
| `security_policy_id` | `string` | 否 | `tls_cipher_policy_1_2` | HTTPS TLS 策略。 |
| `health_check` | `object` | 否 | 见 `variables.tf` | Listener 健康检查配置。 |
| `enable_http_redirect` | `bool` | 否 | `false` | 是否创建 HTTP Listener 和永久跳转。 |
| `redirect_domain` | `string` | 条件必填 | `null` | 开启跳转时必填。 |
| `forwarding_rules` | `map(object)` | 否 | `{}` | 稳定逻辑键的 HTTPS 转发 Rule。 |

## 输出

| 名称 | 类型 | 说明 |
|---|---|---|
| `https_listener_id` | `string` | HTTPS Listener ID。 |
| `http_listener_id` | `string` | HTTP Listener ID；未启用时为 `null`。 |
| `http_redirect_rule_id` | `string` | 跳转 Rule ID；未启用时为 `null`。 |
| `https_forwarding_rule_ids` | `map(string)` | 按稳定输入键返回的转发 Rule ID。 |

## 示例

- [`examples/basic`](examples/basic)：HTTPS 443、证书绑定、TLS 策略、后端组和健康检查。
- [`examples/complete`](examples/complete)：在 basic 基础上增加 HTTP 跳转 HTTPS，以及多个后端组的路径转发。

两个示例均要求调用方提供已有资源 ID，并可分别初始化和执行。

## 说明

- 修改 `load_balancer_id`、协议或监听端口会替换 Listener；修改证书 ID 会原地轮换证书。
- `forwarding_rules` 使用稳定 key；变更 key 会替换对应 Rule，变更域名或路径也可能触发替换。
- 已验证的 HTTP/HTTPS 场景中，`health_check.port = 0` 表示复用后端服务器端口。
- CLB API 在同一实例并发创建或删除多个 Rule 时可能返回
  `InvalidLoadBalancer.InvalidStatus`。在 Provider/API 支持串行化或重试前，
  不应依赖 InfraManager 默认并发执行。

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE)。
