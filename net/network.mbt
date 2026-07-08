///|
/// 网络拓扑路由管理器 (NetworkTopology)
/// 维护仿真集群节点间的连接关系，并路由发送数据包
pub(all) struct NetworkTopology[T] {
  sim : @core.Simulator
  links : Map[String, Link] // Key: "src->dst"
  inboxes : Map[String, Array[Packet[T]]] // Key: dst_node
  mut dropped_count : Int
  mut delivered_count : Int
}

///|
/// 创建新的网络拓扑
pub fn[T] NetworkTopology::new(sim : @core.Simulator) -> NetworkTopology[T] {
  {
    sim,
    links: Map([]),
    inboxes: Map([]),
    dropped_count: 0,
    delivered_count: 0,
  }
}

///|
/// 添加单向网络链路
pub fn[T] NetworkTopology::add_link(
  self : NetworkTopology[T],
  src : String,
  dst : String,
  link : Link,
) -> Unit {
  self.links.set("\{src}->\{dst}", link)
  match self.inboxes.get(dst) {
    None => self.inboxes.set(dst, [])
    Some(_) => ()
  }
}

///|
/// 添加双向对称网络链路
pub fn[T] NetworkTopology::add_bidirectional_link(
  self : NetworkTopology[T],
  node_a : String,
  node_b : String,
  latency : @core.Duration,
  bandwidth? : Double = 0.0,
  loss_rate? : Double = 0.0,
) -> Unit {
  let link_a = Link::new(
    "\{node_a}->\{node_b}",
    latency,
    bandwidth~,
    loss_rate~,
  )
  let link_b = Link::new(
    "\{node_b}->\{node_a}",
    latency,
    bandwidth~,
    loss_rate~,
  )
  self.add_link(node_a, node_b, link_a)
  self.add_link(node_b, node_a, link_b)
}

///|
/// 查询链路对象（可用于实时修改丢包率或延迟进行故障注入）
pub fn[T] NetworkTopology::get_link(
  self : NetworkTopology[T],
  src : String,
  dst : String,
) -> Link? {
  self.links.get("\{src}->\{dst}")
}

///|
/// 发送数据包
/// 如果源和目的节点存在链路，则在链路上模拟传输；否则丢弃并计数
pub fn[T] NetworkTopology::send_packet(
  self : NetworkTopology[T],
  packet : Packet[T],
) -> Bool {
  let key = "\{packet.src}->\{packet.dst}"
  match self.links.get(key) {
    None => {
      self.dropped_count = self.dropped_count + 1
      false
    }
    Some(link) => {
      link.transmit(
        packet,
        self.sim,
        fn(pkt) {
          self.delivered_count = self.delivered_count + 1
          match self.inboxes.get(pkt.dst) {
            None => self.inboxes.set(pkt.dst, [pkt])
            Some(arr) => arr.push(pkt)
          }
        },
        fn(_pkt) { self.dropped_count = self.dropped_count + 1 },
      )
      true
    }
  }
}

///|
/// 从指定节点信箱接收已到达的数据包（非阻塞获取）
pub fn[T] NetworkTopology::receive(
  self : NetworkTopology[T],
  node : String,
) -> Packet[T]? {
  match self.inboxes.get(node) {
    None => None
    Some(arr) => if arr.is_empty() { None } else { Some(arr.remove(0)) }
  }
}

///|
/// 获取已投递的数据包总数
pub fn[T] NetworkTopology::delivered_count(self : NetworkTopology[T]) -> Int {
  self.delivered_count
}

///|
/// 获取已丢弃的数据包总数
pub fn[T] NetworkTopology::dropped_count(self : NetworkTopology[T]) -> Int {
  self.dropped_count
}
