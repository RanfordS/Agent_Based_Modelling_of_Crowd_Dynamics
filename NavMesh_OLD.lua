V2 = require ("Vector2")
E2 = require ("Edge2")

local NavMesh = {}
NavMesh.Metatable =
{__index = NavMesh}

function NavMesh.New ()
	return setmetatable (
	{	Verticies = {}
	,	Edges = {}
	,	Windows = {}
	,	Hulls = {}
	}
	, NavMesh.Metatable)
end

function NavMesh:Add_vertex (Vertex)
	assert (V2.Is(Vertex), "Add vertex expected a Vector2")
	table.insert (self.Verticies, Vertex)
	return #self.Verticies
end

function NavMesh:Make_edge (v0_index, v1_index)
	local v0 = assert (self.Verticies[v0_index]
	, "invalid vertex index for v0: ".. v0_index)
	local v1 = assert (self.Verticies[v1_index]
	, "invalid vertex index for v1: ".. v1_index)

	local new = E2.New (v0, v1)
	local window = false
	for _,e in ipairs (self.Edges) do
		local comp = e == new
		if comp == 1 then
			error ("Attempted to make edge that already exisits")
		elseif comp == -1 then
			window = true
		end
	end

	table.insert (self.Edges, new)
	if window then
		table.insert (self.Windows, new)
	end

	return self
end

function NavMesh:Make_hull (e0_index, ...)
	local E_Index_List = {e0_index, ...}
	
	local E_List = {}
	for i,I in ipairs (E_Index_List) do
		E_List [i] = self.Edges [I]
	end

	local hull = H2.New (E_List)
	return self
end

function NavMesh:Draw ()
	
end

return NavMesh
