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
    #Config.set('compiler', 'cuda', 'assert_errors', value="true")
    Config.set('compiler', 'cpu', 'openmp_sections', value="false")

    globalsdfg = dace.SDFG.from_file("../pi_optim.sdfg")

    globalsdfg.compile()

