# 本地验收自检记录

本文件只记录可以在本地复现的证据，不替代 GitHub、GitLink 或 mooncakes.io 的远程状态。

## 必检命令

```bash
moon version --all
moon update
moon check --target all --deny-warn
moon fmt --check
moon check --fmt --deny-warn
moon info --target all
git diff --exit-code
moon test --target all
moon run cmd/demo
```

## 验收映射

- MoonBit 主实现：仓库源文件以 `.mbt` 为主，模块名在 `moon.mod` 中声明。
- 可复现使用：README 提供安装、检查、测试、运行和最小 API 示例。
- 核心路径：`core`、`sync`、`net`、`fault`、`metrics`、`trace` 均有测试。
- CI：`.github/workflows/ci.yml` 覆盖检查、格式、接口生成差异和多平台测试。
- 开源合规：根目录 `LICENSE` 为 Apache-2.0；本项目声明不复制第三方代码。
- 远程门槛：GitHub/GitLink 的公开同步、最新 CI 运行记录和 mooncakes.io 发布必须在授权后另行核验。

## 当前限制

本地环境若没有 Node.js，`moon test --target all` 的 JS 目标可能无法启动；这不影响 Wasm/Wasm-GC 编译测试，但必须在 CI 或安装 Node.js 后补做 JS 目标验证。项目也不能仅凭本地文件证明 mooncakes.io 已发布。
