local fixes = {}

function angles()
	
	if robot.positioning.orientation.axis.z < 0 then
		robot.true_orientation = 2 * math.pi - robot.positioning.orientation.angle
	else
		robot.true_orientation = robot.positioning.orientation.angle
	end
	
end
	
function fixes.run()
	angles()
end

return fixes