///|
test "fault injector node crash and network partition" {
  let sim = @core.Simulator::new()
  let net : @net.NetworkTopology[String] = @net.NetworkTopology::new(sim)
  let injector = FaultInjector::new(sim)

  // Inject a node crash on node B from 100ms to 300ms
  injector.schedule_fault(
    @core.Duration::from_millis(100L),
    NodeCrash("B"),
    @core.Duration::from_millis(200L),
    net,
  )

  // Inject a partition between [A] and [C] from 200ms to 400ms
  injector.schedule_fault(
    @core.Duration::from_millis(200L),
    NetworkPartition(["A"], ["C"]),
    @core.Duration::from_millis(200L),
    net,
  )

  let mut log = ""
  // Check at 50ms: all normal
  let _ = sim.schedule(@core.Duration::from_millis(50L), () => {
    log = log +
      "50ms:B_crashed=\{injector.is_node_crashed("B")},AC_part=\{injector.is_partitioned("A", "C")};"
  })

  // Check at 150ms: B crashed, AC normal
  let _ = sim.schedule(@core.Duration::from_millis(150L), () => {
    log = log +
      "150ms:B_crashed=\{injector.is_node_crashed("B")},AC_part=\{injector.is_partitioned("A", "C")};"
  })

  // Check at 250ms: B crashed, AC partitioned
  let _ = sim.schedule(@core.Duration::from_millis(250L), () => {
    log = log +
      "250ms:B_crashed=\{injector.is_node_crashed("B")},AC_part=\{injector.is_partitioned("A", "C")};"
  })

  // Check at 350ms: B recovered, AC partitioned
  let _ = sim.schedule(@core.Duration::from_millis(350L), () => {
    log = log +
      "350ms:B_crashed=\{injector.is_node_crashed("B")},AC_part=\{injector.is_partitioned("A", "C")};"
  })

  // Check at 450ms: all recovered
  let _ = sim.schedule(@core.Duration::from_millis(450L), () => {
    log = log +
      "450ms:B_crashed=\{injector.is_node_crashed("B")},AC_part=\{injector.is_partitioned("A", "C")};"
  })

  sim.run()
  inspect(
    log,
    content="50ms:B_crashed=false,AC_part=false;150ms:B_crashed=true,AC_part=false;250ms:B_crashed=true,AC_part=true;350ms:B_crashed=false,AC_part=true;450ms:B_crashed=false,AC_part=false;",
  )
}
