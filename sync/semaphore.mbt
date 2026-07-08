///|
/// 确定性计数信号量 (Semaphore)
/// 用于限制对有限并发资源池的访问
pub(all) struct Semaphore {
  id : Int
  name : String
  mut permits : Int
  mgr : @process.ProcessManager
}

///|
/// 创建一个新的信号量
pub fn Semaphore::new(
  id : Int,
  name : String,
  permits : Int,
  mgr : @process.ProcessManager,
) -> Semaphore {
  { id, name, permits, mgr }
}

///|
/// 获取当前可用许可数
pub fn Semaphore::available_permits(self : Semaphore) -> Int {
  self.permits
}

///|
/// 尝试获取一个许可（非阻塞）
pub fn Semaphore::try_acquire(self : Semaphore) -> Bool {
  if self.permits > 0 {
    self.permits = self.permits - 1
    true
  } else {
    false
  }
}

///|
/// 释放一个许可
pub fn Semaphore::release(self : Semaphore) -> Unit {
  self.permits = self.permits + 1
  let _ = self.mgr.signal_event(self.id)
  ()
}

///|
/// 协作式等待获取许可原语
pub fn Semaphore::wait_acquire(self : Semaphore) -> @process.StepResult {
  WaitEvent(self.id)
}

