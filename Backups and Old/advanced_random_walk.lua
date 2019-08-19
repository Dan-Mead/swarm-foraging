local common = require("scripts/common_functions")

local functions = {}

behaviour = {}
state = {}

distance_travelled = 0

random_walk_dist_max = 400 -- no global time so must use local distances
random_walk_dist_min = 50

base_location = {distance = 0, angle = 0, reference = 0}
target_location = {distance = 0, angle = 0, reference = 0}

heading_error_margin = math.pi * 2 / 180 
turning_p_gain = 10

function functions.start()
	
	current_state = "exploring"		 	-- state is the current task, defines mainly the appearance of the robot
	current_behaviour = "roaming" 		-- behaviour defines the instantaneous action
	current_location = "base"			-- location defines the region the robot currently recognises itself as being on
	
	tumble_distance = robot.random.uniform_int(random_walk_dist_min, random_walk_dist_max)
	
	robot.leds.set_all_colors("red")
	
	if robot.id == "fb0" then
		--log("--Start--")
		file = io.open("outputs/foraging_results.txt", "w")
		file:write("---- \t   \tBegin Recorded Data\t   \t ---- \n time \t | \trobot \t" ..
				"| \t behaviour \n1 = foraging\t 0 = returning \n \n")
		file:close()
		
	end
	
	--log(robot.id .. " foraging...")
	
	file = io.open("outputs/foraging_results.txt", "a")
	file:write(time, " \t | \t", robot.id, " \t | \t", 1, "\n")
	file:close()
	
end


function functions.step()
	
	common.update()
	
	state[current_state]()
	behaviour[current_behaviour]()
	
	if robot.id == "fb0" then
		--log(base_location.distance, "\n", 180 * base_location.reference / math.pi)
		--log(target_location.distance, "\n", 180 * target_location.reference / math.pi, "\n" )
	end
	
end

function state.exploring()					-- first state
	
	common.ground_check()
		
	base_location = common.landmark_update(base_location)		
		
	-- if all sensors read ground, return to base
	if current_location == "target" then
		
		current_state = "returning"
		log(robot.id .. " returning to nest...")
		robot.leds.set_all_colors("green")
		
		target_location = {distance = 0, angle = 0, reference = 0}
		
		-- Record on file
		
		file = io.open("outputs/foraging_results.txt", "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", 0, "\n")
		file:close()
	end

end

function state.foraging()
	
	common.ground_check()
		
	base_location = common.landmark_update(base_location)
	target_location = common.landmark_update(target_location)		
		
	-- if all sensors read ground, return to base
	if current_location == "target" then
		
		current_state = "returning"
		log(robot.id .. " returning to nest...")
		robot.leds.set_all_colors("green")
		
		target_location = {distance = 0, angle = 0, reference = 0}
		
		-- Record on file
		
		file = io.open("outputs/foraging_results.txt", "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", 0, "\n")
		file:close()
	end

end

function state.returning()
	
	common.ground_check()
	
	base_location = common.landmark_update(base_location)
	target_location = common.landmark_update(target_location)
		
	if current_location == "base" then
		current_state = "foraging"
		log(robot.id .. " re-foraging...")
		robot.leds.set_all_colors("red")
		
		base_location = {distance = 0, angle = 0, reference = 0}
		
		file = io.open("outputs/foraging_results.txt", "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", 1, "\n")
		file:close()
	end
	
end

function behaviour.roaming()
	
	robot.wheels.set_velocity(8,8)
	
	if tumble_distance < distance_travelled then
				
		random_walk_tumble()
		
	end
		
	for i = 1,24 do				-- run avoidance if a proximity sensor is tripped
		if robot.proximity[i].value > 0 then
			common.avoid()
			break
		end
	end
end


function behaviour.turning()
	
	heading_error = heading_error - (robot.wheels.distance_right - robot.wheels.distance_left) /robot.wheels.axis_length
			
	v = heading_error * turning_p_gain
	
	if v > 8 then
		v = 8
	elseif v < -8 then
		v = -8
	end
	
	if heading_error > heading_error_margin or heading_error < -heading_error_margin then
		
		robot.wheels.set_velocity(-v, v)
	
	else
		
		current_behaviour = 'roaming'
		
		robot.wheels.set_velocity(8,8)
		
	end
end

function random_walk_tumble()
	
	if current_state == "exploring" then
		random_walk_dist_max = 1.25 * random_walk_dist_max -- needs improving/tuning

		new_angle = robot.random.gaussian(1, 0) -- from Hecker et al., needs tuning

	elseif current_state == "foraging" then

		new_angle = robot.random.gaussian(2, robot.true_orientation - target_location.reference) -- mixed signs a bit here

	elseif current_state == "returning" then

		new_angle = robot.random.gaussian(2, robot.true_orientation - base_location.reference)

	end

	tumble_distance = distance_travelled + robot.random.uniform_int(random_walk_dist_min, random_walk_dist_max)
	

	new_angle = angle_check_turn(new_angle)
	
	common.turn(new_angle)
	
end

function angle_check_turn(angle)
	
	if angle > math.pi then
		angle = angle - 2 * math.pi
	elseif angle < -math.pi then
		angle = angle + 2 * math.pi
	end
	
	return angle
end

return functions
