local V2 = require ("Vector2")

local Edge2 = {}
Edge2.Metatable =
{__index = Edge2}

function Edge2.New (v0, v1)
	assert (V2.Is(v0), "v0 must be Vector2")
	assert (V2.Is(v1), "v1 must be Vector2")

	return setmetatable ({v0=v0, v1=v1}, Edge2.Metatable)
end

function Edge2:Reverse ()
	return Edge2.New (self.v1, self.v0)
end

function Edge2.Metatable.__eq (a,b)
	if a.v0 == b.v0 and a.v1 == b.v1 then
		return  1
	elseif  a.v1 == b.v0 and a.v0 == b.v1 then
		return -1
	end
	return false
end

function Edge2.Turn (a,b)
	local a_d = a.v1 - a.v0
	local b_d = b.v1 - b.v0
	return V2.Dot (a_d:Perp(), b_d)
end

function Edge2:Side (a)
	local s_d = self.v1 - self.v0
	local a_d =       a - self.v0
	return V2.Dot (s_d:Perp(), a_d)
end

function Edge2:Lerp (a)
	return self.v0 + a * (self.v1 - self.v0)
end

function Edge2:Mid ()
	return self:Lerp (0.5)
end

function Edge2:Draw ()
	love.graphics.line (self.v0.x, self.v0.y, self.v1.x, self.v1.y)
end

return Edge2
