local V2 = require ("Vector2")

local Agent = {}
Agent.Metatable =
{__index = Agent}
Agent.model = "Steering_Mod"

Agent.Vars =
{ speed_initial = 0.6--m/s
, speed_max = 0.6--m/s 
, drag = 0.8
, radius = 0.45--m
, collision = 2--m/s
, r_bin = 2
--kernal
, phi_m = math.rad (15)
, phi_M = math.rad (55)
, d_n =  3--m
, d_f = 12--m
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
  file:write (("average life: %.2f\n"  ):format(Agent.Stats.sum_life / Agent.Stats.num_deleted))
  file:close ()                                                                 
end

function Agent.New (pos, tar, dir)
  assert (V2.Is (pos), "Expected pos to be Vector2")
  assert (V2.Is (tar), "Expected tar to be Vector2")
  --assert (V2.Is (dir), "Expected dir to be Vector2")
  dir = (tar-pos):Normalise()

  local New = setmetatable (
  { pos = pos
  , vel = dir * Agent.Vars.speed_initial
  , acc = V2.New (0,0)
  , dir = dir
  , ang = 0
  , tar = tar
  , age = 0
  }
  , Agent.Metatable)

  table.insert (Agent.List, New)
  Agent.Stats.num_created = Agent.Stats.num_created + 1
  return New
end

function Agent:Target_set (t_x, t_y)
  self.tar = V2.New (t_x, t_y)
  return self
end

local function Clamp (x)
  if x < 0 then
    return 0
  elseif x > 1 then
    return 1
  end
  return x
end

local function Sign (a)
  return a < 0 and -1 or 1
end

local function Ranger (l,x,u)
  return Clamp ((u-x)/(u-l))
end

function Agent.Calculate_forces ()
  local bin = {}
  for i, self in ipairs (Agent.List) do
    local sudo_tar = self.tar - self.vel
    local to_tar = sudo_tar - self.pos
    --bin condition
    if to_tar:Magnitude() < Agent.Vars.r_bin then
      table.insert (bin, i)
    else
      --calculate turn & acceleration
      local dtheta = 0
      local f = Agent.Vars.speed_max * self.dir:Dot(to_tar:Normalise())
      local g = V2.New (0,0)
      local tan = self.dir:Perp()
      for j, other in ipairs (Agent.List) do
        local ker_fac = self:Kernel (other.pos)
        if i ~= j and ker_fac then
          local diff = self.pos - other.pos
          f = f * (1-ker_fac)
          g = g + Agent.Vars.collision * diff:Normalise()
          * math.max (1 - diff:Magnitude()/(3*Agent.Vars.radius), 0)
          dtheta = dtheta - ker_fac*Sign (
          (other.pos+other.vel - (self.pos+self.vel)):Dot(tan))
        end
      end
      dtheta = dtheta + (to_tar:Normalise()):Dot(tan)
      self.ang = dtheta
      self.acc = f*self.dir + g
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

function Agent:Kernel (point)
  local p = point - self.pos
  local dist = p:Magnitude()
  if dist > Agent.Vars.d_f then return false end
  if dist < Agent.Vars.radius*3 then return 1 end

  local theta = V2.Angle_between (self.dir, p)
  local factor_angle = Ranger (Agent.Vars.phi_m, theta, Agent.Vars.phi_M)
  if factor_angle == 0 then return false end

  local factor_dist = Ranger (Agent.Vars.d_n, dist, Agent.Vars.d_f)
  return factor_angle * factor_dist
end

function Agent.Step (dt)
  local drag = Agent.Vars.drag^dt
  for i, a in ipairs (Agent.List) do
    a.dir = a.dir:Rotate (a.ang*dt)
    a.vel = (a.vel + dt*a.acc)*drag
    a.pos = a.pos + dt*a.vel
    a.age = a.age + dt
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
