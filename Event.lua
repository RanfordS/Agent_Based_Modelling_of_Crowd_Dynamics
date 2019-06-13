local Event = {}
Event.Metatable =
{__index = Event}

Event.List = {}

function Event.New (t)
  assert (type(t) == "number", "Expected t to be number")
  
  print ("Event.New", t)

  local New =
  { t = t      -- event timer
  , Hooks = {} -- functions called upon event complete
  , Dependencies = {}  -- events that must be completed before this event
  , completed = false
  }
  table.insert (Event.List, New)

  return setmetatable (New, Event.Metatable)
end

function Event:Is_satisfied ()
  for i,E in ipairs (self.Dependencies) do
    if E.completed == false then return false, i end
  end
  return true
end

function Event:Do_event ()
  for i,H in ipairs (self.Hooks) do
    H (self)
  end
end

function Event:Add_hook (hook)
  table.insert (self.Hooks, hook)
  return self
end

function Event:Parse ()
  local complete, id = self:Is_satisfied ()
  if complete then
    self:Do_event ()
    self.completed = true
    return true
  else--set timer to next incomplete event
    self.t = self.Dependencies[id].t
    return false
  end
end

local function Sort (e0, e1)
  return e0.t < e1.t
end

function Event.Tick (dt)
  assert (type(dt) == "number", "Expected dt to be number")
  for i,E in ipairs (Event.List) do
    E.t = E.t - dt
  end
  table.sort (Event.List, Sort)
  local i = 1
  while Event.List[i] and Event.List[i].t <= 0 do
    Event.List[i]:Parse()
    if Event.List[i].completed then
      table.remove (Event.List, i)
    else
      i = i + 1
    end
  end
end

return Event
