///|
/// 确定性伪随机数生成器（PCG32 - Permuted Congruential Generator）
/// 在离散事件仿真中，必须使用确定性的种子随机数生成器，确保网络延迟抖动、
/// 丢包率、重试间隔和排队到达时间在每次运行中完全一致，实现 100% 可复现调试。
pub(all) struct PCG32 {
  mut state : UInt64
  mut inc : UInt64
}

///|
/// 默认初始化序列乘数
const PCG_DEFAULT_MULTIPLIER : UInt64 = 6364136223846793005UL

///|
/// 创建一个新的确定性随机数生成器
/// `seed`: 初始种子
/// `seq`: 序列号（选择不同的流）
pub fn PCG32::new(seed : UInt64, seq : UInt64) -> PCG32 {
  let rng = { state: 0UL, inc: (seq << 1) | 1UL }
  rng.state = rng.state + rng.inc
  rng.step()
  rng.state = rng.state + seed
  rng.step()
  rng
}

///|
/// 内部步进函数
fn PCG32::step(self : PCG32) -> Unit {
  self.state = self.state * PCG_DEFAULT_MULTIPLIER + self.inc
}

///|
/// 生成下一个 32 位无符号整数
pub fn PCG32::next_uint(self : PCG32) -> UInt {
  let oldstate = self.state
  self.step()
  // XSH RR (xorshift high, random rotate)
  let xorshifted = (((oldstate >> 18) ^ oldstate) >> 27).to_uint()
  let rot = (oldstate >> 59).to_uint()
  (xorshifted >> rot.reinterpret_as_int()) | (xorshifted << ((rot ^ 31U) + 1U).reinterpret_as_int())
}

///|
/// 生成下一个正整数
pub fn PCG32::next_int(self : PCG32) -> Int {
  let u = self.next_uint()
  let val = u.reinterpret_as_int()
  if val < 0 {
    -val
  } else {
    val
  }
}

///|
/// 生成 [0.0, 1.0) 范围内的均匀分布浮点数
pub fn PCG32::next_float(self : PCG32) -> Double {
  // 取 32 位随机数除以 2^32
  let u = self.next_uint()
  u.to_double() / 4294967296.0
}

///|
/// 生成 [min, max] 范围内的随机整数
pub fn PCG32::next_int_range(self : PCG32, min : Int, max : Int) -> Int {
  if min >= max {
    return min
  }
  let span = max - min + 1
  min + (self.next_int() % span)
}

///|
/// 生成 [min, max) 范围内的浮点数
pub fn PCG32::next_float_range(self : PCG32, min : Double, max : Double) -> Double {
  if min >= max {
    return min
  }
  min + self.next_float() * (max - min)
}

///|
/// 以给定概率 prob (0.0 ~ 1.0) 返回 true
/// 用于模拟网络丢包、故障发生率等
pub fn PCG32::next_bool(self : PCG32, prob : Double) -> Bool {
  if prob <= 0.0 {
    false
  } else if prob >= 1.0 {
    true
  } else {
    self.next_float() < prob
  }
}

///|
/// 指数分布采样（Exponential Distribution）
/// `rate`: λ (到达率或服务率)
/// 使用逆变换采样法：-ln(1 - u) / λ
/// 排队论仿真（M/M/1 队列）中请求到达时间间隔和服务时间的核心生成算法
pub fn PCG32::next_exponential(self : PCG32, rate : Double) -> Double {
  if rate <= 0.0 {
    return 0.0
  }
  let mut u = self.next_float()
  // 避免对 0 取对数
  if u == 0.0 {
    u = 0.0000001
  }
  let ln_val = log_double(u)
  -(ln_val) / rate
}

///|
/// 正态分布（高斯分布）采样（Normal Distribution）
/// `mean`: 均值 μ
/// `std_dev`: 标准差 σ
/// 使用 Box-Muller 变换，用于模拟网络延迟的真实高斯抖动
pub fn PCG32::next_normal(self : PCG32, mean : Double, std_dev : Double) -> Double {
  if std_dev <= 0.0 {
    return mean
  }
  let mut u1 = self.next_float()
  let u2 = self.next_float()
  if u1 <= 1.0e-10 {
    u1 = 1.0e-10
  }
  let r = sqrt_double(-2.0 * log_double(u1))
  let theta = 2.0 * 3.141592653589793 * u2
  let z0 = r * cos_double(theta)
  mean + z0 * std_dev
}

///|
/// 简易自然对数实现 (泰勒展开/连分式辅助，满足仿真精度要求)
fn log_double(x : Double) -> Double {
  if x <= 0.0 {
    return -20.0
  }
  let mut val = x
  let mut k = 0.0
  while val > 2.0 {
    val = val / 2.718281828459045
    k = k + 1.0
  }
  while val < 0.5 {
    val = val * 2.718281828459045
    k = k - 1.0
  }
  let y = (val - 1.0) / (val + 1.0)
  let y2 = y * y
  let mut sum = y
  let mut term = y
  for i = 3; i <= 15; i = i + 2 {
    term = term * y2
    sum = sum + term / i.to_double()
  }
  2.0 * sum + k
}

///|
/// 简易平方根实现 (牛顿迭代法)
fn sqrt_double(x : Double) -> Double {
  if x <= 0.0 {
    return 0.0
  }
  let mut guess = x
  if guess > 1.0 {
    guess = guess / 2.0
  }
  for i = 0; i < 10; i = i + 1 {
    guess = 0.5 * (guess + x / guess)
  }
  guess
}

///|
/// 简易余弦函数实现 (泰勒展开)
fn cos_double(x : Double) -> Double {
  let pi = 3.141592653589793
  let mut val = x
  while val > pi {
    val = val - 2.0 * pi
  }
  while val < -pi {
    val = val + 2.0 * pi
  }
  let x2 = val * val
  let mut sum = 1.0
  let mut term = 1.0
  let mut sign = -1.0
  let mut fact = 2.0
  for i = 2; i <= 12; i = i + 2 {
    term = term * x2 / (fact * (fact - 1.0))
    sum = sum + sign * term
    sign = -sign
    fact = fact + 2.0
  }
  sum
}
