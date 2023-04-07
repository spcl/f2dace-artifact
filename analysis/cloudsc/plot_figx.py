import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


dace_cpu = pd.read_csv('dace_cpu.csv')
dace_gpu = pd.read_csv('dace_gpu.csv')
fortran_cpu = pd.read_csv('fortran_cpu.csv')
fortran_openacc = pd.read_csv('fortran_openacc.csv')
c_cpu = pd.read_csv('c_cpu.csv')
c_cuda = pd.read_csv('c_cuda.csv')

dframes = [dace_cpu, dace_gpu, fortran_cpu, fortran_openacc, c_cpu, c_cuda]
cpu_frames = [dframes[0], dframes[2], dframes[4]]
gpu_frames = [dframes[1], dframes[3], dframes[5]]

# cpu_filter_by_size = [df[df['size'] == 65536] for df in cpu_frames]
# gpu_filter_by_size = [df[df['size'] == 65536] for df in gpu_frames]

# single_thread = [df[df['threads'] == 1] for df in cpu_filter_by_size]
# multi_thread = [df[df['threads'] == 32] for df in cpu_filter_by_size]

single_thread = [df[df['threads'] == 1] for df in cpu_frames]
multi_thread = [df[df['threads'] == 32] for df in cpu_frames]

single_by_nproma = [df.groupby('nproma').mean().reset_index() for df in single_thread]
multi_by_nproma = [df.groupby('nproma').mean().reset_index() for df in multi_thread]
gpu_by_nproam = [df.groupby('nproma').mean().reset_index() for df in gpu_frames]

single_min_time = [df[df['execution_time'] == df['execution_time'].min()] for df in single_by_nproma]
multi_min_time = [df[df['execution_time'] == df['execution_time'].min()] for df in multi_by_nproma]
gpu_min_time = [df[df['execution_time'] == df['execution_time'].min()] for df in gpu_by_nproam]

single_best_nproma = [df['nproma'].values[0] for df in single_min_time]
multi_best_nproma = [df['nproma'].values[0] for df in multi_min_time]
gpu_best_nproma = [df['nproma'].values[0] for df in gpu_min_time]

single_best_nproma_runtimes = [df[df['nproma'] == single_best_nproma[i]] for i, df in enumerate(single_thread)]
multi_best_nproma_runtimes = [df[df['nproma'] == multi_best_nproma[i]] for i, df in enumerate(multi_thread)]
gpu_best_nproma_runtimes = [df[df['nproma'] == gpu_best_nproma[i]] for i, df in enumerate(gpu_frames)]

dace_cpu_single = single_best_nproma_runtimes[0]
dace_cpu_single['implementation'] = 'DaCe'
dace_cpu_single['execution'] = 'CPU sequential'
fortran_cpu_single = single_best_nproma_runtimes[1]
fortran_cpu_single['implementation'] = 'Fortran'
fortran_cpu_single['execution'] = 'CPU sequential'
c_cpu_single = single_best_nproma_runtimes[2]
c_cpu_single['implementation'] = 'C'
c_cpu_single['execution'] = 'CPU sequential'

dace_cpu_multi = multi_best_nproma_runtimes[0]
dace_cpu_multi['implementation'] = 'DaCe'
dace_cpu_multi['execution'] = 'CPU parallel'
fortran_cpu_multi = multi_best_nproma_runtimes[1]
fortran_cpu_multi['implementation'] = 'Fortran'
fortran_cpu_multi['execution'] = 'CPU parallel'
c_cpu_multi = multi_best_nproma_runtimes[2]
c_cpu_multi['implementation'] = 'C'
c_cpu_multi['execution'] = 'CPU parallel'

dace_gpu = gpu_best_nproma_runtimes[0]
dace_gpu['implementation'] = 'DaCe'
dace_gpu['execution'] = 'GPU'
fortran_openacc = gpu_best_nproma_runtimes[1]
fortran_openacc['implementation'] = 'Fortran'
fortran_openacc['execution'] = 'GPU'
c_cuda = gpu_best_nproma_runtimes[2]
c_cuda['implementation'] = 'C'
c_cuda['execution'] = 'GPU'

df_all = pd.concat([dace_cpu_single, dace_cpu_multi, fortran_cpu_single, fortran_cpu_multi, c_cpu_single, c_cpu_multi, dace_gpu, fortran_openacc, c_cuda])

# sns.barplot(data=df_all, x="execution", y="execution_time", hue="implementation")
# plt.yscale('log')
# plt.show()

# g = sns.FacetGrid(df_all, col="execution")
# g.map(sns.barplot, "implementation", "execution_time")
# g.add_legend()
# plt.show()

# g = sns.catplot(data=df_all, x="execution", y="execution_time", hue='implementation', kind='bar')
# plt.show()

nproma_values = (1, 2, 4, 8, 16, 32, 64, 128)
sizes = (65536//2, 65536, 65536*2, 65536*4)

size = (8192, 16384, 32768, 65536, 131072, 262144)

# fig, (ax1, ax2, ax3) = plt.subplots(nrows=1, ncols=3)

color = sns.color_palette("Set1", 3)
impl = ['DaCe', 'Fortran', 'C']
fig, axes = plt.subplots(nrows=6, ncols=3)
for j, column in enumerate(axes):
    ax1, ax2, ax3 = column

    cdf = df_all[df_all['size'] == size[j]]
    sns.barplot(x='size', y='execution_time', hue='implementation', palette=color, data=cdf[cdf['execution'] == 'CPU sequential'], ax=ax1)
    sns.barplot(x='size', y='execution_time', hue='implementation', palette=color, data=cdf[cdf['execution'] == 'CPU parallel'], ax=ax2)
    sns.barplot(x='size', y='execution_time', hue='implementation', palette=color, data=cdf[cdf['execution'] == 'GPU'], ax=ax3)

    ax1.legend([], [], frameon=False)
    ax2.legend([], [], frameon=False)
    ax3.legend([], [], frameon=False)

    ax1.set_ylabel('Execution time [ms]')
    # ax1.set_ylim(top=43600)
    ax1.set_xlabel('CPU Sequential')
    ax2.set_ylabel('')
    # ax2.set_ylim(top=3600)
    ax2.set_xlabel('CPU Parallel')
    ax3.set_ylabel('')
    ax3.set_ylim(top=180)
    ax3.set_xlabel('GPU')

    # ax1.set_ylabel('Execution time [ms]')
    # # ax1.set_ylim(top=43600)
    # ax1.set_xlabel('Problem size')
    # xticks = []
    # start = 4
    # for i in range(7):
    #     xticks.append(f"{start}k")
    #     start *= 2
    # l = len(ax1.get_xticklabels())
    # ax1.set_xticklabels(xticks[:l])
    # ax2.set_ylabel('')
    # # ax2.set_ylim(top=3600)
    # ax2.set_xlabel('Problem size')
    # ax2.set_xticklabels(xticks)
    # ax3.set_ylabel('')
    # # ax3.set_ylim(top=180)
    # ax3.set_xlabel('Problem size')
    # ax3.set_xticklabels(xticks)


# # cdf = df_all[np.logical_and(df_all['size'] == sizes[i], df_all['nproma'].isin(nproma_values))]
# cdf = df_all
# # sns.barplot(x='implementation', y='execution_time', hue='size', palette=color, data=cdf[cdf['execution'] == 'CPU sequential'], ax=ax1)
# # sns.barplot(x='implementation', y='execution_time', palette=color, hue='size', data=cdf[cdf['execution'] == 'CPU parallel'], ax=ax2)
# # sns.barplot(x='implementation', y='execution_time', palette=color, hue='size', data=cdf[cdf['execution'] == 'GPU'], ax=ax3)

# sns.barplot(x='size', y='execution_time', hue='implementation', palette=color, data=cdf[cdf['execution'] == 'CPU sequential'], ax=ax1)
# sns.barplot(x='size', y='execution_time', palette=color, hue='implementation', data=cdf[cdf['execution'] == 'CPU parallel'], ax=ax2)
# sns.barplot(x='size', y='execution_time', palette=color, hue='implementation', data=cdf[cdf['execution'] == 'GPU'], ax=ax3)

# # fig.text(0.5, 0.04, 'Implementation', ha='center')
# ax1.legend([], [], frameon=False)
# ax2.legend([], [], frameon=False)
# ax3.legend([], [], frameon=False)

# # ax1.set_ylabel('Execution time [ms]')
# # ax1.set_ylim(top=43600)
# # ax1.set_xlabel('CPU Sequential')
# # ax2.set_ylabel('')
# # ax2.set_ylim(top=3600)
# # ax2.set_xlabel('CPU Parallel')
# # ax3.set_ylabel('')
# # ax3.set_ylim(top=180)
# # ax3.set_xlabel('GPU')

# ax1.set_ylabel('Execution time [ms]')
# ax1.set_ylim(top=43600)
# ax1.set_xlabel('Problem size')
# xticks = []
# start = 4
# for i in range(7):
#     xticks.append(f"{start}k")
#     start *= 2
# ax1.set_xticklabels(xticks)
# ax2.set_ylabel('')
# ax2.set_ylim(top=3600)
# ax2.set_xlabel('Problem size')
# ax2.set_xticklabels(xticks)
# ax3.set_ylabel('')
# ax3.set_ylim(top=180)
# ax3.set_xlabel('Problem size')
# ax3.set_xticklabels(xticks)


#     # for i, bar in enumerate(ax1.axes.patches): 

#     #     # move the missing to the centre
#     #     current_width = bar.get_width()
#     #     current_pos = bar.get_x()
#     #     if i == 0:
#     #         new_pos = current_pos + current_width*1.5
#     #         bar.set_x(new_pos)
#     #         # move also the std mark
#     #         ax1.axes.lines[i].set_xdata(new_pos)
#     #         # bar.set_width(current_width*3)

#     # for i, bar in enumerate(ax2.axes.patches): 

#     #     # move the missing to the centre
#     #     current_width = bar.get_width()
#     #     current_pos = bar.get_x()
#     #     if i == 0:
#     #         new_pos = current_pos + current_width*1.5
#     #         bar.set_x(new_pos)
#     #         # move also the std mark
#     #         ax1.axes.lines[i].set_xdata(new_pos)
#     #         # bar.set_width(current_width*3)

#     # for i, bar in enumerate(ax3.axes.patches): 

#     #     # move the missing to the centre
#     #     current_width = bar.get_width()
#     #     current_pos = bar.get_x()
#     #     if i == 0:
#     #         new_pos = current_pos + current_width*1.5
#     #         bar.set_x(new_pos)
#     #         # move also the std mark
#     #         ax1.axes.lines[i].set_xdata(new_pos)
#     #         # bar.set_width(current_width*3)


fig.tight_layout()
plt.show()
fig.savefig('figXd.pdf', bbox_inches='tight')
