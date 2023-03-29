import pathlib
import os
import sys

import dace

if __name__ == "__main__":

    from dace.config import Config
    Config.set('compiler', 'build_type', value="Release")
    Config.set('compiler', 'cuda', 'assert_errors', value="true")
    Config.set('compiler', 'cpu', 'openmp_sections', value="false")

    globalsdfg = dace.SDFG.from_file("cloudscexp2_simplify.sdfg")
    from dace.transformation.auto import auto_optimize as aopt
    aopt.auto_optimize(globalsdfg, dace.DeviceType.Generic)

    globalsdfg.save("cloudsc-generic.sdfg")

