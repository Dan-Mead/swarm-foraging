import xml.etree.ElementTree as ET
import os
import xml.dom.minidom
import numpy as np
import run_file
import gen_variables
import time


os.chdir('..'), os.chdir('..')
os.chdir('Experiments')

path = os.path.abspath(os.curdir)

def triple_to_string(x,y,z):
    return str(x) + ', ' + str(y) + ', ' + str(z)

def controllers(test_type):

    if test_type == 'ARW':
        script = './advanced_random_walk.lua'
    elif test_type == 'Ducat':
        script = './ducatelle.lua'
    elif test_type == 'Kasp':
        script = './kasprzok.lua'
    elif test_type == 'Comp':
        script = './composite.lua'
    elif test_type == 'CRW':
        script = './correlated_random_walk.lua'
    elif test_type == 'BRW':
        script = './biased_random_walk.lua'

    root[1][0][-1].attrib = {'script': './scripts/nest.lua'}
    root[1][1][-1].attrib = {'script': './scripts/target.lua'}

    root[1][2][-1].attrib = {'script': script}

def add_wall(length, xy, loc, width = 0.05, height = 0.2):

    global wall_num

    if xy == 'y':
        orient = 90
    else:
        orient = 0

    loc_x = loc[0]
    loc_y = loc[1]
    loc_z = loc[2]

    l = len(root[2])

    box = root[2].makeelement('box', {'id' : 'wall' + str(wall_num), 'movable': 'false', 'size' : triple_to_string(length,width,height)})
    root[2].append(box)
    box_body = root[2][l].makeelement('body', {'orientation' : str(orient) + ', 0, 0' , 'position': triple_to_string(loc_x, loc_y, loc_z)})
    root[2][l].append(box_body)

    wall_num += 1

def arena_walls():

    global arena_size

    size = triple_to_string(arena_size, 0.1, 0.2)
    orientations = ['90', '90', '0' , '0']
    locs = [triple_to_string(arena_size / 2, 0, 0), triple_to_string(-arena_size / 2, 0, 0),
            triple_to_string(0, arena_size / 2, 0), triple_to_string(0, -arena_size / 2, 0)]
    names = ['Eastwall', 'Westwall', 'Southwall', 'Northwall']


    for i in range(4):

        root[2][i].attrib = {'id': names[i], 'movable': 'false',
                                          'size': size}

        root[2][i][0].attrib = {'orientation': orientations[i] + ', 0, 0', 'position': locs[i]}

def landmarks(nest_loc, target_loc, range = 1):

    l = len(root[2])

    add = root[2].makeelement('foot-bot', {'id': 'nest', 'rab_range' : str(range)})
    root[2].append(add)
    add = root[2][l].makeelement('body', {'orientation': '90, 0, 0', 'position': triple_to_string(nest_loc[0], nest_loc[1], nest_loc[2])})
    root[2][l].append(add)
    add = root[2][l].makeelement('controller', {'config': 'nestbot'})
    root[2][l].append(add)


    add = root[2].makeelement('foot-bot', {'id': 'target', 'rab_range': str(range)})
    root[2].append(add)
    add = root[2][l+1].makeelement('body', {'orientation': '270, 0, 0', 'position': triple_to_string(target_loc[0], target_loc[1], target_loc[2])})
    root[2][l+1].append(add)
    add = root[2][l+1].makeelement('controller', {'config': 'foodbot'})
    root[2][l+1].append(add)

def add_bots(num_bots, nest_loc, arena_size, coverage = "nest"):

    size = 0.2

    width = np.ceil(np.sqrt(2*num_bots)) * size
    depth = width / 2

    if abs(nest_loc[0]) > abs(nest_loc[1]):

        min_x = nest_loc[0] - depth/2 - 2*size
        max_x = nest_loc[0] + depth/2 + 2*size

        min_y = nest_loc[1] - width/2 - 2*size
        max_y = nest_loc[1] + width/2 + 2*size

    else:

        min_x = nest_loc[0] - width / 2 - 3*size
        max_x = nest_loc[0] + width / 2 + 3*size

        min_y = nest_loc[1] - depth / 2 - 2*size
        max_y = nest_loc[1] + depth / 2 + 2*size

    list = np.around([min_x, max_x, min_y, max_y],2)

    for i in range(len(list)):
        if abs(list[i]) > arena_size/2:
            list[i] = arena_size/2 * abs(list[i]) / list[i]

    min_loc = triple_to_string(list[0], list[2], 0)
    max_loc = triple_to_string(list[1], list[3], 0)

    if coverage == "all":
        min_loc = triple_to_string(-arena_size/2, -arena_size/2, 0)
        max_loc = triple_to_string(arena_size/2, arena_size/2, 0)

    l = len(root[2])

    add = root[2].makeelement('distribute', {})
    root[2].append(add)

    add = root[2][l].makeelement('position', {'method': 'uniform', 'min': min_loc, 'max' : max_loc})
    root[2][l].append(add)

    add = root[2][l].makeelement('orientation', {'method': 'uniform', 'min':'0,0,0', 'max':'360,0,0'})
    root[2][l].append(add)

    add = root[2][l].makeelement('entity', {'quantity': str(num_bots), 'max_trials': '100', 'base_num' : '1'})
    root[2][l].append(add)

    add = root[2][l][2].makeelement('foot-bot', {'id': 'fb'})
    root[2][l][2].append(add)

    add = root[2][l][2][0].makeelement('controller', {'config': 'agents'})
    root[2][l][2][0].append(add)

def add_clutter(arena_size, type = 1):

    l = len(root[2])

    add = root[2].makeelement('distribute', {})
    root[2].append(add)

    add = root[2][l].makeelement('position', {'method': 'uniform', 'min': triple_to_string(-arena_size/2, -arena_size/2, 0), 'max' : triple_to_string(arena_size/2, arena_size/2, 0)})
    root[2][l].append(add)

    add = root[2][l].makeelement('orientation', {'method': 'uniform', 'min':'0,0,0', 'max':'360,0,0'})
    root[2][l].append(add)

    if type == 1:

        add = root[2][l].makeelement('entity', {'quantity': '8', 'max_trials': '100'})
        root[2][l].append(add)

        add = root[2][l][2].makeelement('box', {'id': 'ba', 'size' : triple_to_string(1,1,0.5), 'movable' : 'false'})
        root[2][l][2].append(add)

    elif type == 2:

        add = root[2][l].makeelement('entity', {'quantity': '4', 'max_trials': '100'})
        root[2][l].append(add)

        add = root[2][l][2].makeelement('box', {'id': 'bc', 'size': triple_to_string(3, 0.5, 0.5), 'movable': 'false'})
        root[2][l][2].append(add)


def visualiser(viz, lua, size):

    if viz == False:
        root[5].attrib = {}
    else:
        if lua == True:
            add = root[5].makeelement('qt-opengl', {'lua_editor' : 'true'})
            root[5].append(add)
        else:
            add = root[5].makeelement('qt-opengl', {'lua_editor': 'false'})
            root[5].append(add)

        add = root[5][0].makeelement('camera', {})
        root[5][0].append(add)

        p = 3 * size / 5

        add = root[5][0][0].makeelement('placement', {'idx':'0', 'position': triple_to_string(0, -p, p), 'look_at' : '0,0,0', 'lens_focal_length':'20'})
        root[5][0][0].append(add)

        add = root[5][0][0].makeelement('placement', {'idx': '1', 'position': triple_to_string(0, 0, size*4/5), 'look_at': '0,0,0',
                                         'lens_focal_length': '20'})
        root[5][0][0].append(add)

######################################################################################

def generate_variables(coverage, tps, rwm, rwg, k_self, k_bias, d_check, k_check, c_check, num_bots):

    if coverage == "all":
        prop_foraging = 0.5
    else:
        prop_foraging = 1

    variables = {'coverage' : str(coverage),
                 'prop_foraging' : prop_foraging,
                 'tps' : tps, # ticks per second
                 'rwm' : rwm, # random walk mean (length)
                 'rwg' : rwg, # random walk gain
                 'k_self' : k_self, # Kappa value for CRW
                 'k_bias' : k_bias, # Kappa value for BRW
                 'd_check' : d_check, # Ducatelle Check Rate
                 'k_check' : k_check,  # Kasprzok Check Rate
                 'c_check' : c_check,  # Composite Check Rate
                 'num_bots' : num_bots # Number of Robots
                 }

    return variables

def generate_output_path(variables, test_type, test_variable, test_value, test_num):


    output_suffix = ("{:02d}".format(test_num))

    output_file_path = test_type + "_" + test_variable + "_" + str(test_value) + "_" + output_suffix

    return output_file_path

def generate_test(record, variables, test_type, test_variable, num_loops, seeds):

    global tree
    global root
    global wall_num
    global arena_size

    ###### Adjustables #####

    run_test = True

    coverage = variables['coverage']
    ticks_per_sec = variables['tps']  # best = 50
    rwm = variables['rwm']
    rwg = variables['rwg']
    k_self = variables['k_self']
    k_bias = variables['k_bias']
    d_check = variables['d_check']
    k_check = variables['k_check']
    c_check = variables['c_check']
    num_bots = variables['num_bots']

    landmark_range = 1

    wall_num = 0

    if test_variable == 'test':
        test_val = dummy_test_value
        test_var = dummy_test_variable
    else:
        test_val = variables[test_variable]
        test_var = test_variable

    if record == True:

        file = open("outputs/alltests_" + test_type + "_" + test_var + "_" + str(test_val) + ".txt", "w")
        file.write("Sim Time / TPS = " + str(sim_time * ticks_per_sec) + "|" + str(ticks_per_sec) + "\n")
        file.write("Number of Robots / Arena Size = " + str(num_bots) + "|" + str(arena_size) + "\n")
        file.write("Distribution = " + str(coverage) + "|" + "\n")
        file.write("Algorithm = " + str(test_type) + "|" + str(second_test_variable) + " = " + str(second_test_value) + "\n")
        file.write(test_var + " = " + str(test_val) + "\n")
        file.close()

        file = open("outputs/tests_list.txt", "a")
        file.write("alltests_" + test_type + "_" + test_var + "_" + str(test_val) + "\n")
        file.close()

        file = open("outputs/test_list_full.txt",
                    "a")
        file.write("\"alltests_" + test_type + "_" + test_var + "_" + str(test_val) + "\",\n")
        file.close()

    for test_num in range(num_loops):

        seed = seeds[test_num]

        tree = ET.parse('example_blank.argos')
        root = tree.getroot()
        output_file = ('experiment.argos')
        output_file_readable = output_file.replace('.', '_readable.')

        ######################################################################################

        ### Experiment Values

        experiment_values = root[0][0]
        experiment_values.attrib = {'length': str(sim_length), 'ticks_per_second': str(ticks_per_sec),
                                    'random_seed': str(seed)}

        ### Controller Scripts

        controllers(test_type)

        ### Arena values

        arena = root[2]
        arena.attrib = {'center': '0,0,0.5', 'size': str(arena_size) + ', ' + str(arena_size) + ', 1'}

        arena_walls()

        if obstacles == 0:

            nest_loc = [0, -(arena_size / 2 - 1.5), 0]
            target_loc = [0, (arena_size / 2 - 1.5), 0]

        elif obstacles == 1:
            add_wall(6, 'x', [0,1,0])
            add_wall(3, 'x', [-2.5,-1,0])
            add_wall(3, 'x', [2.5,-1,0])

            nest_loc = [0, -(arena_size / 2 - 0.5), 0]
            target_loc = [0, (arena_size / 2 - 0.5), 0]

        elif obstacles == 2:

            add_wall(2.5, 'y', [-1,3.75,0])
            add_wall(2.5, 'y', [1,3.75,0])
            add_wall(2.5, 'x', [-2.25,2.5,0])
            add_wall(2.5, 'x', [2.25,2.5,0])

            add_wall(2, 'x', [0,0.75,0], 1.5)

            add_wall(6, 'x', [0,-1,0])
            add_wall(2, 'y', [-3,-2,0])
            add_wall(2, 'y', [3,-2,0])
            add_wall(2, 'x', [-2,-3,0])
            add_wall(2, 'x', [2,-3,0])

            nest_loc = [0, - 2 * arena_size / 10, 0]
            target_loc = [0, 3.5 * arena_size / 10, 0]

        elif obstacles == 3:

            nest_loc = [4 * arena_size / 10, -4 * arena_size / 10, 0]
            target_loc = [-4 * arena_size / 10, 4 * arena_size / 10, 0]

            add_wall(2, 'y', [-3,4,0])
            add_wall(2, 'y', [-3,0,0])
            add_wall(6, 'x', [0,-3,0])
            add_wall(6, 'x', [-2,1,0])
            add_wall(4, 'x', [1,-1,0])
            add_wall(4, 'x', [1,3,0])
            add_wall(4, 'y', [3,1,0])


        elif obstacles == 4:
            add_clutter(arena_size, 1)
            add_clutter(arena_size, 2)

            nest_loc = [0, -(arena_size / 2 - 0.5), 0]
            target_loc = [0, (arena_size / 2 - 0.5), 0]



        # add_wall(length, xy, loc)

        landmarks(nest_loc, target_loc, landmark_range)  # assumes only one target for now

        add_bots(num_bots, nest_loc, arena_size, coverage)

        ### Visualiser Parameters

        visualiser(viz, lua_editor, arena_size)

        tree.write(output_file)

        dom = xml.dom.minidom.parse(output_file)
        pretty_xml_as_string = dom.toprettyxml()
        with open(output_file_readable, "w") as f:
            f.write(pretty_xml_as_string)

        output_path = generate_output_path(variables, test_type, test_variable, test_val, test_num)

        if record == True:
            file = open(
                "outputs/alltests_" + test_type + "_" + test_var + "_" + str(test_val) + ".txt", "a")
            file.write(output_path + ".txt\n")
            file.close()

        gen_variables.write_file(variables, output_path)

        if run_test:
            run_file.run(output_file)

        print("Test ", test_num + 1, "of ", num_loops, "complete." + " ("+ str(test_type) + "; " + str(test_var) + " = " + str(test_val) + ")")



sim_time = 2000
sim_length = sim_time
ticks_per_sec = 10
arena_size = 10
rwm = 200

record = True
viz = False
lua_editor = False


if record == False:
    file = open("outputs/tests_list.txt", "w")
    file.close()

    file = open("outputs/test_list_full.txt",
               "a")
    file.write("")
    file.close()

true_start_time = time.time()

coverage = "nest"  # all

obstacles = 0

if obstacles == 0 or obstacles == 1:
    rwg = 1.5 # best, 1.5 L, 1.0 H
else:
    rwg = 1

k_self = 5 #best, 5 all
k_bias = 5 #best, 5, all
d_check = 30 # best = 30
k_check = 30 # best  = 30
c_check = 1
num_bots = 24


test_var = 'num_bots'
num_repeats = 10
seeds = np.random.randint(1,9999, size = num_repeats)

second_test_variable = 'Arena' # plain text for legend
second_test_value = obstacles

# dummy_test_values = [10,50,100,150,200]
# dummy_test_variable = "Random Walk Mean"
# for dummy_test_value in dummy_test_values:

for num_bots in [8, 24, 40, 64, 80]:
# for k_bias in [1,2,5,8,10,20]:
# for num_bots in [80]:

    # rwm = dummy_test_value

    k_bias = 5

    variables = generate_variables(coverage, ticks_per_sec, rwm, rwg, k_self, k_bias, d_check, k_check, c_check, num_bots)

    generate_test(record, variables, 'CRW', test_var, num_repeats, seeds)
    generate_test(record, variables, 'BRW', test_var, num_repeats, seeds)
    generate_test(record, variables, 'Kasp', test_var, num_repeats, seeds)
    generate_test(record, variables, 'Ducat', test_var, num_repeats, seeds)

    k_bias = 10

    variables = generate_variables(coverage, ticks_per_sec, rwm, rwg, k_self, k_bias, d_check, k_check, c_check, num_bots)

    generate_test(record, variables, 'Comp', test_var, num_repeats, seeds)


print("All Tests Finished")
print("All tests took ", np.round(time.time() - true_start_time,2), " seconds to complete.")
if record == True:
    file = open("outputs/test_list_full.txt",
                "a")
    file.write("\n")
    file.close()

os.system('play -nq -t alsa synth {} sine {}'.format(1, 440))