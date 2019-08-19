time = 0


function init()
	
	
	
end

function step()
	
	time = time + 1
	robot.leds.set_all_colors(255, 255, 0)	
	
	wholes = math.floor(time / 250)
	rem = time - wholes * 250
	
	robot.range_and_bearing.set_data(1,1) -- identify as active transmitter (landmark)
	robot.range_and_bearing.set_data(2,0) -- identify as nest information
	robot.range_and_bearing.set_data(3, wholes)	-- nest time info
	robot.range_and_bearing.set_data(4, rem)
	
end


function reset()

end

function destroy()

end