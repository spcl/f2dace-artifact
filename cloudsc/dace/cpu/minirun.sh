#!/bin/bash
set -x

cd dwarf-p-cloudsc/build/

OMP_NUM_THREADS=1 gdb ./bin/dwarf-cloudsc-fortran 1 65536 4
