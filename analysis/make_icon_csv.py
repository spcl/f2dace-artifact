import polars as pl
import re
from pathlib import Path

def extract_millis_f90(filepath: Path, meta: dict) -> pl.DataFrame:
    millis = []

    # Read matching lines
    with open(filepath, "r") as f:
        for line in f:
            if "00 nh_solve.veltend" in line:
                parts = line.strip().split()
                assert parts
                millis.append(float(parts[-1])*1000)
    assert len(millis) == 90

    # Compute uncumsum (differences)
    orig = [millis[0]] + [millis[i] - millis[i - 1] for i in range(1, len(millis))]

    # Build the table with metadata
    df = pl.DataFrame({"millis": orig})
    df = df.with_columns([
        pl.lit(value).alias(key) for key, value in meta.items()
    ] + [pl.lit(1).alias('threads')])
    return df

def extract_millis_dace(filepath: Path, meta: dict) -> pl.DataFrame:
    millis = []

    # Read matching lines
    with open(filepath, "r") as f:
        for line in f:
            if "Timer Run took" in line:
                parts = line.strip().split()
                assert parts
                assert parts[-1] == 'us'
                millis.append(float(parts[-2])/1000)
    assert len(millis) == 90

    # Build the table with metadata
    df = pl.DataFrame({"millis": millis})
    df = df.with_columns([
        pl.lit(value).alias(key) for key, value in meta.items()
    ] + [pl.lit(1).alias('threads')])
    return df

logs_f90 = [
    ("R02B03.a100.fortran.log", {"label": "fortran/gpu/a100", "grid": "R02B03", "resolution": "320 km"}),
    ("R02B04.a100.fortran.log", {"label": "fortran/gpu/a100", "grid": "R02B04", "resolution": "160 km"}),
    ("R02B05.a100.fortran.log", {"label": "fortran/gpu/a100", "grid": "R02B05", "resolution": "80 km"}),
    ("R02B03.v100.fortran.log", {"label": "fortran/gpu/v100", "grid": "R02B03", "resolution": "320 km"}),
    ("R02B04.v100.fortran.log", {"label": "fortran/gpu/v100", "grid": "R02B04", "resolution": "160 km"}),
    ("R02B05.v100.fortran.log", {"label": "fortran/gpu/v100", "grid": "R02B05", "resolution": "80 km"}),
]

logs_dace = [
    ("R02B03.a100.dace.log", {"label": "dace/gpu/a100", "grid": "R02B03", "resolution": "320 km"}),
    ("R02B04.a100.dace.log", {"label": "dace/gpu/a100", "grid": "R02B04", "resolution": "160 km"}),
    ("R02B05.a100.dace.log", {"label": "dace/gpu/a100", "grid": "R02B05", "resolution": "80 km"}),
    ("R02B03.v100.dace.log", {"label": "dace/gpu/v100", "grid": "R02B03", "resolution": "320 km"}),
    ("R02B04.v100.dace.log", {"label": "dace/gpu/v100", "grid": "R02B04", "resolution": "160 km"}),
    ("R02B05.v100.dace.log", {"label": "dace/gpu/v100", "grid": "R02B05", "resolution": "80 km"}),
]

# Collect data from all
dfs = [extract_millis_f90(Path(f), meta) for f, meta in logs_f90] + [extract_millis_dace(Path(f), meta) for f, meta in logs_dace]

# Concatenate into a single DataFrame
df = pl.concat(dfs)

print(df)

df.write_csv("icon_gpu.csv")