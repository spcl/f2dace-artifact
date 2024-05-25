import sys
import glob
import os
import pandas as pd

data = []

for f in glob.glob(os.path.join(sys.argv[1], "baseline", "*.txt")):

    vals = os.path.basename(f).split('.')
    threads = int(vals[1])
    size = int(vals[2])
    rep = int(vals[3])

    time = None
    for line in open(f, 'r'):
        if 'Time' in line:
            time = float(line.split()[2])

    if time is not None:
        data.append(['baseline', threads,size, rep, time])
    else:
        print('Missing time',f)

for dace_type in ['baseline_cuda']:

    for gpu_type in ['a100', 'v100']:

        for f in glob.glob(os.path.join(sys.argv[1], dace_type, gpu_type, "*.txt")):

            vals = os.path.basename(f).split('.')
            threads = int(vals[1])
            size = int(vals[2])
            rep = int(vals[3])

            time = None
            for line in open(f, 'r'):
                if 'Time' in line:
                    time = float(line.split()[2])

            if time is not None:
                data.append([f'baseline_{gpu_type}', threads,size, rep, time])
            else:
                print('Missing time',f)

for dace_type in ['dace_cpu']:

    for f in glob.glob(os.path.join(sys.argv[1], dace_type, "*.txt")):

        vals = os.path.basename(f).split('.')
        threads = int(vals[1])
        size = int(vals[2])
        rep = int(vals[3])

        time = None
        for line in open(f, 'r'):
            if 'Time' in line:
                time = float(line.split()[1])

        if time is not None:
            data.append([dace_type, threads,size, rep, time])
        else:
            print('Missing time',f)

for dace_type in ['dace_gpu']:

    for gpu_type in ['a100', 'v100']:

        for f in glob.glob(os.path.join(sys.argv[1], dace_type, gpu_type, "*.txt")):

            vals = os.path.basename(f).split('.')
            threads = int(vals[1])
            size = int(vals[2])
            rep = int(vals[3])

            time = None
            for line in open(f, 'r'):
                if 'Time' in line:
                    time = float(line.split()[1])

            if time is not None:
                data.append([f'{dace_type}_{gpu_type}', threads,size, rep, time])
            else:
                print('Missing time',f)

df = pd.DataFrame(data, columns=['type', 'threads', 'size', 'repetition', 'execution_time'])
df.to_csv('microbenchmark_pi_new.csv')

