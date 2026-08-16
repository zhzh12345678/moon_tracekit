///|
/// Histogram 在某一时刻的不可变快照。
///
/// 快照适合把一次实验的结果交给报告、断言或外部导出器，避免调用方在
/// 继续记录样本后读到一半旧数据、一半新数据的状态。
pub(all) struct HistogramSnapshot {
  name : String
  count : Int
  min : Double
  max : Double
  mean : Double
  p50 : Double
  p95 : Double
  p99 : Double
}

///|
/// 生成当前直方图的统计快照。
pub fn Histogram::snapshot(self : Histogram) -> HistogramSnapshot {
  {
    name: self.name,
    count: self.count(),
    min: self.min(),
    max: self.max(),
    mean: self.mean(),
    p50: self.percentile(0.50),
    p95: self.percentile(0.95),
    p99: self.percentile(0.99),
  }
}

///|
/// 生成适合日志和 CLI 的单行统计结果。
pub fn HistogramSnapshot::to_string(self : HistogramSnapshot) -> String {
  "name=\{self.name} count=\{self.count} min=\{self.min} max=\{self.max} " +
  "mean=\{self.mean} p50=\{self.p50} p95=\{self.p95} p99=\{self.p99}"
}

///|
/// 以稳定字段顺序输出简单 JSON 对象。
/// 指标名称沿用现有 JSON 字符串约定；含引号的名称应由上层命名规范拒绝。
pub fn HistogramSnapshot::to_json(self : HistogramSnapshot) -> String {
  "{\"name\":\"" +
  self.name +
  "\",\"count\":" +
  self.count.to_string() +
  ",\"min\":" +
  self.min.to_string() +
  ",\"max\":" +
  self.max.to_string() +
  ",\"mean\":" +
  self.mean.to_string() +
  ",\"p50\":" +
  self.p50.to_string() +
  ",\"p95\":" +
  self.p95.to_string() +
  ",\"p99\":" +
  self.p99.to_string() +
  "}"
}
