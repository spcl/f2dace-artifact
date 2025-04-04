#!/bin/bash
set -x

cd dwarf-p-cloudsc/build/

# OMP_NUM_THREADS=1 valgrind  --read-var-info=yes --track-origins=yes --log-file=val.log ./bin/dwarf-cloudsc-fortran 1 65536 128
# OMP_NUM_THREADS=1 valgrind --vgdb-error=0 ./bin/dwarf-cloudsc-fortran 1 655 4
# OMP_NUM_THREADS=1 gdb --args ./bin/dwarf-cloudsc-fortran 1 1 4
OMP_NUM_THREADS=1 ./bin/dwarf-cloudsc-fortran 1 65536 128

