///|
/// 遥测计数器 (Counter)
/// 记录仿真过程中的累加指标（如总发包数、重试次数、错误次数等），仅支持单调递增
pub(all) struct Counter {
  name : String
  mut value : Int64
}

///|
/// 创建新的计数器
pub fn Counter::new(name : String) -> Counter {
  { name, value: 0L }
}

///|
/// 增加计数
pub fn Counter::inc(self : Counter, delta~ : Int64 = 1L) -> Unit {
  if delta > 0L {
    self.value = self.value + delta
  }
}

///|
/// 获取当前计数值
pub fn Counter::get(self : Counter) -> Int64 {
  self.value
}
