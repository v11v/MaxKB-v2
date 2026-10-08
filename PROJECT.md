# MaxKB-v2 仓库说明

本仓库基于 [上游 MaxKB](https://github.com/1Panel-dev/MaxKB)，保留原项目名称与 GPL-3.0 许可证，维护本地 OCR 与部署扩展。当前开发分支为 `dev`。

## 目录与入口

| 目录 | 用途 |
| --- | --- |
| `apps/` | Django 后端、知识库、工作流及模型服务 |
| `ui/` | Vue 管理端与聊天端 |
| `installer/` | Docker 镜像及服务启动脚本 |
| `installer/ocr/` | 独立 CPU OCR 服务、模型准备脚本和测试 |
| `main.py` | 后端服务启动与数据库升级入口 |

## 本仓库扩展

- 扫描 PDF 页可调用本机 PaddleOCR，将识别文字交给原有分段和向量化流程。
- PDF 高级分段遵循用户规则；智能分段保留目录与内部链接解析能力。
- OCR 服务与主应用依赖隔离，支持认证、超时恢复及重复页缓存。
- 提供包含 OCR 的 Docker 镜像构建与启动配置，以及 Windows CSV 字段长度兼容修复。

## 开发与部署

- 产品介绍与基础安装：[中文 README](README_CN.md)。
- 本机 OCR 安装与配置：[OCR 使用说明](installer/ocr/README.md)。
- Docker 构建、镜像导出与运行：[Docker 部署说明](installer/DOCKER-BUILD.md)。

OCR 默认在源码运行时关闭，可通过 `MAXKB_OCR_ENABLED=true` 启用；OCR 扩展镜像默认启用。模型权重需按说明准备，不随 Git 仓库分发。

`.env`、认证 token、OCR 模型和虚拟环境、业务数据、镜像归档及本地助手记录均不应提交。原有 `docs/` 分析报告属于本地资料，本次整理未将其纳入版本管理。

## 回归检查

在主应用 Python 环境运行：

```sh
python apps/manage.py test knowledge.test_pdf_ocr knowledge.test_pdf_split_mode
```

OCR HTTP 回归测试不需要加载模型，可直接运行：

```sh
python installer/ocr/test_server.py
```
