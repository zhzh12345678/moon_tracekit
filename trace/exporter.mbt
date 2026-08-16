///|
/// 将字符串编码为 JSON 字符串。
///
/// Span 名称、属性和事件消息通常来自业务输入，不能直接拼接到 JSON
/// 中；这里处理 JSON 必需的引号、反斜杠和控制字符转义。
fn escape_json_string(s : String) -> String {
  let mut out = "\""
  for c in s {
    match c {
      '"' => out = out + "\\\""
      '\\' => out = out + "\\\\"
      '\n' => out = out + "\\n"
      '\r' => out = out + "\\r"
      '\t' => out = out + "\\t"
      '\b' => out = out + "\\b"
      '\f' => out = out + "\\f"
      _ => out = out + "\{c}"
    }
  }
  out + "\""
}

///|
/// 格式化时间为 RFC3339 纳秒（这里简单以纳秒整数代替）
fn format_time(t : @core.Time) -> String {
  t.to_nanos().to_string()
}

///|
/// 导出单个遥测事件，保留日志级别、Span 关联和事件属性。
fn export_event_json(event : TelemetryEvent) -> String {
  let mut json = "{\"timeUnixNano\":\"" +
    format_time(event.time) +
    "\",\"name\":" +
    escape_json_string(event.message) +
    ",\"level\":" +
    escape_json_string(event.level.to_string())
  match event.trace_id {
    Some(tid) => json = json + ",\"traceId\":" + escape_json_string(tid)
    None => ()
  }
  match event.span_id {
    Some(sid) => json = json + ",\"spanId\":" + escape_json_string(sid)
    None => ()
  }
  json = json + ",\"attributes\":{"
  let mut first = true
  for k, v in event.attributes {
    if !first {
      json = json + ","
    }
    json = json + escape_json_string(k) + ":" + escape_json_string(v)
    first = false
  }
  json + "}}"
}

///|
/// 导出Span为OTel JSONL格式
pub fn export_span_jsonl(span : Span) -> String {
  let mut json = "{"
  json = json + "\"traceId\":" + escape_json_string(span.trace_id) + ","
  json = json + "\"spanId\":" + escape_json_string(span.span_id) + ","
  match span.parent_id {
    Some(pid) =>
      json = json + "\"parentSpanId\":" + escape_json_string(pid) + ","
    None => ()
  }
  json = json + "\"name\":" + escape_json_string(span.name) + ","
  json = json +
    "\"startTimeUnixNano\":\"" +
    format_time(span.start_time) +
    "\","
  match span.end_time {
    Some(et) => json = json + "\"endTimeUnixNano\":\"" + format_time(et) + "\","
    None => ()
  }

  // Attributes
  json = json + "\"attributes\":{"
  let mut first_attr = true
  for k, v in span.attributes {
    if !first_attr {
      json = json + ","
    }
    json = json + escape_json_string(k) + ":" + escape_json_string(v)
    first_attr = false
  }
  json = json + "},"

  // Events
  json = json + "\"events\":["
  let mut first_event = true
  for ev in span.events {
    if !first_event {
      json = json + ","
    }
    json = json + export_event_json(ev)
    first_event = false
  }
  json = json + "]"

  json = json + "}"
  json
}

///|
/// 按输入顺序导出多个 Span，每行一个 JSON 对象，便于写入日志文件或管道。
pub fn export_spans_jsonl(spans : Array[Span]) -> String {
  let mut out = ""
  for i, span in spans {
    if i > 0 {
      out = out + "\n"
    }
    out = out + export_span_jsonl(span)
  }
  out
}
