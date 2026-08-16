///|
test "telemetry counters and gauges" {
  let reg = MetricsRegistry::new()
  let c = reg.counter("packets_sent")
  c.inc()
  c.inc(delta=5L)
  inspect(c.get(), content="6")

  let g = reg.gauge("queue_depth")
  g.set(10.0)
  g.add(5.5)
  g.sub(2.0)
  inspect(g.get(), content="13.5")
}

///|
test "histogram percentiles and distribution" {
  let h = Histogram::new("latency_ms")
  for i = 1; i <= 100; i = i + 1 {
    h.record(i.to_double())
  }
  inspect(h.count(), content="100")
  inspect(h.min(), content="1")
  inspect(h.max(), content="100")
  inspect(h.mean(), content="50.5")
  // p50 is around 50 or 51
  let p50 = h.percentile(0.50)
  inspect(p50 >= 50.0 && p50 <= 51.0, content="true")
  // p99 is around 99 or 100
  let p99 = h.percentile(0.99)
  inspect(p99 >= 99.0 && p99 <= 100.0, content="true")
  let p95 = h.p95()
  inspect(p95 >= 95.0 && p95 <= 96.0, content="true")
}

///|
test "histogram snapshot is stable and useful for reports" {
  let h = Histogram::new("request_latency_ms")
  h.record(2.0)
  h.record(4.0)
  h.record(8.0)
  let snapshot = h.snapshot()
  h.record(100.0)
  inspect(snapshot.count, content="3")
  inspect(snapshot.min, content="2")
  inspect(snapshot.max, content="8")
  inspect(snapshot.mean, content="4.666666666666667")
  if snapshot.to_string().contains("p99=") == false {
    fail("text report omitted p99")
  }
  if snapshot.to_json().contains("\"count\":3") == false {
    fail("json report omitted count")
  }
}

///|
test "histogram empty and extreme percentile boundaries" {
  let h = Histogram::new("empty")
  inspect(h.snapshot().count, content="0")
  inspect(h.percentile(-1.0), content="0")
  inspect(h.percentile(2.0), content="0")
  h.record(7.0)
  inspect(h.percentile(-1.0), content="7")
  inspect(h.percentile(2.0), content="7")
}
