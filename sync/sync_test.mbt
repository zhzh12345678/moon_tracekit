///|
test "channel send and receive between processes" {
  let sim = @core.Simulator::new()
  let mgr = @process.ProcessManager::new(sim)
  let chan : Channel[String] = Channel::new(2001, "msg_chan", mgr)
  let mut log = ""

  let _ = mgr.spawn("consumer", fn(ctx) {
    match chan.try_recv() {
      Some(msg) => {
        log = log + "recv_\{msg}@\{ctx.now().to_string()};"
        return ctx.terminate()
      }
      None => {
        log = log + "waiting;"
        return chan.wait_recv()
      }
    }
  })

  let mut prod_step = 0
  let _ = mgr.spawn("producer", fn(ctx) {
    if prod_step == 0 {
      prod_step = 1
      return ctx.sleep(@core.Duration::from_millis(100L))
    } else {
      let _ = chan.try_send("hello_sim")
      log = log + "sent@\{ctx.now().to_string()};"
      return ctx.terminate()
    }
  })

  sim.run()
  inspect(log, content="waiting;sent@100ms;recv_hello_sim@100ms;")
}

///|
test "mutex contention between processes" {
  let sim = @core.Simulator::new()
  let mgr = @process.ProcessManager::new(sim)
  let mutex = Mutex::new(3001, "res_lock", mgr)
  let mut order = ""

  let mut w1_step = 0
  let _ = mgr.spawn("w1", fn(ctx) {
    if w1_step == 0 {
      if mutex.try_lock(ctx.pid()) {
        w1_step = 1
        order = order + "w1_lock@\{ctx.now().to_string()};"
        return ctx.sleep(@core.Duration::from_millis(200L))
      } else {
        return mutex.wait_lock()
      }
    } else {
      let _ = mutex.unlock(ctx.pid())
      order = order + "w1_unlock@\{ctx.now().to_string()};"
      return ctx.terminate()
    }
  })

  let mut w2_step = 0
  let _ = mgr.spawn("w2", fn(ctx) {
    if w2_step == 0 {
      w2_step = 1
      return ctx.sleep(@core.Duration::from_millis(50L))
    } else if w2_step == 1 {
      if mutex.try_lock(ctx.pid()) {
        w2_step = 2
        order = order + "w2_lock@\{ctx.now().to_string()};"
        return ctx.terminate()
      } else {
        order = order + "w2_waiting@\{ctx.now().to_string()};"
        return mutex.wait_lock()
      }
    } else {
      if mutex.try_lock(ctx.pid()) {
        order = order + "w2_lock@\{ctx.now().to_string()};"
        let _ = mutex.unlock(ctx.pid())
        return ctx.terminate()
      } else {
        return mutex.wait_lock()
      }
    }
  })

  sim.run()
  inspect(order, content="w1_lock@0ns;w2_waiting@50ms;w1_unlock@200ms;w2_lock@200ms;")
}

///|
test "semaphore resource pooling" {
  let sim = @core.Simulator::new()
  let mgr = @process.ProcessManager::new(sim)
  // 仅有 1 个许可的信号量
  let sem = Semaphore::new(4001, "pool", 1, mgr)
  let mut log = ""

  let mut p1_step = 0
  let _ = mgr.spawn("p1", fn(ctx) {
    if p1_step == 0 {
      if sem.try_acquire() {
        p1_step = 1
        log = log + "p1_acq@\{ctx.now().to_string()};"
        return ctx.sleep(@core.Duration::from_millis(100L))
      } else {
        return sem.wait_acquire()
      }
    } else {
      sem.release()
      log = log + "p1_rel@\{ctx.now().to_string()};"
      return ctx.terminate()
    }
  })

  let mut p2_step = 0
  let _ = mgr.spawn("p2", fn(ctx) {
    if p2_step == 0 {
      if sem.try_acquire() {
        p2_step = 1
        log = log + "p2_acq@\{ctx.now().to_string()};"
        return ctx.terminate()
      } else {
        log = log + "p2_wait@\{ctx.now().to_string()};"
        return sem.wait_acquire()
      }
    } else {
      if sem.try_acquire() {
        log = log + "p2_acq@\{ctx.now().to_string()};"
        sem.release()
        return ctx.terminate()
      } else {
        return sem.wait_acquire()
      }
    }
  })

  sim.run()
  inspect(log, content="p1_acq@0ns;p2_wait@0ns;p1_rel@100ms;p2_acq@100ms;")
}

///|
test "barrier synchronization" {
  let sim = @core.Simulator::new()
  let mgr = @process.ProcessManager::new(sim)
  // 需要 2 个进程同时到达的屏障
  let barrier = Barrier::new(5001, "sync_point", 2, mgr)
  let mut log = ""

  // Fast worker: arrives at 50ms, waits at barrier
  let mut f_step = 0
  let _ = mgr.spawn("fast", fn(ctx) {
    if f_step == 0 {
      f_step = 1
      return ctx.sleep(@core.Duration::from_millis(50L))
    } else if f_step == 1 {
      f_step = 2
      if barrier.arrive_and_wait() {
        log = log + "fast_passed@\{ctx.now().to_string()};"
        return ctx.terminate()
      } else {
        log = log + "fast_waiting@\{ctx.now().to_string()};"
        return barrier.wait_barrier()
      }
    } else {
      log = log + "fast_woke@\{ctx.now().to_string()};"
      return ctx.terminate()
    }
  })

  // Slow worker: arrives at 150ms, triggers barrier!
  let mut s_step = 0
  let _ = mgr.spawn("slow", fn(ctx) {
    if s_step == 0 {
      s_step = 1
      return ctx.sleep(@core.Duration::from_millis(150L))
    } else {
      if barrier.arrive_and_wait() {
        log = log + "slow_triggered_barrier@\{ctx.now().to_string()};"
        return ctx.terminate()
      } else {
        return barrier.wait_barrier()
      }
    }
  })

  sim.run()
  inspect(log, content="fast_waiting@50ms;slow_triggered_barrier@150ms;fast_woke@150ms;")
}
