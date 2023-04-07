import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


# dace_cpu = pd.read_csv('dace_cpu.csv')
# dace_gpu = pd.read_csv('dace_gpu.csv')
# fortran_cpu = pd.read_csv('fortran_cpu.csv')
# fortran_openacc = pd.read_csv('fortran_openacc.csv')
# c_cpu = pd.read_csv('c_cpu.csv')
# c_cuda = pd.read_csv('c_cuda.csv')

df = pd.read_csv('microbenchmark_pi.csv')
size_filter = df[df['size'] == df['size'].max()]

baseline_single = size_filter[np.logical_and(size_filter['type'] == 'baseline', size_filter['threads'] == 1)]
baseline_multi = size_filter[np.logical_and(size_filter['type'] == 'baseline', size_filter['threads'] == 32)]
baseline_single['type'] = 'Fortran (1 thread)'
baseline_multi['type'] = 'Fortran (32 threads)'
dace_cpu_single = size_filter[np.logical_and(size_filter['type'] == 'dace_cpu', size_filter['threads'] == 1)]
dace_cpu_multi = size_filter[np.logical_and(size_filter['type'] == 'dace_cpu', size_filter['threads'] == 32)]
dace_cpu_single['type'] = 'DaCe CPU (1 thread)'
dace_cpu_multi['type'] = 'DaCe CPU (32 threads)'
dace_gpu = size_filter[size_filter['type'] == 'dace_gpu']
dace_gpu['type'] = 'DaCe GPU'

for d in [dace_cpu_single, dace_cpu_multi, dace_gpu]:
    d['execution_time'] = d['execution_time'] / 1000

# dframes = [dace_cpu, dace_gpu, fortran_cpu, fortran_openacc, c_cpu, c_cuda]
# cpu_frames = [dframes[0], dframes[2], dframes[4]]
# gpu_frames = [dframes[1], dframes[3], dframes[5]]

# cpu_filter_by_size = [df[df['size'] == 65536//8] for df in cpu_frames]
# gpu_filter_by_size = [df[df['size'] == 65536//8] for df in gpu_frames]

# single_thread = [df[df['threads'] == 1] for df in cpu_filter_by_size]
# multi_thread = [df[df['threads'] == 32] for df in cpu_filter_by_size]

# single_by_nproma = [df.groupby('nproma').mean().reset_index() for df in single_thread]
# multi_by_nproma = [df.groupby('nproma').mean().reset_index() for df in multi_thread]
# gpu_by_nproam = [df.groupby('nproma').mean().reset_index() for df in gpu_filter_by_size]

# single_min_time = [df[df['execution_time'] == df['execution_time'].min()] for df in single_by_nproma]
# multi_min_time = [df[df['execution_time'] == df['execution_time'].min()] for df in multi_by_nproma]
# gpu_min_time = [df[df['execution_time'] == df['execution_time'].min()] for df in gpu_by_nproam]

# single_best_nproma = [df['nproma'].values[0] for df in single_min_time]
# multi_best_nproma = [df['nproma'].values[0] for df in multi_min_time]
# gpu_best_nproma = [df['nproma'].values[0] for df in gpu_min_time]

# single_best_nproma_runtimes = [df[df['nproma'] == single_best_nproma[i]] for i, df in enumerate(single_thread)]
# multi_best_nproma_runtimes = [df[df['nproma'] == multi_best_nproma[i]] for i, df in enumerate(multi_thread)]
# gpu_best_nproma_runtimes = [df[df['nproma'] == gpu_best_nproma[i]] for i, df in enumerate(gpu_filter_by_size)]

# dace_cpu_single = single_best_nproma_runtimes[0]
# dace_cpu_single['implementation'] = 'DaCe'
# dace_cpu_single['execution'] = 'CPU sequential'
# fortran_cpu_single = single_best_nproma_runtimes[1]
# fortran_cpu_single['implementation'] = 'Fortran'
# fortran_cpu_single['execution'] = 'CPU sequential'
# c_cpu_single = single_best_nproma_runtimes[2]
# c_cpu_single['implementation'] = 'C'
# c_cpu_single['execution'] = 'CPU sequential'

# dace_cpu_multi = multi_best_nproma_runtimes[0]
# dace_cpu_multi['implementation'] = 'DaCe'
# dace_cpu_multi['execution'] = 'CPU parallel'
# fortran_cpu_multi = multi_best_nproma_runtimes[1]
# fortran_cpu_multi['implementation'] = 'Fortran'
# fortran_cpu_multi['execution'] = 'CPU parallel'
# c_cpu_multi = multi_best_nproma_runtimes[2]
# c_cpu_multi['implementation'] = 'C'
# c_cpu_multi['execution'] = 'CPU parallel'

# dace_gpu = gpu_best_nproma_runtimes[0]
# dace_gpu['implementation'] = 'DaCe'
# dace_gpu['execution'] = 'GPU'
# fortran_openacc = gpu_best_nproma_runtimes[1]
# fortran_openacc['implementation'] = 'Fortran'
# fortran_openacc['execution'] = 'GPU'
# c_cuda = gpu_best_nproma_runtimes[2]
# c_cuda['implementation'] = 'C'
# c_cuda['execution'] = 'GPU'

# df_all = pd.concat([dace_cpu_single, dace_cpu_multi, fortran_cpu_single, fortran_cpu_multi, c_cpu_single, c_cpu_multi, dace_gpu, fortran_openacc, c_cuda])
df_all = pd.concat([baseline_single, baseline_multi, dace_cpu_single, dace_cpu_multi, dace_gpu])

g = sns.barplot(data=df_all, x="type", y="execution_time")
g.set_ylabel('Execution time [s]')
g.set_xlabel('')
# # plt.yscale('log')
# # plt.show()

# # g = sns.FacetGrid(df_all, col="execution")
# # g.map(sns.barplot, "implementation", "execution_time")
# # g.add_legend()
# # plt.show()

# # g = sns.catplot(data=df_all, x="execution", y="execution_time", hue='implementation', kind='bar')
# # plt.show()

# fig, (ax1, ax2, ax3) = plt.subplots(nrows=1, ncols=3, sharex=True)
# color = sns.color_palette("Set1", 3)
# sns.barplot(x='implementation', y='execution_time', palette=color, data=df_all[df_all['execution'] == 'CPU sequential'], ax=ax1)
# sns.barplot(x='implementation', y='execution_time', palette=color, data=df_all[df_all['execution'] == 'CPU parallel'], ax=ax2)
# sns.barplot(x='implementation', y='execution_time', palette=color, data=df_all[df_all['execution'] == 'GPU'], ax=ax3)
# # fig.text(0.5, 0.04, 'Implementation', ha='center')
# ax1.set_ylabel('Execution time [s]')
# ax1.set_ylim(top=1500)
# ax1.set_xlabel('CPU sequential')
# ax2.set_ylabel('')
# ax2.set_ylim(top=90)
# ax2.set_xlabel('CPU parallel')
# ax3.set_ylabel('')
# ax3.set_ylim(top=30)
# ax3.set_xlabel('GPU')
fig = g.get_figure()
fig.tight_layout()
plt.show()
fig.savefig('fig_pi.pdf', bbox_inches='tight')
