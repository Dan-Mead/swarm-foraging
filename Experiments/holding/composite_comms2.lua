local common = require("scripts/common_functions")

local c_comms = {}

function c_comms.receive_and_send()
	
	location_updates()						-- update current location	
	check_received_data()					-- compare with neighbours
	
	if time % (composite_check_rate * tps) == 0 then
		
		data_broadcast()						-- convert data to broadcast format and transmit
		
	end
	
end

function location_updates()					-- checks if robot is currently on locations and changes values
		
	dist = 0.5 * (robot.wheels.distance_left + robot.wheels.distance_right)
	
	if beacon.base.distance then
		beacon.base.distance = beacon.base.distance + dist -- update travel times
	end
	if beacon.target.distance then
		beacon.target.distance = beacon.target.distance + dist
	end
	
end


function check_received_data()
	
	lowest_ids = {base = 0, target = 0} -- assume the robot has the best information
					
	for i = 1,#robot.range_and_bearing do

		if robot.range_and_bearing[i].data[1] == 2 then						-- If there's information about the base transmitted by a robot
			
			if robot.range_and_bearing[i].data[2] == 1 then
				
				temp_target_distance = robot.range_and_bearing[i].data[3] * 250 + robot.range_and_bearing[i].data[4] + robot.range_and_bearing[i].range
				
				if beacon.target.distance == nil then 						-- the robot will use its own information once the target is found, but to intialise
					
					beacon.target.distance = temp_target_distance
					
					robot_target_range = robot.range_and_bearing[i].data[5] * 250 + robot.range_and_bearing[i].data[6]
					robot_target_bearing = robot.range_and_bearing[i].data[7] * 2 * math.pi / 180
					
					robot_direction = robot.range_and_bearing[i].horizontal_bearing + robot.true_orientation
					
					bot_x = math.cos(robot_direction) * robot.range_and_bearing[i].range +  math.cos(robot_target_bearing) * robot_target_range
					bot_y = math.sin(robot_direction) * robot.range_and_bearing[i].range +  math.sin(robot_target_bearing) * robot_target_range
					
					beacon.target.range = math.sqrt(bot_x^2 + bot_y^2)
					beacon.target.bearing = math.atan2(bot_y, bot_x)-- - math.pi
					
					beacon.target.bearing = common.angle_check(beacon.target.bearing)

					lowest_ids.target = i
				
				elseif temp_target_distance < beacon.target.distance then
					
					beacon.target.distance = temp_target_distance
					
					lowest_ids.target = i
					
				end
			
			elseif robot.range_and_bearing[i].data[2] == 0 then
								
				temp_base_distance = robot.range_and_bearing[i].data[3] * 250 + robot.range_and_bearing[i].data[4] + robot.range_and_bearing[i].range
				
				if beacon.base.distance == nil then
					
					beacon.base.distance = temp_base_distance
					
					robot_target_range = robot.range_and_bearing[i].data[7] * 250 + robot.range_and_bearing[i].data[6]
					robot_target_bearing = robot.range_and_bearing[i].data[6] * 2 * math.pi / 180
					
					robot_direction = robot.range_and_bearing[i].horizontal_bearing + robot.true_orientation
					
					bot_x = math.cos(robot_target_bearing) * robot_target_range - math.cos(robot_direction) * robot.range_and_bearing[i].range
					bot_y = math.sin(robot_target_bearing) * robot_target_range - math.sin(robot_direction) * robot.range_and_bearing[i].range
					
					beacon.base.range = math.sqrt(bot_x^2 + bot_y^2)
					beacon.base.bearing = math.atan2(bot_y, bot_x) - math.pi
					
					beacon.base.bearing = common.angle_check(beacon.base.bearing)
					
					lowest_ids.base = i
				
				elseif temp_base_distance < beacon.base.distance then
					
					beacon.base.distance = temp_base_distance
					
					lowest_ids.base = i
					
				end				
			end
		end	
	end
end

function data_conversion()
	
	broadcast_data = {}
	
	for i = 1,10 do												-- reset the broadcast tables
		broadcast_data[i] = 0
	end
	
	if transmit_info == "base" and beacon.base.distance then
		
		broadcast_data[1] = 2									-- identify as active transmitter (robot)
		
		broadcast_data[2] = 0									---- identify as informatiom about the nest

		wholes = math.floor(beacon.base.distance / 250)			
		broadcast_data[3] = wholes
		broadcast_data[4] = beacon.base.distance - wholes * 250
		
		wholes = math.floor(beacon.base.range / 250)			
		broadcast_data[5] = wholes
		broadcast_data[6] = beacon.base.range - wholes * 250
		
		broadcast_data[7] = math.floor(beacon.base.bearing * 180 / (2*math.pi))
		
		if desired_heading then	
			broadcast_data[8] = math.floor(desired_heading * 180 / (2*math.pi))
		else
			broadcast_data[8] = math.floor(robot.true_orientation * 180 / (2*math.pi))
		end
		
		if goal == "base" then
			broadcast_data[9] = 0
		elseif goal == "target" then
			broadcast_data[9] = 1
		end
		
		if beacon.target.distance then
			transmit_info = "target"
		end
		
	elseif transmit_info == "target" and beacon.target.distance then
		
		broadcast_data[1] = 2									-- identify as active transmitter (robot)
		
		broadcast_data[2] = 1									---- identify as informatiom about the target

		wholes = math.floor(beacon.target.distance / 250)			
		broadcast_data[3] = wholes
		broadcast_data[4] = beacon.target.distance - wholes * 250
		
		wholes = math.floor(beacon.target.range / 250)			
		broadcast_data[5] = wholes
		broadcast_data[6] = beacon.target.range - wholes * 250
		
		broadcast_data[7] = math.floor(beacon.target.bearing * 180 / (2*math.pi))
		
		if desired_heading then	
			broadcast_data[8] = math.floor(desired_heading * 180 / (2*math.pi))
		else
			broadcast_data[8] = math.floor(robot.true_orientation * 180 / (2*math.pi))
		end		
		
		if goal == "base" then
			broadcast_data[9] = 0
		elseif goal == "target" then
			broadcast_data[9] = 1
		end
		
		if beacon.base.distance then
			transmit_info = "base"
		end
		
	end

	
end

function data_broadcast()
	
	robot.range_and_bearing.clear_data()

	data_conversion()
	
	for i = 1,10 do

		robot.range_and_bearing.set_data(i,math.floor(broadcast_data[i]))

	end

end

return c_comms