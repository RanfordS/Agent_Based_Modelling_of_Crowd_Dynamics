local V2 = require ("Vector2")

local Agent = {}
Agent.Metatable =
{__index = Agent}

Agent.List = {}

function Agent.New (pos, tar, ang)
	assert (V2.Is (pos), "Expected pos to be Vector2")
	assert (V2.Is (tar), "Expected tar to be Vector2")

	local New = setmetatable (
	{	pos = pos
	,	vel = V2.New (0,0)
	,	acc = V2.New (0,0)
	,	ang = ang
	,	dir = V2.From_angle (ang)
	,	tar = tar
	},	Agent.Metatable)

	table.insert (Agent.List, New)
	return New
end

function Agent:Target_set (t_x, t_y)
	self.tar = V2.New (t_x, t_y)
	return self
end

--	Calculates the forces of all the agents
function Agent.Forces_calculate ()
	local bin = {}
	for i, agent in ipairs (Agent.List) do
		local sudo_tar = agent.tar - agent.vel
		local to_tar = sudo_tar - agent.pos
		agent.dir = to_tar:Normalise()

		if to_tar:MagSquared() < 40 then
			table.insert (bin, i)
		end

		agent.acc = to_tar:Normalise() *
		(0.5 * math.min(to_tar:Magnitude(), 10))--V2.New (0,0)--

		for j, other in ipairs (Agent.List) do
			local ker_fact = agent:Kernal(other.pos + other.vel)
			if i ~= j and ker_fact then
				local diff = agent.pos - other.pos
				local dist = diff:Magnitude()
				agent.acc:Add (
					diff:Normalise() * 40 * ker_fact
					* (math.cos((diff:Magnitude()*math.pi)/(2*80)))
				)
			end
		end

		local acc_mag = agent.acc:Magnitude ()
		if acc_mag > 40 then
			agent.acc = agent.acc:Normalise (40)
--		elseif acc_mag < 4 and agent.vel:Magnitude() < 3 then
--			agent.acc = V2.New (0,0)
		end
	end

	while #bin > 0 do
		table.remove (Agent.List, table.remove (bin, #bin))	
	end
end

--	Performs a physics step of all the agents
function Agent.Step (dt)
	local drag = 0.8^dt
	--print ("drag = ", drag)
	for i, agent in ipairs (Agent.List) do
		--print ("agent", i)
		--print ("initial", agent.pos, agent.vel, agent.acc)
		agent.vel = (agent.vel + dt*agent.acc) * drag
		agent.pos = agent.pos + dt*agent.vel
		--print ("new", agent.pos, agent.vel, agent.acc)
	end
end

local function Clamp (x)
	if x < 0 then
		return 0
	elseif x > 1 then
		return 1
	end
	return x
end

local function Ranger (l,x,u)
	return Clamp((u-x)/(u-l))
end

--	Returns true is the point is in the agent's kernal
local Kernal =
{	r = 10
,	Rn = 20
,	Rf = 90
,	fm = math.rad (15)
,	fM = math.rad (45)
}

function Agent:Kernal (point)
	point = point - self.pos
	local dist = point:Dot(point)
	if dist > Kernal.Rf^2 then return false end
	if dist < Kernal.r^2 then return 1 end
	dist = math.sqrt (dist)
	
	local theta = V2.Angle_between (self.dir, point)
	local factor_angle = Ranger (Kernal.fm, theta, Kernal.fM)
	local factor_dist  = Ranger (Kernal.Rn, dist , Kernal.Rf)
	local result = factor_angle * factor_dist
	return (result ~= 0) and result
end

function Agent:Draw ()
	love.graphics.setColor (1,1,1,1)
	love.graphics.circle ('line', self.pos.x, self.pos.y, 5)

	local pos = self.pos
	local vel = self.vel + pos
	love.graphics.setColor (1,0,0,1)
	love.graphics.line (pos.x, pos.y, vel.x, vel.y)
	local acc = self.acc + pos
	love.graphics.setColor (0,1,0,1)
	love.graphics.line (pos.x, pos.y, acc.x, acc.y)
	local tar = self.tar
	love.graphics.setColor (0,0,.5,1)
	love.graphics.line (pos.x, pos.y, tar.x, tar.y)
	local dir = 10*self.dir + pos
	love.graphics.setColor (0,0,1,1)
	love.graphics.line (pos.x, pos.y, dir.x, dir.y)
	return self
end

function Agent.Draw_all ()
	for i, agent in ipairs (Agent.List) do
		agent:Draw ()
	end
end

return Agent
