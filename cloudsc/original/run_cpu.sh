#!/bin/bash

set -x

pushd dwarf-p-cloudsc/build_cpu > /dev/null

echo "Fortran version"
for threads in 1 2 4 8 16 24 32; do
  for proma in 1 4 128; do
    echo "Threads $threads, proma $proma"
    OMP_NUM_THREADS=$threads ./bin/dwarf-cloudsc-fortran $threads 65536 $proma 2>&1
  done
done

echo "C version"
for threads in 1 2 4 8 16 24 32; do
  for proma in 1 4 128; do
    echo "Threads $threads, proma $proma"
    OMP_NUM_THREADS=$threads ./bin/dwarf-cloudsc-c $threads 65536 $proma 2>&1
  done
done

popd
