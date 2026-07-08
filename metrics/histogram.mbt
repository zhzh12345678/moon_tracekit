///|
/// 直方图统计与分位值计算 (Histogram)
/// 用于收集延迟分布、排队耗时等耗时指标，并支持计算平均值、最大值以及 P50, P90, P99 分位值
pub(all) struct Histogram {
  name : String
  samples : Array[Double]
  mut sum : Double
  mut max_val : Double
  mut min_val : Double
}

///|
/// 创建新的直方图
pub fn Histogram::new(name : String) -> Histogram {
  { name, samples: [], sum: 0.0, max_val: 0.0, min_val: 1.0e18 }
}

///|
/// 记录一次采样数据
pub fn Histogram::record(self : Histogram, val : Double) -> Unit {
  self.samples.push(val)
  self.sum = self.sum + val
  if val > self.max_val {
    self.max_val = val
  }
  if val < self.min_val {
    self.min_val = val
  }
}

///|
/// 获取采样总次数
pub fn Histogram::count(self : Histogram) -> Int {
  self.samples.length()
}

///|
/// 获取平均值
pub fn Histogram::mean(self : Histogram) -> Double {
  if self.samples.is_empty() {
    0.0
  } else {
    self.sum / self.samples.length().to_double()
  }
}

///|
/// 获取最大采样值
pub fn Histogram::max(self : Histogram) -> Double {
  if self.samples.is_empty() {
    0.0
  } else {
    self.max_val
  }
}

///|
/// 获取最小采样值
pub fn Histogram::min(self : Histogram) -> Double {
  if self.samples.is_empty() {
    0.0
  } else {
    self.min_val
  }
}

///|
/// 计算百分位数值 (如 p50 -> percentile(0.50), p99 -> percentile(0.99))
pub fn Histogram::percentile(self : Histogram, p : Double) -> Double {
  let n = self.samples.length()
  if n == 0 {
    return 0.0
  }
  let copy = []
  for i = 0; i < n; i = i + 1 {
    copy.push(self.samples[i])
  }
  copy.sort()
  let mut idx = (n.to_double() * p).to_int()
  if idx >= n {
    idx = n - 1
  }
  if idx < 0 {
    idx = 0
  }
  copy[idx]
}
