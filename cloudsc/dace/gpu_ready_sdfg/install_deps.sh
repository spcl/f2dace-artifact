#!/bin/bash

git clone git@github.com:spcl/dace.git
cd dace && git submodule update --init --recursive && git checkout new_transform_2 && git checkout 7d81d427f04d911ec6f5b99125288b0cb713daaf && cd ..

python -m venv venv
source venv/bin/activate
pip install --editable dace 
