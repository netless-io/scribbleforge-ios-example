# ScribbleForge CocoaPods 集成

## 🚀 快速开始

```bash
# 交互式选择模式（推荐）
./generate.sh

# 直接指定模式
./generate.sh latest              # 最新版本SDK
./generate.sh sourcecode          # 源码集成
./generate.sh version 0.1.35      # 指定版本

# Dry-run模式（只生成Podfile，不构建）
./generate.sh --dry-run
./generate.sh latest --dry-run

# 帮助信息
./generate.sh --help
```

## 📋 集成模式

| 模式 | 说明 | 用途 |
|------|------|------|
| `latest` | 最新版本SDK（默认） | 生产环境 |
| `sourcecode` | 本地源码集成 | 开发调试 |
| `version <版本>` | 指定版本SDK | 版本锁定 |

## 🎯 交互式菜单

运行 `./generate.sh` 会显示选择菜单：

```
1) latest     - 使用最新版本的SDK (推荐)
2) sourcecode - 使用本地源码集成  
3) version    - 使用指定版本的SDK
```

默认选择1，按回车即可。

## 🛠 故障排除

```bash
# 工具检查
brew install tuist
sudo gem install cocoapods

# 权限问题
chmod +x generate.sh

# 清理重建
rm -rf Pods/ Podfile.lock
./generate.sh
``` 