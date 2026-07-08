///|
/// 虚拟时间（以纳秒为单位的绝对时间戳）
pub(all) struct Time {
  nanos : Int64
} derive(Eq, Compare, Debug)

///|
/// 时间间隔（以纳秒为单位的时长）
pub(all) struct Duration {
  nanos : Int64
} derive(Eq, Compare, Debug)

///|
/// 创建零时间点
pub fn Time::zero() -> Time {
  { nanos: 0L }
}

///|
/// 从纳秒创建时间点
pub fn Time::from_nanos(nanos : Int64) -> Time {
  { nanos, }
}

///|
/// 从微秒创建时间点
pub fn Time::from_micros(micros : Int64) -> Time {
  { nanos: micros * 1000L }
}

///|
/// 从毫秒创建时间点
pub fn Time::from_millis(millis : Int64) -> Time {
  { nanos: millis * 1000_000L }
}

///|
/// 从秒创建时间点
pub fn Time::from_secs(secs : Int64) -> Time {
  { nanos: secs * 1000_000_000L }
}

///|
/// 获取纳秒数值
pub fn Time::to_nanos(self : Time) -> Int64 {
  self.nanos
}

///|
/// 获取毫秒数值
pub fn Time::to_millis(self : Time) -> Int64 {
  self.nanos / 1000_000L
}

///|
/// 获取秒数值
pub fn Time::to_secs(self : Time) -> Int64 {
  self.nanos / 1000_000_000L
}

///|
/// 转换为毫秒浮点数（方便监控与日志显示）
pub fn Time::to_millis_double(self : Time) -> Double {
  self.nanos.to_double() / 1000_000.0
}

///|
/// 转换为秒浮点数
pub fn Time::to_secs_double(self : Time) -> Double {
  self.nanos.to_double() / 1000_000_000.0
}

///|
/// 创建零时长
pub fn Duration::zero() -> Duration {
  { nanos: 0L }
}

///|
/// 从纳秒创建时长
pub fn Duration::from_nanos(nanos : Int64) -> Duration {
  { nanos, }
}

///|
/// 从微秒创建时长
pub fn Duration::from_micros(micros : Int64) -> Duration {
  { nanos: micros * 1000L }
}

///|
/// 从毫秒创建时长
pub fn Duration::from_millis(millis : Int64) -> Duration {
  { nanos: millis * 1000_000L }
}

///|
/// 从秒创建时长
pub fn Duration::from_secs(secs : Int64) -> Duration {
  { nanos: secs * 1000_000_000L }
}

///|
/// 从浮点秒创建时长
pub fn Duration::from_secs_double(secs : Double) -> Duration {
  { nanos: (secs * 1000_000_000.0).to_int64() }
}

///|
/// 获取时长的纳秒数值
pub fn Duration::to_nanos(self : Duration) -> Int64 {
  self.nanos
}

///|
/// 获取时长的毫秒数值
pub fn Duration::to_millis(self : Duration) -> Int64 {
  self.nanos / 1000_000L
}

///|
/// 获取时长的秒数值
pub fn Duration::to_secs(self : Duration) -> Int64 {
  self.nanos / 1000_000_000L
}

///|
/// 转换为毫秒浮点数
pub fn Duration::to_millis_double(self : Duration) -> Double {
  self.nanos.to_double() / 1000_000.0
}

///|
/// 转换为秒浮点数
pub fn Duration::to_secs_double(self : Duration) -> Double {
  self.nanos.to_double() / 1000_000_000.0
}

///|
/// 时间点加时长
pub fn Time::add(self : Time, dur : Duration) -> Time {
  { nanos: self.nanos + dur.nanos }
}

///|
/// 时间点减时长
pub fn Time::sub_duration(self : Time, dur : Duration) -> Time {
  { nanos: self.nanos - dur.nanos }
}

///|
/// 两个时间点相减得到时长
pub fn Time::sub(self : Time, other : Time) -> Duration {
  { nanos: self.nanos - other.nanos }
}

///|
/// 时长相加
pub fn Duration::add(self : Duration, other : Duration) -> Duration {
  { nanos: self.nanos + other.nanos }
}

///|
/// 时长相减
pub fn Duration::sub(self : Duration, other : Duration) -> Duration {
  { nanos: self.nanos - other.nanos }
}

///|
/// 时长乘以标量
pub fn Duration::mul(self : Duration, factor : Int64) -> Duration {
  { nanos: self.nanos * factor }
}

///|
/// 时长乘以浮点标量
pub fn Duration::mul_double(self : Duration, factor : Double) -> Duration {
  { nanos: (self.nanos.to_double() * factor).to_int64() }
}

///|
/// 判断是否为零时长
pub fn Duration::is_zero(self : Duration) -> Bool {
  self.nanos == 0L
}

///|
/// 格式化时间为容易阅读的字符串
pub fn Time::to_string(self : Time) -> String {
  if self.nanos < 1000L {
    "\{self.nanos}ns"
  } else if self.nanos < 1000_000L {
    let micros = self.nanos.to_double() / 1000.0
    "\{micros}us"
  } else if self.nanos < 1000_000_000L {
    let millis = self.nanos.to_double() / 1000_000.0
    "\{millis}ms"
  } else {
    let secs = self.nanos.to_double() / 1000_000_000.0
    "\{secs}s"
  }
}

///|
/// 格式化时长为容易阅读的字符串
pub fn Duration::to_string(self : Duration) -> String {
  if self.nanos < 1000L {
    "\{self.nanos}ns"
  } else if self.nanos < 1000_000L {
    let micros = self.nanos.to_double() / 1000.0
    "\{micros}us"
  } else if self.nanos < 1000_000_000L {
    let millis = self.nanos.to_double() / 1000_000.0
    "\{millis}ms"
  } else {
    let secs = self.nanos.to_double() / 1000_000_000.0
    "\{secs}s"
  }
}
