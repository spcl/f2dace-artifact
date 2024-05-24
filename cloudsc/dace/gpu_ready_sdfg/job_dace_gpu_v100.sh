#!/bin/bash -l
#
#SBATCH --job-name="dace_cpu_cloudsc"
#SBATCH --time=4:00:00
#SBATCH --mem=64000
#SBATCH --partition=total
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks-per-node=1
#SBATCH --exclusive
#SBATCH --nodelist=ault09
#SBATCH --hint=nomultithread
#SBATCH --error=dace_cpu_cloudsc.%j.e
#SBATCH --output=dace_cpu_cloudsc.%j.o

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

DATA_DIRECTORY=/users/mcopik/projects/2024/dace_icon/f2dace-artifact/data/cloudsc/dace/gpu_new/v100
mkdir -p ${DATA_DIRECTORY}

DIRECTORY=/users/mcopik/projects/2023/dace_gpu/june_clean_generation/new_test_strided
cd $DIRECTORY
cd dwarf-p-cloudsc/build

for size in 4096 8192 16384 32768 65536 131072 262144; do

  for nproma in 1; do

    for rep in {0..19}; do

      srun --accel-bind=v --cpu-bind=cores,verbose -n ${SLURM_NTASKS} bin/dwarf-cloudsc-fortran 1 ${size} ${nproma} > ${DATA_DIRECTORY}/dace_cpu.${SLURM_CPUS_PER_TASK}.${size}.${nproma}.${rep}.txt 2>&1
    done

  done

done


