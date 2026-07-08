///|
/// M/M/1 排队论仿真系统
/// 模拟泊松到达与指数服务时间的单服务器排队系统，验证利特尔法则 (Little's Law)
pub(all) struct QueueSim {
  sim : @core.Simulator
  mgr : @process.ProcessManager
  server_mutex : @sync.Mutex
  arrival_rate : Double // lambda (到达率)
  service_rate : Double // mu (服务率)
  reg : @metrics.MetricsRegistry
  latency_hist : @metrics.Histogram
  served_counter : @metrics.Counter
}

///|
/// 创建新的排队论仿真
pub fn QueueSim::new(
  sim : @core.Simulator,
  arrival_rate : Double,
  service_rate : Double
) -> QueueSim {
  let mgr = @process.ProcessManager::new(sim)
  let server_mutex = @sync.Mutex::new(9001, "server_lock", mgr)
  let reg = @metrics.MetricsRegistry::new()
  let latency_hist = reg.histogram("customer_latency_ms")
  let served_counter = reg.counter("customers_served")
  {
    sim,
    mgr,
    server_mutex,
    arrival_rate,
    service_rate,
    reg,
    latency_hist,
    served_counter,
  }
}

///|
/// 启动排队论仿真
pub fn QueueSim::start(self : QueueSim, total_customers : Int) -> Unit {
  let mut cust_id = 0
  
  // 客户到达生成器进程
  let mut gen_step = 0
  let _ = self.mgr.spawn("generator", fn(ctx) {
    if cust_id >= total_customers {
      return ctx.terminate()
    }
    if gen_step == 0 {
      gen_step = 1
      // 指数分布到达间隔
      let interval_secs = self.sim.get_rng().next_exponential(self.arrival_rate)
      let interval_ms = (interval_secs * 1000.0).to_int().to_int64()
      return ctx.sleep(@core.Duration::from_millis(interval_ms))
    } else {
      gen_step = 0
      cust_id = cust_id + 1
      self.spawn_customer(cust_id)
      return ctx.yield_now()
    }
  })
  ()
}

///|
/// 内部方法：调度单个客户进程
fn QueueSim::spawn_customer(self : QueueSim, id : Int) -> Unit {
  let arrive_time = self.sim.now()
  let mut step = 0
  let _ = self.mgr.spawn("cust_\{id}", fn(ctx) {
    if step == 0 {
      if self.server_mutex.try_lock(ctx.pid()) {
        step = 1
        // 指数分布服务时间
        let serv_secs = self.sim.get_rng().next_exponential(self.service_rate)
        let serv_ms = (serv_secs * 1000.0).to_int().to_int64() + 1L
        return ctx.sleep(@core.Duration::from_millis(serv_ms))
      } else {
        return self.server_mutex.wait_lock()
      }
    } else {
      let _ = self.server_mutex.unlock(ctx.pid())
      let leave_time = ctx.now()
      let latency_ms = leave_time.sub(arrive_time).to_millis().to_double()
      self.latency_hist.record(latency_ms)
      self.served_counter.inc()
      return ctx.terminate()
    }
  })
  ()
}

///|
/// 获取统计报告
pub fn QueueSim::get_report(self : QueueSim) -> String {
  let mut out = "=== M/M/1 Queue Simulation Results ===\n"
  out = out + "Total Served: \{self.served_counter.get()}\n"
  out = out + "Mean Latency: \{self.latency_hist.mean()} ms\n"
  out = out + "P50 Latency: \{self.latency_hist.percentile(0.50)} ms\n"
  out = out + "P99 Latency: \{self.latency_hist.percentile(0.99)} ms\n"
  out
}
