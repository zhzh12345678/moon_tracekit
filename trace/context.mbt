///|
/// 异步上下文（Context），用于在不同层级和事件之间传播追踪信息
pub(all) struct Context {
  values : Map[String, String]
}

///|
/// 创建空上下文
pub fn Context::background() -> Context {
  { values: {} }
}

///|
/// 派生带有新键值对的上下文
pub fn Context::with_value(
  self : Context,
  key : String,
  value : String,
) -> Context {
  let new_map : Map[String, String] = Map([])
  for k, v in self.values {
    new_map.set(k, v)
  }
  new_map.set(key, value)
  { values: new_map }
}

///|
/// 绑定当前 Span 的 trace/span 标识。
///
/// Context 是不可变快照，适合在异步回调、Actor 消息或模拟事件之间显式
/// 传递；更新子上下文不会修改父上下文。
pub fn Context::with_span(
  self : Context,
  trace_id : String,
  span_id : String,
) -> Context {
  self.with_value("trace_id", trace_id).with_value("span_id", span_id)
}

///|
/// 获取上下文中的值
pub fn Context::value(self : Context, key : String) -> String? {
  self.values.get(key)
}
