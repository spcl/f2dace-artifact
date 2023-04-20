
# Artifact Identification

The main contribution of the paper is a new workflow that translates Fortran applications
into a data-centric representation called SDFG, applies data-flow optimizations in DaCe, and compiles the
applications to CPU and GPU.
We demonstrate that the semi-automatic optimization framework can parallelize applications
and generate optimized representation for CPUs and GPUs.
In the paper, we evaluate the new approach with microbenchmark and CloudSC, a large Fortran kernel
implementing cloud microphysics scheme.

We execute all benchmarks on cluster nodes, each one equipped with a 32-core AMD EPYC 7501 CPU @ 2.0 GHz,
512 GB memory, and NVIDIA Tesla V100 GPU with 32 GB of memory.
We use Python 3.10 with a development branch of DaCe, available
[in the official GitHub repository](https://github.com/spcl/dace/tree/fortran_frontend_candidate_2).
To compile generated code and baseline benchmarks, we use GNU GCC 10.2 and CUDA 11.8.

The computational artifact is [available on GitHub](https://github.com/spcl/f2dace-artifact)
and consists of four main components:
(a) a DaCe translation frontend for Fortran applications,
(b) a set of new SDFG transformations,
(c) benchmark reproduction with configuration and execution scripts,
and (d) generated data used in the paper.
With the artifact, one can generate all performance results presented in the paper: the evaluation
of CloudSC (Figures 1 and 10), as well as the microbenchmark evaluation (Figure 11).

# Reproducibility of Experiments

The artifact repository consists of three main components: `data` contains results generated and presented
in the paper, `analysis` includes all scripts used to produce plots included in the paper,
and `microbenchmarks` and `cloudsc` contain software needed to reproduce the results obtained in the paper.
For each benchmark, we provide Python and Bash scripts automating the entire procedure:

The essential results of the paper include the performance of the new workflow with the CloudSC benchmark,
and a Fortran Pi microbenchmark.
Given the cluster nodes described in previous part, it should not take more than 5 hours to repeat
experiments in all configurations.

## CloudSC

The benchmark is executed on CPU and GPU with the following configuration:
* Repetitions = 20
* CPU Threads = 1, 2, 4, 8, 16, 32
* Size values = 4096, 8192, 16384, 32768, 65536, 131072, 262144
* NPROMA values = 16 64 128

To prepare microbenchmarks, run first `install_deps.sh` in the `microbenchmarks` directory.
The script will install DaCe development branch at the commit version used for the experments.

### Baseline

* First, build the baseline benchmarks by stepping into `cloudsc/original` directory and running
`install_cloudsc.sh`.
* Adjust SLURM scripts `job_cpu_c.sh`, `job_cpu_fortran.sh`, `job_cuda.sh` and `job_openacc.sh`
by replacing directory paths to the current location of the artifact repository and adjusting `sbatch`
configuration to your system (partition, nodelist).
* Submit the baseline benchmark repetitions for CPU, CUDA, and OpenACC by running
`run_cpu.sh`, `run_cuda.sh`, and `run_openacc.sh`, respectively.
* The generated data can be found in `data/cloudsc/original/`.

### DaCe, CPU and GPU (our results)

* First, enter the directories `cloudsc/dace/{cpu,gpu}_ready_sdfg`.
* Build the benchmark by running the following scripts: `install_deps.sh`, `install_cloudsc.sh`,
and `compile_sdfg.sh`.
* Adjust the SLURM scripts `job_dace_cpu.sh` and `job_dace_gpu_a100.sh`
by replacing directory paths to the current location of the artifact repository and adjusting `sbatch`
configuration to your system (partition, nodelist).
* Submit the baseline benchmark repetitions by running `submit.sh`.
* The generated data can be found in `data/cloudsc/dace/{cpu,gpu}`.

### Plotting

To generate Figures 1 and 10, step into the directory `analysis/cloudsc`, run `process_data.py`,
and then execute scripts `plot_fig1.py` and `plot_figx.py`. These generate plots in PDF that were
later improved aesthetically and assembled into the final version in the paper.

## Microbenchmarks

To prepare microbenchmarks, run first `install_deps.sh` in the `microbenchmarks` directory.
The script will install DaCe development branch at the commit version used for the experments.

The microbenchmark includes the parallel Pi computation. The benchmark is executed with the following
configuration:
* Repetitions = 20
* Size = 1000000000, 1250000000, 1500000000, 1750000000, 2000000000
* CPU Threads = 1, 2, 4, 8, 16, 32

### Baseline

* First, build the baseline PI benchmark by stepping into `microbenchmarks/pi/baseline` directory and running
`install_deps.sh`.
* Adjust the SLURM script `job_pi.sh`
by replacing directory paths to the current location of the artifact repository and adjusting `sbatch`
configuration to your system (partition, nodelist).
* Submit the baseline benchmark repetitions by running `submit.sh`.
* The generated data can be found in `data/microbenchmarks/pi/baseline`.

### DaCe, CPU and GPU (our results)

* First, build the optimized benchmark by stepping into `microbenchmarks/pi/dace/{cpu, gpu}`
and run `compile_sdfg.sh`.
* Adjust the SLURM script `job_pi.sh`
by replacing directory paths to the current location of the artifact repository and adjusting `sbatch`
configuration to your system (partition, nodelist).
* Submit the baseline benchmark repetitions by running `submit.sh`.
* The generated data can be found in `data/microbenchmarks/pi/baseline`.

### Plotting

To generate Figure 11, step into the directory `analysis/mirobenchmarks` and run `process_data.py`,
followed by `plot_pi.py`.

