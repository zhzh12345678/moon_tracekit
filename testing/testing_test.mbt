///|
test "chaos runner verification across seeds" {
  let runner = ChaosRunner::new(iterations=5)
  let all_ok = runner.run(fn(seed) {
    let sim = @core.Simulator::new(
      options={ max_time: @core.Time::from_secs(10L), max_events: 1000L, seed },
    )
    let mut log_count = 0
    for j = 0; j < 5; j = j + 1 {
      let _ = sim.schedule(@core.Duration::from_millis((j * 10).to_int64()), () => {
        log_count = log_count + 1
      })
    }
    sim.run()
    assert_sim_time(sim, @core.Time::from_millis(40L)) &&
    assert_event_count_at_least(sim, 5L) &&
    log_count == 5
  })
  inspect(all_ok, content="true")
  inspect(runner.passed_count(), content="5")
  inspect(runner.failed_count(), content="0")
}
