# Pinry 使用笔记

> 项目：[pinry/pinry](https://github.com/pinry/pinry) · [官方文档](https://pinry.github.io/pinry/) · [Docker 镜像](https://hub.docker.com/r/getpinry/pinry)
>
> 核对基准：上游 `master` 提交 [`05476b1`](https://github.com/pinry/pinry/commit/05476b1)（2025-07-09）。部署前以当前版本文档为准。

## 是什么

Pinry 是可自行托管的瀑布流图片收藏板。可以保存图片、给 Pin 加标签、按主题建立画板，并通过浏览器扩展收集网页内容。支持多用户、公开和私密 Pin/画板、标签搜索及 Token API。适合整理灵感图、参考素材和图片书签；它不是通用文件管理器。

## Docker 快速启动

官方预构建镜像将网页、API 和 Nginx 放在同一个容器中，容器内监听 80 端口；数据库、配置和媒体文件保存在 `/data`。以下示例只绑定本机 8080 端口，按需再配置反向代理：

```bash
docker volume create pinry-data
docker run -d --name pinry --restart unless-stopped \
  -p 127.0.0.1:8080:80 \
  -v pinry-data:/data \
  getpinry/pinry
```

浏览器打开 `http://127.0.0.1:8080/`，先注册账号。容器首次启动会在 `/data` 生成 `local_settings.py` 和 SQLite 数据库；上传的媒体文件也保存在该目录下。若要从其他设备访问，需调整端口绑定并配置访问控制与 HTTPS。

需要直接编辑配置时，官方也支持把宿主机的**绝对路径**挂载到 `/data`：

```bash
mkdir -p "$HOME/pinry-data"
docker run -d --name pinry --restart unless-stopped \
  -p 127.0.0.1:8080:80 \
  -v "$HOME/pinry-data:/data" \
  getpinry/pinry
```

两段命令是二选一；复用容器名之前先停止并移除旧容器。不要把上游 `docker-compose.example.yml` 当作同一套生产部署：它是挂载源码的开发配置，只有后端服务，静态页面还需另行提供。

## 常用配置与操作

编辑挂载目录中的 `local_settings.py`（命名卷可用临时容器挂载后编辑），然后重启容器：

| 设置 | 作用 | 上游示例默认值 |
| --- | --- | --- |
| `ALLOW_NEW_REGISTRATIONS` | 是否允许新用户自行注册 | `True` |
| `PUBLIC` | 是否允许未登录用户浏览 Pin | `True` |
| `ALLOWED_HOSTS` | Django 允许的域名 | `['*']` |
| `IMAGE_AUTO_DELETE` | 删除 Pin 时是否删除对应图片 | `True` |

单人使用时，可先注册账号，再将 `ALLOW_NEW_REGISTRATIONS = False`。需要管理用户或修改密码，可使用 `/admin/`；必要时按[官方密码说明](https://pinry.github.io/pinry/passwords/)在容器中创建管理员：

```bash
docker exec -it pinry python manage.py createsuperuser --settings=pinry.settings.docker
docker restart pinry
docker logs --tail 100 pinry
```

备份时保存整个 `/data`，包括 `production.db`、`local_settings.py` 和 `static/media`。升级前先备份，再查看[上游升级说明](https://pinry.github.io/pinry/upgrade-guide/)；出现 `no such table` 时，按上游说明检查数据库迁移。

## 使用入口

- **画板与标签**：画板适合主题分组，标签适合跨画板细分与搜索；画板按用户组织，标签可跨用户使用。见[官方设计说明](https://pinry.github.io/pinry/theories/)。
- **浏览器扩展**：官方文档列出 [Chrome / Firefox 扩展](https://pinry.github.io/pinry/extensions/)，用于从浏览器保存内容。
- **API**：在 `My → Profile` 获取 Token；请求使用 `Authorization: Token <你的令牌>`。交互式 API 和端点以[官方 API 文档](https://pinry.github.io/pinry/api/)及运行实例为准，不把令牌写进仓库。
- **命令行**：上游 README 链接了独立项目 [pinry-cli-py](https://github.com/pinry/pinry-cli-py)，可通过命令行添加图片或 URL。

## 限制与注意

- 官方 Docker 镜像中的 Nginx 直接提供 `/media` 路径；`PUBLIC = False` 只在 Django 中限制请求，**不能保证已知媒体 URL 的文件不可访问**。若素材必须保密，应在反向代理或网络层限制整个站点的访问，并自行验证媒体 URL。
- 首次生成的配置使用 SQLite；单机、小规模收藏足够直接，扩容或改数据库需自行调整配置并迁移数据。
- 官方文档中的开发环境、Docker 镜像和源码构建是不同路径；排查问题时先确认使用的是哪一种部署方式。

## 参考

- [官方 Docker 安装与备份](https://pinry.github.io/pinry/install-with-docker/)
- [配置示例](https://github.com/pinry/pinry/blob/master/pinry/settings/local_settings.example.py)
- [Docker Nginx 配置](https://github.com/pinry/pinry/blob/master/docker/nginx/sites-enabled/default)
- [开发环境说明](https://pinry.github.io/pinry/development/)
