///|
/// Raft 节点角色
pub(all) enum RaftRole {
  Follower
  Candidate
  Leader
} derive(Eq, Compare, Debug)

///|
/// Raft 节点通信消息 payload
pub(all) enum RaftMsg {
  RequestVote(Int, String) // (term, candidate_id)
  VoteResponse(Int, Bool, String) // (term, vote_granted, voter_id)
  Heartbeat(Int, String) // (term, leader_id)
} derive(Eq, Compare, Debug)

///|
/// Raft 集群模拟节点
pub(all) struct RaftNode {
  id : String
  sim : @core.Simulator
  net : @net.NetworkTopology[RaftMsg]
  mut current_term : Int
  mut role : RaftRole
  mut voted_for : String?
  mut votes_received : Int
  mut leader_id : String?
  mut last_heartbeat : @core.Time
  mut election_timeout : Int64 // 随机选举超时阈值 (150ms ~ 300ms)
}

///|
/// 创建新的 Raft 节点
pub fn RaftNode::new(
  id : String,
  sim : @core.Simulator,
  net : @net.NetworkTopology[RaftMsg],
) -> RaftNode {
  {
    id,
    sim,
    net,
    current_term: 0,
    role: Follower,
    voted_for: None,
    votes_received: 0,
    leader_id: None,
    last_heartbeat: sim.now(),
    election_timeout: 150L,
  }
}

///|
/// 辅助方法：结合故障注入器模拟当前节点与目标节点间的网络隔离
pub fn RaftNode::simulate_partition(
  self : RaftNode,
  injector : @fault.FaultInjector,
  target : String,
  duration : @core.Duration,
) -> Unit {
  injector.schedule_fault(
    @core.Duration::from_millis(10L),
    @fault.PacketDropSpike(self.id, target, 1.0),
    duration,
    self.net,
  )
}

///|
/// 重设随机选举超时阈值 (避免多候选人死锁)
fn RaftNode::reset_election_timeout(self : RaftNode) -> Unit {
  let rand_ms = self.sim.get_rng().next_uint().to_int64() % 151L
  self.election_timeout = 150L + rand_ms
}

///|
/// 启动节点（定时检查超时与收信）
pub fn RaftNode::start(self : RaftNode, all_nodes : Array[String]) -> Unit {
  self.reset_election_timeout()
  self.schedule_tick(all_nodes)
}

///|
/// 周期检查信箱与选举超时
fn RaftNode::schedule_tick(self : RaftNode, all_nodes : Array[String]) -> Unit {
  let _ = self.sim.schedule(@core.Duration::from_millis(50L), () => {
    self.process_inbox(all_nodes)
    self.check_election_timeout(all_nodes)
    self.schedule_tick(all_nodes)
  })
  ()
}

///|
/// 处理信箱中的所有到达数据包
fn RaftNode::process_inbox(self : RaftNode, all_nodes : Array[String]) -> Unit {
  for ;; {
    match self.net.receive(self.id) {
      None => break
      Some(pkt) =>
        match pkt.payload {
          RequestVote(term, cand_id) => {
            if term > self.current_term {
              self.current_term = term
              self.role = Follower
              self.voted_for = None
            }
            let granted = if term == self.current_term &&
              (self.voted_for == None || self.voted_for == Some(cand_id)) {
              self.voted_for = Some(cand_id)
              self.last_heartbeat = self.sim.now()
              self.reset_election_timeout()
              true
            } else {
              false
            }
            let resp = @net.Packet::new(
              self.sim.get_rng().next_uint().reinterpret_as_int(),
              self.id,
              cand_id,
              VoteResponse(self.current_term, granted, self.id),
              self.sim.now(),
            )
            let _ = self.net.send_packet(resp)
            ()
          }
          VoteResponse(term, granted, _voter_id) =>
            if self.role == Candidate && term == self.current_term && granted {
              self.votes_received = self.votes_received + 1
              if self.votes_received >= all_nodes.length() / 2 + 1 {
                self.role = Leader
                self.leader_id = Some(self.id)
                self.send_heartbeats(all_nodes)
              }
            }
          Heartbeat(term, leader) =>
            if term >= self.current_term {
              self.current_term = term
              self.role = Follower
              self.leader_id = Some(leader)
              self.last_heartbeat = self.sim.now()
              self.reset_election_timeout()
            }
        }
    }
  }
}

///|
/// 检查选举超时或作为 Leader 发送心跳
fn RaftNode::check_election_timeout(
  self : RaftNode,
  all_nodes : Array[String],
) -> Unit {
  if self.role == Leader {
    self.send_heartbeats(all_nodes)
    return
  }
  let elapsed = self.sim.now().sub(self.last_heartbeat).to_millis()
  if elapsed >= self.election_timeout {
    self.start_election(all_nodes)
  }
}

///|
/// 发起新一轮选举
fn RaftNode::start_election(self : RaftNode, all_nodes : Array[String]) -> Unit {
  self.role = Candidate
  self.current_term = self.current_term + 1
  self.voted_for = Some(self.id)
  self.votes_received = 1
  self.last_heartbeat = self.sim.now()
  self.reset_election_timeout()
  for i = 0; i < all_nodes.length(); i = i + 1 {
    let dst = all_nodes[i]
    if dst != self.id {
      let pkt = @net.Packet::new(
        self.sim.get_rng().next_uint().reinterpret_as_int(),
        self.id,
        dst,
        RequestVote(self.current_term, self.id),
        self.sim.now(),
      )
      let _ = self.net.send_packet(pkt)
      ()
    }
  }
}

///|
/// Leader 广播心跳
fn RaftNode::send_heartbeats(
  self : RaftNode,
  all_nodes : Array[String],
) -> Unit {
  for i = 0; i < all_nodes.length(); i = i + 1 {
    let dst = all_nodes[i]
    if dst != self.id {
      let pkt = @net.Packet::new(
        self.sim.get_rng().next_uint().reinterpret_as_int(),
        self.id,
        dst,
        Heartbeat(self.current_term, self.id),
        self.sim.now(),
      )
      let _ = self.net.send_packet(pkt)
      ()
    }
  }
}
