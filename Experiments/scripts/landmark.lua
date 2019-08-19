time = 0


function init()
	
end

function step()
	
	time = time + 1
	
	wholes = math.floor(time / 250)
	rem = time - wholes * 250
	
	if string.find(robot.id, 'nest') then
		
		robot.leds.set_all_colors(255, 255, 0)	
	
		robot.range_and_bearing.set_data(1,1) -- identify as nest information

		
		robot.range_and_bearing.set_data(4, wholes)
		robot.range_and_bearing.set_data(5, rem)
	
	elseif string.find(robot.id, 'target') then
		
		robot.leds.set_all_colors(0, 255, 255)
	
		robot.range_and_bearing.set_data(6, 1) -- identify as taarget information

		wholes = math.floor(time / 250)
		robot.range_and_bearing.set_data(9, wholes)
		robot.range_and_bearing.set_data(10, rem)
	end
	
end


function reset()

end

function destroy()

end