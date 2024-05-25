import sys
import glob
import os
import pandas as pd

data = []

for ty in ['v100', 'a100']:

    for f in glob.glob(os.path.join(sys.argv[1], ty, "*.txt")):

        vals = os.path.basename(f).split('.')
        threads = int(vals[1])
        size = int(vals[2])
        nproma = int(vals[3])
        rep = int(vals[4])

        execution_time = None
        for line in open(f, 'r'):
            if 'Time' in line:
                execution_time = line.split()[1]
                break

        if execution_time is not None:
            data.append([threads,size, nproma, rep, execution_time, f'dace_{ty}'])
        else:
            print('Missing time',f)

df = pd.DataFrame(data, columns=['threads', 'size', 'nproma', 'repetition', 'execution_time', 'type'])
df.to_csv('dace_gpu_new.csv')

