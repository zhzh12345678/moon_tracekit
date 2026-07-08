///|
/// 多进程同步屏障 (Barrier)
/// 让指定数量的虚拟进程在同一点上等待，直到所有进程都到达后集体唤醒
pub(all) struct Barrier {
  id : Int
  name : String
  parties : Int
  mut arrived : Int
  mgr : @process.ProcessManager
}

///|
/// 创建一个新的同步屏障
pub fn Barrier::new(
  id : Int,
  name : String,
  parties : Int,
  mgr : @process.ProcessManager,
) -> Barrier {
  { id, name, parties, arrived: 0, mgr }
}

///|
/// 进程到达屏障并宣告等待
/// 如果到达数达到 parties，则自动重置并唤醒所有等待进程；返回 true 表示触发了屏障唤醒，false 表示挂起等待
pub fn Barrier::arrive_and_wait(self : Barrier) -> Bool {
  self.arrived = self.arrived + 1
  if self.arrived >= self.parties {
    self.arrived = 0
    let _ = self.mgr.signal_event(self.id)
    true
  } else {
    false
  }
}

///|
/// 协作式屏障等待原语
pub fn Barrier::wait_barrier(self : Barrier) -> @process.StepResult {
  WaitEvent(self.id)
}

