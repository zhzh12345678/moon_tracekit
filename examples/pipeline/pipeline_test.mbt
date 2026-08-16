///|
test "request pipeline covers cache database timeout and trace analysis" {
  let sim = @core.Simulator::new(options={
    max_time: @core.Time::from_secs(10L),
    max_events: 10_000L,
    seed: 20260817UL,
  })
  let report = PipelineScenario::new(sim).run(8)
  inspect(report.requests, content="8")
  inspect(report.successes, content="6")
  inspect(report.timeouts, content="2")
  inspect(report.cache_hits, content="4")
  inspect(report.database_calls, content="4")
  inspect(report.latency.count, content="6")
  inspect(report.trace_analysis.summary().trace_count, content="8")
  inspect(report.trace_analysis.summary().event_count, content="22")
  inspect(report.trace_analysis.summary().error_event_count, content="4")
  inspect(report.is_healthy(), content="true")
  if report.to_string().contains("Issues: none") == false {
    fail("pipeline report contains trace issues")
  }
  if report.to_jsonl().split("\n").length() != report.spans.length() {
    fail("pipeline JSONL does not contain one line per span")
  }
}

///|
test "pipeline is deterministic for the same workload" {
  let options : @core.SimOptions = {
    max_time: @core.Time::from_secs(10L),
    max_events: 10_000L,
    seed: 99UL,
  }
  let first = PipelineScenario::new(@core.Simulator::new(options~)).run(6)
  let second = PipelineScenario::new(@core.Simulator::new(options~)).run(6)
  inspect(first.requests, content="6")
  inspect(first.successes, content="5")
  inspect(first.timeouts, content="1")
  inspect(first.latency.mean, content="15.6")
  inspect(first.to_jsonl(), content=second.to_jsonl())
}

///|
test "empty pipeline produces a valid zero report" {
  let report = PipelineScenario::new(@core.Simulator::new()).run(0)
  inspect(report.requests, content="0")
  inspect(report.successes, content="0")
  inspect(report.timeouts, content="0")
  inspect(report.spans.length(), content="0")
  inspect(report.latency.count, content="0")
  inspect(report.trace_analysis.is_valid(), content="true")
  inspect(report.is_healthy(), content="true")
}
