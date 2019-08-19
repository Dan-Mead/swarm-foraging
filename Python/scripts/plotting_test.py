import os
import numpy as np
import matplotlib.pyplot as plt

# Find directory to outputs.

print(os.path.abspath(os.curdir))

os.chdir('..')
os.chdir('..')

path = os.path.abspath(os.curdir) + "/Experiments/outputs/"



data = open(path + "foraging_results.txt", "r")

lines = data.readlines()

data_length = len(lines)

timestamps = np.zeros(data_length)
robot_ids = np.zeros(data_length)
robot_states = np.zeros(data_length)


for n, line in enumerate(lines):

    if n > 3:

        timestamp = line[:line.find(" ")]
        timestamps[n] = timestamp

        robot_id = line[line.find("fb"):]
        robot_id = robot_id[:robot_id.find(" ")]
        robot_ids[n] = robot_id[2:]

        robot_state = line[-2]
        robot_states[n] = robot_state

max_time = int(np.max(timestamps)) + 1

num_robots = (len(np.unique(robot_ids)))

full_trajectory = np.ones([num_robots, max_time])*2

for n in range(data_length):

    full_trajectory[int(robot_ids[n]),int(timestamps[n])] = robot_states[n]

for i in range(num_robots):
    for t in range(max_time):
        if full_trajectory[i,t] == 2:
            full_trajectory[i, t] = last_value
        else:
            last_value = full_trajectory[i,t]

xs = np.arange(max_time)

# i = 1
# ys = full_trajectory[i,:]
# plt.plot(xs, ys)


for i in range(num_robots):
    ys = full_trajectory[i, :]

    plt.plot(xs, ys)

plt.show()