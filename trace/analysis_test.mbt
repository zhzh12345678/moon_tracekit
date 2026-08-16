///|
fn raw_span(
  trace_id : String,
  span_id : String,
  parent_id : String?,
  name : String,
  start_time : @core.Time,
  end_time : @core.Time?,
  events : Array[TelemetryEvent],
) -> Span {
  {
    trace_id,
    span_id,
    parent_id,
    name,
    start_time,
    end_time,
    attributes: Map([]),
    events,
  }
}

///|
fn make_analyzed_trace() -> (Span, Span, Span) {
  let ctx = Context::background()
  let (root, root_ctx) = Span::start_root(
    "http_request",
    @core.Time::from_millis(100L),
    ctx,
  )
  let (db, _) = Span::start_child(
    "database",
    @core.Time::from_millis(110L),
    root_ctx,
  )
  let (cache, _) = Span::start_child(
    "cache",
    @core.Time::from_millis(112L),
    root_ctx,
  )
  root.add_log(
    @core.Time::from_millis(120L),
    LogLevel::Info,
    "request accepted",
  )
  db.add_log(
    @core.Time::from_millis(130L),
    LogLevel::Error,
    "database timeout",
    attributes={ "retry": "true" },
  )
  cache.end(@core.Time::from_millis(140L))
  db.end(@core.Time::from_millis(160L))
  root.end(@core.Time::from_millis(180L))
  (root, db, cache)
}

///|
test "valid trace analysis reports real request shape" {
  let (root, db, cache) = make_analyzed_trace()
  let analysis = analyze_trace([root, db, cache])
  inspect(analysis.is_valid(), content="true")
  inspect(analysis.issue_count(), content="0")
  let summary = analysis.summary()
  inspect(summary.trace_count, content="1")
  inspect(summary.span_count, content="3")
  inspect(summary.root_count, content="1")
  inspect(summary.event_count, content="2")
  inspect(summary.error_event_count, content="1")
  inspect(summary.open_span_count, content="0")
  inspect(summary.duration.to_millis(), content="80")
  if analysis.to_report().contains("Issues: none") == false {
    fail("valid analysis should not report issues")
  }
  if summary.to_json().contains("\"errorEventCount\":1") == false {
    fail("summary omitted error event count")
  }
}

///|
test "analysis selects one trace from a mixed batch" {
  let (root, db, cache) = make_analyzed_trace()
  let other_ctx = Context::background()
  let (other, _) = Span::start_root(
    "health_check",
    @core.Time::from_secs(2L),
    other_ctx,
  )
  other.end(@core.Time::from_secs(2L).add(@core.Duration::from_millis(1L)))
  let all = [root, db, cache, other]
  let selected = select_trace(all, root.trace_id)
  inspect(selected.length(), content="3")
  let analysis = analyze_trace(selected)
  inspect(analysis.summary().trace_count, content="1")
  let longest = longest_span(selected)
  match longest {
    None => fail("expected a completed span")
    Some(span) => if span.name != "http_request" { fail("wrong longest span") }
  }
}

///|
test "analysis finds error-bearing spans" {
  let (root, db, cache) = make_analyzed_trace()
  let errors = select_spans_with_level([root, db, cache], LogLevel::Error)
  inspect(errors.length(), content="1")
  inspect(errors[0].name, content="database")
  let infos = select_spans_with_level([root, db, cache], LogLevel::Info)
  inspect(infos.length(), content="1")
  inspect(infos[0].name, content="http_request")
}

///|
test "analysis detects missing parents and cross-trace parents" {
  let orphan = raw_span(
    "trace-a",
    "orphan",
    None,
    "orphan",
    @core.Time::from_millis(10L),
    Some(@core.Time::from_millis(20L)),
    [],
  )
  let child = raw_span(
    "trace-a",
    "child",
    Some("missing-parent"),
    "child",
    @core.Time::from_millis(11L),
    Some(@core.Time::from_millis(19L)),
    [],
  )
  let missing = analyze_trace([orphan, child])
  if missing.is_valid() ||
    missing.to_report().contains("missing parent") == false {
    fail("missing parent was not detected")
  }

  let foreign = raw_span(
    "trace-b",
    "foreign",
    None,
    "foreign",
    @core.Time::from_millis(30L),
    Some(@core.Time::from_millis(40L)),
    [],
  )
  let foreign_child = raw_span(
    "trace-b",
    "foreign-child",
    Some("orphan"),
    "foreign_child",
    @core.Time::from_millis(31L),
    Some(@core.Time::from_millis(39L)),
    [],
  )
  let cross = analyze_trace([orphan, foreign, foreign_child])
  if cross.to_report().contains("another trace") == false {
    fail("cross-trace parent was not detected")
  }
}

///|
test "analysis detects bad times and unbound events" {
  let ctx = Context::background()
  let (span, _) = Span::start_root(
    "bad_time",
    @core.Time::from_millis(100L),
    ctx,
  )
  span.events.push(
    TelemetryEvent::new(
      @core.Time::from_millis(50L),
      LogLevel::Warn,
      "arrived too early",
    ),
  )
  span.end(@core.Time::from_millis(90L))
  let invalid = analyze_trace([span])
  if invalid.is_valid() {
    fail("invalid time was accepted")
  }
  if invalid.to_report().contains("invalid span time") == false {
    fail("invalid span time was not reported")
  }
  if invalid.to_report().contains("event outside span") == false {
    fail("event outside span was not reported")
  }
  if invalid.to_report().contains("not bound") == false {
    fail("unbound event was not reported")
  }
}

///|
test "analysis detects duplicate ids and empty names" {
  let first = raw_span(
    "trace-a",
    "same-id",
    None,
    "first",
    @core.Time::zero(),
    Some(@core.Time::from_millis(1L)),
    [],
  )
  let second = raw_span(
    "trace-a",
    "same-id",
    None,
    "",
    @core.Time::from_millis(1L),
    Some(@core.Time::from_millis(2L)),
    [],
  )
  let analysis = analyze_trace([first, second])
  let report = analysis.to_report()
  if report.contains("duplicate span id") == false ||
    report.contains("empty span name") == false {
    fail("duplicate or empty span was not detected")
  }
}

///|
test "analysis handles open spans and no completed range" {
  let ctx = Context::background()
  let (open, _) = Span::start_root("open", @core.Time::from_millis(100L), ctx)
  open.add_log(@core.Time::from_millis(110L), LogLevel::Debug, "still running")
  let analysis = analyze_trace([open])
  inspect(analysis.is_valid(), content="true")
  inspect(analysis.summary().open_span_count, content="1")
  inspect(analysis.summary().duration.to_nanos(), content="0")
  match longest_span([open]) {
    None => ()
    Some(_) => fail("open span must not be the longest completed span")
  }
}

///|
test "analysis supports the single trace convenience entry point" {
  let (root, db, cache) = make_analyzed_trace()
  let analysis = analyze_single_trace(root, [db, cache])
  inspect(analysis.summary().span_count, content="3")
  inspect(analysis.summary().event_count, content="2")
}
