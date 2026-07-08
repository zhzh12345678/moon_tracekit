///|
/// 确定性互斥锁 (Mutex)
/// 用于模拟多进程对共享资源的竞争与排队，锁的申请与释放严格按照虚拟时间与优先队列确定性调度
pub(all) struct Mutex {
  id : Int
  name : String
  mut is_locked : Bool
  mut owner : @process.ProcessId?
  mgr : @process.ProcessManager
}

///|
/// 创建一个新的互斥锁
pub fn Mutex::new(
  id : Int,
  name : String,
  mgr : @process.ProcessManager,
) -> Mutex {
  { id, name, is_locked: false, owner: None, mgr }
}

///|
/// 尝试获取锁（非阻塞）
/// 成功返回 true，失败返回 false
pub fn Mutex::try_lock(self : Mutex, pid : @process.ProcessId) -> Bool {
  if !self.is_locked {
    self.is_locked = true
    self.owner = Some(pid)
    true
  } else if self.owner == Some(pid) {
    // 可重入
    true
  } else {
    false
  }
}

///|
/// 释放锁
pub fn Mutex::unlock(self : Mutex, pid : @process.ProcessId) -> Bool {
  if self.is_locked && self.owner == Some(pid) {
    self.is_locked = false
    self.owner = None
    let _ = self.mgr.signal_event(self.id)
    true
  } else {
    false
  }
}

///|
/// 协作式等待锁原语
pub fn Mutex::wait_lock(self : Mutex) -> @process.StepResult {
  WaitEvent(self.id)
}

