import os
import numpy as np
import matplotlib.pyplot as plt

# Find directory to outputs.

print(os.path.abspath(os.curdir))

os.chdir('..')
os.chdir('..')

path = os.path.abspath(os.curdir) + "/Experiments/outputs/"

def data_mine(path):

    file = open(path + "tests_list.txt", "r")
    lines = file.readlines()

    all_data = {}
    test_names = []
    metadatas = []

    for n, line in enumerate(lines):

        test_set_name = line[:-1]

        test_set = open(path + test_set_name + ".txt", "r")

        tests_list = test_set.readlines()

        num_tests = len(tests_list) - 3

        metadata = get_test_metadata(tests_list)

        full_data = np.zeros([num_tests, metadata['bot_num'], metadata['tick_num']+1])

        for k, test in enumerate(tests_list[5:]):

            file_name = test[:-1]

            timestamps, robot_ids, robot_states = get_test_data(path, file_name)

            for j in range(len(timestamps)):
                timestamp = timestamps[j]
                robot_id = robot_ids[j] - 1
                full_data[k, robot_id, timestamp] = 1

        name_label = test_set_name[test_set_name.find("_")+1:]

        all_data[name_label] = full_data
        test_names.append(str(name_label))
        metadatas.append(metadata)

    return all_data, test_names, metadatas

def get_test_metadata(tests):

    sim_time_line = tests[0]

    ticks_number = sim_time_line[sim_time_line.find("= "):sim_time_line.find("|")]
    ticks_number = int(ticks_number[2:])

    tps = sim_time_line[sim_time_line.find("|"):]
    tps = int(tps[1:])

    bot_density_line = tests[1]

    bot_number = bot_density_line[bot_density_line.find("= "):bot_density_line.find("|")]
    bot_number = int(bot_number[2:])

    arena_size = bot_density_line[bot_density_line.find("|"):]
    arena_size = int(arena_size[1:])

    dist_line = tests[2]

    coverage = dist_line[dist_line.find("= "):dist_line.find("|")]
    coverage = (coverage[2:])

    base_loc = dist_line[dist_line.find("|"):]
    base_loc = (base_loc[1:-1])

    test_line = tests[3]

    algorithm = test_line[test_line.find("= "):test_line.find("|")]
    algorithm = (algorithm[2:])

    variable_line = tests[4]

    variable_name = variable_line[:variable_line.find("=")]
    variable_name = variable_name[:-1]

    variable_value = variable_line[variable_line.find("= "):]
    variable_value = (variable_value[2:-1])

    if algorithm == 'Ducat':
        algorithm = 'Ducatelle'
    elif algorithm == 'Comp':
        algorithm = 'Composite'
    elif algorithm == 'Kasp':
        algorithm = 'Kasprzok'

    metadata = {'tick_num' : ticks_number,
                'tps' : tps,
                'bot_num' : bot_number,
                'arena_size' : arena_size,
                'coverage' : coverage,
                'base_loc' : base_loc,
                'algorithm' : algorithm,
                'var_name' : variable_name,
                'var_val' : variable_value}

    return metadata

def get_test_data(path, file_name):

    data = open(path + file_name, "r")

    lines = data.readlines()

    data_length = len(lines[4:])

    timestamps = np.zeros(data_length, dtype = np.int64)
    robot_ids = np.zeros(data_length, dtype = np.int16)
    robot_states = np.zeros(data_length, dtype = np.int8)

    for n, line in enumerate(lines[4:]):

        timestamp = line[:line.find("|"):]
        timestamps[n] = (timestamp[:-3])

        robot_id = line[line.find("fb")+2:line.find("fb")+5]
        robot_ids[n] = robot_id

        robot_state = line[-2]
        robot_states[n] = robot_state

    return timestamps, robot_ids, robot_states

def plot_final_totals(all_data, test_names, metadatas, type = "norm"):

    ax = plt.gca()

    means = []
    stdevs = []

    total_test_num = len(all_data) * all_data[test_names[0]].shape[0]

    for n, name in enumerate(test_names):

        data = all_data[name]

        cumulatives = np.zeros([len(data), metadatas[n]['tick_num'] + 1])

        for m, set in enumerate(data):
            totals = np.sum(set, axis=0)

            if type == 'raw':
                cumulatives[m, :] = np.cumsum(totals)
            elif type == 'norm':
                cumulatives[m, :] = np.cumsum(totals) / metadatas[n]['bot_num']

        means.append(np.mean(cumulatives, axis=0)[-1])
        stdevs.append(np.std(cumulatives, axis=0)[-1])

    plt.errorbar(np.arange(len(total_test_num)), means, yerr = stdevs, label=test_names[n] + " mean", capsize = 2, marker = 'x', linestyle = 'none')

folder_names = ["bias_on", 'bias_off']

for folder_name in folder_names:

    folder_path = path + folder_name + "/"

    all_data, test_names, metadatas = data_mine(folder_path)

    total_type = "norm"  # norm, raw
    plot_final_totals(all_data, test_names, metadatas, total_type)



    if type == "raw":
        y_string = "Mean number of hits"
    elif type == "norm":
        y_string = "Mean number of hits per robot"

    # plt.legend()

    plt.xlabel("Time (s)")
    plt.ylabel(y_string)

    total_test_num = len(all_data) * all_data[test_names[0]].shape[0]

    plt.xticks(np.arange(len(total_test_num)), test_names, rotation='vertical', fontsize=8)
    plt.tight_layout()
    plt.show()