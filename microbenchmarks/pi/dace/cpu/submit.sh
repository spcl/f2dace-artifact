#!/bin/sh

for threads in 1 2 4 8 16 32; do
  sbatch -c ${threads} < job_pi.sh
done
