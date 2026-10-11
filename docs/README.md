# 开发环境文档

本目录是本仓库个人开发环境的长期维护指南。

## 阅读顺序

建议按以下顺序阅读：

1. [架构说明](architecture.md)：职责、路径和边界。
2. [操作指南](operations.md)：启动环境、提供源码、验证和排错。
3. [JetBrains 配置](jetbrains.md)：配置 IntelliJ 系列 IDE。

## 当前范围

本仓库负责可复用的容器开发环境：

- 基于 Debian Bookworm 的开发镜像。
- 可配置 UID 和 GID 的非 root `dev` 用户。
- `zsh`、常用命令行工具、`mise` 和 `chezmoi`。
- 通过 Compose 持久化 `/home/dev`。
- JetBrains Dev Container 元数据。

本仓库不负责：

- 项目源码的获取或源码挂载。
- 每个项目自己的语言运行时和依赖。
- dotfiles 仓库中的个人 shell 配置。
- AI agent 配置；这属于后续集成层。

## 维护规则

修改开发环境时，必须在同一个变更中更新对应文档。

如果出现新的构建失败、权限问题、路径映射规则或客户端行为，并且它会影响后续维护，就要把这条经验记录在本目录中。
