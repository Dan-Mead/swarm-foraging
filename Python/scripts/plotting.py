import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib

def make_patch_spines_invisible(ax):
    ax.set_frame_on(True)
    ax.patch.set_visible(False)
    for sp in ax.spines.values():
        sp.set_visible(False)


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

        num_tests = len(tests_list) - 5

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

    algorithm = test_line[test_line.find("="):test_line.find("|")]
    algorithm = (algorithm[2:])

    second_variable = test_line[test_line.find("|"):]
    second_variable_name = second_variable[second_variable.find("|")+1:second_variable.find(" =")]
    second_variable_value = second_variable[second_variable.find("= ")+2:-1]


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

    if variable_name == 'coverage':
        variable_name = 'Coverage'
    elif variable_name == 'base_loc':
        variable_name = 'Base Location'
    elif variable_name == 'ticks_per_sec':
        variable_name = 'Ticks per second'
    elif variable_name == 'rwm':
        variable_name = 'Random walk Mean'
    elif variable_name == 'rwg':
        variable_name = 'Random walk gain'
    elif variable_name == 'k_self':
        variable_name = '$\kappa_c$'
    elif variable_name == 'k_bias':
        variable_name = '$\kappa_b$'
    elif variable_name == 'd_check':
        variable_name = 'Ducatelle check rate'
    elif variable_name == 'k_check':
        variable_name = 'Kasprzok check rate'
    elif variable_name == 'c_check':
        variable_name = 'Composite check rate'
    elif variable_name == 'num_bots':
        variable_name = 'Number of Robots'

    metadata = {'tick_num' : ticks_number,
                'tps' : tps,
                'bot_num' : bot_number,
                'arena_size' : arena_size,
                'coverage' : coverage,
                'base_loc' : base_loc,
                'algorithm' : algorithm,
                'var_name' : variable_name,
                'var_val' : variable_value,
                'var_2_name' : second_variable_name,
                'var_2_val' : second_variable_value}

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

def algorithm_sort(algol):

    indexes = {'CRW' : 1, 'BRW' : 2, 'Kasprzok' : 3, 'Ducatelle' : 4, 'Composite' : 5}

    return indexes[algol]

def plot_all_over_time(all_data, test_names, metadatas, type = "raw"):

    for n, name in enumerate(test_names):

        data = all_data[name]

        xs = np.arange(metadatas[n]['tick_num'] + 1)

        for m, test in enumerate(data):

            test[:,0] = 0 # adjust for initial

            totals = np.sum(test, axis = 0)

            if type == "raw":
                plt.plot(xs / metadatas[n]['tps'], np.transpose(np.cumsum(totals)), label= metadatas[n]['var_val'] + "_{:02d}".format(m) + " (" + metadatas[n]['algorithm'] + ")")
                y_string = "Number of transits"
            elif type == "norm":
                plt.plot(xs / metadatas[n]['tps'], np.transpose(np.cumsum(totals) / metadatas[n]['bot_num']), label= metadatas[n]['var_val'] + "_{:02d}".format(m) + " (" + metadatas[n]['algorithm'] + ")")
                y_string = "Number of transits per robot"

    plt.legend(title = metadatas[n]['var_name'] + ":")

    plt.xlabel("Time (s)")
    plt.ylabel(y_string)

def plot_means_over_time(all_data, test_names, metadatas, type = "raw"):

    for n, name in enumerate(test_names):

        data = all_data[name]

        cumulatives = np.zeros([len(data), metadatas[n]['tick_num'] + 1])

        for m, test in enumerate(data):

            test[:, 0] = 0  # adjust for initial

            totals = np.sum(test, axis = 0)

            cumulatives[m,:] = np.cumsum(totals)

        means = np.mean(cumulatives, axis = 0)

        xs = np.arange(metadatas[n]['tick_num'] + 1)

        if type == "raw":
            plt.plot(xs / metadatas[n]['tps'], means, label= metadatas[n]['var_val'] + " (" + metadatas[n]['algorithm'] + ")")
            y_string = "Mean number of transits"
        elif type == "norm":
            plt.plot(xs / metadatas[n]['tps'], means / metadatas[n]['bot_num'], label= metadatas[n]['var_val'] + " (" + metadatas[n]['algorithm'] + ")")
            y_string = "Mean number of transits per robot"

    plt.legend(title = metadatas[n]['var_name'] + ":")

    plt.xlabel("Time (s)")
    plt.ylabel(y_string)

def plot_first_contact(all_data, test_names, metadatas):

    algorithms = []

    for i in metadatas:
        algorithms.append(i['algorithm'])

    algorithms = list(set(algorithms))
    algorithms.sort(key=algorithm_sort)

    input_indexes = np.zeros(len(algorithms))

    num_samples = (all_data[test_names[0]].shape[0])

    means = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])
    stdevs = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    x_labels = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    for n, name in enumerate(test_names):

        data = all_data[name]

        num_bots = metadatas[n]['bot_num']

        all_means = np.zeros([len(data), metadatas[n]['bot_num']])

        for m, test in enumerate(data):

            firsts = np.zeros(num_bots)

            for k in range(num_bots):
                hit_list = np.argwhere(test[k,:])
                if len(hit_list) > 1:
                    firsts[k] = hit_list[1]
                else:
                    firsts[k] = metadatas[n]['tick_num']

            all_means[m,:] = firsts

        for index, val in enumerate(algorithms):

            if metadatas[n]['algorithm'] == val:
                break

        means[index, int(input_indexes[index])] = np.mean(all_means.flatten() / metadatas[n]['tps'])
        stdevs[index, int(input_indexes[index])] = np.std(all_means.flatten() / metadatas[n]['tps'])

        if metadatas[0]['var_name'] == 'Coverage' or metadatas[0]['var_name'] == 'Base Location':
            x_labels[index, int(input_indexes[index])] = (metadatas[n]['var_val'])
        else:
            x_labels[index, int(input_indexes[index])] = (float(metadatas[n]['var_val']))

        input_indexes[index] += 1

    if len(algorithms) == 1:

        if metadatas[0]['var_2_name'] == 'Algorithm':
            plt.errorbar(x_labels[0, :], means[0, :], yerr=stdevs[0, :] / num_samples, capsize=2, marker='o', mec = 'k', linestyle='--', label=algorithms[0])
            plt.legend(title="Algorithm:", loc = 'upper right')
        else:
            plt.errorbar(x_labels[0, :], means[0, :], yerr=stdevs[0, :] / num_samples, capsize=2, marker='o', mec = 'k', linestyle='--', label=metadatas[0]['var_2_val'])
            plt.legend(title=metadatas[0]['var_2_name'] + ":", loc = 'upper right')
    else:

        for i in range(len(algorithms)):
            plt.errorbar(x_labels[i,:], means[i,:], yerr=stdevs[i,:] / num_samples, capsize=2, marker='o', mec = 'k', linestyle='--', label = algorithms[i])
        plt.legend(title="Algorithm:", loc = 'upper right')
    plt.xlabel(metadatas[n]['var_name'])
    plt.ylabel("Mean time to first contact with goal (s)")
    #plt.xticks(rotation='vertical', fontsize=8)

def plot_average_transition(all_data, test_names, metadatas):
    box_plot_data = []

    algorithms = []

    for i in metadatas:
        algorithms.append(i['algorithm'])

    algorithms = list(set(algorithms))
    algorithms.sort(key=algorithm_sort)

    input_indexes = np.zeros(len(algorithms))

    num_samples = (all_data[test_names[0]].shape[0])

    means = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])
    stdevs = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    x_labels = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    for n, name in enumerate(test_names):

        data = all_data[name]

        num_bots = metadatas[n]['bot_num']

        all_means = np.zeros([len(data), metadatas[n]['bot_num']])

        for m, test in enumerate(data):

            for k in range(num_bots):
                hit_list = np.argwhere(test[k, :])

                if len(hit_list) > 1:

                    diffs = np.diff(np.squeeze(hit_list))

                    all_means[m, k] = np.mean(diffs)

                else:
                    all_means[m, k] = metadatas[n]['tick_num']

        for index, val in enumerate(algorithms):

            if metadatas[n]['algorithm'] == val:
                break

        means[index, int(input_indexes[index])] = np.mean(all_means.flatten() / metadatas[n]['tps'])
        stdevs[index, int(input_indexes[index])] = np.std(all_means.flatten() / metadatas[n]['tps'])

        if metadatas[0]['var_name'] == 'Coverage' or metadatas[0]['var_name'] == 'Base Location':
            x_labels[index, int(input_indexes[index])] = (metadatas[n]['var_val'])
        else:
            x_labels[index, int(input_indexes[index])] = (float(metadatas[n]['var_val']))

        input_indexes[index] += 1

        # box_plot_data.append(all_means.flatten() / metadatas[n]['tps'])

    # ax.boxplot(box_plot_data, labels = x_labels)

    if len(algorithms) == 1:

        if metadatas[0]['var_2_name'] == 'Algorithm':
            plt.errorbar(x_labels[0, :], means[0, :], yerr=stdevs[0, :] /num_samples, capsize=2, marker='o', mec = 'k', linestyle='--', label=algorithms[0])
            plt.legend(title="Algorithm:")
        else:
            plt.errorbar(x_labels[0, :], means[0, :], yerr=stdevs[0, :] / num_samples, capsize=2, marker='o', mec = 'k', linestyle='--', label=metadatas[0]['var_2_val'])
            plt.legend(title=metadatas[0]['var_2_name'])
    else:

        for i in range(len(algorithms)):
            plt.errorbar(x_labels[i,:], means[i,:], yerr=stdevs[i,:] / num_samples, capsize=2, marker='o', mec = 'k', linestyle='--', label = algorithms[i])
        plt.legend(title="Algorithm:")

    plt.xlabel(metadatas[n]['var_name'])
    plt.ylabel("Mean transit time (s)")
    # plt.xticks(rotation='vertical', fontsize=8)

def plot_final_totals(all_data, test_names, metadatas, type = "norm"):

    algorithms = []

    for i in metadatas:
        algorithms.append(i['algorithm'])

    algorithms = list(set(algorithms))
    algorithms.sort(key = algorithm_sort)

    input_indexes = np.zeros(len(algorithms))

    num_samples = (all_data[test_names[0]].shape[0])

    means = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])
    stdevs = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    x_labels = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    for n, name in enumerate(test_names):

        data = all_data[name]

        cumulatives = np.zeros([len(data), metadatas[n]['tick_num'] + 1])

        for m, test in enumerate(data):

            test[:, 0] = 0  # adjust for initial

            totals = np.sum(test, axis=0)

            cumulatives[m,:] = np.cumsum(totals)

        for index, val in enumerate(algorithms):

            if metadatas[n]['algorithm'] == val:
                break

        if type == 'norm':
            means[index, int(input_indexes[index])] = np.mean(cumulatives[:, -1]/ metadatas[n]['bot_num'], axis=0)
            stdevs[index, int(input_indexes[index])] = np.std(cumulatives[:, -1] / metadatas[n]['bot_num'], axis=0)

        elif type == 'raw':

            means[index, int(input_indexes[index])] = np.mean(cumulatives[:, -1])
            stdevs[index, int(input_indexes[index])] = np.std(cumulatives[:, -1])

        if metadatas[0]['var_name'] == 'Coverage' or metadatas[0]['var_name'] == 'Base Location':
            x_labels[index, int(input_indexes[index])] = (metadatas[n]['var_val'])
        else:
            x_labels[index, int(input_indexes[index])] = (float(metadatas[n]['var_val']))

        input_indexes[index] += 1

    if len(algorithms) == 1:

        if metadatas[0]['var_2_name'] == 'Algorithm':
            plt.errorbar(x_labels[0, :], means[0, :], yerr=stdevs[0, :] / num_samples, capsize=2, marker='o', mec = 'k', linestyle='--', label=algorithms[0])
            plt.legend(title="Algorithm:", loc = 'upper left')
        else:
            plt.errorbar(x_labels[0, :], means[0, :], yerr=stdevs[0, :], capsize=2, marker='o', mec = 'k', linestyle='--', label=metadatas[0]['var_2_val'])
            plt.legend(title=metadatas[0]['var_2_name'] + ":", loc = 'upper left')
    else:

        for i in range(len(algorithms)):
            plt.errorbar(x_labels[i,:], means[i,:], yerr=stdevs[i,:] / num_samples, capsize=2, marker='o', mec = 'k', linestyle='--', label = algorithms[i])
        plt.legend(title="Algorithm:")#, loc = 'upper left')

    plt.xlabel(metadatas[n]['var_name'])

    if type == "raw":
        y_string = "Mean number of transits"
    elif type == "norm":
        y_string = "Mean number of transits per robot"    # plt.xticks(rotation='vertical', fontsize=8)

    plt.ylabel(y_string)

    return means, x_labels, stdevs, metadatas[0]['var_2_val']

def return_heatmap_data(all_data, test_names, metadatas, type = "norm"):

    algorithms = []

    for i in metadatas:
        algorithms.append(i['algorithm'])

    algorithms = list(set(algorithms))
    algorithms.sort(key = algorithm_sort)

    input_indexes = np.zeros(len(algorithms))

    num_samples = (all_data[test_names[0]].shape[0])

    means = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])
    stdevs = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    x_labels = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    for n, name in enumerate(test_names):

        data = all_data[name]

        cumulatives = np.zeros([len(data), metadatas[n]['tick_num'] + 1])

        for m, test in enumerate(data):

            test[:, 0] = 0  # adjust for initial

            totals = np.sum(test, axis=0)

            cumulatives[m,:] = np.cumsum(totals)

        for index, val in enumerate(algorithms):

            if metadatas[n]['algorithm'] == val:
                break

        if type == 'norm':
            means[index, int(input_indexes[index])] = np.mean(cumulatives[:, -1]/ metadatas[n]['bot_num'], axis=0)
            stdevs[index, int(input_indexes[index])] = np.std(cumulatives[:, -1] / metadatas[n]['bot_num'], axis=0)

        elif type == 'raw':

            means[index, int(input_indexes[index])] = np.mean(cumulatives[:, -1])
            stdevs[index, int(input_indexes[index])] = np.std(cumulatives[:, -1])

        if metadatas[0]['var_name'] == 'Coverage' or metadatas[0]['var_name'] == 'Base Location':
            x_labels[index, int(input_indexes[index])] = (metadatas[n]['var_val'])
        else:
            x_labels[index, int(input_indexes[index])] = (float(metadatas[n]['var_val']))

        input_indexes[index] += 1

    xs = (np.squeeze(x_labels))
    ys = (np.squeeze(metadatas[0]['var_2_val']))
    zs = (np.squeeze(means))

    return xs, ys, zs


def plot_single_folder(path, folder_name, display, type):

    folder_path = path + folder_name + "/"

    all_data, test_names, metadatas = data_mine(folder_path)

    ax = plt.gca()

    if display == 'mean':
        plot_means_over_time(all_data, test_names, metadatas, type)
    elif display == 'all':
        plot_all_over_time(all_data, test_names, metadatas, type)
    elif display == 'first':
        plot_first_contact(all_data, test_names, metadatas)
    elif display == 'transit':
        plot_average_transition(all_data, test_names, metadatas)
    elif display == 'totals':
        plot_final_totals(all_data, test_names, metadatas, type)

def plot_multi_folder(path, folders, display, type):

    all_y1s = []
    all_y2s = []
    all_stdevs = []

    for folder_name in folders:

        folder_path = path + folder_name + "/"

        all_data, test_names, metadatas = data_mine(folder_path)

        ax = plt.gca()

        if display == 'mean':
            plot_means_over_time(all_data, test_names, metadatas, type)
        elif display == 'all':
            plot_all_over_time(all_data, test_names, metadatas, type)
        elif display == 'first':
            plot_first_contact(all_data, test_names, metadatas)
        elif display == 'transit':
            plot_average_transition(all_data, test_names, metadatas)
        elif display == 'totals':
            means, x_labels, stdevs, arena = plot_final_totals(all_data, test_names, metadatas, type)

        arg = np.argmax(means)

        all_y1s.append(x_labels[0, arg])
        all_y2s.append(means[0, arg])
        all_stdevs.append(stdevs[0, arg])


    all_xs = np.array([1.14, 1.16, 1.29, 1.25, 1.473])

    sorted_args = np.argsort(all_xs)
    all_xs = (all_xs[sorted_args])

    all_y1s = np.array(all_y1s)
    all_y2s = np.array(all_y2s)
    all_stdevs = np.array(all_stdevs)

    all_y1s = (all_y1s[sorted_args])
    all_y2s = (all_y2s[sorted_args])
    all_stdevs = (all_stdevs[sorted_args])

    plt.gca().set_prop_cycle(None)

    original_val = np.ones(5) * 10

    p2 = plt.subplots(figsize=(12*(3/4),5*(3/4)))
    ax1 = plt.subplot(1,2,1)
    l1_2, = ax1.plot(all_xs, original_val,'ko--', mec = 'k', label = '\'Standard\' Values')
    l1, = ax1.plot(all_xs, all_y1s,'o--', mec = 'k', label = 'Optimal Values')
    plt.xlabel("Arena Fractal Dimension")
    plt.ylabel("Composite Bias ($\kappa_b$)")
    colour = next(ax._get_lines.prop_cycler)['color']
    colour = next(ax._get_lines.prop_cycler)['color']

    ax1.legend()

    original_ys = np.array([206.7, 101.6, 57.2, 61.4, 116.0])
    original_stds = np.array([10.7, 8.0, 6.0, 11.2, 37.2])

    final_stds = (np.sqrt(original_stds ** 2 + all_stdevs ** 2))

    final_ys_percent = 100 * (all_y2s - original_ys) / original_ys
    final_ys_std = (all_y2s - original_ys) / final_stds


    ax2 = plt.subplot(1,2,2, sharex = ax1)

    # final_stds = np.sqrt((final_stds / (all_y2s - original_ys)) ** 2 + (original_stds / original_ys) **2) * final_ys

    # plt.errorbar(all_xs, final_ys, yerr=final_stds, color = colour, capsize=2, marker='d', mec = 'k', linestyle='--', label = 'Optimal Totals')
    l2, = ax2.plot(all_xs, final_ys_percent, color = colour, marker='d', mec = 'k', linestyle='--', label = 'Residuals')
    y_string = "Mean change vs. standard profile (%)"

    plt.ylabel(y_string)#, rotation = 270, labelpad=16)
    plt.xlabel("Arena Fractal Dimension")
    ax3 = ax2.twinx()

    colour = next(ax._get_lines.prop_cycler)['color']

    # ax3.spines["right"].set_position(("axes", 1.2))
    # make_patch_spines_invisible(ax3)
    # ax3.spines["right"].set_visible(True)

    l3, = ax3.plot(all_xs, final_ys_std, color=colour, marker='d', mec='k', linestyle='--', label='Residuals')
    y_string = "Mean change vs. standard profile ($\sigma$)"
    plt.ylabel(y_string, rotation=270, labelpad=16)

    ax3.legend([l2, l3], np.array(['Percentage Residuals', 'Normalised Residuals']))

    # ax1.yaxis.label.set_color(l1.get_color())
    ax2.yaxis.label.set_color(l2.get_color())
    ax3.yaxis.label.set_color(l3.get_color())

    # ax1.tick_params(axis='y', colors=l1.get_color())
    ax2.tick_params(axis='y', colors=l2.get_color())
    ax3.tick_params(axis='y', colors=l3.get_color())

    print(np.mean(final_ys_percent))
    print(np.mean(final_ys_std))


def plot_heatmap(path, folders, type):


    all_data, test_names, metadatas = data_mine(path + folders[0] + "/")

    xs, ys, zs = return_heatmap_data(all_data, test_names, metadatas, type)

    data_set = np.zeros([len(folders), len(xs)])

    x_ticks = xs
    y_ticks = np.zeros(len(folders))

    ax = plt.gca()

    for n, folder_name in enumerate(folders):

        folder_path = path + folder_name + "/"

        all_data, test_names, metadatas = data_mine(folder_path)

        xs, ys, zs = return_heatmap_data(all_data, test_names, metadatas, type)

        y_ticks[n] = ys
        data_set[n,:] = zs

    y_ticks = np.flip(y_ticks)
    data_set = np.flip(data_set, axis = 0)

    plt.imshow(data_set, cmap='jet', interpolation='bilinear', extent = [np.min(x_ticks),np.max(x_ticks),np.min(y_ticks),np.max(y_ticks)], aspect='auto')
    cbar = plt.colorbar()
    cbar.set_label("Mean number of transits", rotation=270, labelpad=16)
    # x_ticks = np.append(x_ticks, 10)
    # y_ticks = np.append(y_ticks, 0)

    # ax.set_xticklabels(x_ticks)
    # ax.set_yticklabels(np.flip(y_ticks))

    plt.ylabel('Random walk step size gain')
    plt.xlabel('$\kappa_c$')

def plot_final(path, folder_name, display, type):

    folder_path = path + folder_name + "/"

    all_data, test_names, metadatas = data_mine(folder_path)

    plot_final_graph(all_data, test_names, metadatas, type)


def plot_final_graph(all_data, test_names, metadatas, type = "norm"):

    ax = plt.gca()

    algorithms = []

    for i in metadatas:
        algorithms.append(i['algorithm'])

    algorithms = list(set(algorithms))
    algorithms.sort(key = algorithm_sort)

    input_indexes = np.zeros(len(algorithms))

    num_samples = (all_data[test_names[0]].shape[0])

    means = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])
    stdevs = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    maxes = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])
    mins = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    x_labels = np.zeros([len(algorithms), int(len(test_names) / len(algorithms))])

    for n, name in enumerate(test_names):

        data = all_data[name]

        cumulatives = np.zeros([len(data), metadatas[n]['tick_num'] + 1])

        for m, test in enumerate(data):

            test[:, 0] = 0  # adjust for initial

            totals = np.sum(test, axis=0)

            cumulatives[m,:] = np.cumsum(totals)

        for index, val in enumerate(algorithms):

            if metadatas[n]['algorithm'] == val:
                break

        if type == 'norm':
            means[index, int(input_indexes[index])] = np.mean(cumulatives[:, -1]/ metadatas[n]['bot_num'], axis=0)
            stdevs[index, int(input_indexes[index])] = np.std(cumulatives[:, -1] / metadatas[n]['bot_num'], axis=0)

            maxes[index, int(input_indexes[index])] = np.max(cumulatives[:, -1] / metadatas[n]['bot_num'], axis=0)
            mins[index, int(input_indexes[index])] = np.min(cumulatives[:, -1] / metadatas[n]['bot_num'], axis=0)


        elif type == 'raw':

            means[index, int(input_indexes[index])] = np.mean(cumulatives[:, -1])
            stdevs[index, int(input_indexes[index])] = np.std(cumulatives[:, -1])

            maxes[index, int(input_indexes[index])] = np.max(cumulatives[:, -1])
            mins[index, int(input_indexes[index])] = np.min(cumulatives[:, -1])

        if metadatas[0]['var_name'] == 'Coverage' or metadatas[0]['var_name'] == 'Base Location':
            x_labels[index, int(input_indexes[index])] = (metadatas[n]['var_val'])
        else:
            x_labels[index, int(input_indexes[index])] = (float(metadatas[n]['var_val']))

        input_indexes[index] += 1

    markers = ['X', 'v', 's', 'o', 'd']

    # plt.fill_between(xs / tps, maxes, mins, color = colour, alpha = 0.2)

    if len(algorithms) == 1:

        colour = next(ax._get_lines.prop_cycler)['color']

        if metadatas[0]['var_2_name'] == 'Algorithm':
            plt.errorbar(x_labels[0, :], means[0, :], yerr=stdevs[0, :] / num_samples, capsize=2, color=colour, marker= markers, mec = 'k', linestyle='--', label=algorithms[0])
            plt.legend(title="Algorithm:", loc = 'upper left')
        else:
            plt.errorbar(x_labels[0, :], means[0, :], yerr=stdevs[0, :] / num_samples, capsize=2, color=colour, marker= markers, mec = 'k', linestyle='--', label=metadatas[0]['var_2_val'])
            plt.legend(title=metadatas[0]['var_2_name'] + ":", loc = 'upper left')

        # plt.fill_between(x_labels[0, :], means[0, :] + maxes[0, :], means[0, :] - mins[0, :], color=colour, alpha=0.5)

    else:
        for i in range(len(algorithms)):

            colour = next(ax._get_lines.prop_cycler)['color']

            plt.errorbar(x_labels[i,:], means[i,:], yerr=stdevs[i,:], capsize=2, color=colour, marker= 'o' , mec = 'k', linestyle='--', label = algorithms[i])
            # plt.fill_between(x_labels[i, :], means[i, :] + stdevs[i, :], means[i, :] - stdevs[i, :], color=colour, alpha=0.25)
        plt.legend(title="Algorithm:")#, loc = 'upper left')



    plt.xlabel(metadatas[n]['var_name'])

    if type == "raw":
        y_string = "Mean number of transits"
    elif type == "norm":
        y_string = "Mean number of transits per robot"    # plt.xticks(rotation='vertical', fontsize=8)

    plt.ylabel(y_string)

    print(stdevs[4,1])
    print(means[4,1])


font = {'size' : 10}
# font = {'size' : 11}
matplotlib.rc('font', **font)

# path = path + 'tuning/independence_testing/'
# path = path + 'mega_test/'


display = 'totals' #mean, all, first, transit, totals
type = "raw"  # norm, raw

# folder_name = "test"
# plot_single_folder(path, folder_name, display, type)

# folders = ["q_5", "q_10", "q_20", "q_40"]
# plot_heatmap(path, folders, type)

# folders = ["rwg_0", "rwg_1", "rwg_2", "rwg_3", "rwg_4"]
# folders = ["c_check_0", "c_check_1", "c_check_2", "c_check_3", "c_check_4"]
# folders = ["k_self_0", "k_self_1", "k_self_2", "k_self_3", "k_self_4"]
folders = ["k_bias_0", "k_bias_1", "k_bias_2", "k_bias_3", "k_bias_4"]
plot_multi_folder(path, folders, display, type)

# folder_name = "arena_rand"
# plot_final(path, folder_name, display, type)

plt.tight_layout()
plt.show()

plt.savefig('Results/K_bias_tuning_sep.png', bbox_inches='tight')
# plt.savefig('Results/Arena_1_centre_norm', bbox_inches='tight')
#
# display = 'totals' #mean, all, first, transit, totals
# type = "raw"  # norm, raw
#
# plt.clf()
#
# plot_final(path, folder_name, display, type)
#
# plt.tight_layout()
# plt.show()
#
# plt.savefig('Results/Arena_1_centre_raw', bbox_inches='tight')
