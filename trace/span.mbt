///|
/// 追踪跨度 (Span) 
pub(all) struct Span {
  trace_id : String
  span_id : String
  parent_id : String?
  name : String
  start_time : @core.Time
  mut end_time : @core.Time?
  attributes : Map[String, String]
  events : Array[TelemetryEvent]
}

///|
/// 创建一个全新的Trace，返回根Span和Context
pub fn Span::start_root(
  name : String,
  start_time : @core.Time,
  ctx : Context,
) -> (Span, Context) {
  let trace_id = "trace-" + name + "-" + start_time.to_nanos().to_string() // 简化的唯一ID
  let span_id = "span-" + name + "-" + start_time.to_nanos().to_string()
  let span = {
    trace_id,
    span_id,
    parent_id: None,
    name,
    start_time,
    end_time: None,
    attributes: {},
    events: [],
  }
  let new_ctx = ctx.with_span(trace_id, span_id)
  (span, new_ctx)
}

///|
/// 从Context中提取父Span信息，创建子Span
pub fn Span::start_child(
  name : String,
  start_time : @core.Time,
  ctx : Context,
) -> (Span, Context) {
  let parent_trace_id = ctx.value("trace_id")
  let parent_span_id = ctx.value("span_id")

  match parent_trace_id {
    Some(tid) => {
      let span_id = "span-child-" +
        name +
        "-" +
        start_time.to_nanos().to_string()
      let span = {
        trace_id: tid,
        span_id,
        parent_id: parent_span_id,
        name,
        start_time,
        end_time: None,
        attributes: {},
        events: [],
      }
      let new_ctx = ctx.with_span(tid, span_id)
      (span, new_ctx)
    }
    None => Span::start_root(name, start_time, ctx)
  }
}

///|
/// 结束Span
pub fn Span::end(self : Span, end_time : @core.Time) -> Unit {
  self.end_time = Some(end_time)
}

///|
/// 为Span添加属性
pub fn Span::set_attribute(self : Span, key : String, value : String) -> Unit {
  self.attributes.set(key, value)
}

///|
/// 为Span记录事件（Span与日志关联）
pub fn Span::add_event(self : Span, event : TelemetryEvent) -> Unit {
  self.events.push(event.attach(self.trace_id, self.span_id))
}

///|
/// 记录一个与当前 Span 自动关联的日志事件。
pub fn Span::add_log(
  self : Span,
  time : @core.Time,
  level : LogLevel,
  message : String,
  attributes? : Map[String, String] = {},
) -> Unit {
  self.add_event(TelemetryEvent::new(time, level, message, attributes~))
}

///|
/// 从当前 Span 派生异步上下文快照。
pub fn Span::context(self : Span, base : Context) -> Context {
  base.with_span(self.trace_id, self.span_id)
}
