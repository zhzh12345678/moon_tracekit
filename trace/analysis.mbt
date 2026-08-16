///|
/// Trace 数据质量问题。
///
/// 这些问题不是导出器的格式错误，而是调用方在组装完整 trace 时最容易
/// 遗漏的语义约束。将它们显式建模后，CI 可以在写入后端之前阻断坏数据。
pub(all) enum TraceIssue {
  DuplicateSpanId(String)
  MissingParent(String)
  CrossTraceParent(String)
  InvalidSpanTime(String)
  EventOutsideSpan(String)
  UnboundEvent(String)
  EmptySpanName(String)
} derive(Eq, Debug)

///|
/// 一次 trace 的聚合统计。
pub(all) struct TraceSummary {
  trace_count : Int
  span_count : Int
  root_count : Int
  event_count : Int
  error_event_count : Int
  open_span_count : Int
  earliest_start : @core.Time?
  latest_end : @core.Time?
  duration : @core.Duration
}

///|
/// 一次 trace 数据质量分析结果。
pub(all) struct TraceAnalysis {
  summary : TraceSummary
  issues : Array[TraceIssue]
}

///|
/// 将问题转换为稳定、适合日志和 CI 输出的文本。
pub fn TraceIssue::to_string(self : TraceIssue) -> String {
  match self {
    DuplicateSpanId(id) => "duplicate span id: " + id
    MissingParent(id) => "missing parent for span: " + id
    CrossTraceParent(id) => "parent belongs to another trace: " + id
    InvalidSpanTime(id) => "invalid span time: " + id
    EventOutsideSpan(id) => "event outside span: " + id
    UnboundEvent(id) => "event is not bound to its span: " + id
    EmptySpanName(id) => "empty span name: " + id
  }
}

///|
/// 返回分析结果是否适合导出。
pub fn TraceAnalysis::is_valid(self : TraceAnalysis) -> Bool {
  self.issues.is_empty()
}

///|
/// 返回发现的问题数量。
pub fn TraceAnalysis::issue_count(self : TraceAnalysis) -> Int {
  self.issues.length()
}

///|
/// 返回分析摘要。
pub fn TraceAnalysis::summary(self : TraceAnalysis) -> TraceSummary {
  self.summary
}

///|
/// 返回所有问题的只读数组视图。
pub fn TraceAnalysis::issues(self : TraceAnalysis) -> ArrayView[TraceIssue] {
  self.issues[:]
}

///|
/// 以稳定字段顺序生成摘要文本。
pub fn TraceSummary::to_string(self : TraceSummary) -> String {
  let earliest = match self.earliest_start {
    Some(t) => t.to_string()
    None => "none"
  }
  let latest = match self.latest_end {
    Some(t) => t.to_string()
    None => "none"
  }
  "traces=\{self.trace_count} spans=\{self.span_count} roots=\{self.root_count} " +
  "events=\{self.event_count} errors=\{self.error_event_count} " +
  "open=\{self.open_span_count} earliest=\{earliest} latest=\{latest} " +
  "duration=\{self.duration.to_string()}"
}

///|
/// 以稳定字段顺序生成摘要 JSON。
pub fn TraceSummary::to_json(self : TraceSummary) -> String {
  "{\"traceCount\":" +
  self.trace_count.to_string() +
  ",\"spanCount\":" +
  self.span_count.to_string() +
  ",\"rootCount\":" +
  self.root_count.to_string() +
  ",\"eventCount\":" +
  self.event_count.to_string() +
  ",\"errorEventCount\":" +
  self.error_event_count.to_string() +
  ",\"openSpanCount\":" +
  self.open_span_count.to_string() +
  ",\"durationNanos\":" +
  self.duration.to_nanos().to_string() +
  "}"
}

///|
/// 生成包含摘要和问题列表的 CI 报告。
pub fn TraceAnalysis::to_report(self : TraceAnalysis) -> String {
  let mut out = "=== Trace Quality Report ===\n"
  out = out + "Valid: \{self.is_valid()}\n"
  out = out + self.summary.to_string() + "\n"
  if self.issues.is_empty() {
    return out + "Issues: none\n"
  }
  out = out + "Issues:\n"
  for issue in self.issues {
    out = out + "- " + issue.to_string() + "\n"
  }
  out
}

///|
/// 以两个时间点之间的较早值更新起点。
fn update_earliest(current : @core.Time?, candidate : @core.Time) -> @core.Time {
  match current {
    None => candidate
    Some(value) => if candidate.compare(value) < 0 { candidate } else { value }
  }
}

///|
/// 以两个时间点之间的较晚值更新终点。
fn update_latest(current : @core.Time?, candidate : @core.Time) -> @core.Time {
  match current {
    None => candidate
    Some(value) => if candidate.compare(value) > 0 { candidate } else { value }
  }
}

///|
/// 计算一组 Span 的 trace 质量和时间范围。
///
/// 校验分两阶段进行：第一阶段登记 Span 和 trace ID，第二阶段检查父子
/// 关系及事件关联。这样可以正确处理子 Span 出现在父 Span 之前或之后的
/// 批量导出顺序，而不会把合法的乱序输入误报为缺少父节点。
pub fn analyze_trace(spans : Array[Span]) -> TraceAnalysis {
  let span_ids : Map[String, Span] = Map([])
  let trace_ids : Map[String, Bool] = Map([])
  let mut root_count = 0
  let mut event_count = 0
  let mut error_event_count = 0
  let mut open_span_count = 0
  let mut earliest_start : @core.Time? = None
  let mut latest_end : @core.Time? = None
  let issues : Array[TraceIssue] = []

  // Pass one: collect IDs, aggregate range and validate local Span fields.
  for span in spans {
    match span_ids.get(span.span_id) {
      Some(_) => issues.push(DuplicateSpanId(span.span_id))
      None => span_ids.set(span.span_id, span)
    }
    trace_ids.set(span.trace_id, true)
    if span.parent_id == None {
      root_count = root_count + 1
    }
    if span.name == "" {
      issues.push(EmptySpanName(span.span_id))
    }
    earliest_start = Some(update_earliest(earliest_start, span.start_time))
    match span.end_time {
      None => open_span_count = open_span_count + 1
      Some(end_time) => {
        latest_end = Some(update_latest(latest_end, end_time))
        if end_time.compare(span.start_time) < 0 {
          issues.push(InvalidSpanTime(span.span_id))
        }
      }
    }
    for event in span.events {
      event_count = event_count + 1
      if event.level == LogLevel::Error {
        error_event_count = error_event_count + 1
      }
    }
  }

  // Pass two: validate parent relationships and event ownership.
  for span in spans {
    match span.parent_id {
      None => ()
      Some(parent_id) =>
        match span_ids.get(parent_id) {
          None => issues.push(MissingParent(span.span_id))
          Some(parent) =>
            if parent.trace_id != span.trace_id {
              issues.push(CrossTraceParent(span.span_id))
            }
        }
    }
    for event in span.events {
      if event.trace_id != Some(span.trace_id) ||
        event.span_id != Some(span.span_id) {
        issues.push(UnboundEvent(span.span_id))
      }
      let event_before_start = event.time.compare(span.start_time) < 0
      let event_after_end = match span.end_time {
        None => false
        Some(end_time) => event.time.compare(end_time) > 0
      }
      if event_before_start || event_after_end {
        issues.push(EventOutsideSpan(span.span_id))
      }
    }
  }

  let duration = match (earliest_start, latest_end) {
    (Some(start), Some(end)) =>
      if end.compare(start) >= 0 {
        end.sub(start)
      } else {
        @core.Duration::zero()
      }
    _ => @core.Duration::zero()
  }
  {
    summary: {
      trace_count: trace_ids.length(),
      span_count: spans.length(),
      root_count,
      event_count,
      error_event_count,
      open_span_count,
      earliest_start,
      latest_end,
      duration,
    },
    issues,
  }
}

///|
/// 分析单个完整 trace 的便捷入口。
pub fn analyze_single_trace(
  root : Span,
  children : Array[Span],
) -> TraceAnalysis {
  let all = [root]
  for child in children {
    all.push(child)
  }
  analyze_trace(all)
}

///|
/// 只保留指定 trace ID 的 Span，适合多请求批量日志中的单 trace 查询。
pub fn select_trace(spans : Array[Span], trace_id : String) -> Array[Span] {
  let selected : Array[Span] = []
  for span in spans {
    if span.trace_id == trace_id {
      selected.push(span)
    }
  }
  selected
}

///|
/// 只保留包含指定事件级别的 Span。
pub fn select_spans_with_level(
  spans : Array[Span],
  level : LogLevel,
) -> Array[Span] {
  let selected : Array[Span] = []
  for span in spans {
    let mut found = false
    for event in span.events {
      if event.level == level {
        found = true
      }
    }
    if found {
      selected.push(span)
    }
  }
  selected
}

///|
/// 返回指定 trace 中所有 Span 的最长持续时间。
pub fn longest_span(spans : Array[Span]) -> Span? {
  let mut result : Span? = None
  let mut has_result = false
  let mut longest = @core.Duration::zero()
  for span in spans {
    match span.end_time {
      None => ()
      Some(end_time) => {
        let duration = end_time.sub(span.start_time)
        if !has_result || duration.compare(longest) > 0 {
          result = Some(span)
          has_result = true
          longest = duration
        }
      }
    }
  }
  result
}
