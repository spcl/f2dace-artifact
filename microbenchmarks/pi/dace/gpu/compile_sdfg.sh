#!/bin/bash

source ../../../venv/bin/activate
python compile_gpu.py
c++ -I ../../../dace/dace/runtime/include/ -Wl,-rpath,$(pwd)/.dacecache/thepi/build  -L .dacecache/thepi/build thepi_main.cpp -lthepi -o thepi
