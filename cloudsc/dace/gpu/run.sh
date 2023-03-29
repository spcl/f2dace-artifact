#!/bin/bash

cd dwarf-p-cloudsc/build/

for proma in 1 4 128; do
  echo "Proma $proma"
  OMP_NUM_THREADS=1 ./bin/dwarf-cloudsc-fortran 1 65536 $proma 2>&1 | grep "Time";
done
