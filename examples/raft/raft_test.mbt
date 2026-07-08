///|
test "raft leader election and fault tolerance simulation" {
  let sim = @core.Simulator::new(options={
    max_time: @core.Time::from_secs(5L),
    max_events: 10_000L,
    seed: 42UL,
  })
  let net : @net.NetworkTopology[RaftMsg] = @net.NetworkTopology::new(sim)
  let injector = @fault.FaultInjector::new(sim)

  // 建立 3 节点全互联网络，延迟 10ms
  let nodes = ["n1", "n2", "n3"]
  net.add_bidirectional_link("n1", "n2", @core.Duration::from_millis(10L))
  net.add_bidirectional_link("n2", "n3", @core.Duration::from_millis(10L))
  net.add_bidirectional_link("n1", "n3", @core.Duration::from_millis(10L))

  let r1 = RaftNode::new("n1", sim, net)
  let r2 = RaftNode::new("n2", sim, net)
  let r3 = RaftNode::new("n3", sim, net)

  r1.start(nodes)
  r2.start(nodes)
  r3.start(nodes)

  // 1. 验证在 1s 时确定性选出唯一 Leader
  let mut leader_count_at_1s = 0
  let _ = sim.schedule(@core.Duration::from_secs(1L), () => {
    if r1.role == Leader {
      leader_count_at_1s = leader_count_at_1s + 1
    }
    if r2.role == Leader {
      leader_count_at_1s = leader_count_at_1s + 1
    }
    if r3.role == Leader {
      leader_count_at_1s = leader_count_at_1s + 1
    }
  })

  // 2. 在 1.5s 时通过故障注入器在链路 n1->n2 和 n1->n3 上注入 100% 丢包率（模拟 n1 被分区隔离）
  injector.schedule_fault(
    @core.Duration::from_millis(1500L),
    PacketDropSpike("n1", "n2", 1.0),
    @core.Duration::from_millis(2000L),
    net,
  )
  injector.schedule_fault(
    @core.Duration::from_millis(1500L),
    PacketDropSpike("n1", "n3", 1.0),
    @core.Duration::from_millis(2000L),
    net,
  )


  sim.run()
  inspect(leader_count_at_1s, content="1")
}
