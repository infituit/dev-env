# 架构说明

## 目标

`dev-env` 是个人使用、可复用的开发环境。它不是项目模板，也不决定要打开哪个源码仓库。调用方可以使用 Docker Compose、Dev Containers 客户端、JetBrains Gateway 或其他客户端来提供源码并选择工作区。

设计上要把容器基础层、个人偏好和项目配置分开：

| 层           | 负责方                          | 职责                                                         |
| ------------ | ------------------------------- | ------------------------------------------------------------ |
| 容器基础层   | `dev-env`                       | OS 镜像、`dev` 用户、基础 CLI 工具、`zsh`、`mise`、`chezmoi` |
| 个人偏好层   | 已有 dotfiles 仓库              | shell 启动、alias、prompt、插件、Git 偏好、`mise activate`   |
| 项目环境层   | 各项目仓库                      | `mise.toml`、`mise.lock`、语言版本、项目任务和依赖           |
| Agent 环境层 | `ai-agent-config`               | agent 规则、skills、MCP servers、权限和 agent 状态           |
| 客户端集成层 | JetBrains、VS Code 或其他调用方 | 源码位置、工作区、IDE 设置和信任目录                         |

不要因为某个项目需要某个工具，就把它直接放入基础镜像。不要把个人 dotfiles 内容复制到本仓库。只有当 agent 层的运行契约明确且可以独立验证时，才增加 agent 集成。

## 仓库组件

### `Dockerfile`

`Dockerfile` 按职责分层：

1. `mise` 镜像阶段提供固定版本的 `mise` 二进制。
2. Dev Containers Bookworm 镜像提供开发基础镜像。
3. OS 层安装所有环境都会用到的基础包。
4. 身份层创建非 root 的 `dev` 用户和持久化 home。
5. `mise` 层安装项目工具管理器。
6. `chezmoi` 层只安装 dotfiles 管理器，不在构建镜像时访问私有仓库。
7. 后续 Docker 访问、agent 配置或语言运行时必须保持独立分层。

有稳定发布资产时，应固定网络下载的版本。版本参数放在文件顶部，便于审查和升级。

### `docker-compose.yml`

Compose 定义一个长期运行的开发容器和一个 Tailscale sidecar：

- service：`devbox`
- container：`personal-devbox`
- 用户：`dev`
- 环境变量：通过可选的 `.env` 文件注入，仓库只提交 `.env.example`
- home volume：`personal-devbox-home`，挂载到 `/home/dev`
- 默认命令：`sleep infinity`
- service：`tailscale`
- container：`personal-devbox-tailscale`
- Tailscale 状态：只保存在容器生命周期内的 `tmpfs`
- `devbox` 通过 `network_mode: service:tailscale` 使用 Tailscale 的网络命名空间
- Tailscale 使用 `NET_ADMIN`、`NET_RAW` 和 `/dev/net/tun` 提供内核网络模式

`TS_AUTHKEY` 必须来自 Tailscale 管理控制台创建的可重复使用、临时
(`Reusable` + `Ephemeral`) auth key。临时节点离线后由 Tailscale 自动清理；
Compose 不持久化 Tailscale 节点身份，因此重建环境会注册一个新的临时节点。

Compose **不会**定义宿主源码 bind mount、`working_dir` 或固定的 `workspaceFolder`。源码获取和工作区位置属于调用方，这样可复用环境就不会假设项目如何 clone 或打开。

### `.env` 与 `.env.example`

个人凭据和机器相关变量放在 `.env` 中，`.env` 不纳入 git 管理。仓库只提供 `.env.example` 作为模板，记录变量名和用途。Compose 用 `env_file` 的 `required: false` 读取 `.env`，因此没有该文件时环境仍可构建和启动。secret 绝不能进入提交到 git 的文件。

### `.devcontainer/devcontainer.json`

该文件提供 Dev Containers 兼容性和 JetBrains 定制。它指向 Compose service，并设置 `remoteUser` 为 `dev`。可以添加 Dev Containers 实现支持的客户端设置或插件，但不能让它变成第二套容器运行时真相。

## 路径契约

个人工作区约定为：

```text
宿主机：~/items
容器内：/home/dev/items
```

这个映射是集成约定，不是基础 Compose 文件的职责。需要使用该约定的调用方必须自己提供 bind mount 并选择工作区。例如，可以把包含 `dev-env` 的源码目录映射为 `/home/dev/items/dev-env`，然后将该路径作为工作区打开。

容器 home 固定为 `/home/dev`。本仓库不能假定当前源码仓库一定是 `/home/dev/items/dev-env`，因为同一个环境还要承载其他项目。

## 持久化

`/home/dev` 持久化后，shell 状态、`mise` 状态和缓存、chezmoi 配置以及其他用户级开发状态可以在容器重建后保留。

这个 volume 只是便利状态，不是项目源码的唯一来源。真实项目源码必须留在调用方提供的工作区或宿主机仓库中。不能让可删除的 home volume 成为项目数据的唯一备份。

## 扩展规则

增加工具或配置层前，先回答：

1. 它是所有项目都需要，还是只有一个项目需要？
2. 它属于 OS 基础层、dotfiles、项目配置、agent 配置还是 IDE 客户端？
3. 现有的 `mise` 或 dotfiles 层能否完成这件事？
4. 它是否需要凭据、宿主挂载、Docker socket 或客户端设置？
5. 是否可以不依赖私有仓库和个人 secret 完成构建与验证？

只有第一类内容属于基础镜像，其他内容必须留在自己的职责层中。
