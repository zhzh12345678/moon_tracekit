///|
/// 虚拟进程调度与管理器
/// 统一管理所有协作式协程进程的生命周期、睡眠唤醒机制与事件通知映射
pub(all) struct ProcessManager {
  sim : @core.Simulator
  mut next_pid : Int
  processes : Map[ProcessId, Process]
  waiting_map : Map[Int, Array[ProcessId]]
}

///|
/// 创建一个新的进程管理器
pub fn ProcessManager::new(sim : @core.Simulator) -> ProcessManager {
  { sim, next_pid: 1, processes: Map([]), waiting_map: Map([]) }
}

///|
/// 获取底层仿真器
pub fn ProcessManager::sim(self : ProcessManager) -> @core.Simulator {
  self.sim
}

///|
/// 获取已注册的进程总数
pub fn ProcessManager::process_count(self : ProcessManager) -> Int {
  self.processes.length()
}

///|
/// 根据 ID 查询进程状态
pub fn ProcessManager::get_state(
  self : ProcessManager,
  pid : ProcessId,
) -> ProcessState? {
  match self.processes.get(pid) {
    None => None
    Some(p) => Some(p.state)
  }
}

///|
/// 创建并注册一个新的协作式虚拟进程
/// 返回进程 ID，并在仿真引擎中立即调度初始步
pub fn ProcessManager::spawn(
  self : ProcessManager,
  name : String,
  handler : (ProcessContext) -> StepResult,
) -> ProcessId {
  let pid = self.next_pid
  self.next_pid = self.next_pid + 1
  let proc = Process::new(pid, name, handler)
  self.processes.set(pid, proc)
  // 在当前时间戳立刻调度初始执行
  let _ = self.sim.schedule(@core.Duration::zero(), priority=0, () => {
    self.step_process(pid)
  })
  pid
}

///|
/// 内部方法：执行进程的单步状态机
fn ProcessManager::step_process(self : ProcessManager, pid : ProcessId) -> Unit {
  match self.processes.get(pid) {
    None => ()
    Some(proc) => {
      if proc.state == Terminated {
        return
      }
      proc.state = Running
      let ctx = ProcessContext::new(proc.id, proc.name, self.sim)
      let res = (proc.handler)(ctx)
      match res {
        Continue => {
          proc.state = Ready
          // 优先级设为 1，让出优先级 0 的高优事件
          let _ = self.sim.schedule(@core.Duration::zero(), priority=1, () => {
            self.step_process(pid)
          })
          ()
        }
        Sleep(dur) => {
          proc.state = Waiting
          let _ = self.sim.schedule(dur, priority=0, () => {
            // 休眠结束唤醒
            if proc.state == Waiting {
              proc.state = Ready
              self.step_process(pid)
            }
          })
          ()
        }
        WaitEvent(event_key) => {
          proc.state = Waiting
          match self.waiting_map.get(event_key) {
            None => self.waiting_map.set(event_key, [pid])
            Some(list) => list.push(pid)
          }
          ()
        }
        Terminate => {
          proc.state = Terminated
          ()
        }
      }
    }
  }
}

///|
/// 触发同步事件键，唤醒所有在 event_key 上等待的虚拟进程
pub fn ProcessManager::signal_event(
  self : ProcessManager,
  event_key : Int,
) -> Int {
  match self.waiting_map.get(event_key) {
    None => 0
    Some(list) => {
      let count = list.length()
      for i = 0; i < count; i = i + 1 {
        let pid = list[i]
        match self.processes.get(pid) {
          None => ()
          Some(proc) =>
            if proc.state == Waiting {
              proc.state = Ready
              let _ = self.sim.schedule(@core.Duration::zero(), priority=0, () => {
                self.step_process(pid)
              })
              ()
            }
        }
      }
      self.waiting_map.remove(event_key)
      count
    }
  }
}

///|
/// 终止并清理指定进程
pub fn ProcessManager::kill(self : ProcessManager, pid : ProcessId) -> Bool {
  match self.processes.get(pid) {
    None => false
    Some(proc) => {
      proc.state = Terminated
      true
    }
  }
}
