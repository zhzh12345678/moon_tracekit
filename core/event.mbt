///|
/// 事件唯一标识符
pub type EventId = Int

///|
/// 离散事件模型
/// `id`: 事件唯一 ID
/// `time`: 触发的虚拟时间戳
/// `priority`: 优先级（当多个事件在同一纳秒触发时，优先级高的先执行；若优先级相同，ID 小的先执行，确保确定性）
/// `handler`: 事件执行函数
pub(all) struct Event {
  id : EventId
  time : Time
  priority : Int
  handler : () -> Unit
}

///|
/// 为优先队列实现比较规则
/// 最小堆规则：执行时间越早越优先；时间相同看优先级（数字越小越优先）；都相同看 ID
pub impl Compare for Event with compare(self : Event, other : Event) -> Int {
  let time_cmp = self.time.compare(other.time)
  if time_cmp != 0 {
    return time_cmp
  }
  let prio_cmp = self.priority.compare(other.priority)
  if prio_cmp != 0 {
    return prio_cmp
  }
  self.id.compare(other.id)
}

///|
/// 判断两个事件是否相等
pub impl Eq for Event with equal(self : Event, other : Event) -> Bool {
  self.id == other.id && self.time == other.time && self.priority == other.priority
}

///|
/// 创建一个新的事件
pub fn Event::new(
  id : EventId,
  time : Time,
  priority~ : Int = 0,
  handler : () -> Unit
) -> Event {
  { id, time, priority, handler }
}
