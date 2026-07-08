///|
/// 仿真时间断言
/// 验证仿真器当前时间戳是否严格等于预期时间
pub fn assert_sim_time(sim : @core.Simulator, expected : @core.Time) -> Bool {
  sim.now() == expected
}

///|
/// 仿真事件数量断言
/// 验证仿真器已执行的离散事件数是否不少于最小预期值
pub fn assert_event_count_at_least(
  sim : @core.Simulator,
  min_count : Int64,
) -> Bool {
  sim.event_count() >= min_count
}
