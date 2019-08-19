local fixes = require("scripts.fixes")
local controller = require("scripts.ducatelle")

--local controller = require("scripts.advanced_random_walk")

time = 0


function init()

	controller.start()
	
	
end

function step()

	fixes.run()

	controller.step()
	
	time = time + 1
	
	if robot.id == "fb0" then
		if time % 1000 == 0 then
			log(time)
		end
	end
end


function reset()

end

function destroy()

end

-- TODO:

-- Update constantly or move towards?
-- With roam or without

-- Update turning mechanism?? (in ducatelle and adv random walk)

-- Tuneable Constants:

			-- Step Length
			-- Standard Deviation of Normal
			-- Transmission Time

-- Only update s(T) if a target robot (seen target) - or if actually on target?
-- Need some interaction between origins, else oldest is always final.