#!/bin/bash

pushd dwarf-p-cloudsc/build_cuda > /dev/null

echo "CUDA version"
for proma in 1 4 128; do
  echo "proma $proma"
  OMP_NUM_THREADS=1 ./bin/dwarf-cloudsc-cuda 1 65536 $proma 2>&1 | grep "TOTAL" | awk '{print $8}';
done

echo "CUDA hoist version"
for proma in 1 4 128; do
  echo "proma $proma"
  OMP_NUM_THREADS=1 ./bin/dwarf-cloudsc-cuda-hoist 1 65536 $proma 2>&1 | grep "TOTAL" | awk '{print $8}';
done

echo "CUDA k caching version"
for proma in 1 4 128; do
  echo "proma $proma"
  OMP_NUM_THREADS=1 ./bin/dwarf-cloudsc-cuda-k-caching 1 65536 $proma 2>&1 | grep "TOTAL" | awk '{print $8}';
done

popd
