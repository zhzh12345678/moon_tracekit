///|
/// 虚拟进程唯一标识符
pub type ProcessId = Int

///|
/// 进程生命周期状态
pub(all) enum ProcessState {
  Ready
  Running
  Waiting
  Terminated
} derive(Eq, Compare, Debug)

///|
/// 协作式调度下一步执行结果指令
/// 虚拟进程每次执行完一步后，向调度器返回此指令以控制后续行为
pub(all) enum StepResult {
  Continue // 立即在当前虚拟时间继续执行下一逻辑步
  Sleep(@core.Duration) // 挂起并休眠指定时长后由引擎自动唤醒
  WaitEvent(Int) // 挂起并等待特定事件键（如通道消息到达、网络发包完毕）触发
  Terminate // 进程执行完毕，正常退出
} derive(Eq, Compare, Debug)

///|
/// 虚拟进程上下文
/// 提供给进程回调函数，用于获取当前时间、仿真器实例和发起协作式原语
pub(all) struct ProcessContext {
  pid : ProcessId
  name : String
  sim : @core.Simulator
}

///|
/// 创建进程上下文
pub fn ProcessContext::new(
  pid : ProcessId,
  name : String,
  sim : @core.Simulator,
) -> ProcessContext {
  { pid, name, sim }
}

///|
/// 获取当前进程 ID
pub fn ProcessContext::pid(self : ProcessContext) -> ProcessId {
  self.pid
}

///|
/// 获取当前进程名称
pub fn ProcessContext::name(self : ProcessContext) -> String {
  self.name
}

///|
/// 获取当前虚拟时间
pub fn ProcessContext::now(self : ProcessContext) -> @core.Time {
  self.sim.now()
}

///|
/// 获取底层离散事件仿真器
pub fn ProcessContext::sim(self : ProcessContext) -> @core.Simulator {
  self.sim
}

///|
/// 协作式原语：休眠指定时长
pub fn ProcessContext::sleep(
  self : ProcessContext,
  dur : @core.Duration,
) -> StepResult {
  let _ = self
  Sleep(dur)
}

///|
/// 协作式原语：休眠直至绝对时间点
pub fn ProcessContext::sleep_until(
  self : ProcessContext,
  target : @core.Time,
) -> StepResult {
  let dur = target.sub(self.now())
  if dur.to_nanos() <= 0L {
    Continue
  } else {
    Sleep(dur)
  }
}

///|
/// 协作式原语：主动让出 CPU（在当前时间戳以较低优先级重排队）
pub fn ProcessContext::yield_now(self : ProcessContext) -> StepResult {
  let _ = self
  Continue
}

///|
/// 协作式原语：等待同步事件键
pub fn ProcessContext::wait_for(
  self : ProcessContext,
  event_key : Int,
) -> StepResult {
  let _ = self
  WaitEvent(event_key)
}

///|
/// 协作式原语：终止当前进程
pub fn ProcessContext::terminate(self : ProcessContext) -> StepResult {
  let _ = self
  Terminate
}

///|
/// 虚拟进程模型
pub(all) struct Process {
  id : ProcessId
  name : String
  mut state : ProcessState
  handler : (ProcessContext) -> StepResult
}

///|
/// 创建一个新虚拟进程
pub fn Process::new(
  id : ProcessId,
  name : String,
  handler : (ProcessContext) -> StepResult,
) -> Process {
  { id, name, state: Ready, handler }
}
