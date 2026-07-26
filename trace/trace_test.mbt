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
  span.add_event(
    @trace.TelemetryEvent::new(
      @core.Time::from_millis(105L),
      @trace.LogLevel::Info,
      "request processed",
    ),
  )

  let t2 = @core.Time::from_millis(120L)
  span.end(t2)

  if span.attributes.get("http.status") != Some("200") {
    fail("expected 200")
  }
  if span.events.length() != 1 {
    fail("assert error")
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
