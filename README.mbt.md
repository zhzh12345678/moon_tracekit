# MoonTraceKit

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![MoonBit 0.10.3](https://img.shields.io/badge/MoonBit-0.10.3-purple.svg)](https://www.moonbitlang.com)
[![OSC 2026](https://img.shields.io/badge/OSC_2026-Track_1-orange.svg)](https://www.gitlink.org.cn/competitions/track1_2026MoonBit)

MoonTraceKit is a MoonBit-native deterministic tracing and observability toolkit for event-driven systems. It focuses on three things:

- deterministic virtual time and reproducible simulations
- structured tracing, logging, and metrics for concurrent workflows
- a test-friendly runtime that makes race conditions and timing bugs easier to reproduce

The repository is organized as a single-owner OSC 2026 project and is intended to satisfy the final acceptance checklist:

- public repository
- Apache-2.0 license
- clear README and architecture notes
- runnable tests and CI
- a single contributor: `zhzh12345678`

## Repository

- GitHub: [zhzh12345678/moon_tracekit](https://github.com/zhzh12345678/moon_tracekit)
- GitLink: [zhzh12345678/moon_tracekit](https://gitlink.org.cn/zhzh12345678/moon_tracekit)

## Layout

- `core/`: virtual time engine, scheduling primitives, and deterministic simulation helpers
- `process/`: lightweight actor-style process management
- `sync/`: deterministic channels, mutexes, semaphores, and barriers
- `net/` and `fault/`: network topology, packet routing, and fault injection
- `metrics/`: counters, gauges, histograms, and percentile reporting
- `testing/`: assertions and chaos-oriented test helpers
- `examples/`: queueing and distributed-systems simulations
- `cmd/demo/`: interactive demo entry point
- `docs/ARCHITECTURE.md`: architecture notes and module overview

## Build And Test

The project targets MoonBit `0.10.3`.

### 安装环境

请按照[MoonBit官方指南](https://www.moonbitlang.cn/download/)安装最新的 `0.10.3` 工具链。

```bash
# 验证安装版本
moon version --all
# 更新依赖
moon update
```

### 启动命令

运行本地交互式追踪演示：

```bash
moon run cmd/demo
```

将输出包含队列模拟、Raft 选举，以及我们提供的 **全链路追踪 SDK 瀑布流和 OTel JSONL 演示**。

### API 示例

这是一个如何在你的 MoonBit 业务代码中加入追踪、记录日志，并导出瀑布流的示例：

```moonbit
let bg_ctx = @trace.Context::background()
let t_start = @core.Time::from_millis(100L)

// 1. 创建 Root Span
let (root_span, ctx) = @trace.Span::start_root("process_request", t_start, bg_ctx)
root_span.set_attribute("http.method", "GET")

// 2. 异步上下文传播，创建子 Span
let t_db = @core.Time::from_millis(110L)
let (db_span, _) = @trace.Span::start_child("db_query", t_db, ctx)

// 3. 关联遥测日志
db_span.add_event(@trace.TelemetryEvent::new(
  @core.Time::from_millis(115L),
  @trace.LogLevel::Info,
  "Executing DB query",
))

// 4. 结束 Spans
db_span.end(@core.Time::from_millis(150L))
root_span.end(@core.Time::from_millis(165L))

// 5. 打印瀑布流及导出 OTel JSONL
println(@trace.print_waterfall([root_span, db_span], t_start, @core.Time::from_millis(170L)))
println(@trace.export_span_jsonl(root_span))
```

## CI

The repository ships a GitHub Actions workflow in [`.github/workflows/ci.yml`](.github/workflows/ci.yml) that runs:

- `moon check --target all --deny-warn`
- `moon fmt --deny-warn`
- `moon check --fmt --deny-warn`
- `moon info --target all --deny-warn`
- `moon test --target all`

The workflow installs the latest MoonBit toolchain, refreshes dependencies with `moon update`, and validates the project on Linux, macOS, and Windows.

## Source Scale

This repository contains over **4,000 lines of effective MoonBit source code** (`.mbt` and `.mbti`), specifically focusing on the virtual time engine, synchronization primitives, simulation actors, and the **full-link tracing SDK**. This explicitly avoids counting generated binary files or external `.moon` target caches, ensuring compliance with the contest requirement of 4~10k effective lines.

## Acceptance Checklist

- one contributor only: `zhzh12345678 <863146696@qq.com>`
- default branch: `main`
- license: Apache-2.0
- tests: deterministic unit and integration coverage across all core packages
- CI: present and aligned with the contest guidance
- repository metadata: `moon.mod` points to the correct GitHub repository

## Architecture Notes

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the module breakdown and design rationale.
