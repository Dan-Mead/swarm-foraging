
local myFunction = require("scripts.functions")

file = io.open("outputs/test.txt", "w")

file:write("New Beginnings\n")

t = 0

function init()

	myFunction.start()

end

function step()

	myFunction.step()
	t = t+1
	file:write(t .. "\n")
	
end


function reset()

	file:flush()
	file = io.open("outputs/test.txt", "a")
	myFunction.start()
--	file:close()
--	file:write(t .. "\n")
	t = 0	

end

function destroy()



end

