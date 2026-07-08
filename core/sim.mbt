///|
/// 仿真引擎配置项
pub(all) struct SimOptions {
  max_time : Time
  max_events : Int64
  seed : UInt64
}

///|
/// 默认配置：仿真最大时间 100,000 秒，最大事件数 10 亿次，默认种子 42
pub fn SimOptions::default() -> SimOptions {
  { max_time: Time::from_secs(100_000L), max_events: 1000_000_000L, seed: 42UL }
}

///|
/// 离散事件仿真引擎核心
/// 管理虚拟时间轴、优先队列、确定性随机数与事件循环
pub(all) struct Simulator {
  mut current_time : Time
  mut next_event_id : Int
  mut event_count : Int64
  mut is_running : Bool
  options : SimOptions
  queue : PriorityQueue[Event]
  mut rng : PCG32
}

///|
/// 创建一个新的离散事件仿真器
pub fn Simulator::new(
  options? : SimOptions = SimOptions::default(),
) -> Simulator {
  {
    current_time: Time::zero(),
    next_event_id: 1,
    event_count: 0L,
    is_running: false,
    options,
    queue: PriorityQueue::new(),
    rng: PCG32::new(options.seed, 1UL),
  }
}

///|
/// 获取当前虚拟时间
pub fn Simulator::now(self : Simulator) -> Time {
  self.current_time
}

///|
/// 获取当前已执行的事件总数
pub fn Simulator::event_count(self : Simulator) -> Int64 {
  self.event_count
}

///|
/// 获取仿真引擎内置的确定性随机数生成器
pub fn Simulator::get_rng(self : Simulator) -> PCG32 {
  self.rng
}

///|
/// 判断仿真引擎是否正在运行中
pub fn Simulator::is_running(self : Simulator) -> Bool {
  self.is_running
}

///|
/// 在当前时间的基础上延迟 delay 时间调度一个事件
/// `priority`: 优先级，默认 0。越小越优先执行
pub fn Simulator::schedule(
  self : Simulator,
  delay : Duration,
  priority? : Int = 0,
  handler : () -> Unit,
) -> EventId {
  let target_time = self.current_time.add(delay)
  self.schedule_at(target_time, priority~, handler)
}

///|
/// 在绝对虚拟时间 target_time 调度一个事件
pub fn Simulator::schedule_at(
  self : Simulator,
  target_time : Time,
  priority? : Int = 0,
  handler : () -> Unit,
) -> EventId {
  let id = self.next_event_id
  self.next_event_id = self.next_event_id + 1
  let event = Event::new(id, target_time, priority~, handler)
  self.queue.push(event)
  id
}

///|
/// 单步执行一个事件
/// 返回 true 表示成功执行了一个事件；返回 false 表示队列已空或达到结束条件
pub fn Simulator::step(self : Simulator) -> Bool {
  if !self.is_running {
    return false
  }
  if self.event_count >= self.options.max_events {
    self.is_running = false
    return false
  }
  match self.queue.pop() {
    None => {
      self.is_running = false
      false
    }
    Some(event) => {
      if event.time.compare(self.options.max_time) > 0 {
        self.is_running = false
        return false
      }
      self.current_time = event.time
      self.event_count = self.event_count + 1L
      (event.handler)()
      true
    }
  }
}

///|
/// 启动并持续运行仿真，直到事件队列为空、达到最大时间或最大事件限制
pub fn Simulator::run(self : Simulator) -> Unit {
  self.is_running = true
  while self.is_running {
    let stepped = self.step()
    if !stepped {
      break
    }
  }
  self.is_running = false
}

///|
/// 运行仿真直到指定的虚拟时间点 target_time
pub fn Simulator::run_until(self : Simulator, target_time : Time) -> Unit {
  self.is_running = true
  while self.is_running {
    match self.queue.peek() {
      None => {
        self.is_running = false
        break
      }
      Some(event) => {
        if event.time.compare(target_time) > 0 {
          self.current_time = target_time
          break
        }
        let stepped = self.step()
        if !stepped {
          break
        }
      }
    }
  }
}

///|
/// 停止仿真运行
pub fn Simulator::stop(self : Simulator) -> Unit {
  self.is_running = false
}

///|
/// 重置仿真器状态
pub fn Simulator::reset(self : Simulator) -> Unit {
  self.current_time = Time::zero()
  self.next_event_id = 1
  self.event_count = 0L
  self.is_running = false
  self.queue.clear()
  self.rng = PCG32::new(self.options.seed, 1UL)
}
