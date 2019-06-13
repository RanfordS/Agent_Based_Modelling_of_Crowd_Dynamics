--local Agent = require ("Agent")

local Heat_Map = {}
Heat_Map.Metatable =
{__index = Heat_Map}

-- Creates a new heat map object using the "Heat" function and "decay" parameter
-- with square "res" by "res" grid cells of the given "size", initialised to
-- zero.
function Heat_Map.New (Heat, decay, size, res, vec)
  local New = setmetatable (
  { Heat  = Heat
  , decay = decay
  , size  = size
  , res   = res
  , vec   = vec or false
  , sum   = 0
  }
  , Heat_Map.Metatable)
  for i = 1, res do
    local Sub = {}
    for j = 1, res do
      Sub [j] = vec and V2.New(0,0) or 0
    end
    New [i] = Sub
  end
  return New
end

function Heat_Map:Evaluate (dt)
  local omega = self.decay^dt
  for i = 1, self.res do
    for j = 1, self.res do
      self [i] [j] = self[i][j]*omega
    end
  end
  for _, agent in ipairs (Agent.List) do
    local i = 1 + math.floor (agent.pos.x / self.size)
    local j = 1 + math.floor (agent.pos.y / self.size)
    if i < 1 or i > self.res
    or j < 1 or j > self.res
    then
      --print ("Agent out of bounds")
    else
      local h = self.Heat (agent, dt)
      self [i] [j] = self[i][j] + h
      self.sum = self.sum + h
    end
  end
  return self
end

local function Colorise (v)
  local r,g,b = 0,0,0
  if v < 1 then
    r,g,b =  0 , 0 , v
  elseif v < 2 then
    r,g,b =  0 ,v-1, 1
  elseif v < 3 then
    r,g,b = v-2, 1 ,3-v
  elseif v < 4 then
    r,g,b =  1 ,4-v, 0
  else
    r,g,b =  1 ,v-4,v-4
  end
  return r,g,b
end

local function Colorise_light (v)
  v = 1 - 1/(v + 1)
  if v < 0.1 then
    r,g,b = 1 - v/0.1, 1, 1
  elseif v < 0.3 then
    r,g,b = 0, 1 - (v-0.1)/0.2, 1
  elseif v < 0.6 then
    local a = (v-0.3)/0.3
    r,g,b = a,0,1-a
  else
    r,g,b = 1, (v-0.6)/0.4, 0
  end
  return r,g,b
end

Heat_Map.Color = Colorise

function Heat_Map:Draw (alpha, lt, s)
  for i = 1, self.res do
    local x = (i-1)*self.size
    for j = 1, self.res do
      local y = (j-1)*self.size
      if self.vec then
        local x = x + self.size/2
        local y = y + self.size/2
        local v = self[i][j]
        local vn = v/10
        local t = vn:Perp()

        local n = V2.New (x,y) + 1*v
        local h1 = n - vn + t
        local h2 = n - vn - t

        love.graphics.setColor (1,0,0,alpha)
        love.graphics.line ((x-lt.x)*s, (y-lt.y)*s
        , (n.x-lt.x)*s, (n.y-lt.y)*s)
        love.graphics.line ((h1.x-lt.x)*s, (h1.y-lt.y)*s
        , (n.x-lt.x)*s, (n.y-lt.y)*s
        , (h2.x-lt.x)*s, (h2.y-lt.y)*s)
      else
        local r,g,b = Colorise (self[i][j])
        love.graphics.setColor (r,g,b, alpha)
        love.graphics.rectangle ("fill"
        , (x-lt.x)*s, (y-lt.y)*s
        , self.size*s, self.size*s)
      end
    end
  end
end

function Heat_Map:Export (path)
  local file = io.open (path, "w")
  for i = 1, self.res do
    for j = 1, self.res do
      local val = self[i][j]
      if self.vec then
        if val:Magnitude() > 0.1 then
          val = val/self.size
          file:write (("\\draw[-latex',line width=\\Rarrowscale] (%i,%i) -- ++(%f,%f);\n"):format(i,j,val.x,val.y))
        end
      else
        local r,g,b = Colorise_light (val)
        file:write (("\\definecolor{Heat}{rgb}{%.2f,%.2f,%.2f}\n\\draw[fill=Heat] (%i.5,%i.5) rectangle ++(1,1);\n"):format(r,g,b,i-1,j-1))
      end
    end
  end
  file:close ()
  print ("Heat_Map:Export("..path..") successful")
end

return Heat_Map
