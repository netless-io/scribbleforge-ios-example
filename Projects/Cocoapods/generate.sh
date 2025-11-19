#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_MODE="latest"
SCRIBBLEFORGE_PODSPEC_URL="https://raw.githubusercontent.com/netless-io/scribbleforge-ios-release/refs/heads/main/ScribbleForge.podspec"
SCRIBBLEFORGE_SOURCE_PATH="../../../scribbleforge-ios"

# 帮助信息
show_help() {
    echo -e "${BLUE}ScribbleForge CocoaPods 项目生成脚本${NC}"
    echo ""
    echo "用法: $0 [选项] [--dry-run]"
    echo ""
    echo "选项:"
    echo "  latest                  使用最新版本的SDK (默认)"
    echo "  sourcecode              使用源码集成"
    echo "  localframework          使用本地 Framework 集成"
    echo "  version <版本号>         使用指定版本的SDK"
    echo "  --dry-run               只生成Podfile，不执行构建"
    echo "  -h, --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                      # 交互式选择模式"
    echo "  $0 latest               # 最新SDK版本并构建"
    echo "  $0 latest --dry-run     # 只生成最新SDK的Podfile"
    echo "  $0 version 0.1.35       # 指定SDK版本并构建"
}

# 交互式选择模式
interactive_mode_selection() {
    echo -e "${CYAN}=== 选择集成模式 ===${NC}" >&2
    echo "" >&2
    echo "请选择 ScribbleForge 的集成方式：" >&2
    echo "" >&2
    echo -e "${GREEN}1) latest${NC}     - 使用最新版本的SDK (推荐)" >&2
    echo -e "${YELLOW}2) sourcecode${NC} - 使用本地源码集成" >&2
    echo -e "${CYAN}3) localframework${NC} - 使用本地 Framework 集成" >&2
    echo -e "${BLUE}4) version${NC}    - 使用指定版本的SDK" >&2
    echo "" >&2
    
    while true; do
        read -p "请输入选择 [1-4，默认为1]: " choice >&2
        choice=${choice:-1}  # 默认选择1(latest)
        
        case $choice in
            1)
                echo "latest"
                return 0
                ;;
            2)
                echo "sourcecode"
                return 0
                ;;
            3)
                echo "localframework"
                return 0
                ;;
            4)
                while true; do
                    read -p "请输入SDK版本号 (例如: 0.1.35): " version >&2
                    if [ -n "$version" ]; then
                        echo "version:$version"
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

# 生成 Podfile
generate_podfile() {
    local mode=$1
    local version=$2
    
    echo -e "${YELLOW}正在生成 Podfile...${NC}"
    
    cat > Podfile << EOF
use_frameworks!

platform :ios, '16.0'

target 'S11E-Pod' do
EOF

    case $mode in
        "sourcecode")
            echo -e "${GREEN}使用源码集成模式${NC}"
            cat >> Podfile << EOF
    # 源码集成方式（本地源码）
    pod 'ScribbleForge/AgoraRtmKit2.2.x', :path => '$SCRIBBLEFORGE_SOURCE_PATH'
EOF
            ;;
        "localframework")
            echo -e "${GREEN}使用本地 Framework 模式${NC}"
            cat >> Podfile << EOF
    # 本地 Framework 模式
    pod 'ScribbleForge/AgoraRtmKit2.2.x', :path => '../../../scribbleforge-ios/ci-scripts/ScribbleLocalFramework'
EOF
            ;;
        "latest")
            echo -e "${GREEN}使用最新SDK版本${NC}"
            cat >> Podfile << EOF
    # SDK集成方式（最新版本）
    pod 'ScribbleForge/AgoraRtmKit2.2.x', :podspec => '$SCRIBBLEFORGE_PODSPEC_URL'
EOF
            ;;
        "version")
            echo -e "${GREEN}使用指定SDK版本: $version${NC}"
            cat >> Podfile << EOF
    # SDK集成方式（指定版本）
    pod 'ScribbleForge/AgoraRtmKit2.2.x', '$version'
EOF
            ;;
    esac

    cat >> Podfile << EOF
    
    pod 'AgoraRtcEngine_iOS', '~> 4.3.0'
    pod 'Zip'
    pod 'DebugSwift'
    pod 'SnapKit'
    pod 'Toast-Swift'
end

# 集成模式: $mode
EOF

    if [ "$mode" = "version" ] && [ -n "$version" ]; then
        echo "# 指定版本: $version" >> Podfile
    fi
}

# 设置环境变量
set_environment_variables() {
    local mode=$1
    
    if [ "$mode" = "sourcecode" ]; then
        export TUIST_SOURCE_INTEGRATION=true
        echo -e "${GREEN}✅ 已设置 TUIST_SOURCE_INTEGRATION 环境变量${NC}"
    else
        unset TUIST_SOURCE_INTEGRATION
    fi
}

# 主函数
main() {
    local mode=""
    local version=""
    local dry_run=false
    local interactive=false
    
    # 检查是否有--dry-run参数
    for arg in "$@"; do
        case $arg in
            "--dry-run")
                dry_run=true
                ;;
        esac
    done
    
    # 解析参数
    case $1 in
        "sourcecode")
            mode="sourcecode"
            ;;
        "localframework")
            mode="localframework"
            ;;
        "latest")
            mode="latest"
            ;;
        "version")
            if [ -z "$2" ] || [[ "$2" == "--dry-run" ]]; then
                echo -e "${RED}错误: 请提供版本号${NC}"
                echo "用法: $0 version <版本号> [--dry-run]"
                exit 1
            fi
            mode="version"
            version="$2"
            ;;
        "-h"|"--help")
            show_help
            exit 0
            ;;
        "--dry-run")
            # 如果第一个参数是 --dry-run，需要交互式选择
            interactive=true
            ;;
        "")
            # 没有参数，需要交互式选择
            interactive=true
            ;;
        *)
            echo -e "${RED}错误: 未知参数 '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
    
    # 如果需要交互式选择
    if [ "$interactive" = true ]; then
        echo -e "${BLUE}=== ScribbleForge CocoaPods 项目生成 ===${NC}"
        echo ""
        
        if [ "$dry_run" = true ]; then
            echo -e "${YELLOW}🔍 Dry-run 模式：只生成 Podfile${NC}"
            echo ""
        fi
        
        selection=$(interactive_mode_selection)
        
        if [[ $selection == version:* ]]; then
            mode="version"
            version="${selection#version:}"
        else
            mode="$selection"
        fi
        
        echo ""
        echo -e "${CYAN}已选择: $mode${NC}"
        if [ "$mode" = "version" ]; then
            echo -e "${CYAN}版本: $version${NC}"
        fi
        echo ""
    else
        echo -e "${BLUE}=== ScribbleForge CocoaPods 项目生成 ===${NC}"
        echo ""
        
        if [ "$dry_run" = true ]; then
            echo -e "${YELLOW}🔍 Dry-run 模式：只生成 Podfile${NC}"
            echo ""
        fi
    fi
    
    if [ "$dry_run" = false ]; then
        # 检查必要工具
        if ! command -v tuist &> /dev/null; then
            echo -e "${RED}错误: tuist 未安装${NC}"
            exit 1
        fi
        
        if ! command -v pod &> /dev/null; then
            echo -e "${RED}错误: CocoaPods 未安装${NC}"
            exit 1
        fi
    fi
    
    # 设置环境变量
    set_environment_variables "$mode"
    
    # 生成 Podfile
    generate_podfile "$mode" "$version"
    
    echo ""
    echo -e "${YELLOW}生成的 Podfile 内容:${NC}"
    echo -e "${CYAN}$(cat Podfile)${NC}"
    echo ""
    
    if [ "$dry_run" = true ]; then
        echo -e "${GREEN}✅ Podfile 生成完成（dry-run 模式）${NC}"
        echo -e "${BLUE}集成模式: $mode${NC}"
        if [ "$mode" = "version" ]; then
            echo -e "${BLUE}SDK版本: $version${NC}"
        fi
        if [ "$mode" = "sourcecode" ]; then
            echo -e "${BLUE}环境变量: TUIST_SOURCE_INTEGRATION=true${NC}"
        fi
        echo ""
        echo -e "${YELLOW}要执行完整构建，请运行:${NC}"
        if [ "$mode" = "version" ]; then
            echo "./generate.sh $mode $version"
        else
            echo "./generate.sh $mode"
        fi
        return 0
    fi
    
    # 执行 tuist generate
    echo -e "${YELLOW}正在运行 tuist generate...${NC}"
    if tuist generate --no-open; then
        echo -e "${GREEN}✅ tuist generate 完成${NC}"
    else
        echo -e "${RED}❌ tuist generate 失败${NC}"
        exit 1
    fi
    
    # 执行 pod install
    echo ""
    echo -e "${YELLOW}正在运行 pod install...${NC}"
    if pod install; then
        echo -e "${GREEN}✅ pod install 完成${NC}"
    else
        echo -e "${RED}❌ pod install 失败${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}🎉 项目生成完成！${NC}"
    echo -e "${BLUE}集成模式: $mode${NC}"
    if [ "$mode" = "version" ]; then
        echo -e "${BLUE}SDK版本: $version${NC}"
    fi
    if [ "$mode" = "sourcecode" ]; then
        echo -e "${BLUE}编译标志: TUIST_SOURCE_INTEGRATION${NC}"
    fi
    echo ""
    echo -e "${YELLOW}打开项目:${NC}"
    echo "open S11E-Pod.xcworkspace"
}

# 运行主函数
main "$@"
