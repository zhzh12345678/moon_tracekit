///|
test "time and duration arithmetic" {
  let t0 = Time::zero()
  let d1 = Duration::from_millis(500L)
  let t1 = t0.add(d1)
  inspect(t1.to_string(), content="500ms")
  let d2 = Duration::from_secs(2L)
  let t2 = t1.add(d2)
  inspect(t2.to_string(), content="2.5s")
  inspect(t2.sub(t1).to_string(), content="2s")
}

///|
test "deterministic pcg32 sequence" {
  let rng1 = PCG32::new(12345UL, 1UL)
  let rng2 = PCG32::new(12345UL, 1UL)
  let v1 = rng1.next_uint()
  let v2 = rng2.next_uint()
  inspect(v1 == v2, content="true")
  let f1 = rng1.next_float()
  let f2 = rng2.next_float()
  inspect(f1 == f2, content="true")
  let exp_val = rng1.next_exponential(10.0)
  inspect(exp_val >= 0.0, content="true")
}

///|
test "event ordering" {
  let e1 = Event::new(1, Time::from_millis(100L), priority=1, () => ())
  let e2 = Event::new(2, Time::from_millis(100L), priority=0, () => ())
  let e3 = Event::new(3, Time::from_millis(50L), priority=0, () => ())
  inspect(e3.compare(e1) < 0, content="true")
  inspect(e2.compare(e1) < 0, content="true")
}

///|
test "priority queue min heap" {
  let pq : PriorityQueue[Int] = PriorityQueue::new()
  pq.push(30)
  pq.push(10)
  pq.push(20)
  inspect(pq.length(), content="3")
  inspect(pq.pop() == Some(10), content="true")
  inspect(pq.pop() == Some(20), content="true")
  inspect(pq.pop() == Some(30), content="true")
  inspect(pq.pop() == None, content="true")
}

///|
test "simulator scheduling and execution" {
  let sim = Simulator::new()
  let mut log = ""
  let _ = sim.schedule(Duration::from_millis(100L), () => log = log + "e1;")
  let _ = sim.schedule(Duration::from_millis(50L), () => log = log + "e2;")
  let _ = sim.schedule(Duration::from_millis(100L), priority=-1, () => {
    log = log + "e3_prio;"
  })
  sim.run()
  inspect(log, content="e2;e3_prio;e1;")
  inspect(sim.now().to_string(), content="100ms")
  inspect(sim.event_count(), content="3")
}
