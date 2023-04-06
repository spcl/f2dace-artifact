#!/bin/bash

git clone https://github.com/UCL-RITS/pi_examples.git
cd pi_examples
git checkout 0dd7d4e4ed48fb9fbba3897edfff76c5abd24ce9
cd fortran_omp_pi_dir/
make gfortran
