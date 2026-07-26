///|
/// 将键值对转义为JSON字符串（简化版）
fn escape_json_string(s : String) -> String {
  // TODO: full escape
  "\"" + s + "\"" // 简化的转义
}

///|
/// 格式化时间为 RFC3339 纳秒（这里简单以纳秒整数代替）
fn format_time(t : @core.Time) -> String {
  t.to_nanos().to_string()
}

///|
/// 导出Span为OTel JSONL格式
pub fn export_span_jsonl(span : Span) -> String {
  let mut json = "{"
  json = json + "\"traceId\":\"" + span.trace_id + "\","
  json = json + "\"spanId\":\"" + span.span_id + "\","
  match span.parent_id {
    Some(pid) => json = json + "\"parentSpanId\":\"" + pid + "\","
    None => ()
  }
  json = json + "\"name\":\"" + span.name + "\","
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
    json = json + "{"
    json = json + "\"timeUnixNano\":\"" + format_time(ev.time) + "\","
    json = json + "\"name\":\"" + ev.message + "\""
    json = json + "}"
    first_event = false
  }
  json = json + "]"

  json = json + "}"
  json
}
