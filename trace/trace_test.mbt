///|
test "context background" {
  let ctx = @trace.Context::background()
  if ctx.value("nonexistent") != None {
    fail("expected None")
  }
}

///|
test "context with value" {
  let ctx1 = @trace.Context::background()
  let ctx2 = ctx1.with_value("key1", "val1")
  let ctx3 = ctx2.with_value("key2", "val2")
  let ctx4 = ctx2.with_value("key1", "val3")

  if ctx1.value("key1") != None {
    fail("assert error")
  }
  if ctx2.value("key1") != Some("val1") {
    fail("assert error")
  }
  if ctx3.value("key1") != Some("val1") {
    fail("assert error")
  }
  if ctx3.value("key2") != Some("val2") {
    fail("expected val2")
  }

  if ctx4.value("key2") != None {
    fail("expected None")
  }
}

///|
test "context propagates span identity without mutating its parent" {
  let base = @trace.Context::background()
  let (root, root_ctx) = @trace.Span::start_root(
    "request",
    @core.Time::from_millis(10L),
    base,
  )
  let root_trace = root_ctx.value("trace_id")
  let root_span = root_ctx.value("span_id")
  let child_ctx = root.context(base)
  if child_ctx.value("trace_id") != root_trace ||
    child_ctx.value("span_id") != root_span {
    fail("span context was not propagated")
  }
  if base.value("trace_id") != None || base.value("span_id") != None {
    fail("parent context was mutated")
  }
}

///|
test "telemetry event creation" {
  let t = @core.Time::from_millis(100L)
  let ev = @trace.TelemetryEvent::new(t, @trace.LogLevel::Info, "test msg")
  if ev.time.to_millis() != 100L {
    fail("assert error")
  }
  // if ev.level != @trace.LogLevel::Info { fail("assert error") } // LogLevel requires Eq
  if ev.message != "test msg" {
    fail("assert error")
  }
}

///|
test "telemetry event with attributes" {
  let t = @core.Time::from_millis(100L)
  let ev = @trace.TelemetryEvent::new(t, @trace.LogLevel::Debug, "test msg", attributes={
    "attr1": "val1",
  })
  if ev.attributes.get("attr1") != Some("val1") {
    fail("expected Some(val1)")
  }
}

///|
test "span start root" {
  let bg = @trace.Context::background()
  let t = @core.Time::from_millis(200L)
  let (span, ctx) = @trace.Span::start_root("root_op", t, bg)

  if span.name != "root_op" {
    fail("assert error")
  }
  if span.parent_id != None {
    fail("expected None")
  }

  // Context should have trace_id and span_id
  let tid = ctx.value("trace_id")
  let sid = ctx.value("span_id")
  match tid {
    Some(_) => ()
    None => fail("trace_id missing")
  }
  match sid {
    Some(_) => ()
    None => fail("span_id missing")
  }
}

///|
test "span start child" {
  let bg = @trace.Context::background()
  let t1 = @core.Time::from_millis(100L)
  let (root, ctx1) = @trace.Span::start_root("root", t1, bg)

  let t2 = @core.Time::from_millis(110L)
  let (child, ctx2) = @trace.Span::start_child("child", t2, ctx1)

  if child.parent_id != Some(root.span_id) {
    fail("expected parent")
  }
  if child.trace_id != root.trace_id {
    fail("assert error")
  }

  let cid = ctx2.value("span_id")
  if cid != Some(child.span_id) {
    fail("expected span_id")
  }
}

///|
test "span end and attributes" {
  let bg = @trace.Context::background()
  let t1 = @core.Time::from_millis(100L)
  let (span, _) = @trace.Span::start_root("root", t1, bg)

  span.set_attribute("http.status", "200")
  span.add_log(
    @core.Time::from_millis(105L),
    @trace.LogLevel::Info,
    "request processed",
    attributes={ "component": "http" },
  )

  let t2 = @core.Time::from_millis(120L)
  span.end(t2)

  if span.attributes.get("http.status") != Some("200") {
    fail("expected 200")
  }
  if span.events.length() != 1 {
    fail("assert error")
  }
  if span.events[0].trace_id != Some(span.trace_id) ||
    span.events[0].span_id != Some(span.span_id) {
    fail("event was not associated with span")
  }
  if span.events[0].attributes.get("component") != Some("http") {
    fail("event attributes were lost")
  }
}

///|
test "waterfall generation" {
  let bg = @trace.Context::background()
  let t1 = @core.Time::from_millis(100L)
  let (root, ctx1) = @trace.Span::start_root("root", t1, bg)
  let (child, _) = @trace.Span::start_child(
    "child",
    @core.Time::from_millis(110L),
    ctx1,
  )

  child.end(@core.Time::from_millis(120L))
  root.end(@core.Time::from_millis(130L))

  let out = @trace.print_waterfall(
    [root, child],
    @core.Time::from_millis(100L),
    @core.Time::from_millis(130L),
  )
  if out.length() == 0 {
    fail("waterfall empty")
  }
}

///|
test "otel jsonl export" {
  let bg = @trace.Context::background()
  let t1 = @core.Time::from_millis(100L)
  let (root, _) = @trace.Span::start_root("root", t1, bg)
  root.set_attribute("key", "val")
  root.end(@core.Time::from_millis(110L))

  let out = @trace.export_span_jsonl(root)
  if out.length() == 0 {
    fail("json empty")
  }
}

///|
test "otel export includes event correlation and level" {
  let bg = @trace.Context::background()
  let (span, _) = @trace.Span::start_root("worker", @core.Time::zero(), bg)
  span.add_log(
    @core.Time::from_millis(2L),
    @trace.LogLevel::Error,
    "database timeout",
    attributes={ "retry": "true" },
  )
  let out = @trace.export_span_jsonl(span)
  if out.contains("\"level\":\"ERROR\"") == false {
    fail("event level was not exported")
  }
  if out.contains("\"traceId\":\"" + span.trace_id) == false ||
    out.contains("\"spanId\":\"" + span.span_id) == false {
    fail("event correlation was not exported")
  }
  if out.contains("\"retry\":\"true\"") == false {
    fail("event attributes were not exported")
  }
}

///|
test "otel export escapes business strings" {
  let bg = @trace.Context::background()
  let (span, _) = @trace.Span::start_root(
    "read \"config\"",
    @core.Time::zero(),
    bg,
  )
  span.set_attribute("path", "C:\\tmp\\a\nnext")
  span.add_event(
    @trace.TelemetryEvent::new(
      @core.Time::from_millis(1L),
      @trace.LogLevel::Warn,
      "line 1\nline 2",
    ),
  )
  let out = @trace.export_span_jsonl(span)
  if out.contains("read \\\"config\\\"") == false {
    fail("span name was not escaped")
  }
  if out.contains("\\n") == false || out.contains("\\\\tmp") == false {
    fail("control characters were not escaped")
  }
}

///|
test "batch export preserves order and empty input" {
  let bg = @trace.Context::background()
  let (first, _) = @trace.Span::start_root("first", @core.Time::zero(), bg)
  let (second, _) = @trace.Span::start_root("second", @core.Time::zero(), bg)
  let empty = @trace.export_spans_jsonl([])
  if empty != "" {
    fail("empty batch should be empty")
  }
  let out = @trace.export_spans_jsonl([first, second])
  if out.split("\n").length() != 2 {
    fail("batch must contain one line per span")
  }
  if out.contains("first") == false || out.contains("second") == false {
    fail("batch lost a span")
  }
}

///|
test "waterfall clips spans outside the requested window" {
  let bg = @trace.Context::background()
  let (span, _) = @trace.Span::start_root(
    "long_operation",
    @core.Time::from_millis(0L),
    bg,
  )
  span.end(@core.Time::from_millis(200L))
  let out = @trace.print_waterfall(
    [span],
    @core.Time::from_millis(50L),
    @core.Time::from_millis(100L),
  )
  if out.contains("250ms") {
    fail("waterfall used unclipped duration")
  }
  if out.contains("50000000ns") == false {
    fail("waterfall did not show visible duration")
  }
}

///|
test "waterfall rejects an empty time window" {
  let out = @trace.print_waterfall(
    [],
    @core.Time::from_millis(5L),
    @core.Time::from_millis(5L),
  )
  if out.contains("Invalid time range") == false {
    fail("invalid range was not reported")
  }
}
