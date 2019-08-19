local functions = {}

function functions.start()
	
	robot.wheels.set_velocity(5,5)
	--robot.leds.set_all_colors(125,125,0)
	robot.leds.set_all_colors(255,255,0)
	log("--Start--")

end


function functions.step()
	
end


function functions.diffdrive(v, a)
	left_speed = v - a
	right_speed = v + a
	
	robot.wheels.set_velocity(left_speed, right_speed)

end

function functions.avoid()
	
	for i = 1,24 do
		if i <= 12 then
			right_sensors = right_sensors + robot.proximity[i].value
		else
			left_sensors = left_sensors + robot.proximity[i].value
		end


	if (right_sensors ~= 0) then
		diffdrive(0,-5)
	elseif (left_sensors ~=0) then 
		diffdrive(0,5)
	else
		diffdrive(5,0)
	end
--		log(right_sensors)
--		log("Sensor: " .. i)
--		log("Angle: " .. robot.proximity[i].angle)
--		log("Value: " .. robot.proximity[i].value)
	end
end


return functions
