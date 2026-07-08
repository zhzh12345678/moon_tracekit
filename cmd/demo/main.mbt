///|
/// MoonEventSim 交互式演示程序主入口
fn main {
  println("==================================================")
  println("   MoonEventSim: 确定性离散事件仿真框架演示   ")
  println("==================================================\n")

  println("[演示 1] M/M/1 排队论与利特尔法则仿真 (500 客户)...")
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
  println("[演示 2] 3 节点 Raft 集群选主与混沌容错仿真...")
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
    "Raft 集群仿真完成！虚拟总运行耗时: \{sim2.now().to_string()}，执行总离散事件数: \{sim2.event_count()}",
  )
  println("==================================================")
}
