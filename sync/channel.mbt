///|
/// 确定性异步/同步消息通道
/// 支持无界缓冲与容量限制。在离散事件仿真中，通道发送与接收行为严格按照虚拟时间点排序
pub(all) struct Channel[T] {
  id : Int
  name : String
  capacity : Int // capacity <= 0 表示无界缓冲
  buffer : Array[T]
  mgr : @process.ProcessManager
}

///|
/// 创建一个新的通道
pub fn[T] Channel::new(
  id : Int,
  name : String,
  mgr : @process.ProcessManager,
  capacity? : Int = 0,
) -> Channel[T] {
  { id, name, capacity, buffer: [], mgr }
}

///|
/// 获取通道中的消息数
pub fn[T] Channel::length(self : Channel[T]) -> Int {
  self.buffer.length()
}

///|
/// 检查通道是否为空
pub fn[T] Channel::is_empty(self : Channel[T]) -> Bool {
  self.buffer.is_empty()
}

///|
/// 尝试发送消息（非阻塞）
/// 返回 true 表示发送成功；返回 false 表示通道已满
pub fn[T] Channel::try_send(self : Channel[T], val : T) -> Bool {
  if self.capacity > 0 && self.buffer.length() >= self.capacity {
    false
  } else {
    self.buffer.push(val)
    let _ = self.mgr.signal_event(self.id)
    true
  }
}

///|
/// 尝试接收消息（非阻塞）
pub fn[T] Channel::try_recv(self : Channel[T]) -> T? {
  if self.buffer.is_empty() {
    None
  } else {
    let val = self.buffer.remove(0)
    let _ = self.mgr.signal_event(self.id + 1000000) // 唤醒可能因写满而等待的发送者
    Some(val)
  }
}

///|
/// 协作式接收原语：如果通道有数据则直接获取；如果没有则挂起当前进程等待消息
/// 使用示例：
/// if let Some(val) = chan.try_recv() { ... } else { return chan.wait_recv() }
pub fn[T] Channel::wait_recv(self : Channel[T]) -> @process.StepResult {
  WaitEvent(self.id)
}

///|
/// 协作式发送等待原语：如果通道满则等待
pub fn[T] Channel::wait_send(self : Channel[T]) -> @process.StepResult {
  WaitEvent(self.id + 1000000)
}
