#!/bin/bash

git clone https://github.com/ecmwf-ifs/dwarf-p-cloudsc.git
cp cloudsc-modifications/* dwarf-p-cloudsc/src/cloudsc_fortran/

cd dwarf-p-cloudsc
./cloudsc-bundle create
./cloudsc-bundle build --build-type release --cloudsc-fortran=ON

