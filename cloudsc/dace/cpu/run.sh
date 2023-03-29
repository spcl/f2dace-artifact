#!/bin/bash

cd dwarf-p-cloudsc/build/

for threads in 1 2 4 8 16 24 32; do
  for proma in 1 4 128; do
    echo "Threads $threads, proma $proma"
    OMP_NUM_THREADS=$threads ./bin/dwarf-cloudsc-fortran $threads 65536 $proma 2>&1 | grep "Time";
  done
done
