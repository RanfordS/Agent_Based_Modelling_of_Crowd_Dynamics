path = os.tmpname ()
program = ("love /home/alex/Documents/Uni/2018-2019/Project/Program < %s")
:format (path)

for model = 1, 3 do
  for scenario = 1, 4 do
    print (model, scenario)
    local file = io.open (path, "w")
    file:write (model, "\n")
    file:write (scenario, "\n")
    file:close ()
    os.execute (program)
  end
end
