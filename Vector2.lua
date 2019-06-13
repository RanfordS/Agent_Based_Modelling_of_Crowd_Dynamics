local Vector2 = {}
Vector2.Metatable =
{__index = Vector2}

function Vector2.New (x,y)
	assert (type(x) == "number", "Vector2.x only takes numbers")
	assert (type(y) == "number", "Vector2.y only takes numbers")
	return setmetatable ({x=x,y=y}, Vector2.Metatable)
end

function Vector2.From_angle (theta)
	return Vector2.New (math.cos(theta), math.sin(theta))
end

function Vector2:Clone ()
	Vector2.New (self.x, self.y)
end

function Vector2:Draw ()
	love.graphics.points (self.x, self.y)
end

--	gen

function Vector2.Metatable.__tostring (a)
	return string.format ("(%f,%f)", a.x, a.y)
end

function Vector2.Metatable.__len (a)
	return a:Magnitude ()	
end

function Vector2.Metatable.__concat (a,b)
	return tostring (a) .." ".. tostring (b)
end

--	math

function Vector2.Metatable.__unm (a)
	return Vector2.New (-a.x, -a.y)
end

function Vector2.Metatable.__add (a,b)
	if not Vector2.Is (a) then a = Vector2.New (a,a) end
	if not Vector2.Is (b) then b = Vector2.New (b,b) end
	return Vector2.New (a.x+b.x, a.y+b.y)
end

function Vector2.Metatable.__sub (a,b)
	if not Vector2.Is (a) then a = Vector2.New (a,a) end
	if not Vector2.Is (b) then b = Vector2.New (b,b) end
	return Vector2.New (a.x-b.x, a.y-b.y)
end

function Vector2.Metatable.__mul (a,b)
	if not Vector2.Is (a) then a = Vector2.New (a,a) end
	if not Vector2.Is (b) then b = Vector2.New (b,b) end
	return Vector2.New (a.x*b.x, a.y*b.y)
end

function Vector2.Metatable.__div (a,b)
	if not Vector2.Is (a) then a = Vector2.New (a,a) end
	if not Vector2.Is (b) then b = Vector2.New (b,b) end
	return Vector2.New (a.x/b.x, a.y/b.y)
end

function Vector2.Metatable.__mod (a,b)
	if not Vector2.Is (a) then a = Vector2.New (a,a) end
	if not Vector2.Is (b) then b = Vector2.New (b,b) end
	return Vector2.New (a.x%b.x, a.y%b.y)
end

function Vector2.Metatable.__pow (a,b)
	if not Vector2.Is (a) then a = Vector2.New (a,a) end
	if not Vector2.Is (b) then b = Vector2.New (b,b) end
	return Vector2.New (a.x^b.x, a.y^b.y)
end

--	comp

function Vector2.Metatable.__eq (a,b)
	return (a.x == b.x) and (a.y == b.y)
end

function Vector2.Metatable.__lt (a,b)
	return (a.x > b.x), (a.y > b.y)
end

function Vector2.Metatable.__le (a,b)
	return (a.x >= b.x), (a.y >= b.y)
end

--	cust

function Vector2:Unpack ()
	return self.x, self.y
end

function Vector2.Is (a)
	return getmetatable (a) == Vector2.Metatable
end

function Vector2:Sum ()
	return self.x + self.y
end

function Vector2.Dot (a,b)
	return (a*b):Sum()
end

function Vector2:MagSquared ()
	return (self):Dot (self)
end

function Vector2:Magnitude ()
	return math.sqrt (self:MagSquared())
end

function Vector2:Normalise (s)
	s = s or 1
	return self / (s*self:Magnitude())
end

function Vector2.DistSquared (a,b)
	return (a-b):MagSquared()
end

function Vector2.Distance (a,b)
	return (a-b):Magnitude()
end

function Vector2:Perp ()
	return Vector2.New (-self.y, self.x)
end

function Vector2:Angle ()
	return math.atan2 (self.y, self.x)
end

function Vector2.Angle_between (a,b)
	return math.acos ((a:Dot(b))/math.sqrt(a:Dot(a) * b:Dot(b)))
end

function Vector2:In_place (a)
	assert (Vector2.Is (a), ":In_place expects vector")
	self.x = a.x
	self.y = a.y
	return self
end

function Vector2:Add (a)
	return self:In_place (self + a)
end

function Vector2:Rotate (a)
  local c = math.cos (a)
  local s = math.sin (a)
  return Vector2.New (self.x*c - self.y*s, self.x*s + self.y*c)
end

return Vector2
