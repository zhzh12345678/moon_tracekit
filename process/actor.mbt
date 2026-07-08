///|
/// 离散时间驱动的 Actor 信箱与异步消息模型
/// 支持以确定性的虚拟时间传递和处理消息，适用于分布式一致性与 RPC 模拟
pub(all) struct Actor[Msg] {
  name : String
  sim : @core.Simulator
  mailbox : Array[Msg]
  handler : (ActorContext[Msg], Msg) -> Unit
  mut is_processing : Bool
}

///|
/// Actor 执行上下文
pub(all) struct ActorContext[Msg] {
  name : String
  sim : @core.Simulator
  self_actor : Actor[Msg]
}

///|
/// 创建新的 Actor 实例
pub fn[Msg] Actor::new(
  name : String,
  sim : @core.Simulator,
  handler : (ActorContext[Msg], Msg) -> Unit,
) -> Actor[Msg] {
  { name, sim, mailbox: [], handler, is_processing: false }
}

///|
/// 获取当前时间
pub fn[Msg] ActorContext::now(self : ActorContext[Msg]) -> @core.Time {
  self.sim.now()
}

///|
/// 异步发送消息给 Actor
/// 消息将在下一纳秒或延迟 delay 后到达信箱并处理
pub fn[Msg] Actor::send(
  self : Actor[Msg],
  msg : Msg,
  delay? : @core.Duration = @core.Duration::zero(),
) -> Unit {
  let _ = self.sim.schedule(delay, priority=0, () => {
    self.mailbox.push(msg)
    self.schedule_process()
  })
  ()
}

///|
/// 内部调度信箱处理
fn[Msg] Actor::schedule_process(self : Actor[Msg]) -> Unit {
  if !self.is_processing && !self.mailbox.is_empty() {
    self.is_processing = true
    let _ = self.sim.schedule(@core.Duration::zero(), priority=0, () => {
      self.process_next()
    })
    ()
  }
}

///|
/// 内部处理单条消息
fn[Msg] Actor::process_next(self : Actor[Msg]) -> Unit {
  if !self.mailbox.is_empty() {
    let msg = self.mailbox.remove(0)
    let ctx = { name: self.name, sim: self.sim, self_actor: self }
    (self.handler)(ctx, msg)
  }
  if !self.mailbox.is_empty() {
    let _ = self.sim.schedule(@core.Duration::zero(), priority=0, () => {
      self.process_next()
    })
    ()
  } else {
    self.is_processing = false
  }
}
