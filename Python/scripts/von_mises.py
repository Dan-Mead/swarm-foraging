import numpy as np
import matplotlib.pyplot as plt
import scipy.special as sp

def factorial(n):

    if n == 0:
        return 1
    else:
        for i in range(2, n):
            n = n * i
    return n

def mod_bessel_0(z):

    k = 0
    output = 0
    num = 1
    dem = 1

    while abs(num / dem) > 0.01:

        num = ((1 / 4) * z ** 2) ** k
        dem = (factorial(k)) ** 2

        # num = ((z**2) / 4) ** k
        # dem = (factorial(k))**2

        output = output + num / dem

        k = k + 1

    return (output)

def von_mises(theta, mu, k):

    num = np.exp(k * np.cos(theta - mu))
    dem = 2 * np.pi * mod_bessel_0(k)

    return num / dem

def von_mises_pdf(mu, k):

    angles = np.arange(-180,180)
    sum = 0
    n = 0

    probs = np.zeros(len(angles))

    for i in angles:

        i = i * np.pi / 180
        probs[n] = von_mises(i, mu, k)
        sum = sum + probs[n]
        n = n + 1

    return probs, sum

def combine_pdf(prob_1, sum_1, prob_2, sum_2):

    output_probs = np.zeros(len(prob_1))

    for i in range(0, len(prob_1)):

        output_probs[i] = prob_1[i] + prob_2[i]

    sum = sum_1 + sum_2

    return output_probs, sum


ks = [0,1, 10, 20, 40]
#
xs = np.arange(-180,180)
#
for n, k in enumerate(ks):

    ys, sum = von_mises_pdf(0, k)
    plt.plot(xs, ys/sum * 100, label = "$\kappa$ = {}".format(k))


# k = 2
# u = np.pi/2
#
# ys_1, sum_1 = von_mises_pdf(u, k)
# plt.plot(xs, ys_1/sum_1 * 100, label = "$\kappa$ = {}, $\mu$ = {}$^\circ$".format(k, int(u * 180 / np.pi)))

# k = 4
# u = 0
# ys_2, sum_2 = von_mises_pdf(u, k)
# plt.plot(xs, ys_2/sum_2 * 100, label = "$\kappa$ = {}, $\mu$ = {}$^\circ$".format(k, int(u * 180 / np.pi)))
#
# new_prob, new_sum = combine_pdf(ys_1, sum_1, ys_2, sum_2)
#
# plt.plot(xs,new_prob/new_sum * 100, label = 'Combined')

font_size = 12
tick_size = 11

plt.xlabel("Angle ($^\circ$)", fontsize = font_size)
plt.ylabel("Probability (%)", fontsize = font_size)
plt.legend(fontsize=font_size)

plt.xticks(fontsize=tick_size)
plt.yticks(fontsize=tick_size)
plt.show()



