import pathlib
import os
import sys

import dace
from dace.sdfg import infer_types
from dace.transformation.auto.auto_optimize import make_transients_persistent
from dace.transformation.auto.auto_optimize import auto_optimize

if __name__ == "__main__":

    from dace.config import Config
    Config.set('compiler', 'build_type', value="Release")
    Config.set('compiler', 'cuda', 'assert_errors', value="true")
    Config.set('compiler', 'cpu', 'openmp_sections', value="false")

    globalsdfg = dace.SDFG.from_file("CLOUDSCOUTER_autoopt_loops_unrolled.sdfg")
    globalsdfg.apply_gpu_transformations_cloudsc()
    globalsdfg.simplify()

    from dace.transformation import helpers as xfh
    for n, p in globalsdfg.all_nodes_recursive():
        if isinstance(n, dace.nodes.MapEntry):
            if xfh.get_parent_map(p, n) is None:
                n.schedule = dace.ScheduleType.GPU_Device
            else:
                n.schedule = dace.ScheduleType.Sequential

    globalsdfg.save("cloudsc-gpu-before-infer.sdfg")
    infer_types.infer_connector_types(globalsdfg)
    infer_types.set_default_schedule_and_storage_types(globalsdfg, None)
    make_transients_persistent(globalsdfg, dace.DeviceType.GPU)

    globalsdfg.save("cloudsc-gpu.sdfg")

    globalsdfg.compile()

