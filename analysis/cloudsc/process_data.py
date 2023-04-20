#!/bin/sh

python dace/analyze_cpu.py ../../data/cloudsc/dace/cpu/
python dace/analyze_gpu.py ../../data/cloudsc/dace/gpu/
# silence warnings on data that we do not use.
python original/analyze_fortran.py ../../data/cloudsc/original/fortran_cpu > /dev/null
python original/analyze_c.py ../../data/cloudsc/original/c_cpu > /dev/nul
python original/analyze_cuda.py ../../data/cloudsc/original/c_cuda > /dev/null
python original/analyze_openacc.py ../../data/cloudsc/original/fortran_openacc > /dev/null
