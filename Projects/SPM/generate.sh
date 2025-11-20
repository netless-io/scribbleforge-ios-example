#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_MODE="remote"
DEFAULT_REMOTE_VERSION="1.1.0-canary.3"
SCRIBBLEFORGE_SOURCE_PATH="../../../scribbleforge-ios"
SCRIBBLEFORGE_LOCAL_FRAMEWORK_PATH="../../../scribbleforge-ios/ci-scripts/ScribbleLocalFramework"

# 帮助信息
show_help() {
    echo -e "${BLUE}ScribbleForge SPM 项目生成脚本${NC}"
    echo ""
    echo "用法: $0 [选项] [--dry-run]"
    echo ""
    echo "选项:"
    echo "  remote [版本号]         使用远程二进制包（可选指定版本，默认 ${DEFAULT_REMOTE_VERSION}）"
    echo "  source                  使用本地源码集成"
    echo "  localframework          使用本地 Framework 集成"
    echo "  --dry-run               仅展示配置，不执行构建"
    echo "  -h, --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                      # 交互式选择模式"
    echo "  $0 remote               # 远程（默认版本）并构建"
    echo "  $0 remote 1.2.3         # 远程指定版本并构建"
    echo "  $0 source --dry-run     # 仅展示源码模式配置"
}

# 交互式选择模式
interactive_mode_selection() {
    echo -e "${CYAN}=== 选择集成模式 ===${NC}" >&2
    echo "" >&2
    echo "请选择 ScribbleForge 的 SPM 集成方式：" >&2
    echo "" >&2
    echo -e "${GREEN}1) remote${NC}          - 远程包（默认）" >&2
    echo -e "${YELLOW}2) source${NC}          - 本地源码" >&2
    echo -e "${CYAN}3) localframework${NC}  - 本地 Framework" >&2
    echo -e "${BLUE}4) remote (指定版本)${NC}" >&2
    echo "" >&2

    while true; do
        read -p "请输入选择 [1-4，默认为1]: " choice >&2
        choice=${choice:-1}

        case $choice in
            1)
                echo "remote"
                return 0
                ;;
            2)
                echo "source"
                return 0
                ;;
            3)
                echo "localframework"
                return 0
                ;;
            4)
                while true; do
                    read -p "请输入远程版本号 (例如: ${DEFAULT_REMOTE_VERSION}): " version >&2
                    if [ -n "$version" ]; then
                        echo "remote:$version"
                        return 0
                    else
                        echo -e "${RED}错误: 版本号不能为空${NC}" >&2
                    fi
                done
                ;;
            *)
                echo -e "${RED}无效选择，请输入 1、2、3 或 4${NC}" >&2
                ;;
        esac
    done
}

# 设置环境变量
set_environment_variables() {
    local mode=$1
    local version=$2

    export TUIST_SPM_MODE="$mode"

    if [ "$mode" = "remote" ]; then
        export TUIST_REMOTE_VERSION="${version:-$DEFAULT_REMOTE_VERSION}"
        echo -e "${GREEN}✅ 已设置 TUIST_REMOTE_VERSION=${TUIST_REMOTE_VERSION}${NC}"
    else
        unset TUIST_REMOTE_VERSION
    fi

    echo -e "${GREEN}✅ 已设置 TUIST_SPM_MODE=${TUIST_SPM_MODE}${NC}"
}

# 显示当前配置
show_selection_summary() {
    local mode=$1
    local version=$2
    echo ""
    echo -e "${CYAN}集成模式: ${mode}${NC}"
    case $mode in
        "remote")
            echo -e "${CYAN}版本: ${version:-$DEFAULT_REMOTE_VERSION}${NC}"
            ;;
        "source")
            echo -e "${CYAN}路径: ${SCRIBBLEFORGE_SOURCE_PATH}${NC}"
            ;;
        "localframework")
            echo -e "${CYAN}路径: ${SCRIBBLEFORGE_LOCAL_FRAMEWORK_PATH}${NC}"
            ;;
    esac
    echo ""
}

# 主函数
main() {
    local mode=""
    local version=""
    local dry_run=false
    local interactive=false

    # 检查是否有 --dry-run
    for arg in "$@"; do
        if [ "$arg" = "--dry-run" ]; then
            dry_run=true
        fi
    done

    # 解析参数
    case $1 in
        "remote")
            mode="remote"
            if [ -n "$2" ] && [ "$2" != "--dry-run" ]; then
                version="$2"
            fi
            ;;
        "source")
            mode="source"
            ;;
        "localframework")
            mode="localframework"
            ;;
        "-h"|"--help")
            show_help
            exit 0
            ;;
        "--dry-run")
            interactive=true
            ;;
        "")
            interactive=true
            ;;
        *)
            echo -e "${RED}错误: 未知参数 '$1'${NC}"
            show_help
            exit 1
            ;;
    esac

    # 交互式选择
    if [ "$interactive" = true ]; then
        echo -e "${BLUE}=== ScribbleForge SPM 项目生成 ===${NC}"
        echo ""

        if [ "$dry_run" = true ]; then
            echo -e "${YELLOW}🔍 Dry-run 模式：仅展示配置${NC}"
            echo ""
        fi

        selection=$(interactive_mode_selection)

        if [[ $selection == remote:* ]]; then
            mode="remote"
            version="${selection#remote:}"
        else
            mode="$selection"
        fi

        echo ""
        echo -e "${CYAN}已选择: $mode${NC}"
        if [ "$mode" = "remote" ] && [ -n "$version" ]; then
            echo -e "${CYAN}版本: $version${NC}"
        fi
        echo ""
    else
        echo -e "${BLUE}=== ScribbleForge SPM 项目生成 ===${NC}"
        echo ""

        if [ "$dry_run" = true ]; then
            echo -e "${YELLOW}🔍 Dry-run 模式：仅展示配置${NC}"
            echo ""
        fi
    fi

    if [ "$dry_run" = false ]; then
        if ! command -v tuist &> /dev/null; then
            echo -e "${RED}错误: tuist 未安装${NC}"
            exit 1
        fi
    fi

    set_environment_variables "$mode" "$version"
    show_selection_summary "$mode" "$version"

    if [ "$dry_run" = true ]; then
        echo -e "${GREEN}✅ Dry-run 完成，未执行生成步骤${NC}"
        if [ "$mode" = "remote" ] && [ -n "$version" ]; then
            echo -e "${BLUE}远程版本: $version${NC}"
        fi
        return 0
    fi

    echo -e "${YELLOW}正在运行 tuist generate...${NC}"
    if tuist generate --no-open; then
        echo -e "${GREEN}✅ tuist generate 完成${NC}"
    else
        echo -e "${RED}❌ tuist generate 失败${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}🎉 项目生成完成！${NC}"
    echo -e "${BLUE}集成模式: $mode${NC}"
    if [ "$mode" = "remote" ]; then
        echo -e "${BLUE}版本: ${version:-$DEFAULT_REMOTE_VERSION}${NC}"
    fi
    echo ""
    echo -e "${YELLOW}打开项目:${NC}"
    echo "open S11E-SPM.xcodeproj"
}

main "$@"
