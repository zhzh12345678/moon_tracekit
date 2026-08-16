///|
/// 统一遥测事件级别
pub(all) enum LogLevel {
  Debug
  Info
  Warn
  Error
} derive(Eq, Debug)

///|
/// 返回稳定的日志级别名称，供文本和 JSONL 导出使用。
pub fn LogLevel::to_string(self : LogLevel) -> String {
  match self {
    Debug => "DEBUG"
    Info => "INFO"
    Warn => "WARN"
    Error => "ERROR"
  }
}

///|
/// 统一遥测事件，包含日志、追踪事件等
pub(all) struct TelemetryEvent {
  time : @core.Time
  level : LogLevel
  message : String
  attributes : Map[String, String]
  trace_id : String?
  span_id : String?
}

///|
/// 创建新的遥测事件
pub fn TelemetryEvent::new(
  time : @core.Time,
  level : LogLevel,
  message : String,
  attributes? : Map[String, String] = {},
) -> TelemetryEvent {
  { time, level, message, attributes, trace_id: None, span_id: None }
}

///|
/// 为事件绑定产生它的 Span，用于跨日志、事件和 trace 的关联查询。
fn TelemetryEvent::attach(
  self : TelemetryEvent,
  trace_id : String,
  span_id : String,
) -> TelemetryEvent {
  {
    time: self.time,
    level: self.level,
    message: self.message,
    attributes: self.attributes,
    trace_id: Some(trace_id),
    span_id: Some(span_id),
  }
}
