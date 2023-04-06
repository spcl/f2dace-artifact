#!/bin/bash

git clone git@github.com:spcl/dace.git
cd dace && git submodule update --init --recursive && git checkout fortran_frontend_candidate_2 && git checkout 39fd28d41675988d214ff05153802831f0246a09 && cd ..

python -m venv venv
source venv/bin/activate
pip install --editable dace 
