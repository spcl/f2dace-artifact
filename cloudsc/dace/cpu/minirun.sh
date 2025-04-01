#!/bin/bash
set -x

cd dwarf-p-cloudsc/build/

OMP_NUM_THREADS=1 gdb --args ./bin/dwarf-cloudsc-fortran 1 65536 4
# OMP_NUM_THREADS=1 ./bin/dwarf-cloudsc-fortran 1 65536 4

