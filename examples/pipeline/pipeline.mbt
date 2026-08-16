///|
/// 一个可重复的请求流水线实验结果。
pub(all) struct PipelineReport {
  requests : Int
  successes : Int
  timeouts : Int
  cache_hits : Int
  database_calls : Int
  latency : @metrics.HistogramSnapshot
  trace_analysis : @trace.TraceAnalysis
  spans : Array[@trace.Span]
}

///|
/// 请求流水线实验。
///
/// 该场景模拟常见的边缘服务：请求先访问缓存，未命中时访问数据库；
/// 数据库慢请求会触发超时事件。所有步骤使用虚拟时间和固定规则，适合
/// 在 CI 中验证 tracing、指标和错误分析是否保持一致。
pub(all) struct PipelineScenario {
  sim : @core.Simulator
  latency : @metrics.Histogram
  mut requests : Int
  mut successes : Int
  mut timeouts : Int
  mut cache_hits : Int
  mut database_calls : Int
  spans : Array[@trace.Span]
}

///|
/// 创建默认流水线实验。
pub fn PipelineScenario::new(sim : @core.Simulator) -> PipelineScenario {
  {
    sim,
    latency: @metrics.Histogram::new("request_latency_ms"),
    requests: 0,
    successes: 0,
    timeouts: 0,
    cache_hits: 0,
    database_calls: 0,
    spans: [],
  }
}

///|
/// 运行指定数量的请求并返回完整遥测报告。
pub fn PipelineScenario::run(
  self : PipelineScenario,
  request_count : Int,
) -> PipelineReport {
  if request_count <= 0 {
    return self.report()
  }
  for id = 0; id < request_count; id = id + 1 {
    self.schedule_request(id)
  }
  self.sim.run()
  self.report()
}

///|
/// 将一个请求安排到虚拟时间线上。
fn PipelineScenario::schedule_request(
  self : PipelineScenario,
  id : Int,
) -> Unit {
  let start = @core.Time::from_millis((id * 20).to_int64())
  let request_ctx = @trace.Context::background()
  let (root, root_ctx) = @trace.Span::start_root(
    "http_request_\{id}",
    start,
    request_ctx,
  )
  root.set_attribute("http.method", "GET")
  root.set_attribute("http.route", "/v1/items/:id")
  root.add_log(start, @trace.LogLevel::Info, "request accepted", attributes={
    "request.id": id.to_string(),
  })
  self.spans.push(root)
  self.requests = self.requests + 1

  if id % 2 == 0 {
    self.cache_hits = self.cache_hits + 1
    let (cache, _) = @trace.Span::start_child(
      "cache_lookup",
      start.add(@core.Duration::from_millis(1L)),
      root_ctx,
    )
    cache.set_attribute("cache.hit", "true")
    cache.add_log(
      start.add(@core.Duration::from_millis(2L)),
      @trace.LogLevel::Debug,
      "cache hit",
    )
    cache.end(start.add(@core.Duration::from_millis(3L)))
    self.spans.push(cache)
    let _ = self.sim.schedule_at(start.add(@core.Duration::from_millis(4L)), () => {
      root.end(start.add(@core.Duration::from_millis(4L)))
      self.successes = self.successes + 1
      self.latency.record(4.0)
    })
    return ()
  }

  self.database_calls = self.database_calls + 1
  let (db, db_ctx) = @trace.Span::start_child(
    "database_query",
    start.add(@core.Duration::from_millis(2L)),
    root_ctx,
  )
  db.set_attribute("db.system", "postgresql")
  db.add_log(
    start.add(@core.Duration::from_millis(3L)),
    @trace.LogLevel::Info,
    "query started",
  )
  self.spans.push(db)
  let timeout = id % 4 == 3
  let finish = if timeout {
    start.add(@core.Duration::from_millis(120L))
  } else {
    start.add(@core.Duration::from_millis(30L + id.to_int64()))
  }
  let _ = self.sim.schedule_at(finish, () => {
    if timeout {
      db.add_log(
        finish.sub_duration(@core.Duration::from_millis(1L)),
        @trace.LogLevel::Error,
        "database timeout",
        attributes={ "timeout_ms": "100" },
      )
      db.end(finish)
      root.add_log(finish, @trace.LogLevel::Error, "request timed out", attributes={
        "retryable": "true",
      })
      root.end(finish)
      self.timeouts = self.timeouts + 1
    } else {
      db.add_log(
        finish.sub_duration(@core.Duration::from_millis(1L)),
        @trace.LogLevel::Info,
        "query completed",
      )
      db.end(finish)
      let _ = db_ctx
      root.end(finish)
      self.successes = self.successes + 1
      self.latency.record(finish.sub(start).to_millis().to_double())
    }
  })
  ()
}

///|
/// 生成不可变实验报告。
fn PipelineScenario::report(self : PipelineScenario) -> PipelineReport {
  let analysis = @trace.analyze_trace(self.spans)
  {
    requests: self.requests,
    successes: self.successes,
    timeouts: self.timeouts,
    cache_hits: self.cache_hits,
    database_calls: self.database_calls,
    latency: self.latency.snapshot(),
    trace_analysis: analysis,
    spans: self.spans,
  }
}

///|
/// 报告是否同时满足业务结果和 trace 质量要求。
pub fn PipelineReport::is_healthy(self : PipelineReport) -> Bool {
  self.requests == self.successes + self.timeouts &&
  self.trace_analysis.is_valid() &&
  self.trace_analysis.summary().span_count == self.spans.length()
}

///|
/// 生成适合 CLI 或 CI artifact 的流水线摘要。
pub fn PipelineReport::to_string(self : PipelineReport) -> String {
  "requests=\{self.requests} successes=\{self.successes} " +
  "timeouts=\{self.timeouts} cache_hits=\{self.cache_hits} " +
  "database_calls=\{self.database_calls}\n" +
  "latency=\{self.latency.to_string()}\n" +
  self.trace_analysis.to_report()
}

///|
/// 导出本次实验的完整 Span JSONL。
pub fn PipelineReport::to_jsonl(self : PipelineReport) -> String {
  @trace.export_spans_jsonl(self.spans)
}
