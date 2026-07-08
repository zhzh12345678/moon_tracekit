///|
test "link transmission and bandwidth delay" {
  let sim = @core.Simulator::new()
  let link = Link::new(
    "eth0",
    @core.Duration::from_millis(10L),
    bandwidth=1000.0, // 1000 Bytes / sec -> 1 ms per Byte
  )
  let mut delivered_time = ""
  let pkt = Packet::new(1, "A", "B", "hello", sim.now(), size=50) // 50 Bytes -> 50 ms bandwidth delay
  link.transmit(
    pkt,
    sim,
    fn(p) { delivered_time = "\{p.payload}@\{sim.now().to_string()}" },
    fn(_p) { () },
  )
  sim.run()
  // Total delay = 10ms latency + 50ms trans = 60ms
  inspect(delivered_time, content="hello@60ms")
}

///|
test "network topology routing and packet loss" {
  let sim = @core.Simulator::new()
  let net : NetworkTopology[String] = NetworkTopology::new(sim)
  net.add_bidirectional_link("node1", "node2", @core.Duration::from_millis(20L))

  // Send 3 packets
  let _ = net.send_packet(Packet::new(101, "node1", "node2", "msg1", sim.now()))
  let _ = net.send_packet(Packet::new(102, "node1", "node2", "msg2", sim.now()))
  let _ = net.send_packet(
    Packet::new(103, "node1", "node3", "drop_me", sim.now()),
  ) // No link to node3!

  sim.run()
  inspect(net.delivered_count(), content="2")
  inspect(net.dropped_count(), content="1")

  let p1 = net.receive("node2")
  let p2 = net.receive("node2")
  let p3 = net.receive("node2")
  inspect(p1 != None, content="true")
  inspect(p2 != None, content="true")
  inspect(p3 == None, content="true")
}
