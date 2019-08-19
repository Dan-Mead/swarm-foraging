import numpy as np
import matplotlib.pyplot as plt

def cauchy(theta, mu, rho):

    return (1 / (2 * np.pi)) * ((1 - rho ** 2) / (1 + rho ** 2 - 2 * rho * np.cos(theta - mu)))

def cauchy_pdf(mu, rho):

    # angles = np.arange(-180,180)

    output_probs = np.zeros(360)
    output_sum = 0
    n = 0

    for i in range(-180,180):

        i = i * np.pi / 180
        output_probs[n] = cauchy(i, mu, rho)
        output_sum = output_sum + output_probs[n]
        n = n + 1



    return output_probs, output_sum

def combine_pdf(prob_1, sum_1, prob_2, sum_2):

    output_probs = np.zeros(len(probs_1))

    for i in range(0, len(prob_1)):

        output_probs[i] = prob_1[i] + prob_2[i]

    sum = sum_1 + sum_2

    return output_probs, sum


def sample_pdf(probs, sum):

    rand = np.random.uniform()

    summed = 0
    for i  in range (1, len(probs)):

        summed += probs[i]

        if summed / sum > rand:
            new_angle = i - 181
            break


    if new_angle == nil:
        new_angle = 180


    return (new_angle * np.pi / 180)

# for rho in [0, 0.1,0.25,0.5,0.75]:
#
#     probs, sum = cauchy_pdf(0,rho)
#
#     xs = np.arange(-180,180)
#
#     plt.plot(xs,probs/sum)

probs_1, sum_1 = cauchy_pdf(0,0.25)
probs_2, sum_2 = cauchy_pdf(np.pi/2,0.5)


xs = np.arange(-180,180)
plt.plot(xs,probs_1/sum_1)
plt.plot(xs,probs_2/sum_2)

new_prob, new_sum = combine_pdf(probs_1, sum_1, probs_2, sum_2)

plt.plot(xs,new_prob/new_sum)

plt.show()