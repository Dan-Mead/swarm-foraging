local d_comms = {}

function d_comms.receive_and_send()
	
	location_updates()						-- update current location	
	check_received_data()					-- compare with neighbours
	
	if time % (ducatelle_check_rate * tps) == 0 then
		
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

			temp_base_distance = robot.range_and_bearing[i].data[2] * 250 + robot.range_and_bearing[i].data[3] + robot.range_and_bearing[i].range

			temp_base_time = robot.range_and_bearing[i].data[4] * 250 + robot.range_and_bearing[i].data[5]
			
			if beacon.base.time and beacon.base.distance then

				if temp_base_time > beacon.base.time then

					beacon.base.time = temp_base_time
					beacon.base.distance = temp_base_distance
					lowest_ids.base = i

				elseif temp_base_time == beacon.base.time and temp_base_distance < 1.1 * beacon.base.distance then -- allows a little leeway so robots aren't just swapping information constantly if one doesn't move

					beacon.base.time = temp_base_time
					beacon.base.distance = temp_base_distance
					lowest_ids.base = i

				end

			else

				beacon.base.time = temp_base_time
				beacon.base.distance = temp_base_distance
				lowest_ids.base = i

			end
		end


		if robot.range_and_bearing[i].data[6] == 2 then						-- If there's information about the target transmitted

			temp_target_distance = robot.range_and_bearing[i].data[7] * 250 + robot.range_and_bearing[i].data[8] + robot.range_and_bearing[i].range

			temp_target_time = robot.range_and_bearing[i].data[9] * 250 + robot.range_and_bearing[i].data[10]

			if beacon.target.time and beacon.target.distance then

				if temp_target_time > beacon.target.time then

					beacon.target.time = temp_target_time
					beacon.target.distance = temp_target_distance
					lowest_ids.target = i

				elseif temp_target_time == beacon.target.time and temp_target_distance < 1.1 * beacon.target.distance then

					beacon.target.time = temp_target_time
					beacon.target.distance = temp_target_distance
					lowest_ids.target = i

				end

			else

				beacon.target.time = temp_target_time
				beacon.target.distance = temp_target_distance
				lowest_ids.target = i

			end
		end			
		
	end
		
end

function data_conversion()
	
	broadcast_data = {}
	
	for i = 1,10 do												-- reset the broadcast tables
		broadcast_data[i] = 0
	end
	
	if beacon.base.distance and beacon.base.time then
		
		broadcast_data[1] = 2									-- identify as active transmitter (robot, nest)
		
		wholes = math.floor(beacon.base.distance / 250)			-- Conversion to base 250 for efficient transmission
		broadcast_data[2] = wholes
		broadcast_data[3] = beacon.base.distance - wholes * 250

		wholes = math.floor(beacon.base.time / 250)
		broadcast_data[4] = wholes
		broadcast_data[5] = beacon.base.time - wholes * 250
		
	end
	
	if beacon.target.distance and beacon.target.time then
		
		broadcast_data[6] = 2									-- identify as active transmitter (robot, target)
		
		wholes = math.floor(beacon.target.distance / 250)
		broadcast_data[7] = wholes
		broadcast_data[8] = beacon.target.distance - wholes * 250

		wholes = math.floor(beacon.target.time / 250)
		broadcast_data[9] = wholes
		broadcast_data[10] = beacon.target.time - wholes * 250
		
	end		
end

function data_broadcast()
	
	robot.range_and_bearing.clear_data()

	data_conversion()
	
	for i = 1,10 do

		robot.range_and_bearing.set_data(i,math.floor(broadcast_data[i]))

	end

end

return d_comms