import os
import subprocess,sys
import time
import numpy as np

# file_name = "experiment.argos"

def run(file_name):

    # os.chdir('..')
    # os.chdir('..')
    # os.chdir('Experiments')
    path = os.path.abspath(os.curdir)

    cmd = " argos3 -c " + file_name

    start_time = time.time()

    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    out,err = process.communicate()

    # print(out.decode("utf-8"))
    print(out.decode("utf-8"))

    if err:
        print(err.decode("utf-8"))

    # while True:
    #     out = process.stdout.readline(1)
    #
    #     output = out.decode("utf-8")
    #     # print(output)
    #     if output == '':
    #         break
    end_time = time.time()

    print("Done in", np.round(end_time - start_time, 2) ,"s")