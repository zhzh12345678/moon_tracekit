///|
/// 确定性混沌模糊测试引擎 (ChaosRunner)
/// 通过对同一仿真场景注入不同的确定性随机种子（如 1..N），验证分布式算法或并发排队在不同时延抖动与重排序场景下的绝对不变性
pub(all) struct ChaosRunner {
  iterations : Int
  mut passed : Int
  mut failed : Int
}

///|
/// 创建新的混沌测试引擎
pub fn ChaosRunner::new(iterations? : Int = 10) -> ChaosRunner {
  { iterations, passed: 0, failed: 0 }
}

///|
/// 运行多种子迭代验证
/// `test_factory`: 接收一个种子 UInt64，构造并返回运行完测试后是否满足不变性的布尔结果
pub fn ChaosRunner::run(
  self : ChaosRunner,
  test_factory : (UInt64) -> Bool,
) -> Bool {
  for i = 1; i <= self.iterations; i = i + 1 {
    let seed = i.to_uint64()
    let ok = test_factory(seed)
    if ok {
      self.passed = self.passed + 1
    } else {
      self.failed = self.failed + 1
    }
  }
  self.failed == 0
}

///|
/// 获取通过次数
pub fn ChaosRunner::passed_count(self : ChaosRunner) -> Int {
  self.passed
}

///|
/// 获取失败次数
pub fn ChaosRunner::failed_count(self : ChaosRunner) -> Int {
  self.failed
}
