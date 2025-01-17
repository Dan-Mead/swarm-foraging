local fixes = require("scripts.fixes")
local common = require("scripts/common_functions")
local c_comms = require("scripts/composite_comms")
local export = require("scripts/write_functions")
local variables = require("scripts/variables")
local ksp = require("scripts/kasprzok_equations")

-- Instantiation --

time = 0

behaviour = {}
state = {}

distance_travelled = 0
step_distance = 0

beacon = {base, target}
beacon.base = {identifier, range, bearing, distance, time} 		-- identifier allows for multiple beacons (currently unimplemented), range and bearing are for site fidelity, distance and time are for Ducatelle
beacon.target = {identifier, range, bearing, distance, time}


-- Constants --

dv = 10															-- default speed
max_speed = 30

prox_check = 5

heading_error_margin = math.pi * 2 / 180 
turning_p_gain = 10

-- Tunables --

proportion_foraging = variables.prop_foraging
tps = variables.tps

RW_mean = variables.rwm
RW_stdev = RW_mean/3

RW_gain = variables.rwg

k_val = {self, bias}
k_val.self = variables.k_self
k_val.bias = variables.k_bias								

composite_check_rate = variables.c_check								-- ## Ducatelle Addition

output_file_path = "outputs/" .. variables.output_path .. ".txt"

function init()
	
	common.setup()
	
	robot.id_number = tonumber(string.sub(robot.id, (-#robot.id + 2))) -- would have to be implemented in real life but for simulation this is acceptable
	
	--beacon.base.range = 0
	--beacon.base.bearing = robot.positioning.orientation.angle + math.pi
	--beacon.base.bearing = common.angle_check_turn(beacon.base.bearing)
	--beacon.base.distance = 0
	--beacon.base.time = 0
	
	export.header(goal)
	
end

function step()
	
	fixes.run()
	
	time = time + 1
	
	common.update()
	common.update_leds()
	
	change_time(goal)
	
	c_comms.receive_and_send() 								-- ## Ducatelle Addition
	
	if time > (composite_check_rate * tps) and time % (composite_check_rate * tps) == 1 then
		check_comms_for_goal(goal)
		update_biases()
	end
		
	behaviour[current_behaviour]()
	
	goal_check()
	
	--if robot.id == "fb1" then robot.leds.set_all_colors(0, 0, 0) end
		
end

--------------------------------------------------------------------------------------------------------------------------

function goal_check()
			
	if current_location == goal then
		
		if goal == "target" then
		
			current_state = "returning"
			current_behaviour = "roaming"
			log(robot.id .. " returning to nest...")

			goal = "base"
			
			if beacon.base.bearing then
				goal_bearing = beacon.base.bearing - robot.true_orientation
			end			
		elseif goal == "base" then
		
			current_state = "foraging"
			current_behaviour = "roaming"
			log(robot.id .. " re-foraging...")
			
			goal = "target"
			if beacon.target.bearing then
				goal_bearing = beacon.target.bearing - robot.true_orientation
			end
			
		end
		
		export.change_behaviour(goal)
		
		robot.wheels.set_velocity(0,0)
		
		if goal_bearing then
			
			goal_bearing = common.angle_check_turn(goal_bearing)
		
			common.turn(goal_bearing)
			
			desired_heading = desired_heading_calc(goal_bearing)
		
		else
			goal_bearing = math.pi
		end
		
		common.turn(goal_bearing)
			
		desired_heading = desired_heading_calc(goal_bearing)
		
	
	end

end

function behaviour.roaming()
	
	robot.wheels.set_velocity(dv,dv)
	
	if step_distance > tumble_distance then
				
		random_walk_tumble()
		
	end
	
	for i = 1,24 do				-- run avoidance if a proximity sensor is tripped
		if i <= prox_check or i >= (25-prox_check) then
			if robot.proximity[i].value > 0 then
				
				--if check_obstruction() == false then
				--	common.avoid(prox_check)
				--else	
				--	adv_dodge(prox_check)
				--end
				common.avoid(prox_check)
				break
			end
		end
	end
	
end


function behaviour.turning()
	
	heading_error = heading_error - (robot.wheels.distance_right - robot.wheels.distance_left) / robot.wheels.axis_length
			
	v = heading_error * turning_p_gain
	
	if math.abs(v) > max_speed then
		v = max_speed * math.abs(v) / v
	end
	
	if math.abs(heading_error) > heading_error_margin then
		
		robot.wheels.set_velocity(-v, v)
	
	else
		
		desired_heading = nil
		
		current_behaviour = 'roaming'
		
	end
end

function behaviour.moving_to_location()
		
	heading_error = heading_error - (robot.wheels.distance_right - robot.wheels.distance_left) /robot.wheels.axis_length
	
	heading_error = common.angle_check_turn(heading_error)
	
	v = heading_error * turning_p_gain
	
	if math.abs(v) > max_speed then
		v = max_speed * math.abs(v) / v
	end
	
	if heading_error > heading_error_margin or heading_error < -heading_error_margin then
		
		robot.wheels.set_velocity(-v, v)
		
	elseif step_distance < location_range then
		
		robot.wheels.set_velocity(dv,dv)
		
	else
		robot.wheels.set_velocity(dv,dv)
		--random_walk_tumble()
		
		desired_heading = nil
		
		current_behaviour = "roaming"
		
	end
	
	for i = 1,24 do				-- run avoidance if a proximity sensor is tripped
		if i <= prox_check or i >= (25-prox_check) then
			if robot.proximity[i].value > 0 then
				
				if check_obstruction() == false then
					current_behaviour = "roaming"
					common.avoid(prox_check)
				end
				
				common.avoid(prox_check)
				--adv_dodge(prox_check)
				
				break
			end
		elseif robot.proximity[i].value > 0 then
			robot.wheels.set_velocity(dv,dv)
		end
	end

end

--------------------------------------------------------------------------------------------------------------------------

function random_walk_tumble()
	
	if current_state == "exploring" then
		
		RW_mean = RW_mean * RW_gain
		
		RW_stdev = RW_mean / 3
		
	end
	
	probs, sum = ksp.von_mises_pdf(0, k_val.self)
	
	if goal == "target" and beacon.target.bearing then

		landmark_direction = (beacon.target.bearing - robot.true_orientation)

		goal_probs, goal_sum = ksp.von_mises_pdf(landmark_direction, k_val.bias)

		probs, sum = ksp.combine_pdf(probs, sum, goal_probs, goal_sum)

	elseif goal == "base" and beacon.base.bearing then

		landmark_direction = (beacon.base.bearing - robot.true_orientation)

		goal_probs, goal_sum = ksp.von_mises_pdf(landmark_direction, k_val.bias)

		probs, sum = ksp.combine_pdf(probs, sum, goal_probs, goal_sum)

	end
	
	heading_distribution = {angles = probs, total = sum}

	new_angle = ksp.sample_pdf(heading_distribution)
		
	tumble_distance = math.abs(robot.random.gaussian(RW_stdev, RW_mean))
	
	new_angle = common.angle_check_turn(new_angle)
	
	common.turn(new_angle)
	
	desired_heading = desired_heading_calc(new_angle)
	
	step_distance = 0
		
	common.neaten_tables() -- neatens tables a bit
	
end


function check_comms_for_goal(goal)

	if lowest_ids[goal] ~= 0 then
		
		num_contacts = 0
		
		for i = 1, #robot.range_and_bearing do
			if robot.range_and_bearing[i].data[1] == 2 then
				num_contacts = num_contacts + 1
			end
		end
		
		if num_contacts == 1 then
		
			heading = robot.range_and_bearing[lowest_ids[goal]].data[8] * 2 * math.pi / 180 - robot.true_orientation

			bearing = robot.range_and_bearing[lowest_ids[goal]].horizontal_bearing

			target_direction = (heading + math.pi) + math.pi/4 * math.sin(heading - bearing)

			target_direction = common.angle_check_turn(target_direction)

			desired_heading = desired_heading_calc(target_direction)
		
			heading_error = target_direction

			--location_range = math.abs(robot.random.gaussian(RW_stdev, RW_mean))
			location_range = robot.range_and_bearing[lowest_ids[goal]].range
			
		elseif num_contacts > 1 then
			
			range = robot.range_and_bearing[lowest_ids[goal]].range
			bearing = robot.range_and_bearing[lowest_ids[goal]].horizontal_bearing

			heading_error = bearing + math.tan(3 * robot.wheels.axis_length / range)

			location_range = range
		
		end

		step_distance = 0

		current_behaviour = "moving_to_location"	

	end
	
end

function change_time(goal)										-- correction from legacy code
			
	if current_location == "base" then
		beacon.base.time = 0
	elseif current_location == "target" then
		beacon.target.time = 0
	end
end

function check_obstruction()
	
	obstruction = false
	
	for i = 1,#robot.range_and_bearing do
		
		if math.abs(robot.range_and_bearing[i].horizontal_bearing) < math.abs(robot.proximity[prox_check+2].angle) and robot.range_and_bearing[i].range < 35 then -- maybe less?
			obstruction = true
			break
		end
	end
	
	return obstruction

end

function adv_dodge(num)
	
	prox_sensors = {front = 0, left = 0, right = 0}
	
	for i = 1,24 do
		if i <= 3 or i >= 22 then
			prox_sensors.front = prox_sensors.front + robot.proximity[i].value
		elseif i <= num then
			prox_sensors.left = prox_sensors.left + robot.proximity[i].value
		elseif i >= (25 - num) then 
			prox_sensors.right = prox_sensors.right + robot.proximity[i].value

		end
	end
	
	if prox_sensors.right ~= 0 or prox_sensors.front ~= 0 then
		robot.wheels.set_velocity(-dv/2, dv)
	elseif prox_sensors.left ~= 0 then
		robot.wheels.set_velocity(dv, -dv/2)		
	end	
	
end

function desired_heading_calc(angle)
	
	desired_heading = angle + robot.true_orientation
	
	desired_heading = common.angle_check(desired_heading)
	
	return desired_heading

end
	
function update_biases()
	
	if goal == "target" and beacon.target.distance then
		r_d = beacon.target.range / beacon.target.distance
	elseif goal == "base" and beacon.base.distance then
		r_d = beacon.base.range / beacon.base.distance
	else
		r_d = 1
	end
	
	k_val.self = variables.k_self / r_d
	k_val.bias = variables.k_bias * r_d
	
	if k_val.self > 50 then
		k_val.self = 50
	end
end
