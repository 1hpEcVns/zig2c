# Zig to C 开发环境

基于 Nix 的 Zig + C 开发环境，专为competitive programming设计。

## 环境要求

- Nix with flake support

## 快速开始

```sh
# 进入开发环境
nix develop -i

# 编译运行
zig build-exe main.zig -O Debug
./main
```

## 脚本

| 脚本 | 说明 |
|------|------|
| `zc.sh <file.zig>` | 翻译 Zig 代码到 C |
| `zcr.sh <file.zig>` | 翻译到 C (输出信息) |
| `zd.sh <file.zig>` | 使用 lldb 调试 |

## 依赖

- zig (unstable)
- clang (llvm)
- lldb (llvm)
- helix (编辑器)
- zls (语言服务器)

## 配置

- Helix: 自动配置 Zig 语言支持 + ZLS
- 缓存目录: `/tmp/cache`, `/tmp/zig-cache`

## 示例代码

`main.zig` - 二叉树遍历:
- 前序遍历 (Preorder)
- 中序遍历 (Inorder)
- 后序遍历 (Postorder)

`header.zig` - 快速 IO 库:
- `init()` - 初始化
- `readInt(T)` - 读取整数
- `printInt(x)` - 输出整数
- `printStr(s)` - 输出字符串

## 调试

```sh
# 使用 lldb 调试
./zd.sh main.zig

# 或手动
zig build-exe main.zig -O Debug
lldb ./main -b -o "run"
```