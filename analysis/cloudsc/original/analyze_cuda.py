import sys
import glob
import os
import pandas as pd

data = []

for f in glob.glob(os.path.join(sys.argv[1], "*.txt")):

    vals = os.path.basename(f).split('.')
    type_ = vals[0]
    threads = int(vals[1])
    size = int(vals[2])
    nproma = int(vals[3])
    rep = int(vals[4])

    total_time = None
    execution_time = None
    for line in open(f, 'r'):
        if 'TOTAL' in line and len(line.split()) == 10:
            total_time = line.split()[7]
        elif 'core' in line and len(line.split()) == 11:
            execution_time = line.split()[7]

    if execution_time is not None and total_time is not None:
        data.append([type_, threads,size, nproma, rep, execution_time, total_time])
    else:
        print('Missing time',f)

df = pd.DataFrame(data, columns=['type', 'threads', 'size', 'nproma', 'repetition', 'execution_time', 'total_time'])
df = df[df['type'] == 'cuda']
df.to_csv('c_cuda.csv')

