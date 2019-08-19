local rand_walk = {}

function rand_walk.cauchy(theta, mu, rho)
	
	return (1/(2 * math.pi)) * ((1 - rho^2) / (1 + rho^2 - 2*rho*math.cos(theta - mu)))
end

function rand_walk.cauchy_pdf(mu, rho)
	
	output_probs = {}
	output_sum = 0
	n = 1
	
	for i = -180, 180 do
		
		i = i * math.pi/180
		output_probs[n] = rand_walk.cauchy(i, mu, rho)
		output_sum = output_sum + output_probs[n]
		n = n+1
		
	end
	
	return output_probs, output_sum
end

function rand_walk.combine_pdf(prob_1, sum_1, prob_2, sum_2)
	
	output_probs = {}
	
	for i = 1, #prob_1 do
		
		output_probs[i] = prob_1[i] + prob_2[i]
		
	end
	
	sum = sum_1 + sum_2
	
	return output_probs, sum
end

function rand_walk.sample_pdf(probs, sum)
	
	rand = robot.random.uniform()
	
	summed = 0 
	for i = 1, #probs do
		
		summed = summed + probs[i]		
		
		if summed / sum > rand then
			new_angle = i - 181
			break
		end
	end
	
	if new_angle == nil then
		new_angle = 180
	end
		
	return (new_angle * math.pi / 180)
		
end