#!/bin/bash

git clone git@github.com:mcopik/dace.git
cd dace && git submodule update --init --recursive && git checkout new_transform_2 && git checkout a780ceabe3d89487bad7d27678452fa21eb9de61 && cd ..

python -m venv venv
source venv/bin/activate
pip install --editable dace 
