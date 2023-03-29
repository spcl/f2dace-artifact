import dace
from dace.transformation.auto.auto_optimize import auto_optimize
from dace.transformation.dataflow import MapCollapse, MapFission, MapFusion, RemoveIntermediateWrite
from dace.transformation.interstate import InlineSDFG
from dace.transformation.interstate.move_loop_into_map import MoveMapIntoLoop, MoveMapIntoIf
from typing import List, Set, Tuple


def find_defined_symbols(sdfg: dace.SDFG) -> Set[str]:
    return sdfg.symbols.keys() - sdfg.free_symbols


def fix_sdfg_symbols(sdfg: dace.SDFG):
    for state in sdfg.nodes():
        for node in state.nodes():
            if isinstance(node, dace.nodes.NestedSDFG):
                fix_sdfg_symbols(node.sdfg)
    for s in find_defined_symbols(sdfg):
        del sdfg.symbols[s]
        if s in sdfg.parent_nsdfg_node.symbol_mapping:
            del sdfg.parent_nsdfg_node.symbol_mapping[s]


def fix_arrays(sdfg: dace.SDFG):
    repl_dict = {'_for_it_0': 1}
    for sd in sdfg.all_sdfgs_recursive():
        sd.replace_dict(repl_dict, replace_in_graph=False, replace_keys=False)


def fix_sdfg_parents(sdfg: dace.SDFG):
    for sd in sdfg.all_sdfgs_recursive():
        if sd.parent is not None:
            if sd.parent.parent != sd.parent_sdfg:
                print(f"Fixing parent of {sd.label}")
                sd.parent_sdfg = sd.parent.parent


def find_toplevel_maps(sdfg: dace.SDFG) -> List[Tuple[dace.SDFG, dace.SDFGState, dace.nodes.MapEntry]]:
    map_entries = []
    for state in sdfg.nodes():
        scope_dict = state.scope_dict()
        for node in state.nodes():
            if isinstance(node, dace.nodes.MapEntry) and scope_dict[node] is None:
                map_entries.append((sdfg, state, node))
            elif isinstance(node, dace.nodes.NestedSDFG) and scope_dict[node] is None:
                map_entries.extend(find_toplevel_maps(node.sdfg))
    return map_entries


def count_sdfg_transient_memory(sdfg: dace.SDFG) -> int:
    memory = 0
    # for _, desc in sdfg.arrays.items():
    #     if desc.transient:
    #         memory += desc.total_size
    for sd in sdfg.all_sdfgs_recursive():
        for _, desc in sd.arrays.items():
            if desc.transient:
                memory += desc.total_size
    return memory


def count_map_transient_memory(sdfg: dace.SDFG, state: dace.SDFGState, map_entry: dace.nodes.MapEntry) -> int:
    memory = 0
    scope_children = state.scope_children()[map_entry]
    for node in scope_children:
        # TODO: This is too broad.
        if isinstance(node, dace.nodes.AccessNode) and node.desc(sdfg).transient:
            memory += sdfg.arrays[node.data].total_size
        elif isinstance(node, dace.nodes.MapEntry):
            memory += count_map_transient_memory(sdfg, state, node)
        elif isinstance(node, dace.nodes.NestedSDFG):
            memory += count_sdfg_transient_memory(node.sdfg)
    return memory


def fission_sdfg(sdfg: dace.SDFG, name: str = None, iteration: int = 0) -> int:

    if name:
        name = f"{name}_"
    else:
        name = ""
    top_level_maps = find_toplevel_maps(sdfg)
    count = 0
    for sd, state, map_entry in top_level_maps:
        mem = count_map_transient_memory(sd, state, map_entry)
        if dace.symbolic.issymbolic(mem):
            print(f"[{sd.label}, {state}, {map_entry}]: {mem} {'(TO FISSION)' if dace.symbolic.issymbolic(mem) else ''}")
            scope_children = state.scope_children()[map_entry]
            if len(scope_children) == 2 and isinstance(scope_children[0], dace.nodes.NestedSDFG):
                try:
                    MapFission.apply_to(sd, expr_index=1, map_entry=map_entry, nested_sdfg=scope_children[0])
                except ValueError:
                    try:
                        MoveMapIntoLoop.apply_to(sd, map_entry=map_entry, nested_sdfg=scope_children[0], map_exit=scope_children[1])
                    except ValueError:
                        try:
                            MoveMapIntoIf.apply_to(sd, map_entry=map_entry, nested_sdfg=scope_children[0], map_exit=scope_children[1])
                        except ValueError:
                            print("Map cannot be moved into loop")
                            continue
            else:
                try:
                    MapFission.apply_to(sd, expr_index=0, map_entry=map_entry)
                except ValueError:
                    print("Map cannot be fissioned (expr_index=0)")
                    continue
            count += 1
            sdfg.save(f'{name}interim_step_{iteration}.sdfg')
            # sdfg.validate()
            sdfg.simplify()
            sdfg.apply_transformations_repeated(RemoveIntermediateWrite)
            sd.apply_transformations_repeated(MapCollapse)
            sdfg.simplify()
            sdfg.apply_transformations_repeated(RemoveIntermediateWrite)
            fix_sdfg_symbols(sdfg)
            fix_arrays(sdfg)
            sdfg.save(f'{name}fission_step_{iteration}.sdfg')
    return count


# sdfg = dace.SDFG.from_file('cloudscexp2_optimized.sdfg')
sdfg = dace.SDFG.from_file('cloudsc-generic.sdfg')
# sdfg = dace.SDFG.from_file('cloudsc2nl_optimized2.sdfg')
# sdfg.apply_transformations(InlineSDFG)
fix_sdfg_symbols(sdfg)
#sdfg.compile()

count = 1
iteration = 0
while count > 0:
    count = fission_sdfg(sdfg, "cloudscexp2_2", iteration)
    # count = fission_sdfg(sdfg, "cloudsc2nl", iteration)
    # sdfg.compile()
    print(f"Fissioned {count} maps")
    iteration += 1
sdfg.simplify()
for sd, state, map_entry in find_toplevel_maps(sdfg):
    print(f"[{sd.label}, {state}, {map_entry}]: {count_map_transient_memory(sd, state, map_entry)}")
sdfg.save('almost_fissioned.sdfg')
sdfg.compile()

# # Check
# sdfg = dace.SDFG.from_file('fission_step_4.sdfg')
# # # fix_sdfg_parents(sdfg)
# # for sd, state, map_entry in find_toplevel_maps(sdfg):
# #     print(f"[{sd.label}, {state}, {map_entry}]: {count_map_transient_memory(sd, state, map_entry)}")
# # sdfg.compile()
# sdfg.apply_gpu_transformations()
# sdfg.view()
# sdfg.compile()

# ### Debugging

# # sdfg = dace.SDFG.from_file('ice_supersaturation_adjustment_routine_1679043900_1905677.sdfg')
# sdfg = dace.SDFG.from_file('cloudsc2nl_scalar_fiss.sdfg')
# auto_optimize(sdfg, device=dace.DeviceType.Generic)
# # sdfg.view()
# from dace import propagate_memlets_sdfg
# propagate_memlets_sdfg(sdfg)
# sdfg.validate()
# # sdfg.simplify(verbose=True)
# # sdfg.apply_transformations_repeated(MapFusion)
# # sdfg.view()
# # sdfg.validate()
# # sdfg.simplify(verbose=True)
# # fix_sdfg_symbols(sdfg)
# # sdfg.apply_transformations_repeated(RemoveIntermediateWrite)
# # sdfg.view()
# # sdfg.simplify(verbose=True)
# # sdfg.view()
# # sdfg.apply_transformations_repeated(MapCollapse)
# # # sdfg.view()
# # sdfg.simplify()
# # # sdfg.view()
# # sdfg.compile()
# # fission_sdfg(sdfg, 10)
# sdfg.compile()




