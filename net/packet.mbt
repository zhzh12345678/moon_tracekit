///|
/// 网络数据包结构
/// 在离散事件仿真中，网络通信以数据包为单位在虚拟链路上传输
pub(all) struct Packet[T] {
  id : Int
  src : String
  dst : String
  size : Int // 字节数，用于计算带宽排队延迟
  payload : T
  send_time : @core.Time
} derive(Eq, Compare, Debug)

///|
/// 创建新的数据包
pub fn[T] Packet::new(
  id : Int,
  src : String,
  dst : String,
  payload : T,
  send_time : @core.Time,
  size~ : Int = 64
) -> Packet[T] {
  { id, src, dst, size, payload, send_time }
}
