#!/bin/bash

pushd dwarf-p-cloudsc/build_openacc > /dev/null

echo "OpenACC version"
for proma in 1 4 128; do
  echo "proma $proma"
  OMP_NUM_THREADS=1 ./bin/dwarf-cloudsc-gpu-scc 1 65536 $proma 2>&1 | grep "TOTAL" | grep -v "rank" | awk '{print $10}';
done

echo "OpenACC hoist version"
for proma in 1 4 128; do
  echo "proma $proma"
  OMP_NUM_THREADS=1 ./bin/dwarf-cloudsc-gpu-scc-hoist 1 65536 $proma 2>&1 | grep "TOTAL" | grep -v "rank" | awk '{print $10}';
done

popd
