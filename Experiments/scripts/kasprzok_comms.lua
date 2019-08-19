local ksp = require("scripts/kasprzok_equations")
local common = require("scripts/common_functions")

local k_comms = {}

broadcast_data = {}

function k_comms.broadcast()
	
	for i = 1,10 do
		broadcast_data[i] = 0
	end
	
	broadcast_data[1] = 2 -- identify as active transmitter (robot)
	broadcast_data[2] = robot.id_number
		
	if goal == "base" then
	
		broadcast_data[3] = 0
	
	elseif goal == "target" then
		
		broadcast_data[3] = 1
	
	end
	
	broadcast_data[4] = math.floor(robot.true_orientation * 180 / (2*math.pi))
	
	robot.range_and_bearing.clear_data()
	
	for i = 1,10 do
		robot.range_and_bearing.set_data(i,broadcast_data[i])
	end
end

function k_comms.process_data()
	
	closest_id = nil
	closest_range = math.huge
	
	if goal == "base" then
	
		g = 1
	
	elseif goal == "target" then
		
		g = 0
	
	end
	
	for i = 1,#robot.range_and_bearing do
		
		if robot.range_and_bearing[i].data[1] == 2 and robot.range_and_bearing[i].range < 35 then
		
			id_num = robot.range_and_bearing[i].data[2]
			
			goal_val = robot.range_and_bearing[i].data[3]
			
			heading_val = robot.range_and_bearing[i].data[4]*2*math.pi/180
			
			add_interaction(time, id_num, goal_val, heading_val,robot.range_and_bearing[i].horizontal_bearing)
			
			if robot.range_and_bearing[i].range < closest_range and g == goal_val then
				
				closest_id = i
				closest_id_num = id_num
				closest_range = robot.range_and_bearing[i].range
				
			end

		end
	end
	
	if closest_id then
		
		if closest_id_num ~= last_closest then
		
			goal_heading = robot.range_and_bearing[closest_id].data[4]*2*math.pi/180

			turn_dir = goal_heading - robot.true_orientation + math.pi

			turn_dir = common.angle_check_turn(turn_dir)

			common.turn(turn_dir)

			last_closest = closest_id_num
		
		end
	
	end
	
end

function add_interaction(t, id_num, aim, dir, bear)
	
	data = {time = t, id = id_num, goal = aim, heading = dir, bearing = bear}
	
	table.insert(interactions, data)
	
end

function k_comms.interaction_timeout()
	
	for n,val in pairs(interactions) do
				
		if (time - val.time) > 10 * tps then
			interactions[n] = nil
		end
	end
end

function k_comms.wall_detection()
		
	left_wall_angle = nil
	right_wall_angle = nil
	
	for i = 1,24 do
		if i <= 4 then
			
			if robot.proximity[i].value > 0 then
				
				if left_wall_angle == nil then
					left_wall_angle = robot.proximity[i].angle
				elseif robot.proximity[i].angle < left_wall_angle then
					left_wall_angle = robot.proximity[i].angle
				end
					
			end
				
		elseif i >= (25-4) then
			if robot.proximity[i].value > 0 then
				
				if right_wall_angle == nil then
					right_wall_angle = robot.proximity[i].angle
				elseif robot.proximity[i].angle > right_wall_angle then
					right_wall_angle = robot.proximity[i].angle
				end
					
			end
		end
	end
	
	if left_wall_angle or right_wall_angle then
	
		if right_wall_angle and left_wall_angle then
			if math.abs(left_wall_angle) <= math.abs(right_wall_angle) then
				wall_angle = left_wall_angle
			else
				wall_angle = right_wall_angle
			end
		
		elseif left_wall_angle then
			wall_angle = left_wall_angle
		elseif right_wall_angle then
			wall_angle = right_wall_angle
		end
		

		robot_obstruction = false

		for j = 1,#robot.range_and_bearing do

			bot_angle = robot.range_and_bearing[j].horizontal_bearing

			if math.abs(bot_angle - wall_angle) < 60 * math.pi / 180 and robot.range_and_bearing[j].data[1] == 2 then

				robot_obstruction = true
				break

			end
		end

		if robot_obstruction == false then

			wall_hit = {t = time, angle = wall_angle}

		end
	end
end


return k_comms