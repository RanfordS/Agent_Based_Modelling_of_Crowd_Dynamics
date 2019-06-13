V2 = require ("Vector2")
NM = require ("NavMesh")
Event = require ("Event")
--Agent = require ("Agent")
io.write ("Mode:\n1 - Basic\n2 - Kernel\n3 - Steering\n")
while true do
  local mode = tonumber (io.read ())
  if mode then
    mode = ({"Agent_Basic","Agent_Kernel","Agent_Steering","Agent_Steering_Mod"})[mode]
    if mode then
      Agent = require (mode)
      break
    end
  end
  io.write ("!!\n")
end
io.write ("./\n")

function Lerp_rand (l,u)
  return math.random()*(u-l) + l
end
Scenario = {}
function Scenario.Interference ()
  local y0 = Lerp_rand(40,50)
  local y1 = Lerp_rand(30,40)
  Agent.New (V2.New( 5,y0), V2.New(75,y0), math.rad(  0))
  Agent.New (V2.New(75,y1), V2.New( 5,y1), math.rad(180))
end
function Scenario.Cross ()
  Agent.New (V2.New( 5,Lerp_rand(35,45)), V2.New(75,Lerp_rand(35,45)), math.rad(  0))
  Agent.New (V2.New(Lerp_rand(35,45),75), V2.New(Lerp_rand(35,45), 5), math.rad( 90))
end
function Scenario.Counter ()
  Agent.New (V2.New( 5,Lerp_rand(35,45)), V2.New(75,Lerp_rand(35,45)), math.rad(  0))
  Agent.New (V2.New(75,Lerp_rand(35,45)), V2.New( 5,Lerp_rand(35,45)), math.rad(180))
end
function Scenario.Circular ()
  for i = 1, 2 do
    local theta0 = Lerp_rand (0,360)
    local theta1 = Lerp_rand (-90,90) + theta0 + 180
    local c = V2.New (40,40)
    Agent.New (35*V2.From_angle (math.rad(theta0)) + c
              ,35*V2.From_angle (math.rad(theta1)) + c
              ,math.rad(theta0 + 180))
  end
end
io.write ("Scenario:\n1 - Interference\n2 - Cross\n3 - Counter\n4 - Circular\n")
while true do
  local input = tonumber (io.read())
  if input then
    input = ({"Interference","Cross","Counter","Circular"})[input]
    if input then
      Scenario.active = Scenario[input]
      Scenario.name = input
      break
    end
  end
  io.write ("!!\n")
end
io.write ("./\n")
Heat_Map = require ("Heat_Map")

Map = {active = false}

function love.load ()
  Map.occupation = Heat_Map.New (function (a,dt)
    return dt
  end, 0.5, 5, 16)
  Map.congestion = Heat_Map.New (function (a,dt)
    return dt/(1 + a.vel:Magnitude()^3)
  end, 0.5, 5, 16)
  Map.flow = Heat_Map.New (function (a,dt)
    return dt*a.vel
  end, 0.8, 5, 16, true)
  -- Events
  local Prefix = string.format ("Res_%s/%s/", Agent.model, Scenario.name)
  Event.New( 40):Add_hook (function ()
    Map.occupation:Export (Prefix .. "040_occupation.tex")
    Map.congestion:Export (Prefix .. "040_congestion.tex")
    Map.flow      :Export (Prefix .. "040_flow.tex")
  end)
  Event.New( 80):Add_hook (function ()
    Map.occupation:Export (Prefix .. "080_occupation.tex")
    Map.congestion:Export (Prefix .. "080_congestion.tex")
    Map.flow      :Export (Prefix .. "080_flow.tex")
  end)
  Event.New(200):Add_hook (function ()
    Map.occupation:Export (Prefix .. "200_occupation.tex")
    Map.congestion:Export (Prefix .. "200_congestion.tex")
    Map.flow      :Export (Prefix .. "200_flow.tex")
    local stats_path = Prefix .. "stats"
    Agent.Stats.Write (stats_path)
    local stats_file = io.open (stats_path, "a")
    stats_file:write(("Total congestion: %.1f\n"):format(Map.congestion.sum))
    stats_file:close()
    love.event.quit (0)
  end)
end

timer   = 0
counter = 0
function love.update (dt)
	counter = counter + dt
  timer = timer + dt
	if counter > 0 then
		counter = counter - 4
    Scenario.active ()
	end

	Agent.Calculate_forces ()
	Agent.Step (dt)
  Map.occupation:Evaluate (dt)
  Map.congestion:Evaluate (dt)
  Map.flow:Evaluate (dt)
  Event.Tick (dt)
end

Camera =
{ pos = V2.New (0,0)
, scale = 7.5
}

function love.draw ()
	love.graphics.setBlendMode ("add")
	love.graphics.setColor (1,1,1,1)

  if Map.active then
    --love.graphics.setLineWidth (1)
    Map.active:Draw (0.5, Camera.pos, Camera.scale)
    --love.graphics.setLineWidth (1)
  end

	Agent.Draw_all (Camera.pos, Camera.scale)

  -- kernel visual
  if view_kernel then
    love.graphics.setColor (1,1,1,.1)
    love.graphics.setPointSize (1)
    for x=0,800,2 do
      for y=0,600,2 do
        local sum = 0
        local tst = (V2.New(x,y) / Camera.scale) + Camera.pos
        for i=1,#Agent.List do
          local ker = Agent.List[i]:Kernel(tst)
          if ker then sum = sum + ker end
        end
        if sum > 0 then
          love.graphics.setColor (0.5*sum,0.45*sum,0.40*sum,1)
          love.graphics.points (x,y)
        end
      end
    end
  end
  love.graphics.setColor (1,1,1,1)
  love.graphics.printf (string.format ("%.1f", timer), 10, 580, 780, "right")
  if display_help then
    love.graphics.setBlendMode ("alpha", "alphamultiply")
    love.graphics.setColor (0,0,0,0.5)
    love.graphics.rectangle ("fill",10,10,160,580)
    love.graphics.setColor (1,1,1,1)
    love.graphics.printf (
[[Help:
c - congestion map
f - flow map
h - help
k - kernel preview
o - occupation
]],10,10,160)
  end
end

local function Do_switch (case, cases)
  if cases [case] then
    return cases [case] ()
  end
end

--abcdefghijklmnopqrstuvwxyz--
--  #  # #  #   #           --
local Keypressed_Cases =
{ c = function ()
    if Map.active == Map.congestion then
      Map.active = false
    else
      Map.active = Map.congestion
    end
    print ("congestion", Map.active == Map.congestion)
  end
, f = function ()
    if Map.active == Map.flow then
      Map.active = false
    else
      Map.active = Map.flow
    end
    print ("flow", Map.active == Map.flow)
  end
, h = function ()
    display_help = not display_help
    print ("help", display_help)
  end
, k = function ()
    view_kernel = not view_kernel
    print ("kernel", view_kernel)
  end
, o = function ()
    if Map.active == Map.occupation then
      Map.active = false
    else
      Map.active = Map.occupation
    end
    print ("occupation", Map.active == Map.occupation)
  end
, p = function ()
    Map.flow:Export ("HMF-"..Agent.model..".tex")
    Map.congestion:Export ("HMC-"..Agent.model..".tex")
  end
}

function love.keypressed (key, scancode, is_repeat)
   Do_switch (key, Keypressed_Cases)
end

