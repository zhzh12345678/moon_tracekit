///|
/// 瞬时状态仪表 (Gauge)
/// 记录仿真过程中的瞬时变化指标（如当前信箱深度、活跃进程数、当前网络排队长度等）
pub(all) struct Gauge {
  name : String
  mut value : Double
}

///|
/// 创建新的仪表
pub fn Gauge::new(name : String, init_val~ : Double = 0.0) -> Gauge {
  { name, value: init_val }
}

///|
/// 设置瞬时值
pub fn Gauge::set(self : Gauge, val : Double) -> Unit {
  self.value = val
}

///|
/// 增加数值
pub fn Gauge::add(self : Gauge, delta : Double) -> Unit {
  self.value = self.value + delta
}

///|
/// 减少数值
pub fn Gauge::sub(self : Gauge, delta : Double) -> Unit {
  self.value = self.value - delta
}

///|
/// 获取当前值
pub fn Gauge::get(self : Gauge) -> Double {
  self.value
}
