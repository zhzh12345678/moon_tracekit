///|
/// 统一遥测事件级别
pub(all) enum LogLevel {
  Debug
  Info
  Warn
  Error
} derive(Eq, Debug)

///|
/// 统一遥测事件，包含日志、追踪事件等
pub(all) struct TelemetryEvent {
  time : @core.Time
  level : LogLevel
  message : String
  attributes : Map[String, String]
}

///|
/// 创建新的遥测事件
pub fn TelemetryEvent::new(
  time : @core.Time,
  level : LogLevel,
  message : String,
  attributes? : Map[String, String] = {},
) -> TelemetryEvent {
  { time, level, message, attributes }
}
