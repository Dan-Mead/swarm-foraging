local functions = {}

behaviour = {}
state = {}

random_walk_time_max = 400
random_walk_time_min = 50


function functions.start()
	
	current_state = "foraging"		 	-- state is the current task, defines mainly the appearance of the robot
	current_behaviour = "roaming" 		-- behaviour defines the instantaneous action
	
	tumble_time = time + robot.random.uniform_int(random_walk_time_min, random_walk_time_max) 
	
	
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
	
	state[current_state]()
	behaviour[current_behaviour]()
	
	
	

end


function state.foraging()
	
	ground_sensors_on, activated_sensor = ground_check()
	
	-- if all sensors read ground, return to base
	if ground_sensors_on == 4 then
		current_state = "returning"
		log(robot.id .. " returning to nest...")
		robot.leds.set_all_colors("green")

		-- Record on file
		
		file = io.open("outputs/foraging_results.txt", "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", 0, "\n")
		file:close()
		
	-- else, turn towards a sensor if rear sensor activated
		
	elseif ground_sensors_on == 1 then

		if activated_sensor == 2 then
			angle = 3 * - math.pi/4
			turn(angle)
		elseif activated_sensor == 3 then
			angle = 3*math.pi/4
			turn(angle)
		end
	end
end

function state.returning()
	
	ground_sensors_on, activated_sensor = ground_check()
	
	if ground_sensors_on == 4 then
		current_state = "foraging"
		log(robot.id .. " re-foraging...")
		robot.leds.set_all_colors("red")
		
		file = io.open("outputs/foraging_results.txt", "a")
		file:write(time, " \t | \t", robot.id, " \t | \t", 1, "\n")
		file:close()
	
	elseif ground_sensors_on == 1 then
		
		if activated_sensor == 2 then
			angle = 3 * - math.pi/4
			turn(angle)
		elseif activated_sensor == 3 then
			angle = 3*math.pi/4
			turn(angle)
		end
	end
end



function behaviour.roaming()
	
	robot.wheels.set_velocity(8,8)
	
	if tumble_time < time then
		tumble_time = time + robot.random.uniform_int(random_walk_time_min, random_walk_time_max)
		new_angle = robot.random.uniform(-math.pi, math.pi)
		turn(new_angle)
	end
	
		
	for i = 1,24 do				-- run avoidance if a proximity sensor is tripped
		if robot.proximity[i].value > 0 then
			avoid()
			break
		end
	end
	
end



function ground_check()
	
	ground_sensors_on = 0
	
	if current_state == "foraging" then
	
		for i = 1,4 do
			if robot.motor_ground[i].value < 0.1 then
				ground_sensors_on = ground_sensors_on + 1
				activated_sensor = i
			end
		end
	
	elseif current_state == "returning" then
		
		for i = 1,4 do
			if robot.motor_ground[i].value > 0.9 then
				ground_sensors_on = ground_sensors_on + 1
				activated_sensor = i
			end
		end
	end
	
	return ground_sensors_on, activated_sensor
end



function avoid()
	
	left_sensors = 0
	right_sensors = 0
	
	for i = 1,24 do
		if i < 10 then -- 7 for wall following, 10 for bounce
			left_sensors = left_sensors + robot.proximity[i].value
		elseif i > 14 then -- 18 for wall following, 14 for bounce
			right_sensors = right_sensors + robot.proximity[i].value
		end
	end
	
	if right_sensors ~= 0 then
		robot.wheels.set_velocity(-4, 8)
	elseif left_sensors ~= 0 then
		robot.wheels.set_velocity(8,-4)
	else
		robot.wheels.set_velocity(8,8)
		
	end

end



function turn(angle) -- function initialises the turning behaviour
	
	turn_angle = angle
	
	turn_distance = (robot.wheels.axis_length / 2) * angle
	distance_turned = - robot.wheels.distance_left -- offset from last loop
	current_behaviour = 'turning'
	
end


function behaviour.turning()
	
	distance_turned = distance_turned + robot.wheels.distance_left
	
	if turn_angle >= 0 then
		if distance_turned > turn_distance then
			current_behaviour = 'roaming'
		else
			robot.wheels.set_velocity(4, -4)
		end
	else
		if distance_turned < turn_distance then
			current_behaviour = 'roaming'
		else
			robot.wheels.set_velocity(-4, 4)
		end
	end
end

return functions
