#!/bin/bash

source venv/bin/activate
python f2d.py
python compile_generic.py
python map_fission.py
python compile_gpu.py
