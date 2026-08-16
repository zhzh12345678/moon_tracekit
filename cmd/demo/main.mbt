///|
/// MoonTraceKit interactive demo entry point
fn main {
  println("==================================================")
  println("   MoonTraceKit: deterministic tracing toolkit demo")
  println("==================================================\n")

  println("[Demo 1] M/M/1 queue and Little's Law simulation (500 customers)...")
  let sim1 = @core.Simulator::new(options={
    max_time: @core.Time::from_secs(100_000L),
    max_events: 10_000_000L,
    seed: 12345UL,
  })
  let qsim = @queue.QueueSim::new(sim1, 5.0, 10.0)
  qsim.start(500)
  sim1.run()
  println(qsim.get_report())

  println("--------------------------------------------------\n")
  println(
    "[Demo 2] 3-node Raft cluster leader election and split-brain simulation...",
  )
  let sim2 = @core.Simulator::new(options={
    max_time: @core.Time::from_secs(5L),
    max_events: 10_000L,
    seed: 42UL,
  })
  let net : @net.NetworkTopology[@raft.RaftMsg] = @net.NetworkTopology::new(
    sim2,
  )
  let nodes = ["node1", "node2", "node3"]
  net.add_bidirectional_link("node1", "node2", @core.Duration::from_millis(10L))
  net.add_bidirectional_link("node2", "node3", @core.Duration::from_millis(10L))
  net.add_bidirectional_link("node1", "node3", @core.Duration::from_millis(10L))

  let r1 = @raft.RaftNode::new("node1", sim2, net)
  let r2 = @raft.RaftNode::new("node2", sim2, net)
  let r3 = @raft.RaftNode::new("node3", sim2, net)
  r1.start(nodes)
  r2.start(nodes)
  r3.start(nodes)
  sim2.run()
  println(
    "Raft simulation complete. Virtual time: \{sim2.now().to_string()}, total events: \{sim2.event_count()}",
  )
  println("==================================================")

  println(
    "\n[Demo 3] Full-link Tracing (Span, Context, Waterfall, OTel JSONL)...",
  )
  let bg_ctx = @trace.Context::background()
  let t_start = @core.Time::from_millis(100L)
  let (root_span, ctx1) = @trace.Span::start_root(
    "process_request", t_start, bg_ctx,
  )
  root_span.set_attribute("http.method", "GET")
  root_span.set_attribute("http.url", "/api/v1/data")

  let t_db = @core.Time::from_millis(110L)
  let (db_span, _) = @trace.Span::start_child("db_query", t_db, ctx1)
  db_span.set_attribute("db.system", "mysql")
  db_span.add_log(
    @core.Time::from_millis(115L),
    @trace.LogLevel::Info,
    "Executing SELECT * FROM users",
    attributes={ "db.system": "mysql" },
  )
  db_span.end(@core.Time::from_millis(150L))

  let t_cache = @core.Time::from_millis(150L)
  let (cache_span, _) = @trace.Span::start_child("cache_update", t_cache, ctx1)
  cache_span.end(@core.Time::from_millis(160L))

  root_span.end(@core.Time::from_millis(165L))

  let spans = [root_span, db_span, cache_span]
  println(
    @trace.print_waterfall(
      spans,
      @core.Time::from_millis(100L),
      @core.Time::from_millis(170L),
    ),
  )

  println("OTel JSONL Export for the complete trace:")
  println(@trace.export_spans_jsonl(spans))
  println("==================================================")
}
