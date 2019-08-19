local export = {}

function export.header(goal)
	
	if goal == "target" then
		g = 1
	else
		g = 0
	end
	
	if robot.id == "fb1" then
		--log("--Start--")
		file = io.open(output_file_path, "w")
		file:write("---- \t   \tBegin Recorded Data\t   \t ---- \ntime \t | \trobot \t" ..
				"| \t goal \n1 = target\t 0 = base \n \n")
		file:close()
	end
		
	file = io.open(output_file_path, "a")
	file:write(time, " \t | \t", robot.id, " \t | \t", g, "\n")
	file:close()
		
end

function export.change_behaviour(goal)
	
	if goal == "target" then
		g = 1
	else
		g = 0
	end
	
	file = io.open(output_file_path, "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", g, "\n")
		file:close()
end


return export