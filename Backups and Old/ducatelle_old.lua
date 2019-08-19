local common = require("scripts/common_functions")
local comms = require("scripts/ducatelle_comms")

local functions = {}

behaviour = {}
state = {}

distance_travelled = 0

random_walk_dist_max = 400 -- no global time so must use local distances [400,50]
random_walk_dist_min = 50

base_location = {distance = 0, angle = 0, reference = 0}
target_location = {distance = 0, angle = 0, reference = 0} -- these may not be required for Ducatelle method

broadcast_data = {}
broadcast_info = {base, target} -- info is the values evaluated at each timestep, fed into data
broadcast_info.base = {distance, time}
broadcast_info.target = {distance, time}

counter = 0
broadcast_counter_reset = 400

heading_error_margin = math.pi * 2 / 180 
turning_p_gain = 10


comm_type = "ducatelle"
test_type = "ducatelle_broadcast_time"
test_variable = broadcast_counter_reset

output_file_path = "outputs/" .. comm_type .. "_" .. test_variable .. ".txt"



function functions.start()
	
	current_state = "exploring"		 	-- state is the current task, defines mainly the appearance of the robot
	current_behaviour = "roaming" 		-- behaviour defines the instantaneous action
	
	tumble_distance = robot.random.uniform_int(random_walk_dist_min, random_walk_dist_max)
	
	robot.leds.set_all_colors("red")
	
	if robot.id == "fb0" then
		--log("--Start--")
		file = io.open(output_file_path, "w")
		file:write("---- \t   \tBegin Recorded Data\t   \t ---- \n time \t | \trobot \t" ..
				"| \t behaviour \n1 = foraging\t 0 = returning \n \n")
		file:close()
		
	end
	
	--log(robot.id .. " foraging...")
	
	file = io.open(output_file_path, "a")
	file:write(time, " \t | \t", robot.id, " \t | \t", 1, "\n")
	file:close()
	
	broadcast_info.base.distance = math.huge
	broadcast_info.base.time = 0
	
	broadcast_info.target.distance = math.huge
	broadcast_info.target.time = 0
	
	
end


function functions.step()
	
	if robot.id == "fb0" then
		--log()
		
	end
	
	counter = counter + 1
	
	if robot.id == "fb00" then
		robot.leds.set_all_colors("black")	
		log(current_behaviour)
		
		log("Target Distance: ", broadcast_info.target.distance)
		log("Target Time: ", broadcast_info.target.time)
		
	end
	
	common.update()
	common.ground_check() -- check current location
	common.update_leds()
		
	state[current_state]()
	behaviour[current_behaviour]()
	
	if robot.id == "fb0" then
		robot.leds.set_all_colors("black")			
	end
	
	
	--log(robot.id, " Target Distance: ", broadcast_info.target.distance)
	--log(robot.id, " Target Time: ", broadcast_info.target.time)
	
end

-----------------------------------------------------------------------------------------------------------------------

function state.exploring()					-- first state
	
	goal = "target"
			
	base_location = common.landmark_update(base_location) 	-- update distance to base landmark
	
	comms.receive_and_send()
	
	check_comms_for_goal(goal)
		
	-- if all sensors read ground, return to base
	if current_location == goal then
		
		current_state = "returning"
		current_behaviour = "roaming"
		log(robot.id .. " returning to nest...")
		
		target_location = {distance = 0, angle = 0, reference = 0}
		
		-- Record on file
		
		file = io.open(output_file_path, "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", 0, "\n")
		file:close()
	
	end

end

function state.foraging()
	
	goal = "target"
		
	base_location = common.landmark_update(base_location)
	target_location = common.landmark_update(target_location)
	
	comms.receive_and_send()
	
	check_comms_for_goal(goal)
	
	-- if all sensors read ground, return to base
	if current_location == goal then
		
		current_state = "returning"
		current_behaviour = "roaming"
		log(robot.id .. " returning to nest...")
		
		target_location = {distance = 0, angle = 0, reference = 0}
		
		-- Record on file
		
		file = io.open(output_file_path, "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", 0, "\n")
		file:close()

	end

end

function state.returning()
	
	goal = "base"
	
	base_location = common.landmark_update(base_location)
	target_location = common.landmark_update(target_location)
	
	comms.receive_and_send()
	
	check_comms_for_goal(goal)
		
	if current_location == goal then
		current_state = "foraging"
		current_behaviour = "roaming"
		log(robot.id .. " re-foraging...")
		
		base_location = {distance = 0, angle = 0, reference = 0}
		
		file = io.open(output_file_path, "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", 1, "\n")
		file:close()
		
	end
	
end

--------------------------------------------------------------------------------------------------------------------------

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

function behaviour.moving_to_location()
		
	heading_error = heading_error - (robot.wheels.distance_right - robot.wheels.distance_left) /robot.wheels.axis_length
	
	heading_error = angle_check_turn(heading_error)
	
	v = heading_error * turning_p_gain
	
	if math.abs(v) > 8 then
		v = 8 * math.abs(v) / v
	end
	
	if heading_error > heading_error_margin or heading_error < -heading_error_margin then
		robot.wheels.set_velocity(-v, v)
	elseif distance_travelled < location_range then
		
		v = 8
		
		robot.wheels.set_velocity(v,v)
	else
		random_walk_tumble()
		current_behaviour = "waiting"
		
		--robot.wheels.set_velocity(8,8)
		
	end
	
	for i = 1,24 do				-- run avoidance if a proximity sensor is tripped
		if robot.proximity[i].value > 0 then
			common.avoid()
			--dodge()
			break
		end
	end

end

function behaviour.waiting()
	robot.wheels.set_velocity(0, 0)
end

function dodge()
	
	prox_sensors = {left = 0, right = 0}
	
	for i = 1,24 do
		if i <= 3 then
			prox_sensors.left = prox_sensors.left + robot.proximity[i].value
		elseif i >= 22 then 
			prox_sensors.right = prox_sensors.right + robot.proximity[i].value

		end
	end
	
	if prox_sensors.right ~= 0 then
		robot.wheels.set_velocity(-4, 8)
	elseif prox_sensors.left ~= 0 then
		robot.wheels.set_velocity(8, -4)
	else
		--robot.wheels.set_velocity(8,8)
		
	end	
	
	
end

function dodge_complex()
	
	avoid_gain = 8
	avoid_decay = 0.85
	
	prox_sensors = {left = 0, right = 0}
	
	for i = 1,24 do
		if i <= 8 then
			prox_sensors.left = prox_sensors.left + robot.proximity[i].value
		elseif i >= 17 then 
			prox_sensors.right = prox_sensors.right + robot.proximity[i].value

		end
	end
	
	v_l = avoid_gain * (prox_sensors.left)
	v_r = avoid_gain * (prox_sensors.right)
	
	if v_r >= v_l then
		v_l = -v_r * 0.5
		
	else
		v_r = -v_l * 0.5
	end
	
	v_l = robot.wheels.velocity_left * avoid_decay + v_l
	if math.abs(v_l) > 8 then
		v_l = 8 * math.abs(v_l) / v_l
	end
	
	v_r = robot.wheels.velocity_right * avoid_decay + v_r
	if math.abs(v_r) > 8 then
		v_r = 8 * math.abs(v_r) / v_r
	end
	
	if prox_sensors.left ~= 0 or prox_sensors.right ~= 0 then
		robot.wheels.set_velocity(v_l + 1, v_r + 1)
	else
		robot.wheels.set_velocity(8,8)
	end
	
	
end
	

function random_walk_tumble()
	
	if current_state == "exploring" then
		random_walk_dist_max = 1.25 * random_walk_dist_max -- needs improving/tuning

		new_angle = robot.random.gaussian(1, 0) -- from Hecker et al., needs tuning

	else
		new_angle = robot.random.gaussian(0.5, 0)

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

function check_comms_for_goal(goal)
	
	if counter == 1 then
		
		check_receieved_data() 					-- update all tables with best data, return best info for navigating
		
		if robot.id == "fb0" then
		end
		
		if lowest_ids[goal] ~= 0 then
			
			--log(robot.id, " changing")
			
			range = robot.range_and_bearing[lowest_ids[goal]].range
			bearing = robot.range_and_bearing[lowest_ids[goal]].horizontal_bearing
			
			heading_error = bearing + math.tan(2.5 * robot.wheels.axis_length / range)
			
			location_range = range + distance_travelled
			
			current_behaviour = "moving_to_location"
		end
	end
end

return functions
