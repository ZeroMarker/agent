#!/bin/bash
# ====================================================
#  Rclone PikPak 上传封装（mv 语义，源会消失）
#  用法：upload <folder|file> [target，默认 ~/pik/TikTok]
#  示例：
#    source rclone/upload.sh && upload ./record1
#    source rclone/upload.sh && upload ./record1 ~/pik/TikTok
#    ./rclone/upload.sh ./record1 ~/pik/TikTok
#
#  行为（等价手写 mv，避免同名嵌套 record1/record1）：
#  - target/<basename> 不存在：mv <folder>/ <target>（整目录移入）
#  - target/<basename> 已存在：mv <folder>/* <target>/<basename>/（合并内容，含隐藏文件）
#  - 文件：mv <file> <target>/
#  要求 ~/pik 已挂载；未挂载直接中止（防写入本地空目录造成“假上传”）。
# ====================================================

# upload <src> [dst]
upload() {
    local src="${1:-}"
    local dst="${2:-$HOME/pik/TikTok}"

    if [ -z "$src" ]; then
        echo "用法：upload <folder|file> [target，默认 ~/pik/TikTok]" >&2
        return 1
    fi
    if [ ! -e "$src" ]; then
        echo "❌ 源不存在：$src" >&2
        return 1
    fi

    # 手动展开前导 ~（加引号传入时 bash 不展开）
    case "$dst" in
        "~"/*) dst="$HOME/${dst#~/}" ;;
        "~") dst="$HOME" ;;
    esac

    mkdir -p "$dst" || return 1

    # 未挂载中止：否则 mv 写进本地空目录，看似成功实则没上传
    if ! findmnt "$HOME/pik" >/dev/null 2>&1; then
        echo "❌ ~/pik 未挂载，拒绝移动（先 systemctl restart rclone-pikpak）" >&2
        return 1
    fi

    # 文件：直接移入目标
    if [ ! -d "$src" ]; then
        mv -- "$src" "$dst/" || return 1
        echo "✅ 已移动：$src → $dst/$(basename "$src")"
        return 0
    fi

    # 目录：去尾部 / 后取 basename
    local base
    base="$(basename "${src%/}")"

    # 同名不存在：整目录移入
    if [ ! -e "$dst/$base" ]; then
        mv -- "$src" "$dst/" || return 1
        echo "✅ 已移动整目录：$src → $dst/$base"
        return 0
    fi

    # 同名已存在：合并内容（含隐藏文件，空目录直接吃掉）
    local f
    local moved=0
    shopt -s dotglob nullglob
    local files=("$src"/*)
    shopt -u dotglob nullglob
    if [ "${#files[@]}" -eq 0 ]; then
        rmdir -- "$src" || return 1
        echo "✅ 源为空目录，已删除：$src（目标 $dst/$base 不变）"
        return 0
    fi
    for f in "${files[@]}"; do
        mv -- "$f" "$dst/$base/" || return 1
        moved=$((moved + 1))
    done
    rmdir -- "$src" || return 1
    echo "✅ 已合并 $moved 项：$src/* → $dst/$base/（源目录已删）"
}

# 直接执行时透传参数；被 source 时只定义函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    upload "$@"
fi
