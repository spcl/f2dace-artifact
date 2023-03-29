
1. Run `install_deps.sh` to set up DaCe.

2. Run `compile_sdfg.sh` to generate the CPU-transformed SDFG and compile it.

3. In `cloudsc-modifications/CMakeLists.txt`, change lines 27 and 30 to point to `dace` and `.dacecache` in the current directory.

4. Run `install_cloudsc.sh` to create the CloudSC installation that uses DaCe-generated code.

5. Run `OMP_NUM_THREADS=<num-threads> ./bin/dwarf-cloudsc-fortran <num-threads> <ngoptot> <nproma>`

6. Run `OMP_NUM_THREADS=<num-threads> ./bin/dwarf-cloudsc-fortran <num-threads> <ngoptot> <nproma> | grep Time` to get only the time in milliseconds.
