#!/bin/bash

git clone https://github.com/ecmwf-ifs/dwarf-p-cloudsc.git

cd dwarf-p-cloudsc
./cloudsc-bundle create
./cloudsc-bundle build --build-type release --cloudsc-fortran=ON --cloudsc-c=ON --build-dir build_cpu --with-serialbox

# This will fail - cloudsc still tries to compile Fortran with CUDA which does not work
./cloudsc-bundle build --build-type release --cloudsc-fortran=OFF --cloudsc-c=ON --with-cuda --build-dir build_cuda --with-serialbox; cd build_cuda && make dwarf-cloudsc-cuda dwarf-cloudsc-cuda-hoist dwarf-cloudsc-cuda-k-caching && cd ..

./cloudsc-bundle build --build-type release --cloudsc-fortran=ON --with-gpu --build-dir build_openacc

cp -r cloudsc_python_modifications/* dwarf-p-cloudsc/src/cloudsc_python
