#!/bin/bash -l
#
#SBATCH --job-name="cloudsc_c"
#SBATCH --time=4:00:00
#SBATCH --mem=64000
#SBATCH --partition=total
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks-per-node=1
#SBATCH --exclusive
#SBATCH --hint=nomultithread
#SBATCH --error=cloudsc_c.%j.e
#SBATCH --output=cloudsc_c.%j.o

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export SLURM_CPU_BIND=VERBOSE
export OMP_PLACES=cores
export OMP_PROC_BIND=close 

echo "MPI ranks: ${SLURM_NTASKS}"
echo "PerNode: ${SLURM_NTASKS_PER_NODE}"

echo "Nodes: ${SLURM_JOB_NUM_NODES} Tasks: ${SLURM_NTASKS}"
echo "Nodes: ${SLURM_JOB_NODELIST}"
echo "Bind Type: ${SLURM_CPU_BIND_TYPE}"
echo "Bind List: ${SLURM_CPU_BIND_LIST}"
echo "OpenMP places: ${OMP_PLACES}"
echo "OpenMP threads: ${OMP_NUM_THREADS}"

DATA_DIRECTORY=/users/mcopik/projects/2023/dace_gpu/new_transformation/artifact/data/cloudsc/original/c_cuda
mkdir -p ${DATA_DIRECTORY}

DIRECTORY=/users/mcopik/projects/2023/dace_gpu/new_transformation/artifact/cloudsc/original
cd $DIRECTORY
cd dwarf-p-cloudsc/build_cuda/

for size in 4096 8192 16384 32768 65536 131072 262144; do

  for nproma in 1 4 16 64 128; do

    for rep in {0..19}; do

      OMP_NUM_THREADS=1 srun --accel-bind=v --cpu-bind=cores,verbose -n ${SLURM_NTASKS} ./bin/dwarf-cloudsc-cuda 1 ${size} ${nproma} > ${DATA_DIRECTORY}/cuda.${SLURM_CPUS_PER_TASK}.${size}.${nproma}.${rep}.txt 2>&1

      OMP_NUM_THREADS=1 srun --accel-bind=v --cpu-bind=cores,verbose -n ${SLURM_NTASKS} ./bin/dwarf-cloudsc-cuda-hoist 1 ${size} ${nproma} > ${DATA_DIRECTORY}/cuda_hoist.${SLURM_CPUS_PER_TASK}.${size}.${nproma}.${rep}.txt 2>&1

      OMP_NUM_THREADS=1 srun --accel-bind=v --cpu-bind=cores,verbose -n ${SLURM_NTASKS} ./bin/dwarf-cloudsc-cuda-k-caching 1 ${size} ${nproma} > ${DATA_DIRECTORY}/cuda_k_caching.${SLURM_CPUS_PER_TASK}.${size}.${nproma}.${rep}.txt 2>&1

    done

  done

done

