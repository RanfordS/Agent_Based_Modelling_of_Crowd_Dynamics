local V2 = require ("Vector2")

local Hull2 = { }
Hull2.Metatable =
{__index = Hull2}

function Hull2.New (Indicies)
  local New =
  { Verticies = {}
  , Adjacent  = {}
  , n = #Indicies
  }
  for i = 1, New.n do
    New.Verticies [i] = Indicies[i]
    New.Adjacent  [i] = false
  end
  return setmetatable (New, Hull2.Metatable)
end

function Hull2:Contains (p, V)
  for i = 1, self.n do
    local j = i % self.n + 1
    local v0, v1 = V[i], V[j]
    local r = p - v0
    local n = (v1 - v0):Perp()
    if r:Dot(n) < 0 then
      return false
    end
  end
  return true
end

function Hull2:Verify (V)
  for i = 1, self.n do
    local j = i % self.n + 1
    local k = j % self.n + 1
    local v0, v1, v2 = V[i], V[j], V[k]
    local r =  v2 - v0
    local n = (v1 - v0):Perp()
    if r:Dot(n) < 0 then
      return false
    end
  end
  return true
end

return Hull2
