#!/bin/bash

for i in `seq 1 10`; do bash run_cpu.sh >run_cpu.sh.$i.log 2>&1; done
for i in `seq 1 10`; do bash run_cuda.sh >run_cuda.sh.$i.log 2>&1; done
for i in `seq 1 10`; do bash run_openacc.sh >run_openacc.sh.$i.log 2>&1; done
