///|
/// 遥测指标注册表与报告器 (MetricsRegistry)
/// 统一管理所有 Counters, Gauges 和 Histograms，并生成人类可读的统计分析报告
pub(all) struct MetricsRegistry {
  counters : Map[String, Counter]
  gauges : Map[String, Gauge]
  histograms : Map[String, Histogram]
}

///|
/// 创建新的注册表
pub fn MetricsRegistry::new() -> MetricsRegistry {
  {
    counters: Map([]),
    gauges: Map([]),
    histograms: Map([]),
  }
}

///|
/// 注册或获取计数器
pub fn MetricsRegistry::counter(self : MetricsRegistry, name : String) -> Counter {
  match self.counters.get(name) {
    Some(c) => c
    None => {
      let c = Counter::new(name)
      self.counters.set(name, c)
      c
    }
  }
}

///|
/// 注册或获取仪表
pub fn MetricsRegistry::gauge(self : MetricsRegistry, name : String) -> Gauge {
  match self.gauges.get(name) {
    Some(g) => g
    None => {
      let g = Gauge::new(name)
      self.gauges.set(name, g)
      g
    }
  }
}

///|
/// 注册或获取直方图
pub fn MetricsRegistry::histogram(self : MetricsRegistry, name : String) -> Histogram {
  match self.histograms.get(name) {
    Some(h) => h
    None => {
      let h = Histogram::new(name)
      self.histograms.set(name, h)
      h
    }
  }
}

///|
/// 生成当前集群遥测数据的简报字符串
pub fn MetricsRegistry::summary(self : MetricsRegistry) -> String {
  let mut out = "=== Telemetry Report ===\n"
  out = out + "Counters: \{self.counters.length()}\n"
  out = out + "Gauges: \{self.gauges.length()}\n"
  out = out + "Histograms: \{self.histograms.length()}\n"
  out
}
