# MoonTraceKit

MoonTraceKit 是一个 MoonBit 原生的确定性仿真与可观测性工具包，面向事件驱动服务、分布式协议和并发组件的回归测试。它把虚拟时间、调度、网络故障、指标和 tracing 放在同一个可复现的测试模型中。

## 能解决什么问题

- 用虚拟纳秒时钟复现超时、重试、排队和竞态，不依赖真实机器时间。
- 用优先队列、Actor 风格进程和同步原语构建可控的并发场景。
- 模拟链路延迟、带宽、丢包、节点宕机和网络分区，验证故障恢复路径。
- 收集 Counter、Gauge、Histogram 和 Span，并输出延迟分位数、ASCII waterfall 和 OTel 风格 JSONL。

项目不是生产网络栈或完整 Raft 实现；`examples/` 用于展示如何把组件组合到可运行的实验中，生产系统应自行接入真实 IO、持久化和安全策略。

## 仓库与许可证

- GitHub：<https://github.com/zhzh12345678/moon_tracekit>
- GitLink：<https://gitlink.org.cn/zhzh12345678/moon_tracekit>
- 许可证：Apache License 2.0，完整文本见 [LICENSE](LICENSE)。

项目为原创 MoonBit 实现，不复制第三方源代码；当前没有外部运行时依赖。若后续加入依赖、生成代码或测试数据，应在本文件或 `docs/` 中记录来源、版本、许可证和再分发范围。

## 目录

- `core/`：虚拟时间、事件、确定性 PCG32 随机数和最小堆优先队列。
- `process/`：轻量 Actor 风格进程调度。
- `sync/`：Channel、Mutex、Semaphore、Barrier。
- `net/`、`fault/`：链路、拓扑、带宽/延迟/丢包和故障注入。
- `metrics/`、`trace/`：指标、Span、Context、waterfall、JSONL 导出。
- `testing/`：断言和确定性 chaos runner。
- `examples/`：M/M/1 排队与三节点选举实验。
- `cmd/demo/`：可直接运行的综合演示。
- `docs/`：架构、验收自检和边界说明。

## 安装与运行

项目兼容 MoonBit 0.10.3 及更新版本；本地验收使用 MoonBit 0.10.7。安装后在仓库根目录执行：

```bash
moon version --all
moon update
moon check --target all --deny-warn
moon fmt --check
moon test --target all
moon run cmd/demo
```

`cmd/demo` 会运行 500 个客户的 M/M/1 排队实验、三节点选举实验和 tracing/OTel 导出示例。所有测试不依赖网络服务和真实时钟，因此同一工具链下结果应可重复。

## 最小使用样例

```moonbit
let sim = @core.Simulator::new()
let _ = sim.schedule(@core.Duration::from_millis(10L), () => println("ready"))
sim.run()

let ctx = @trace.Context::background()
let (span, _) = @trace.Span::start_root("request", sim.now(), ctx)
span.set_attribute("http.method", "GET")
let child_ctx = span.context(ctx)
let (db_span, _) = @trace.Span::start_child("database", sim.now(), child_ctx)
db_span.add_log(sim.now(), @trace.LogLevel::Info, "query started")
db_span.end(sim.now().add(@core.Duration::from_millis(1L)))
span.end(sim.now().add(@core.Duration::from_millis(2L)))
println(@trace.export_spans_jsonl([span, db_span]))
```

## 工程质量与验收证据

CI 位于 `.github/workflows/ci.yml`，覆盖 Linux、macOS、Windows，并显式安装 Node.js 后执行 `moon check`、格式检查、`moon info`、生成接口差异检查和测试。核心边界测试位于各包的 `*_test.mbt`；可复现实验与已知边界见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) 和 [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md)。

本地源码规模会随提交变化，请用 `rg --files -g '*.mbt'` 配合行数统计核验，不在文档中虚构固定覆盖率或行数。最终验收还要求 GitHub/GitLink 公开同步以及发布到 mooncakes.io，这两项必须以远程页面和发布查询结果为准。
