local V2 = require ("Vector2")
local E2 = require ("Edge2")

local Hull2 = {}
Hull2.Metatable =
{__index = Hull2}

function Hull2.New (Edge_List)
	local num = #Edge_List
	local i = 1

	--	check convex
	local e_prev = Edge_List [#Edge_List]
	while i <= num do
		local e_next = Edge_List [i]

		if e_prev.v1 ~= e_next.v0 then
			error ("Hull2 edges are not continuous")
		end

		if E2.Turn (e_prev, e_next) < 0 then
			error ("Hull2 is not convex")
		end

		e_prev = e_next
		i = i + 1
	end

	return setmetatable (Edge_List, Hull2.Metatable)
end

function Hull2:Contains (a)
	for i = 1, #self do
		if self[i]:Side (a) < 0 then
			return false
		end
	end
	return true
end

function Hull2:Draw ()
	local Polygon = {}
	for i = 1, #self do
		Polygon [2*i-1] = self[i].v0.x
		Polygon [2*i  ] = self[i].v0.y
	end
	love.graphics.polygon ('fill', Polygon)
end

return Hull2
