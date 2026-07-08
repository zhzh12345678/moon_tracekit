///|
/// 故障类型定义
/// 支持网络分区、节点宕机、时延抖动突增与丢包率突增等分布式常见故障
pub(all) enum FaultType {
  NetworkPartition(Array[String], Array[String]) // 两个节点集合之间的网络隔离
  NodeCrash(String) // 节点宕机
  PacketDropSpike(String, String, Double) // 链路丢包率突增
} derive(Eq, Compare, Debug)

///|
/// 确定性故障注入器 (FaultInjector)
/// 可以在指定的虚拟时间轴上精确调度故障的发生与恢复，用于检验混沌测试下的系统容错与自愈能力
pub(all) struct FaultInjector {
  sim : @core.Simulator
  crashed_nodes : Map[String, Bool]
  partitions : Array[(Array[String], Array[String])]
}

///|
/// 创建新的故障注入器
pub fn FaultInjector::new(sim : @core.Simulator) -> FaultInjector {
  {
    sim,
    crashed_nodes: Map([]),
    partitions: [],
  }
}

///|
/// 检查指定节点是否处于宕机状态
pub fn FaultInjector::is_node_crashed(self : FaultInjector, node : String) -> Bool {
  match self.crashed_nodes.get(node) {
    None => false
    Some(val) => val
  }
}

///|
/// 检查两个节点之间是否存在网络分区隔离
pub fn FaultInjector::is_partitioned(
  self : FaultInjector,
  node_a : String,
  node_b : String
) -> Bool {
  let count = self.partitions.length()
  for i = 0; i < count; i = i + 1 {
    let (g1, g2) = self.partitions[i]
    if (contains(g1, node_a) && contains(g2, node_b)) ||
       (contains(g2, node_a) && contains(g1, node_b)) {
      return true
    }
  }
  false
}

///|
/// 辅助方法：检查数组是否包含元素
fn contains(arr : Array[String], item : String) -> Bool {
  let len = arr.length()
  for i = 0; i < len; i = i + 1 {
    if arr[i] == item {
      return true
    }
  }
  false
}

///|
/// 综合判断：在当前故障态下，从 src 到 dst 的数据包是否应当被丢弃
pub fn FaultInjector::should_drop_packet(
  self : FaultInjector,
  src : String,
  dst : String
) -> Bool {
  if self.is_node_crashed(src) || self.is_node_crashed(dst) {
    return true
  }
  self.is_partitioned(src, dst)
}

///|
/// 在指定虚拟时间调度故障发生，并在持续 duration 后自动恢复
pub fn[T] FaultInjector::schedule_fault(
  self : FaultInjector,
  start_delay : @core.Duration,
  fault : FaultType,
  duration : @core.Duration,
  net : @net.NetworkTopology[T]
) -> Unit {
  // 调度故障开始
  let _ = self.sim.schedule(start_delay, priority=-1, () => {
    match fault {
      NodeCrash(node) => {
        self.crashed_nodes.set(node, true)
      }
      NetworkPartition(g1, g2) => {
        self.partitions.push((g1, g2))
      }
      PacketDropSpike(src, dst, rate) => {
        match net.get_link(src, dst) {
          None => ()
          Some(link) => link.set_loss_rate(rate)
        }
      }
    }
  })

  // 调度故障恢复
  let recover_time = start_delay.add(duration)
  let _ = self.sim.schedule(recover_time, priority=-1, () => {
    match fault {
      NodeCrash(node) => {
        self.crashed_nodes.set(node, false)
      }
      NetworkPartition(g1, g2) => {
        // 移除该分区记录
        let len = self.partitions.length()
        for i = 0; i < len; i = i + 1 {
          let (p1, p2) = self.partitions[i]
          if p1 == g1 && p2 == g2 {
            let _ = self.partitions.remove(i)
            break
          }
        }
      }
      PacketDropSpike(src, dst, _rate) => {
        match net.get_link(src, dst) {
          None => ()
          Some(link) => link.set_loss_rate(0.0)
        }
      }
    }
  })
  ()
}
