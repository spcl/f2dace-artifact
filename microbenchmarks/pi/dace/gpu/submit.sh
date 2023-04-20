#!/bin/sh

for threads in 1; do
  sbatch -c ${threads} < job_pi.sh
done
