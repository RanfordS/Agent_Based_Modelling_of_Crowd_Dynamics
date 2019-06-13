local V2 = require ("Vector2")

local Agent = {}
Agent.Metatable =
{__index = Agent}
Agent.model = "Basic"

Agent.Vars =
{ speed_initial = 0.7
, drag = 0.8
, radius = 0.45
, r_bin = 2
, d = 8
, limit_target  = 0.7
, limit_agent   = 0.7
, weight_target = 0.7
, weight_agent  = 1.2
, threshold     = 0.1
}

Agent.List = {}
Agent.Stats =
{ num_created = 0
, num_deleted = 0
, num_max     = 0
, sum_life    = 0
}

function Agent.Stats.Write (path)
  local file = io.open (path, "w")
  file:write (("agents created: %i\n"  ):format(Agent.Stats.num_created))
  file:write (("agents deleted: %i\n"  ):format(Agent.Stats.num_deleted))
  file:write (("max agents: %i\n"      ):format(Agent.Stats.num_max))
  file:write (("sum agent life: %.1f\n"):format(Agent.Stats.sum_life))
  file:write (("average life: %.2f\n"  ):format(Agent.Stats.sum_life
  / Agent.Stats.num_deleted))
  file:close ()
end

function Agent.New (pos, tar)
	assert (V2.Is (pos), "Expected pos to be Vector2")
	assert (V2.Is (tar), "Expected tar to be Vector2")
	-- Agent declaration
	local New = setmetatable (
	{	pos = pos
	,	vel = (tar-pos):Normalise (Agent.Vars.speed_initial)
	,	acc = V2.New (0,0)
	,	tar = tar
  , age = 0
	},	Agent.Metatable)

	table.insert (Agent.List, New)
  Agent.Stats.num_created = Agent.Stats.num_created + 1
	return New
end

function Agent:Target_set (t_x, t_y)
	self.tar = V2.New (t_x, t_y)
	return self
end

function Agent.Calculate_forces ()
  local bin = {}
	for i, agent in ipairs (Agent.List) do
		local sudo_tar = agent.tar - agent.vel -- Predictive target position
		local to_tar = sudo_tar - agent.pos

    if to_tar:Magnitude() < Agent.Vars.r_bin then
      table.insert (bin, i)
    else
      -- target force
      agent.acc = to_tar:Normalise() *
      (Agent.Vars.weight_target
      * math.min(to_tar:Magnitude(), Agent.Vars.limit_target))

      for j, other in ipairs (Agent.List) do
        if i ~= j then
          local diff = agent.pos - other.pos
          local dist = diff:Magnitude()
          if dist < Agent.Vars.d then
            agent.acc:Add (
              diff:Normalise() * Agent.Vars.weight_agent
              * (math.cos((diff:Magnitude()*math.pi)/(2*Agent.Vars.d)))
            )
          end
        end
      end

      local acc_mag = agent.acc:Magnitude ()
      if acc_mag > Agent.Vars.limit_agent then
        agent.acc = agent.acc:Normalise (1/Agent.Vars.limit_agent)
      elseif acc_mag < Agent.Vars.threshold then
        agent.acc = V2.New (0,0)
      end
    end
  end
  while #bin > 0 do
    local i = table.remove (bin, #bin)
    local a = table.remove (Agent.List, i)
    Agent.Stats.num_deleted = Agent.Stats.num_deleted + 1
    Agent.Stats.sum_life = Agent.Stats.sum_life + a.age
  end
  Agent.Stats.num_max = math.max (#Agent.List, Agent.Stats.num_max)
end

function Agent.Step (dt)
	local drag = Agent.Vars.drag^dt -- mu
	for i, agent in ipairs (Agent.List) do
		agent.vel = (agent.vel + dt*agent.acc) * drag
		agent.pos = agent.pos + dt*agent.vel
    agent.age = agent.age + dt
	end
end

function Agent:Draw (lt, s)
  local s_pos = s*(self.pos - lt)
	love.graphics.setColor (1,1,1,1)
	love.graphics.circle ('line', s_pos.x, s_pos.y, s*Agent.Vars.radius)

  local s_vel = s*(self.pos + self.vel - lt)
  love.graphics.setColor (1,0,0,1)
  love.graphics.line (s_pos.x, s_pos.y, s_vel.x, s_vel.y)

  local s_acc = s*(self.pos + self.acc - lt)
  love.graphics.setColor (0,1,0,1)
  love.graphics.line (s_pos.x, s_pos.y, s_acc.x, s_acc.y)

  local s_tar = s*(self.tar - lt)
  love.graphics.setColor (0,0,1,0.1)
  love.graphics.line (s_pos.x, s_pos.y, s_tar.x, s_tar.y)

  return self
end

function Agent.Draw_all (lt, s)
	for i, a in ipairs (Agent.List) do
		a:Draw (lt, s)
	end
end

return Agent
