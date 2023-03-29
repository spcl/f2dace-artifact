from fparser.common.readfortran import FortranStringReader
from fparser.common.readfortran import FortranFileReader
from fparser.two.parser import ParserFactory
import sys, os
import numpy as np

current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

from dace import SDFG, SDFGState, nodes, dtypes, data, subsets, symbolic
from dace.frontend.fortran import fortran_parser
from fparser.two.symbol_table import SymbolTable
from dace.transformation.pass_pipeline import Pipeline
from dace.transformation.passes.scalar_fission import ScalarFission

import dace.frontend.fortran.ast_components as ast_components
import dace.frontend.fortran.ast_transforms as ast_transforms
import dace.frontend.fortran.fcdc_utils as fcdc_utils
import dace.frontend.fortran.ast_internal_classes as ast_internal_classes

if __name__ == "__main__":
    parser = ParserFactory().create(std="f2008")
    #testname = "int_assign"

    #testname = "arrayrange1"
    #testname = "cloudsc2ad"
    #testname = "cloudsc2nl-minimal"
    testname = "cloudscexp2"
    path = os.curdir
    reader = FortranFileReader(os.path.realpath(os.path.join(path, testname + ".F90")))
    ast = parser(reader)
    tables = SymbolTable
    own_ast = ast_components.InternalFortranAst(ast, tables)
    program = own_ast.create_ast(ast)
    functions_and_subroutines_builder = ast_transforms.FindFunctionAndSubroutines()
    functions_and_subroutines_builder.visit(program)
    own_ast.functions_and_subroutines = functions_and_subroutines_builder.nodes
    program = ast_transforms.functionStatementEliminator(program)
    program = ast_transforms.CallToArray(functions_and_subroutines_builder.nodes).visit(program)
    program = ast_transforms.CallExtractor().visit(program)
    program = ast_transforms.SignToIf().visit(program)
    program = ast_transforms.ArrayToLoop().visit(program)
    program = ast_transforms.SumToLoop().visit(program)
    program = ast_transforms.ForDeclarer().visit(program)
    program = ast_transforms.IndexExtractor().visit(program)
    ast2sdfg = fortran_parser.AST_translator(own_ast, __file__)
    sdfg = SDFG("top_level")
    ast2sdfg.top_level = program
    ast2sdfg.globalsdfg = sdfg
    ast2sdfg.translate(program, sdfg)

    for node, parent in sdfg.all_nodes_recursive():
        if isinstance(node, nodes.NestedSDFG):
            if 'CLOUDSCOUTER' in node.sdfg.name:
                sdfg = node.sdfg
                break
    sdfg.parent = None
    sdfg.parent_sdfg = None
    sdfg.parent_nsdfg_node = None
    sdfg.reset_sdfg_list()

    sdfg.validate()
    sdfg.save(os.path.join(path, testname + "_initial.sdfg"))

    from dace.transformation.passes import ScalarToSymbolPromotion
    for sd in sdfg.all_sdfgs_recursive():
        promoted = ScalarToSymbolPromotion().apply_pass(sd, {})
        print(f"Promoted the following scalars: {promoted}")
    sdfg.save(os.path.join(path, f'{testname}_promoted.sdfg'))
    from dace.sdfg import utils
    utils.normalize_offsets(sdfg)
    sdfg.save(os.path.join(path, f'{testname}_normalized.sdfg'))
    sdfg.simplify(verbose=True)
    sdfg.save(os.path.join(path, f'{testname}_simplified.sdfg'))
    pipeline = Pipeline([ScalarFission()])
    for sd in sdfg.all_sdfgs_recursive():
        results = pipeline.apply_pass(sd, {})[ScalarFission.__name__]
    print(len(results), "scalar fissions applied")
    sdfg.save(os.path.join(path, f'{testname}_scalar_fissioned.sdfg'))

    #from dace.transformation.dataflow import PruneConnectors
    #sdfg.apply_transformations_repeated([PruneConnectors], validate=True)

    sdfg.simplify(verbose=True)
    sdfg.save(os.path.join(path, testname + "_simplify.sdfg"))
    #from dace.transformation.auto import auto_optimize as aopt
    #aopt.auto_optimize(sdfg, dtypes.DeviceType.CPU)
    #sdfg.save(os.path.join(path, testname + "_optimized.sdfg"))
    #sdfg.compile()
