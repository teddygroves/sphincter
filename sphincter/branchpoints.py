from pathlib import Path

import bambi as bmb
import numpy as np
import pandas as pd
import pandera as pa
from pandera.typing import DataFrame
from scipy.special import logit

ROOT_DIR = Path(__file__).parent.parent
DATA_DIR = ROOT_DIR / "data"
RAW_DIR = DATA_DIR / "raw"
IDATA_DIR = ROOT_DIR / "inferences" / "branchpoints"
PREPARED_DIR = DATA_DIR / "prepared"
RAW_DATA_FILE = (
    RAW_DIR / "angio-architecture" / "PA branch diameters 020323.xlsx"
)

YCOLS = ["is_sphincter", "is_bulb"]
FORMULAE = {
    "is_sphincter": "is_sphincter['True'] ~ age + branch_number + ln_depth",
    "is_bulb": "is_bulb['True'] ~ age + branch_number + ln_depth + logit_firstorder_per_pa",
}
FORMULA_BULB = ()

Age = pd.CategoricalDtype(categories=["adult", "old"], ordered=True)


def normalise_column_name(colname: str) -> str:
    return (
        colname.lower()
        .replace("1.", "first")
        .replace("bulb_diam", "bulb_diameter")
        .replace("sphinc_diam", "sphincter_diameter")
        .replace("firstord_diam", "firstorder_diameter")
        .replace("neck", "sphincter")
        .replace("/", "_per_")
        .replace(" ", "")
    )


def normalise_column_names(df: pd.DataFrame) -> pd.DataFrame:
    new = df.copy()
    new.columns = [normalise_column_name(c) for c in df.columns]
    return new


class BranchpointData(pa.DataFrameModel):
    mouse_id: str
    pa_id: str
    branch_id: str
    branch_number: float
    depth: float
    pa_diam: float
    sphincter_diameter: float
    firstorder_diameter: float = pa.Field(
        description="diameter of 1st order capillary"
    )
    forking: float = pa.Field(
        description="If yes, then the branch bifurcated immediately at the branchpoint, and there will not be any sphincter. Should be counted as not having a sphincter."
    )
    sphincter_per_firstorder: float = pa.Field(
        description="Neck is what we used to call the sphincter, if this number is less than 0.8, it is a sphincter"
    )
    firstorder_per_pa: float = pa.Field(
        description="The ratio of 1st order capillary to PA says something about the pressure drop."
    )
    is_sphincter: bool = pa.Field(
        description="Is the sphincter diameter less than 0.8 times the first order capillary diameter?"
    )
    is_bulb: bool = pa.Field(
        description="Is the bulb diameter at least 1.25 times the first order capillary diameter?"
    )


def load_data() -> pd.DataFrame:
    out = pd.read_excel(RAW_DATA_FILE, sheet_name="In vivo results")
    assert out is not None
    return out


def prepare_data(
    raw: pd.DataFrame,
) -> DataFrame[BranchpointData]:
    ln_cols = ["depth"]
    logit_cols = ["firstorder_per_pa"]
    dropna_cols = YCOLS + [
        "sphincter_diameter",
        "firstorder_diameter",
        "logit_firstorder_per_pa",
    ]
    # filtering
    branchpoints = raw.pipe(normalise_column_names).copy()
    # new columns
    branchpoints["mouse_id"] = branchpoints["date"].astype(str)
    branchpoints["age"] = branchpoints["age"].str.lower().astype(Age)
    branchpoints["pa_number"] = branchpoints["pa_number"].astype(str)
    branchpoints["branch_id"] = branchpoints["branch_number"].astype(str)
    branchpoints["branch_number"] = branchpoints["branch_number"].astype(float)
    branchpoints["depth"] = branchpoints["depth"].astype(float)
    branchpoints["is_sphincter"] = (
        branchpoints["sphincter_diameter"] / branchpoints["firstorder_diameter"]
        < 0.8
    )
    branchpoints["is_bulb"] = (
        branchpoints["bulb_diameter"] / branchpoints["firstorder_diameter"]
        > 1.25
    )
    branchpoints["firstorder_per_pa"] = branchpoints["firstorder_per_pa"].clip(
        upper=0.98
    )
    for ln_col in ln_cols:
        branchpoints[f"ln_{ln_col}"] = np.log1p(branchpoints[ln_col])
    for logit_col in logit_cols:
        branchpoints[f"logit_{logit_col}"] = logit(branchpoints[logit_col])
    branchpoints = branchpoints.dropna(subset=dropna_cols).copy()
    return branchpoints  # type: ignore


def main():
    msts_raw = load_data()
    branchpoints = prepare_data(msts_raw)
    branchpoints.to_csv(PREPARED_DIR / "branchpoints.csv")
    for ycol in YCOLS:
        model = bmb.Model(
            FORMULAE[ycol],
            data=branchpoints,
            family="bernoulli",
        )
        idata = model.fit(
            idata_kwargs={"log_likelihood": True},
            nuts={"max_treedepth": 10},
        )
        model.predict(idata, kind="response", inplace=True)
        model.predict(idata, kind="response_params", inplace=True)
        idata.to_netcdf(IDATA_DIR / f"{ycol}.nc")


if __name__ == "__main__":
    main()
