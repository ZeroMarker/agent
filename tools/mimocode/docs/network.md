# 网络

## 代理

```bash
export HTTPS_PROXY=https://proxy.example.com:8080
export HTTP_PROXY=http://proxy.example.com:8080
export NO_PROXY=localhost,127.0.0.1
```

> TUI 与本地 HTTP 服务器通信，必须绕过代理以防止路由循环。

### 身份验证

```bash
export HTTPS_PROXY=http://username:password@proxy.example.com:8080
```

## 自定义证书

```bash
export NODE_EXTRA_CA_CERTS=/path/to/ca-cert.pem
```
