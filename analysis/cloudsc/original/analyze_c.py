import sys
import glob
import os
import pandas as pd

data = []

for f in glob.glob(os.path.join(sys.argv[1], "*.txt")):

    vals = os.path.basename(f).split('.')
    threads = int(vals[1])
    size = int(vals[2])
    nproma = int(vals[3])
    rep = int(vals[4])

    time = None
    for line in open(f, 'r'):
        if 'TOTAL' in line and len(line.split()) == 11:
            time = line.split()[7]

    if time is not None:
        data.append([threads,size, nproma, rep,time])
    else:
        print('Missing time',f)

df = pd.DataFrame(data, columns=['threads', 'size', 'nproma', 'repetition', 'execution_time'])
df.to_csv('c_cpu.csv')

