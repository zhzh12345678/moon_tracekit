///|
/// 网络链路模拟 (Link)
/// 模拟物理/虚拟链路的光速传播时延、带宽限制、随机时延抖动以及基于确定性随机数的丢包率
pub(all) struct Link {
  name : String
  latency : @core.Duration // 基础传播时延
  bandwidth : Double // 带宽 (Bytes/sec)，小于等于0表示无限带宽
  mut loss_rate : Double // 丢包率 (0.0 ~ 1.0)
  jitter : @core.Duration // 时延抖动上限
}

///|
/// 创建新的网络链路
pub fn Link::new(
  name : String,
  latency : @core.Duration,
  bandwidth~ : Double = 0.0,
  loss_rate~ : Double = 0.0,
  jitter~ : @core.Duration = @core.Duration::zero()
) -> Link {
  { name, latency, bandwidth, loss_rate, jitter }
}

///|
/// 设置当前链路丢包率（可用于故障注入）
pub fn Link::set_loss_rate(self : Link, rate : Double) -> Unit {
  self.loss_rate = rate
}

///|
/// 在链路上模拟传输数据包
/// 结合确定性随机数生成器进行丢包判断和抖动计算，按虚拟时间调度到达事件
pub fn[T] Link::transmit(
  self : Link,
  packet : Packet[T],
  sim : @core.Simulator,
  on_receive : (Packet[T]) -> Unit,
  on_drop : (Packet[T]) -> Unit
) -> Unit {
  // 1. 确定性丢包检测
  if self.loss_rate > 0.0 {
    let roll = sim.get_rng().next_float()
    if roll < self.loss_rate {
      on_drop(packet)
      return
    }
  }

  // 2. 带宽传输时延计算 (size / bandwidth)
  let mut trans_millis = 0L
  if self.bandwidth > 0.0 && packet.size > 0 {
    let secs = packet.size.to_double() / self.bandwidth
    trans_millis = (secs * 1000.0).to_int().to_int64()
  }
  let trans_delay = @core.Duration::from_millis(trans_millis)

  // 3. 确定性时延抖动计算
  let mut jitter_delay = @core.Duration::zero()
  if self.jitter.to_nanos() > 0L {
    let max_jitter_ms = self.jitter.to_millis()
    if max_jitter_ms > 0L {
      let rand_ms = sim.get_rng().next_uint().to_int64() % (max_jitter_ms + 1L)
      jitter_delay = @core.Duration::from_millis(rand_ms)
    }
  }

  // Total Delay
  let total_delay = self.latency.add(trans_delay).add(jitter_delay)
  let _ = sim.schedule(total_delay, priority=0, () => {
    on_receive(packet)
  })
  ()
}
