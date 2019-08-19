import os
import numpy as np
import matplotlib.pyplot as plt

# Find directory to outputs.

print(os.path.abspath(os.curdir))

os.chdir('..')
os.chdir('..')

path = os.path.abspath(os.curdir) + "/Experiments/outputs/" #Kasp_tps_tests/

def get_data_over_time(file_name):

    data = open(path + file_name, "r")

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

    hit_list = np.zeros(max_time)

    for i in timestamps:
        if i > 0:
            hit_list[int(i)] += 1

    return max_time, hit_list, [timestamps, robot_ids, robot_states]

def get_data_set(test_set):

    file = open(path + test_set + ".txt", "r")

    tests = file.readlines()

    num_test = len(tests) - 1

    sim_time_line = tests[0]

    sim_time = sim_time_line[sim_time_line.find("= "):sim_time_line.find("|")]

    sim_time = int(sim_time[2:])

    tps = sim_time_line[sim_time_line.find("|"):]

    tps = int(tps[1:])

    hits_array = np.zeros([num_test, sim_time+1])

    label_list = []

    for n, file_name in enumerate(tests[2:]):

        file_name = file_name[:-1]

        max_time, hits, individual_info = get_data_over_time(file_name)

        for i in range(max_time):
            hits_array[n,i] = hits[i]

        label_list.append(file_name[:-4])

    return [hits_array, label_list, tps], individual_info

def plot_all(test_set_info):

    hits_array = test_set_info[0]
    label_list = test_set_info[1]
    tps = test_set_info[2]

    for i in range(hits_array.shape[0]):

        xs = np.arange(hits_array.shape[1])
        ys = np.cumsum(hits_array[i, :])

        plt.plot(xs/tps, ys, label = label_list[i])

    plt.legend()

    plt.xlabel("Time (s)")
    plt.ylabel("Number of Hits")

def plot_mean(test_set_info, test_name):

    hits_array = test_set_info[0]
    label_list = test_set_info[1]
    tps = test_set_info[2]

    xs = np.arange(hits_array.shape[1])
    ys = np.cumsum(np.mean(hits_array, axis = 0))

    plt.plot(xs/tps, ys, label = test_name[9:] + " mean")
    # plt.plot(xs/tps, maxes, 'k--', label = test_name[9:] + " max")
    # plt.plot(xs/tps, mins, 'k--', label = test_name[9:] + " min")

    plt.legend()

    plt.xlabel("Time (s)")
    plt.ylabel("Mean Number of Hits")

def plot_data_full(test_set_info):


    hits_array = test_set_info[0]
    label_list = test_set_info[1]
    tps = test_set_info[2]

    xs = np.arange(hits_array.shape[1])
    ys = np.cumsum(np.mean(hits_array, axis = 0))

    cumulative = np.cumsum(hits_array, axis=1)

    maxes = (np.max(cumulative, axis=0))
    mins = (np.min(cumulative, axis=0))

    stdevs = np.std(cumulative, axis = 0)

    colour = next(ax._get_lines.prop_cycler)['color']

    # plt.fill_between(xs / tps, maxes, mins, color = colour, alpha = 0.2)
    plt.fill_between(xs / tps, ys + stdevs, ys - stdevs, color = colour, alpha=0.5)
    plt.plot(xs / tps, ys, color = colour, label=test_name[9:])

    plt.legend()

    plt.xlabel("Time (s)")
    plt.ylabel("Mean Number of Hits")

def plot_mean_with_totals(test_set_info, test_name, loop_num):

    global fig
    global ax1
    global ax2

    if loop_num == 0:
        fig, (ax1, ax2) = plt.subplots(1, 2, sharey=True)

    hits_array = test_set_info[0]
    tps = test_set_info[2]

    xs = np.arange(hits_array.shape[1])
    ys = np.cumsum(np.mean(hits_array, axis = 0))

    ax1.plot(xs/tps, ys, label = test_name[9:] + " mean")

    ax1.legend()

    ax1.set_xlabel("Time (s)")
    ax1.set_ylabel("Mean Number of Hits")

    x_val = (test_name[test_name.rfind("_"):])
    x_val = float(x_val[1:])

    ax2.scatter(x_val, ys[-1])




    # ax2.plot()



# get_data_set("example") ## duplicate do not delet

# path = path + "Kasp_tps/"
# tests = ["alltests_Kasp_tps_10", "alltests_Kasp_tps_20", "alltests_Kasp_tps_30", "alltests_Kasp_tps_40", "alltests_Kasp_tps_50", "alltests_Kasp_tps_100"]
# tests = ["alltests_Kasp_tps_40"]

# path = path + "Kasp_check/"
# tests = ["Kasp_check_0.1", "Kasp_check_0.5", "Kasp_check_1", "Kasp_check_5", "Kasp_check_10"]
#
# path = path + "ARW_tps/"
# tests = ["alltests_ARW_tps_10", "alltests_ARW_tps_20", "alltests_ARW_tps_50"]
#
# path = path + "ARW_rwg/"
# tests = ["alltests_ARW_rwg_1", "alltests_ARW_rwg_1.1", "alltests_ARW_rwg_1.25", "alltests_ARW_rwg_1.5", "alltests_ARW_rwg_1.75", "alltests_ARW_rwg_2"]

# path = path + "small_empty_nest/"
# path = path + "large_cluttered_nest/"
# path = path + "large_cluttered_nest_2/"
# tests = ["alltests_ARW_test_", "alltests_Ducat_test_", "alltests_Kasp_test_"]

# path = path + "small_empty_nest/"
tests = ["alltests_ARW_num_bots_64",
"alltests_Kasp_num_bots_64",
"alltests_Ducat_num_bots_64",
"alltests_Comp_num_bots_64"]

# tests = ["alltests_Ducat_test_"]

ax = plt.gca()

## Read from test done and iterate

loop_num = 0

for i in tests:

    test_name = i
    test_set_info, individual_info = get_data_set(test_name)

    # plot_all(test_set_info)
    plot_mean(test_set_info, test_name)
    # plot_mean_with_totals(test_set_info, test_name, loop_num)
    # plot_data_full(test_set_info)

    loop_num += 1

# PLot final amounts

# test_name = "alltests_Kasp_tps_10"
# test_set_info = get_data_set(test_name)

# plot_all(test_set_info)
#
# plot_mean(test_set_info, test_name)
# plot_data_full(test_set_info)

# ax.margins(x = 0.01, y = 0.05)
# print(int(test_set_info[0].shape[1] / test_set_info[2]))

plt.show()