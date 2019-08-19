local fixes = require("scripts.fixes")
local common = require("scripts/common_functions")
local export = require("scripts/write_functions")
local ksp = require("scripts/kasprzok_equations")
local k_comms = require("scripts/kasprzok_comms")
local variables = require("scripts/variables")


-- Instantiation --

time = 0

behaviour = {}
state = {}

distance_travelled = 0
step_distance = 0

beacon = {base, target}
beacon.base = {identifier, range, bearing, distance, time} 		-- identifier allows for multiple beacons (currently unimplemented), range and bearing are for site fidelity, distance and time are for Ducatelle
beacon.target = {ientifier, range, bearing, distance, time}


-- Constants --

heading_error_margin = math.pi * 2 / 180 
turning_p_gain = 10

prox_check = 5
																-- ## kspzrok Addition
self_k_min = 3.5
goal_k_min = 4.5
dv = 10															-- default speed
max_speed = 30
quorum = 20 													-- changed from paper

k_val = {self, base, target}
k_val.self = self_k_min
k_val.base = goal_k_min
k_val.target = goal_k_min

interactions = {}

-- Tunables --

proportion_foraging = variables.prop_foraging
tps = variables.tps

kasp_check_rate = variables.k_check

output_file_path = "outputs/" .. variables.output_path .. ".txt"


function init()
	
	common.setup()
	
	robot.id_number = tonumber(string.sub(robot.id, (-#robot.id + 2))) -- would have to be implemented in real life but for simulation this is acceptable
	
	k_v = dv
	
	export.header(goal)
	
end

function step()
	
	fixes.run()
	
	time = time + 1
	
	common.update()
	common.update_leds()
	
	--if robot.id == "fb1" and time % tsp == 0 then log(time) end
	
	
	k_comms.process_data()
	k_comms.wall_detection()
	k_comms.broadcast()
		
	behaviour[current_behaviour]()
	
	goal_check()
	
	
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
		--random_walk_tumble()
	
	end

end

function behaviour.roaming()
	
	if time % (kasp_check_rate * tps) == 0 then
		decision()
	end
	
	if math.abs(k_v) > max_speed then
		k_v = max_speed * math.abs(k_v) / k_v
	end
	
	robot.wheels.set_velocity(k_v,k_v)
	
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

function decision()
	
	k_comms.interaction_timeout()
	
	k_val.self = ksp.calc_k(interactions, time, self_k_min)
	
	if k_val.self > 60 then
		k_val.self = 60
	end

	if goal == "target" and beacon.target.bearing then
		
		probs, sum = ksp.von_mises_pdf(0, k_val.self)		
	
		goal_probs, goal_sum = ksp.von_mises_pdf(beacon.target.bearing - robot.true_orientation, goal_k_min)
	
		probs, sum = ksp.combine_pdf(probs, sum, goal_probs, goal_sum)
	
	elseif goal == "base" and beacon.base.bearing then
		
		k_val.base = ksp.calc_k(interactions, time, goal_k_min)
		
		probs, sum = ksp.von_mises_pdf(0, self_k_min)		
	
		goal_probs, goal_sum = ksp.von_mises_pdf(beacon.base.bearing - robot.true_orientation, k_val.base)
	
		probs, sum = ksp.combine_pdf(probs, sum, goal_probs, goal_sum)
	
	else
			
		probs, sum = ksp.von_mises_pdf(0, k_val.self)
	
	end
	
		
	--adjusting distributions, adjusting speed
	
	k_v = ksp.calc_v(interactions, time, dv)

	heading_distribution = {angles = probs, total = sum}
	
	new_angle = ksp.calc_new_heading(heading_distribution, k_val, interactions, wall_hit, time)
	
	new_angle = common.angle_check_turn(new_angle)
	
	common.turn(new_angle)
	
	common.neaten_tables() -- neatens tables a bit
	
end
