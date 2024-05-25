#!/bin/bash -l
#
#SBATCH --job-name="pi_baseline"
#SBATCH --time=4:00:00
#SBATCH --mem=64000
#SBATCH --partition=total
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks-per-node=1
#SBATCH --exclusive
#SBATCH --nodelist=ault09
#SBATCH --hint=nomultithread
#SBATCH --error=cloudsc_fortran.%j.e
#SBATCH --output=cloudsc_fortran.%j.o

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

DATA_DIRECTORY=/users/mcopik/projects/2024/dace_icon/f2dace-artifact/data/microbenchmarks/pi_new/baseline
mkdir -p ${DATA_DIRECTORY}

DIRECTORY=/users/mcopik/projects/2024/dace_icon/f2dace-artifact/microbenchmarks/pi_new/baseline
cd $DIRECTORY
cd pi_examples/fortran_omp_pi_dir

for size in 1000000000 1250000000 1500000000 1750000000 2000000000; do

  for rep in {0..19}; do

    srun --accel-bind=v --cpu-bind=cores,verbose -n ${SLURM_NTASKS} ./pi ${size}  > ${DATA_DIRECTORY}/pi.${SLURM_CPUS_PER_TASK}.${size}.${rep}.txt 2>&1
  done

done


