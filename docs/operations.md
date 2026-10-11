# 操作指南

## 前置条件

- Docker Engine 或带 Compose v2 的 Docker Desktop。
- 如果通过 GitHub clone 私有仓库，需要 GitHub CLI (`gh`)。
- 使用个人工作区约定时，宿主机需要有 `~/items`。
- 使用 IDE 集成时，需要 JetBrains IDE 或其他 Dev Containers 客户端。

Windows 上建议使用带 WSL2 backend 的 Docker Desktop。宿主工作区需要放在 Docker Desktop 可以共享给容器的位置。不要假设 Linux `$HOME` 表达式在每个 Windows shell 中含义相同；通过选定的调用方或客户端提供源码挂载。

## 启动基础环境

在已 clone 的 `dev-env` 仓库中执行：

```sh
docker compose build
docker compose up -d
docker compose exec devbox zsh
```

Compose service 会启动一个空闲容器。它不会 clone 项目，也不会选择项目工作区，这是有意的边界。

停止容器但保留持久化状态：

```sh
docker compose stop
```

删除容器但保留 home volume：

```sh
docker compose down
```

除非确实要删除可重建的 home volume，否则不要使用 `docker compose down -v`。

## 提供项目源码

调用方负责提供源码。使用个人工作区约定时，可以先把项目 clone 到宿主机 `~/items`，再挂载到容器的 `/home/dev/items`：

```text
~/items/<project>  ->  /home/dev/items/<project>
```

之后由调用方把需要开发的项目目录设置为 IDE 工作区。基础 `dev-env` Compose 文件不会写死该挂载，因此也可以配合其他源码提供方式使用。

## 首次应用 dotfiles

镜像包含 `chezmoi`，但 `docker build` 阶段绝不会访问私有 dotfiles 仓库。源码仓库在容器内可用后，显式初始化并应用：

```sh
chezmoi init --source "$HOME/items/dotfiles"
chezmoi apply --source "$HOME/items/dotfiles"
```

如果 dotfiles 源码是私有仓库且没有通过挂载目录提供，需要先配置 Git 或 SSH 认证，再执行 `chezmoi init`。不要把 token 写进 `Dockerfile`、Compose 文件或 Git 仓库。

已有 dotfiles 仓库继续负责 `.zshrc`、`.zshenv`、插件、alias、prompt 配置和 `mise activate`。

## 使用 `mise` 管理项目工具

项目仓库负责自己的工具声明：

```text
<project>/mise.toml
<project>/mise.lock
```

进入项目目录后执行：

```sh
mise trust
mise install
```

只信任你理解其来源和命令的配置。基础镜像必须确保 `mise` 的 data、config、cache 和 state 目录都可由 `dev` 写入；这些目录放在 `/home/dev` 下更合适，因为该 home 是持久化 volume。

## 验证清单

构建或升级后执行：

```sh
docker compose config --quiet
docker compose build
docker compose up -d
docker compose exec -T devbox sh -lc \
  'id; pwd; command -v mise; command -v chezmoi; zsh --version'
```

另外确认：

- 进程以 `dev` 而不是 `root` 运行。
- `/home/dev` 可由 `dev` 写入。
- `mise` 的 data、config、cache 和 state 目录可写。
- 不访问私有 dotfiles 仓库时，`chezmoi` 也可以正常使用。
- 调用方提供的项目路径在容器内的预期位置可见。
- 重建容器不会删除持久化 home volume。
- JetBrains 可以以 `dev` 用户连接 Compose service。

## 已知坑

### 在构建镜像时安装私有 dotfiles

这会失败，因为构建镜像时没有用户的 GitHub 或 SSH 凭据。镜像中只安装 `chezmoi`，等运行时凭据或源码挂载可用后再应用 dotfiles。

### 把 `mise` 状态写入 root 拥有的系统目录

以 root 安装二进制，不代表非 root 的 `dev` 用户可以写入 data 和 cache。运行时目录应放在 `/home/dev` 下，并且每次修改镜像后都要以 `dev` 身份验证。

### 把容器路径当成宿主路径

JetBrains Trusted Locations 在宿主客户端配置。应该信任宿主路径 `~/items`；在容器内信任 `/home/dev/items` 不会配置宿主 IDE。

### 让基础镜像绑定某一个项目

不要仅仅因为当前项目需要，就把语言运行时、项目依赖、源码挂载或固定工作区加入基础镜像。把它放到项目仓库或调用方配置中。

### 依赖 `latest`

固定镜像使用的 `mise` 和 `chezmoi` 版本。版本升级要作为环境变更审查，修改版本参数后重新构建。

## 升级流程

1. 一次只修改一个版本或一个分层。
2. 验证基础镜像或安装器变更时，使用 `docker compose build --no-cache`。
3. 以 `dev` 用户执行验证清单。
4. 重新测试 dotfiles 初始化，以及一个代表性项目的 `mise install`。
5. 检查 JetBrains 连接和工作区行为。
6. 将新的兼容性约束或失败原因记录到本文档。
7. 将 Dockerfile、配置和文档一起提交。
