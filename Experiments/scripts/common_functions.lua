local common = {proportion_foraging}

function common.setup()
	
	tumble_distance = 200 --robot.random.gaussian(RW_stdev, RW_mean)
	
	current_state = "exploring"
	current_behaviour = "roaming"
	
	if robot.random.bernoulli(proportion_foraging) == 1 then
		goal = "target"
	else
		goal = "base"
	end		
	
	if goal == "base" then
		robot.leds.set_all_colors(255, 255, 0)
	elseif goal == "target" then
		robot.leds.set_all_colors(0, 255, 255)
	end
		
end

function common.update()
	
	last_step = 0.5 * (robot.wheels.distance_left + robot.wheels.distance_right)
	
	distance_travelled = distance_travelled + last_step
	
	step_distance = step_distance + last_step
	
	num_received_broadcasts = #robot.range_and_bearing
	
	if num_received_broadcasts > 0 then
				
		for i = 1,num_received_broadcasts do
	
			if robot.range_and_bearing[i].data[1] == 1 and robot.range_and_bearing[i].data[2] == 0 then
				
				current_location = "base"
				
				beacon.base.distance = robot.range_and_bearing[i].range				
				beacon.base.range = robot.range_and_bearing[i].range
				beacon.base.bearing = robot.range_and_bearing[i].horizontal_bearing + robot.true_orientation
				
				beacon.base.bearing = angle_check(beacon.base.bearing)
				
				beacon.base.time = robot.range_and_bearing[i].data[3] * 250 + robot.range_and_bearing[i].data[4]
			
			elseif robot.range_and_bearing[i].data[1] == 1 and robot.range_and_bearing[i].data[2] == 1 then
				
				current_location = "target"
				
				beacon.target.distance = robot.range_and_bearing[i].range
				beacon.target.range = robot.range_and_bearing[i].range
				beacon.target.bearing = robot.range_and_bearing[i].horizontal_bearing + robot.true_orientation
				
				beacon.target.bearing = angle_check(beacon.target.bearing)
				
				beacon.target.time = robot.range_and_bearing[i].data[3] * 250 + robot.range_and_bearing[i].data[4]
			
			end
		end
	end
	
	if current_location ~= "base" and current_location ~= "target" then
		current_location = "transit"
	end
	
	if beacon.base.range then
		landmark_update(beacon.base)
	end
	
	if beacon.target.range then
		landmark_update(beacon.target)
	end
	
end


function landmark_update(input_location)
	
	bot_x = last_step * math.cos(robot.true_orientation)
	bot_y = last_step * math.sin(robot.true_orientation)
	
	base_x = input_location.range * math.cos(input_location.bearing + math.pi)
	base_y = input_location.range * math.sin(input_location.bearing + math.pi)
	
	new_x = bot_x + base_x
	new_y = bot_y + base_y
	
	input_location.range = math.sqrt(math.pow(new_x, 2) + math.pow(new_y, 2))
	
	input_location.bearing = math.atan2(new_y, new_x) - math.pi
	
	input_location.bearing = angle_check(input_location.bearing)
	
end

function common.avoid(num) -- 5, 20
	
	prox_sensors = {left = 0, right = 0}
	
	for i = 1,24 do
		if i <= num then
			prox_sensors.left = prox_sensors.left + robot.proximity[i].value
		elseif i >= (25 - num) then 
			prox_sensors.right = prox_sensors.right + robot.proximity[i].value

		end
	end
	
	if prox_sensors.right ~= 0 then
		robot.wheels.set_velocity(-dv/2, dv)
	elseif prox_sensors.left ~= 0 then
		robot.wheels.set_velocity(dv, -dv/2)		
	end	
	
end


function common.turn(angle)
	
	heading_error = angle - (robot.wheels.distance_right - robot.wheels.distance_left) / robot.wheels.axis_length
	
	current_behaviour = "turning"
	
end

function common.update_leds()
	
	if goal == "base" then
		--robot.leds.set_all_colors("green")
		robot.leds.set_all_colors(255, 255, 0)
	elseif goal == "target" then
		--robot.leds.set_all_colors("red")
		robot.leds.set_all_colors(0, 255, 255)

	end
	
	if goal == "base" and current_behaviour == "moving_to_location" then
		robot.leds.set_all_colors(0, 0, 0)
	elseif goal == "target" and current_behaviour == "moving_to_location" then
		robot.leds.set_all_colors(255, 255, 255)
	end
	
end	
		

function angle_check(angle)
	
	if angle > 2 * math.pi then
		angle = angle - 2 * math.pi
	elseif angle < 0 then
		angle = angle + 2 * math.pi
	end
	
	return angle
end

function common.angle_check(angle)
	
	if angle > 2 * math.pi then
		angle = angle - 2 * math.pi
	elseif angle < 0 then
		angle = angle + 2 * math.pi
	end
	
	return angle
end

function common.angle_check_turn(angle)
	
	if angle > math.pi then
		angle = angle - 2 * math.pi
	elseif angle < -math.pi then
		angle = angle + 2 * math.pi
	end
	
	return angle
end

function common.neaten_tables()
	
	output_probs = nil
	probs = nil
	goal_probs = nil
	heading_distribution = nil
end



return common