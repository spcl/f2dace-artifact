#!/bin/bash

git clone git@github.com:spcl/dace.git
cd dace && git submodule update --init --recursive && git checkout fortran_frontend_candidate_2 && git checkout bd39a19d36f8da06f58dc750ea95628f644dad24 && cd ..

python -m venv venv
source venv/bin/activate
pip install --editable dace 
