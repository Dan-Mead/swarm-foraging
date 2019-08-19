local fixes = require("scripts.fixes")
local common = require("scripts/common_functions")
local export = require("scripts/write_functions")
local variables = require("scripts/variables")
local ksp = require("scripts/kasprzok_equations")

-- Instantiation --

time = 0

behaviour = {}
state = {}

distance_travelled = 0
step_distance = 0

beacon = {base, target}
beacon.base = {identifier, range, bearing, distance, time} 		-- identifier allows for multiple beacons (currently unimplemented), range and bearing are for site fidelity, distance and time are for Ducatelle
beacon.target = {identifier, range, bearing, distance, time}


-- Constants --

dv = 10															-- default speed
max_speed = 30

prox_check = 5

heading_error_margin = math.pi * 2 / 180 
turning_p_gain = 10

-- Tunables --

proportion_foraging = variables.prop_foraging
tps = variables.tps

RW_mean = variables.rwm
RW_stdev = RW_mean/3

RW_gain = variables.rwg

enable_BRW = false											

k_val = {self, bias}
k_val.self = variables.k_self
k_val.bias = variables.k_bias

output_file_path = "outputs/" .. variables.output_path .. ".txt"

logged_start = false

function init()
		
	common.setup()
	export.header(goal)
	
end

function step()

	fixes.run()
	
	time = time + 1
	
	common.update()
	common.update_leds()
	
	behaviour[current_behaviour]()
	
	goal_check()
	
	--if robot.id == "fb1" then robot.leds.set_all_colors(0, 0, 0) end

				
end

function goal_check()
			
	if current_location == goal then
		
		if goal == "target" then
		
			current_state = "returning"
			current_behaviour = "roaming"
			log(robot.id .. " returning to nest...")

			goal = "base"
			
		elseif goal == "base" then
		
			current_state = "foraging"
			current_behaviour = "roaming"
			log(robot.id .. " re-foraging...")
			
			goal = "target"
			
		end
		
		export.change_behaviour(goal)
		
		robot.wheels.set_velocity(0,0)
		random_walk_tumble()
	
	end

end

function behaviour.roaming()
	
	robot.wheels.set_velocity(dv,dv)
	
	if step_distance > tumble_distance then
				
		random_walk_tumble()
		
	end
	
	for i = 1,24 do				-- run avoidance if a proximity sensor is tripped
		if i <= prox_check or i >= (25-prox_check) then
			if robot.proximity[i].value > 0 then
				
				common.avoid(prox_check)
				
				break
			end
		end
	end
	
end


function behaviour.turning()
	
	heading_error = heading_error - (robot.wheels.distance_right - robot.wheels.distance_left) / robot.wheels.axis_length
			
	v = heading_error * turning_p_gain
	
	if math.abs(v) > max_speed then
		v = max_speed * math.abs(v) / v
	end
	
	if math.abs(heading_error) > heading_error_margin then
		
		robot.wheels.set_velocity(-v, v)
	
	else
		
		current_behaviour = 'roaming'
		
	end
end

function random_walk_tumble()
	
	if current_state == "exploring" then
		
		RW_mean = RW_mean * RW_gain
		
		RW_stdev = RW_mean / 3
		
	end
	
	probs, sum = ksp.von_mises_pdf(0, k_val.self)
	
	if enable_BRW == true then
	
		if goal == "target" and beacon.target.bearing then
						
			landmark_direction = (beacon.target.bearing - robot.true_orientation)
					
			goal_probs, goal_sum = ksp.von_mises_pdf(landmark_direction, k_val.bias)

			probs, sum = ksp.combine_pdf(probs, sum, goal_probs, goal_sum)
			
		elseif goal == "base" and beacon.base.bearing then
						
			landmark_direction = (beacon.base.bearing - robot.true_orientation)
			
			goal_probs, goal_sum = ksp.von_mises_pdf(landmark_direction, k_val.bias)

			probs, sum = ksp.combine_pdf(probs, sum, goal_probs, goal_sum)

		end
		
	end
	
	heading_distribution = {angles = probs, total = sum}

	new_angle = ksp.sample_pdf(heading_distribution)
	
	--log(robot.id, " ", new_angle * 180/math.pi)
	
	tumble_distance = math.abs(robot.random.gaussian(RW_stdev, RW_mean))
	
	new_angle = common.angle_check_turn(new_angle)
	
	common.turn(new_angle)
	
	step_distance = 0
		
	common.neaten_tables() -- neatens tables a bit
	
end

