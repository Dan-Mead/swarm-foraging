import os

# os.chdir('..'), os.chdir('..')
# os.chdir('Experiments/scripts')
#
# path = os.path.abspath(os.curdir)

def write_file(variables, output_path):
    file = open("scripts/variables.lua", "w")


    file.write("variables = {} \n\n")

    for i in variables:

        file.write("variables." + i + " = " + str(variables[i]) +"\n\n")

    file.write("variables.output_path = \"" + output_path + "\"\n\n")

    file.write("return variables")

    file.close()



