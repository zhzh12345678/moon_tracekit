///|
test "m/m/1 queue simulation little's law verification" {
  let sim = @core.Simulator::new(options={
    max_time: @core.Time::from_secs(100_000L),
    max_events: 10_000_000L,
    seed: 12345UL,
  })
  // 到达率 lambda = 5.0 / sec, 服务率 mu = 10.0 / sec (rho = 0.5)
  // 理论平均等待系统时间 W = 1 / (mu - lambda) = 1 / 5 = 0.2s = 200ms
  let qsim = QueueSim::new(sim, 5.0, 10.0)
  qsim.start(500)
  sim.run()

  inspect(qsim.served_counter.get(), content="500")
  let mean_lat = qsim.latency_hist.mean()
  // 均值应在理论值 200ms 附近（考虑随机波动在 100ms ~ 350ms 间）
  inspect(mean_lat >= 100.0 && mean_lat <= 350.0, content="true")
}
