
local myFunction = require("scripts.functions")

time = 0

function init()

	myFunction.start()

end

function step()

	myFunction.step()
	time = time + 1

end


function reset()

end

function destroy()

end

-- TODO:
--			Clutter
--			Transfer Time
--			'Dodge left' implementation??
--			Correlated Random Walk
-- 			Current Heading / Source Location