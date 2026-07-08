///|
/// 基于二叉堆（最小堆）的高性能优先队列
/// 适用于保存离散仿真事件，确保最先到期的事件能够以 O(1) 查得、O(log N) 取出
pub(all) struct PriorityQueue[T] {
  items : Array[T]
}

///|
/// 创建一个新的优先队列
pub fn[T] PriorityQueue::new() -> PriorityQueue[T] {
  { items: [] }
}

///|
/// 获取队列元素数量
pub fn[T] PriorityQueue::length(self : PriorityQueue[T]) -> Int {
  self.items.length()
}

///|
/// 判断队列是否为空
pub fn[T] PriorityQueue::is_empty(self : PriorityQueue[T]) -> Bool {
  self.items.is_empty()
}

///|
/// 清空优先队列
pub fn[T] PriorityQueue::clear(self : PriorityQueue[T]) -> Unit {
  self.items.clear()
}

///|
/// 向优先队列插入元素
pub fn[T : Compare] PriorityQueue::push(self : PriorityQueue[T], item : T) -> Unit {
  self.items.push(item)
  self.sift_up(self.items.length() - 1)
}

///|
/// 查看队首元素（最小元素）
pub fn[T] PriorityQueue::peek(self : PriorityQueue[T]) -> T? {
  if self.items.is_empty() {
    None
  } else {
    Some(self.items[0])
  }
}

///|
/// 弹出队首元素
pub fn[T : Compare] PriorityQueue::pop(self : PriorityQueue[T]) -> T? {
  if self.items.is_empty() {
    return None
  }
  let len = self.items.length()
  if len == 1 {
    return self.items.pop()
  }
  let top = self.items[0]
  let last = self.items.pop().unwrap()
  self.items[0] = last
  self.sift_down(0)
  Some(top)
}

///|
/// 内部自底向上调整堆
fn[T : Compare] PriorityQueue::sift_up(self : PriorityQueue[T], index : Int) -> Unit {
  let mut idx = index
  while idx > 0 {
    let parent = (idx - 1) / 2
    if self.items[idx].compare(self.items[parent]) < 0 {
      let tmp = self.items[idx]
      self.items[idx] = self.items[parent]
      self.items[parent] = tmp
      idx = parent
    } else {
      break
    }
  }
}

///|
/// 内部自顶向下调整堆
fn[T : Compare] PriorityQueue::sift_down(self : PriorityQueue[T], index : Int) -> Unit {
  let len = self.items.length()
  let mut idx = index
  while true {
    let left = 2 * idx + 1
    let right = 2 * idx + 2
    let mut smallest = idx
    if left < len && self.items[left].compare(self.items[smallest]) < 0 {
      smallest = left
    }
    if right < len && self.items[right].compare(self.items[smallest]) < 0 {
      smallest = right
    }
    if smallest != idx {
      let tmp = self.items[idx]
      self.items[idx] = self.items[smallest]
      self.items[smallest] = tmp
      idx = smallest
    } else {
      break
    }
  }
}
