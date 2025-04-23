import re
from pathlib import Path

import polars as pl


def run_info(logname: str):
    match = re.search(r"^.+?\.(?P<threads>\d+)\.(?P<size>\d+)\.(?P<nproma>\d+)\.\d+\..*$", logname)
    assert match
    return match.group('threads'), match.group('size'), match.group('nproma')


def get_millis_v1(log: str):
    millis = []
    for l in log.splitlines():
        match = re.search(r"^Time (?P<millis>\d+) \[ms]$", l)
        if not match:
            continue
        millis.append(int(match.group('millis')))
    assert len(millis) == 1
    return millis[0]


def get_millis_v2(log: str):
    millis = []
    for l in log.splitlines():
        match = re.search(r"^Time (?P<millis>\d+) \[ms]$", l)
        if not match:
            continue
        millis.append(int(match.group('millis')))
    assert len(millis) == 2
    return millis[0]


def get_millis_v3(log: str):
    millis = []
    for l in log.splitlines():
        match = re.search(r".*?\s+(?P<millis>\d+)\s+(?P<ignore_1>\d+)\s+(?P<ignore_2>\d+)\s+TOTAL$", l)
        if not match:
            continue
        millis.append(int(match.group('millis')))
    assert len(millis) == 1
    return millis[0]


def get_millis_v4(log: str):
    millis = []
    for l in log.splitlines():
        match = re.search(r".*?\s+(?P<millis>\d+)\s+(?P<ignore_1>\d+)\s+@ core#$", l)
        if not match:
            continue
        millis.append(int(match.group('millis')))
    assert len(millis) == 1
    return millis[0]


def get_millis_v5(log: str):
    millis = []
    for l in log.splitlines():
        match = re.search(r".*?\s+(?P<millis>\d+)\s+(?P<ignore_1>\d+)\s+(?P<ignore_2>\d+)\s+:\s+TOTAL$", l)
        if not match:
            continue
        millis.append(int(match.group('millis')))
    if len(millis) != 1:
        print(log)
    assert len(millis) == 1
    return millis[0]


SCHEMA = [('label', pl.String), ('threads', pl.Int32), ('problem_size', pl.Int64), ('nproma', pl.Int64),
          ('millis', pl.Int64)]

label_to_logs = {
    'dace/cpu': 'data/cloudsc/dace/cpu/dace_cpu.*.txt',
    'dace/cpu/nonoptim': 'data/cloudsc/dace/cpu/nonoptim/dace_cpu.*.txt',
    'dace/gpu/v100': 'data/cloudsc/dace/gpu/dace_cpu.*.txt',
    'dace/gpu/a100': 'data/cloudsc/dace/gpu/a100/dace_cpu.*.txt',
    'dace/gpu_new/v100': 'data/cloudsc/dace/gpu_new/v100/dace_cpu.*.txt',
    'dace/gpu_new/a100': 'data/cloudsc/dace/gpu_new/a100/dace_cpu.*.txt',
    'original/c/cpu': 'data/cloudsc/original/c_cpu/c.*.txt',
    'original/c/cuda/v100': 'data/cloudsc/original/c_cuda/cuda.*.txt',
    'original/c/cuda/a100': 'data/cloudsc/original/c_cuda/a100/cuda.*.txt',
    'original/c/cuda_new/v100': 'data/cloudsc/original/c_cuda_new/v100/cuda.*.txt',
    'original/c/cuda_new/a100': 'data/cloudsc/original/c_cuda_new/a100/cuda.*.txt',
    'original/fortran/cpu': 'data/cloudsc/original/fortran_cpu/fortran.*.txt',
    'original/fortran/openacc': 'data/cloudsc/original/fortran_openacc/openacc.*.txt',
    'original/fortran/openacc/hoist': 'data/cloudsc/original/fortran_openacc/openacc_hoist.*.txt',
}

label_to_milliparser = {
    'dace/cpu': get_millis_v1,
    'dace/cpu/nonoptim': get_millis_v1,
    'dace/gpu/v100': get_millis_v2,
    'dace/gpu/a100': get_millis_v2,
    'dace/gpu_new/v100': get_millis_v2,
    'dace/gpu_new/a100': get_millis_v2,
    'original/c/cpu': get_millis_v3,
    'original/c/cuda/v100': get_millis_v4,
    'original/c/cuda/a100': get_millis_v4,
    'original/c/cuda_new/v100': get_millis_v4,
    'original/c/cuda_new/a100': get_millis_v4,
    'original/fortran/cpu': get_millis_v5,
    'original/fortran/openacc': get_millis_v5,
    'original/fortran/openacc/hoist': get_millis_v5,
}


def main():
    daata = []
    for label, lg_pat in label_to_logs.items():
        get_millis = label_to_milliparser[label]
        for lg in Path('..').rglob(lg_pat):
            th, sz, nproma = run_info(Path(lg).name)
            lg_content = Path(lg).read_text()
            if ('core dumped' in lg_content
                    or 'job termination' in lg_content
                    or 'Exited with exit code' in lg_content
                    or 'Out Of Memory' in lg_content
                    or 'Unable to create step' in lg_content):
                continue
            millis = get_millis(lg_content)
            assert millis > 0, lg
            daata.append({
                'log': lg,
                'label': label,
                'threads': th,
                'problem_size': sz,
                'nproma': nproma,
                'millis': millis,
            })
    daata = pl.DataFrame(daata, schema=SCHEMA)
    print(daata)
    daata.write_csv('daata.csv')


if __name__ == '__main__':
    main()
