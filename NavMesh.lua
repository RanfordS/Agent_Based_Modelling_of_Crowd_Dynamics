local V2 = require ("Vector2")

local NavMesh = { }
NavMesh.Metatable =
{__index = NavMesh}

function NavMesh.New ()
  return setmetatable (
  { Verticies = {}
  , Hulls     = {}
  }
  , NavMesh.Metatable)
end

function NavMesh:Add_vertex (pos)
  assert (V2.Is(pos), "Add vertex expected a Vector2")
  table.insert (self.Verticies, pos)
  return #self.Verticies
end

function NavMesh:Make_hull (Indicies)
  local New = Hull2.New (Indicies)
  if not New:Verify() then
    error ("Hull not convex\n".. table.concat (Indicies, ','))
  end
  table.insert (self.Hulls, New)
end

function NavMesh:Adjacency ()
  for h0, H0 in ipairs (self.Hulls) do
    for h1, H1 in ipairs (self.Hulls) do
      if h0 ~= h1 then
        for i0 = 1, H0.n do
          local j0 = i0 % H0.n + 1
          local vi0 = H0.Verticies [i0]
          local vj0 = H0.Verticies [j0]
          for i1 = 1, H1.n do
            local j1 = i1 % H1.n + 1
            local vi1 = H1.Verticies [i1]
            local vj1 = H1.Verticies [j1]

            if  vi0 == vj1
            and vi1 == vj0
            then
              H0.Adjacent [i0] = h1
              H1.Adjacent [i1] = h0
            end
          end
        end
      end
    end
  end
end

return NavMesh
