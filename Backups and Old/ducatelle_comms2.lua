local comms = {}

function comms.receive_and_send()
	
	location_updates()						-- update current location	
		
	data_broadcast()						-- convert data to broadcast format
	
end

function location_updates()					-- checks if robot is currently on locations and changes values
		
	dist = 0.5 * (robot.wheels.distance_left + robot.wheels.distance_right)
	
	broadcast_info.base.distance = broadcast_info.base.distance + dist -- update travel times
	broadcast_info.target.distance = broadcast_info.target.distance + dist
	
	if current_location == "target" then
		
		broadcast_info.target.distance = 0
		broadcast_info.target.time = 0
		broadcast_info.target.origin = true
		
	elseif current_location == "base" then
		
		broadcast_info.base.distance = 0
		broadcast_info.base.time = 0
		broadcast_info.base.origin = true	
	end
	
end


function check_receieved_data()
	
	lowest_ids = {base = 0, target = 0} -- assume the robot has the best information
	
	num_received_broadcasts = #robot.range_and_bearing
	
	if num_received_broadcasts > 0 then
				
		for i = 1,num_received_broadcasts do
			
			temp_base_distance = robot.range_and_bearing[i].data[2] * 250 + robot.range_and_bearing[i].data[3] + robot.range_and_bearing[i].range
			
			temp_base_time = robot.range_and_bearing[i].data[4] * 250 + robot.range_and_bearing[i].data[5]
			
			temp_target_distance = robot.range_and_bearing[i].data[7] * 250 + robot.range_and_bearing[i].data[8] + robot.range_and_bearing[i].range
			
			temp_target_time = robot.range_and_bearing[i].data[9] * 250 + robot.range_and_bearing[i].data[10]
			
			temp_base_time > 0 then -- message is valid, all messages are > 0
			
			if broadcast_info.base.origin == true then
				
				if robot.range_and_bearing[i].data[1] ~= 0 then
					if temp_base_time > broadcast_info.base.time then

						broadcast_info.base.time = temp_base_time
						broadcast_info.base.distance = temp_target_distance
						lowest_ids.base = i

						base_origin = false

					elseif temp_base_time == broadcast_info.base.time and temp_base_distance < broadcast_info.base.distance then

						broadcast_info.base.time = temp_base_time
						broadcast_info.base.distance = temp_target_distance
						lowest_ids.base = i

						base_origin = false
					end
				end
			--else 									-- needs a catch for if two 'targets' are in communication, in which case one should give way to another
					
				
			
			--end

			if robot.range_and_bearing[i].data[6] ~= 0 then
				if temp_target_time > broadcast_info.target.time then

					broadcast_info.target.time = temp_target_time
					broadcast_info.target.distance = temp_target_distance
					lowest_ids.target = i
					
					target_origin = false

				elseif temp_target_time == broadcast_info.target.time and temp_target_distance < broadcast_info.target.distance then

					broadcast_info.target.time = temp_target_time
					broadcast_info.target.distance = temp_target_distance
					lowest_ids.target = i
					
					target_origin = false
				end
			end			
			
		end
	end	
end

function data_conversion()
	
	for i = 1,10 do											-- reset the broadcast tables
		broadcast_data[i] = 0
	end
	
	if broadcast_info.base.origin == true then
		broadcast_data[1] = 1
	end
	
	if broadcast_info.target.origin == true then
		broadcast_data[6] = 1
	end	
		
	transmit_base_distance = broadcast_info.base.distance
	transmit_base_time = broadcast_info.base.time
	transmit_target_distance = broadcast_info.target.distance
	transmit_target_time = broadcast_info.target.time
	
	
	-- Conversion to base 250 for efficient transmission	
	
	wholes = math.floor(transmit_base_distance / 250)
	broadcast_data[2] = wholes
	broadcast_data[3] = transmit_base_distance - wholes * 250
	
	wholes = math.floor(transmit_base_time / 250)
	broadcast_data[4] = wholes
	broadcast_data[5] = transmit_base_time - wholes * 250

	wholes = math.floor(transmit_target_distance / 250)
	broadcast_data[7] = wholes
	broadcast_data[8] = transmit_target_distance - wholes * 250
	
	wholes = math.floor(transmit_target_time / 250)
	broadcast_data[9] = wholes
	broadcast_data[10] = transmit_target_time - wholes * 250
	
end

function data_broadcast()
	
	--robot.range_and_bearing.clear_data()
	
	if counter >= counter_reset then
		
		counter = 0
		
		if robot.id == "fb0" then
				--log("Broadcast")
			end
		
		if broadcast_info.target.origin == true then 
		
			broadcast_info.target.time = broadcast_info.target.time + 1
		
		end
			
		if broadcast_info.base.origin == true then
		
			broadcast_info.base.time = broadcast_info.base.time + 1
		
		end
			
		
		data_conversion()

		for i = 1,10 do

			robot.range_and_bearing.set_data(i,math.floor(broadcast_data[i]))

		end
		
		robot.leds.set_all_colors("black")
		
	end
end

return comms