///|
/// 生成 ASCII 瀑布流视图
pub fn print_waterfall(
  spans : Array[Span],
  min_time : @core.Time,
  max_time : @core.Time,
) -> String {
  let mut output = "--- ASCII Waterfall View ---\n"
  let total_nanos = max_time.to_nanos() - min_time.to_nanos()
  let width = 50.0

  if total_nanos <= 0L {
    return output + "Invalid time range.\n"
  }

  // 简单根据 start_time 排序
  spans.sort_by(fn(a, b) {
    if a.start_time.to_nanos() < b.start_time.to_nanos() {
      -1
    } else if a.start_time.to_nanos() > b.start_time.to_nanos() {
      1
    } else {
      0
    }
  })

  for span in spans {
    let start_nanos = span.start_time.to_nanos()
    let raw_end = match span.end_time {
      Some(et) => et.to_nanos()
      None => max_time.to_nanos()
    }
    let visible_start = if start_nanos < min_time.to_nanos() {
      min_time.to_nanos()
    } else if start_nanos > max_time.to_nanos() {
      max_time.to_nanos()
    } else {
      start_nanos
    }
    let visible_end = if raw_end < min_time.to_nanos() {
      min_time.to_nanos()
    } else if raw_end > max_time.to_nanos() {
      max_time.to_nanos()
    } else {
      raw_end
    }
    let start_offset = visible_start - min_time.to_nanos()
    let span_dur = if visible_end > visible_start {
      visible_end - visible_start
    } else {
      0L
    }

    let pre_spaces = (start_offset.to_double() / total_nanos.to_double() * width).to_int()
    let mut bar_len = (span_dur.to_double() / total_nanos.to_double() * width).to_int()
    if bar_len < 1 {
      bar_len = 1
    }

    let mut line = ""
    for i = 0; i < pre_spaces; i = i + 1 {
      line = line + " "
    }
    for i = 0; i < bar_len; i = i + 1 {
      line = line + "█"
    }

    output = output +
      line +
      " [" +
      span.name +
      "] " +
      span_dur.to_string() +
      "ns\n"
  }
  output = output + "----------------------------\n"
  output
}
