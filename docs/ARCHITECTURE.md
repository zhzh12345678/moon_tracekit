# MoonTraceKit 架构与边界

## 1. 设计目标

MoonTraceKit 是一个面向测试与实验的确定性运行时。核心原则是：同一初始状态、种子和事件输入，应得到相同的事件顺序、虚拟时间、指标和 trace 输出。它适合验证协议状态机、重试/超时策略、排队模型和故障恢复逻辑。

## 2. 分层

| 层 | 包 | 责任 |
| --- | --- | --- |
| 时间与调度 | `core` | 纳秒时间、事件优先队列、PCG32、最大时间/事件数保护 |
| 进程与同步 | `process`, `sync` | Actor 风格协作、Channel、Mutex、Semaphore、Barrier |
| 网络与故障 | `net`, `fault` | 链路延迟/带宽/丢包、拓扑路由、分区、宕机、丢包突增 |
| 可观测性 | `metrics`, `trace` | Counter、Gauge、Histogram、带 trace/span 关联的统一事件、Span、Context、waterfall、JSONL |
| 验证与样例 | `testing`, `examples`, `cmd/demo` | 确定性 chaos、排队实验、选举实验和可运行演示 |

## 3. 可复现执行模型

`Simulator` 从当前虚拟时间取出最早事件；相同时间按优先级和事件编号排序。回调可以继续安排事件。`max_time` 和 `max_events` 防止错误模型无限运行。随机行为只从模拟器提供的 PCG32 产生，测试应固定 seed 并比较可观察结果。

## 4. 真实应用边界

网络包、Actor 和 Raft 示例是测试模型，不负责真实 socket、持久化日志、成员变更、TLS、认证或生产级故障隔离。Histogram 使用内存样本并在计算分位数时排序，适合测试和中小规模实验；生产遥测需要窗口化或压缩算法。OTel 导出提供稳定的 JSONL 形状，调用方仍应负责资源属性、批量传输和后端协议适配。

## 5. 验证矩阵

- 时间：零值、纳秒/微秒/毫秒/秒换算、负向差值、同刻度优先级、时间和事件上限。
- 调度：空队列、事件回调追加事件、`run_until`、重置后重新运行。
- 网络：未知链路、带宽延迟、双向链路、队列接收顺序和丢包。
- 故障：节点宕机、分区、丢包突增及按时恢复。
- 指标：空直方图、单样本、P50/P95/P99、极端分位数和重复注册。
- Trace：根/子 Span、父子 Context、特殊字符 JSON 转义、未结束 Span 和批量导出。

对应测试分布在各包的 `*_test.mbt` 文件中，综合路径由 `cmd/demo` 和 `examples/` 覆盖。`Span.add_log` 会把日志事件绑定到当前 Span 的 `trace_id` 与 `span_id`，`Span.context` 可将该身份作为不可变快照传给后续异步回调；`export_spans_jsonl` 则按一行一个对象输出完整 trace。
