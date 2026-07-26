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
  let new_map = {}
  for k, v in self.values {
    new_map.set(k, v)
  }
  new_map.set(key, value)
  { values: new_map }
}

///|
/// 获取上下文中的值
pub fn Context::value(self : Context, key : String) -> String? {
  self.values.get(key)
}
