///|
test "process manager spawn and sleep" {
  let sim = @core.Simulator::new()
  let mgr = ProcessManager::new(sim)
  let mut step_count = 0
  let mut final_time = ""
  let _ = mgr.spawn("worker-1", fn(ctx) {
    if step_count == 0 {
      step_count = 1
      return ctx.sleep(@core.Duration::from_millis(200L))
    } else if step_count == 1 {
      step_count = 2
      final_time = ctx.now().to_string()
      return ctx.terminate()
    } else {
      return Terminate
    }
  })
  sim.run()
  inspect(step_count, content="2")
  inspect(final_time, content="200ms")
}

///|
test "process wait and signal event" {
  let sim = @core.Simulator::new()
  let mgr = ProcessManager::new(sim)
  let mut log = ""
  let pid1 = mgr.spawn("waiter", fn(ctx) {
    if log == "" {
      log = log + "waiting;"
      return ctx.wait_for(1001)
    } else {
      log = log + "woke_up_at_\{ctx.now().to_string()};"
      return ctx.terminate()
    }
  })
  let _ = sim.schedule(@core.Duration::from_millis(500L), () => {
    log = log + "signaling;"
    let _ = mgr.signal_event(1001)
    ()
  })
  sim.run()
  inspect(log, content="waiting;signaling;woke_up_at_500ms;")
  inspect(mgr.get_state(pid1) == Some(Terminated), content="true")
}

///|
test "actor mailbox messaging" {
  let sim = @core.Simulator::new()
  let mut received = ""
  let actor : Actor[String] = Actor::new("echo", sim, fn(ctx, msg) {
    received = received + "\{msg}@\{ctx.now().to_string()};"
  })
  actor.send("hello", delay=@core.Duration::from_millis(50L))
  actor.send("world", delay=@core.Duration::from_millis(150L))
  sim.run()
  inspect(received, content="hello@50ms;world@150ms;")
}
