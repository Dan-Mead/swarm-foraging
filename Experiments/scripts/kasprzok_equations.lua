local ksp = {}


function factorial(n)
    
	if n == 0 then
		return 1
	else
		for i = 2,n-1 do
			n = n * i
		end
		return n
	end
end


function mod_bessel_0(z)
	
	k = 0
	output = 0
	num = 1
	dem = 1

	while num/dem > 0.01 do

		num = ((1/4) * z^2)^k
		dem = (factorial(k))^2

		output = output + num/dem

		k = k + 1
	end
	return(output)
	
end


function ksp.von_mises(theta, mu, k)
	return ((math.exp(k * math.cos(theta-mu)))/(2 * math.pi * mod_bessel_0(k)))
end

function ksp.von_mises_pdf(mu, k)
	
	output_probs = {}
	output_sum = 0
	n = 1
	
	for i = -180, 180 do
		
		i = i * math.pi/180
		output_probs[n] = ksp.von_mises(i, mu, k)
		output_sum = output_sum + output_probs[n]
		n = n+1
		
	end
	
	return output_probs, output_sum
end

--------------------------------------------------------------------------------------------------------

function ksp.combine_pdf(prob_1, sum_1, prob_2, sum_2)
	
	output_probs = {}
	
	for i = 1, #prob_1 do
		
		output_probs[i] = prob_1[i] + prob_2[i]
		
	end
	
	sum = sum_1 + sum_2
	
	return output_probs, sum
end
	
function ksp.sample_pdf(heading_distribution)
	
	sample_probs = heading_distribution.angles
	sample_sum = heading_distribution.total
	
	new_angle = nil
	
	rand = robot.random.uniform()
	
	summed = 0 
	for i = 1, #sample_probs do
		
		summed = summed + sample_probs[i] / sample_sum		
		
		if summed > rand then
			new_angle = i - 181
			if robot.id == "fb42" then 
			end
			break
		end
	end
	
	if new_angle == nil then
		new_angle = 180
	end
	
	return (new_angle * math.pi / 180)
		
end
	
function ksp.calc_k(interactions, time, k_min)
	
	sum = 0
	
	for n,val in pairs(interactions) do
				
		A = 100 / tps -- Adjusted for different tick rates, 5 times few interactions so have increase this value, 5 times longer between ticks so have decreased the decay below
		T = tps * (2/5)
		
		sum = sum + A * math.exp(-T * (time - val.time) / tps)
			
		--log(robot.id, " ", (time - val.time) / tps, " ", math.exp(-T * (time - val.time) / tps))
	end
	
	k = k_min + sum
		
	return k
end

function ksp.calc_v(interactions, time, dv)
	
	sum_I = 0
	sum_R = 0
	
	I = 1.5 -- Taken from Kaspzrok et al.
	R = 3
	L_I = 2
	L_R = 4
		
	for n,val in pairs(interactions) do
				
		sum_I = sum_I + I * math.exp(-L_I * (time - val.time) / tps)
		sum_R = sum_R - R * math.exp(-L_R * (time - val.time) / tps)
		
	end
	
	k_v = dv + sum_I + sum_R
	
	if math.abs(k_v) > max_speed then
		k_v = max_speed * math.abs(k_v) / k_v
	end
		
	return k_v
	
end

function ksp.congestion_direction(interactions, time)
	
	top = 0
	bot = 0
	
	for n,val in pairs(interactions) do
		
		if (time - val.time) <= 4 * tps then
			
			top = top + math.sin(val.bearing)
			bot = bot + math.cos(val.bearing)
			
		end
		
	end
	
	theta = math.atan2(top,bot)
	
	return(theta)
end

function avoid_wall(heading_distribution, wall_hit)
		
	wall_region_top = wall_hit.angle + math.pi/2
	wall_region_bottom = wall_hit.angle - math.pi/2
		
	if wall_region_top > math.pi then
		wall_region_top = wall_region_top - 2*math.pi
	elseif wall_region_bottom < -math.pi then
		wall_region_bottom = wall_region_bottom + 2* pi
	end

	for i = 1,#heading_distribution.angles do
		
		angle = (i - 181) * math.pi / 180
		
		if math.abs(wall_hit.angle) <= math.pi/2 then
		
			if angle < (wall_region_top) and angle > (wall_region_bottom) then

				heading_distribution.angles[i] = 0

			end
		
		else
			
			if angle < (wall_region_top) or angle > (wall_region_bottom) then

				heading_distribution.angles[i] = 0

			end
		
		end
	end

			
	return heading_distribution
		
end

function avoid_congestion(k_param, congestion_angle, heading_distribution)
	
		
	avoid_region_top = congestion_angle + (2*k_param) * math.pi/180
	avoid_region_bottom = congestion_angle - (2*k_param) * math.pi/180
	
	wrapped = false
	
	if avoid_region_top > math.pi then
		avoid_region_top = avoid_region_top - 2*math.pi
		
		wrapped = true
		
	elseif avoid_region_bottom < -math.pi then
		avoid_region_bottom = avoid_region_bottom + 2* math.pi
		
		wrapped = true
		
	end
	
	for i = 1,#heading_distribution.angles do
		
		angle = (i - 181) * math.pi / 180
		
		if wrapped == false then
		
			if angle < (avoid_region_top) and angle > (avoid_region_bottom) then

				heading_distribution.angles[i] = 0

			end
		
		else
			
			if angle < (avoid_region_top) or angle > (avoid_region_bottom) then

				heading_distribution.angles[i] = 0

			end
		
		end
	end
	
	return heading_distribution
end

function heading_sum(heading_distribution)
	
	sum = 0
	
	for i = 1,#heading_distribution.angles do
		sum = sum + heading_distribution.angles[i]
	end
	
	return sum
end
	

function ksp.calc_new_heading(heading_distribution, k_val, interactions, wall_hit, time)
	
	if wall_hit and (time - wall_hit.t) < 2 * tps then
		
		heading_distribution = avoid_wall(heading_distribution, wall_hit)
	
	end
	
	if k_val.self > quorum then
		
		congestion_angle = ksp.congestion_direction(interactions, time)

		heading_distribution = avoid_congestion(k_val.self, congestion_angle, heading_distribution)
		
	end
		
	heading_distribution.total = heading_sum(heading_distribution)
	
	new_angle = ksp.sample_pdf(heading_distribution)
	
	return new_angle
end


	
return ksp
	
	
	