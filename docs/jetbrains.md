# JetBrains 配置

## 简体中文界面

Dev Container 声明了 JetBrains 中文语言包插件，ID 为 `com.intellij.zh`。当前版本的 JetBrains IDE 通常已经内置并启用了该插件。

在 JetBrains 客户端中选择简体中文：

```text
Settings | Appearance & Behavior | System Settings | Language and Region
```

将 **Language** 设置为 **Chinese (Simplified)**。如果 IDE 提示，按要求重启。

语言选择属于 JetBrains 客户端设置，不是可移植的 Dev Container 设置。

## 信任 `~/items`

Trusted Locations 同样属于 JetBrains 客户端设置。在宿主机中一次性添加 `~/items`：

1. 打开 **Settings | Appearance & Behavior | Trusted Locations**。
2. 添加 `~/items`。
3. 应用变更。

之后 `~/items` 下的项目都会被自动信任。调用方将该宿主目录挂载到容器后，对应的容器路径通常是 `/home/dev/items`。

这里的宿主路径和容器路径有意不同。JetBrains 会先要求客户端信任宿主项目位置，再连接 Dev Container。`dev-env` 的 Compose 文件本身不挂载源码；由调用方决定如何提供源码。

## 官方参考

- [Customizing Dev Container settings](https://www.jetbrains.com/help/idea/customizing-devcontainer-json-file.html)
- [Language and region](https://www.jetbrains.com/help/idea/language-and-region.html)
- [Project security](https://www.jetbrains.com/help/idea/project-security.html)
