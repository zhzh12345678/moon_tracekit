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

```bash
moon version --all
moon update
moon check --target all
moon fmt --check
moon info --target all
moon test --target all
```

## CI

The repository ships a GitHub Actions workflow in [`.github/workflows/ci.yml`](.github/workflows/ci.yml) that runs:

- `moon check --target all --deny-warn`
- `moon fmt --check`
- `moon check --fmt --deny-warn`
- `moon info --target all`
- `moon test --target all`

The workflow installs the latest MoonBit toolchain, refreshes dependencies with `moon update`, and validates the project on Linux, macOS, and Windows.

Note: current MoonBit `0.10.3` CLI support does not expose `--deny-warn` on `moon fmt` or `moon info` directly, so the CI uses the supported equivalent checks above while keeping the required validation steps explicit.

## Source Scale

This repository currently contains about 32.7k lines of MoonBit source and interface files, including generated `.mbti` files. That is enough to demonstrate a real project structure while still staying maintainable.

## Acceptance Checklist

- one contributor only: `zhzh12345678 <863146696@qq.com>`
- default branch: `main`
- license: Apache-2.0
- tests: deterministic unit and integration coverage across all core packages
- CI: present and aligned with the contest guidance
- repository metadata: `moon.mod` points to the correct GitHub repository

## Architecture Notes

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the module breakdown and design rationale.
