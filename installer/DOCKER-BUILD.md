# 本地 Docker 镜像

包含 OCR 的镜像名称：`maxkb:local-ocr`，平台：`linux/amd64`。

`maxkb-local-ocr-amd64.tar` 是通过下方构建步骤生成的镜像归档，不随 Git 仓库分发。归档不包含本地业务数据、根目录 `.env` 或已有 OCR token。

## 导入与运行

将归档复制到目标机器，在归档所在目录执行：

```sh
docker load -i maxkb-local-ocr-amd64.tar
docker run -d --name maxkb-local --restart unless-stopped -p 8080:8080 -v maxkb-local-data:/opt/maxkb maxkb:local-ocr
```

访问 `http://localhost:8080/admin/`。首次启动会自动初始化数据库，等待初始化完成后再访问。
镜像包含 PostgreSQL、pgvector、Redis、本地向量模型、CPU PaddleOCR 3.3.2 和 PP-OCRv5 中文识别模型。
业务数据保存在 `maxkb-local-data` 卷内。OCR 默认启用，独立 Python 环境位于 `/opt/maxkb-ocr/venv`，不会覆盖主服务依赖。
OCR 仅监听容器内的 `127.0.0.1:11637`，无需映射额外端口；首次启动自动生成共享认证文件 `/opt/maxkb/ocr/token`。
已打包识别模型，运行时无需重新下载。可用 `-e MAXKB_OCR_ENABLED=false` 禁用 OCR。

可使用 `maxkb-local-ocr-amd64.tar.sha256` 校验归档的 SHA-256。

## 从源码重新构建

在项目根目录执行。已有 `ui/dist` 时，Dockerfile 会直接使用它，因此先重新编译管理端和聊天端：

```sh
cd ui
npm install
npm run build
npm run build-chat
cd ..
docker build --platform linux/amd64 -f installer/Dockerfile -t maxkb:local --build-arg DOCKER_IMAGE_TAG=local .
docker build --platform linux/amd64 -f installer/Dockerfile-ocr -t maxkb:local-ocr .
docker save -o maxkb-local-ocr-amd64.tar maxkb:local-ocr
```

第二步构建使用本地 `maxkb:local` 作为基础镜像，默认值可通过 `--build-arg MAXKB_IMAGE=...` 指定。
构建前，`installer/ocr/runtime/text-models` 必须包含已下载的模型及校验清单；新检出项目请先按 [OCR 安装说明](ocr/README.md) 执行 warmup。
构建时校验原模型清单并生成容器路径配置，不修改本机模型文件；Windows 虚拟环境、缓存日志及本机认证文件均被排除。

默认 Python 包源为 PyPI。如遇下载连接问题，可在两个构建命令中分别增加：

```sh
--build-arg PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple
```

原不含 OCR 的 `maxkb:local` 镜像和 `maxkb-local-amd64.tar` 仍保留；使用新版归档和 `maxkb:local-ocr` 即可启用 OCR。
