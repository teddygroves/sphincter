from pathlib import Path

import bambi as bmb
import numpy as np
import pandas as pd
import pandera as pa
from pandera.typing import DataFrame, Series

ROOT_DIR = Path(__file__).parent.parent
DATA_DIR = ROOT_DIR / "data"
RAW_DIR = DATA_DIR / "raw"
IDATA_DIR = ROOT_DIR / "inferences" / "collaterals"
PREPARED_DIR = DATA_DIR / "prepared"
RAW_DATA_FILE = RAW_DIR / "angio-architecture" / "Collaterals measurement.xlsx"

FORMULA_AGE = "{y} ~ age"
FORMULA_AGE_AND_MOUSE = "{y} ~ (1|mouse_id) + (1|age)"

Age = pd.CategoricalDtype(categories=["adult", "old"], ordered=True)


class CollateralSchema(pa.DataFrameModel):
    mouse_id: Series[str] = pa.Field(unique=False)
    collateral_id: Series[str] = pa.Field(unique=True)
    age: Series[pd.CategoricalDtype] = pa.Field(
        coerce=True,
        nullable=False,
        dtype_kwargs={"categories": ["old", "adult"], "ordered": True},
    )
    diameter_mean: Series[float] = pa.Field(gt=0.0)
    diameter_sd: Series[float] = pa.Field(ge=0.0)
    curved_length: Series[float] = pa.Field(gt=0.0)
    straight_line_distance: Series[float] = pa.Field(gt=0.0)
    tortuosity: Series[float] = pa.Field(ge=1.0)
    ln_curved_length: Series[float] = pa.Field()
    ln_diameter_mean: Series[float] = pa.Field()
    ln_tortuosity: Series[float] = pa.Field()


class MouseSchema(pa.DataFrameModel):
    mouse_id: Series[str]
    age: Series[pd.CategoricalDtype] = pa.Field(
        coerce=True,
        nullable=False,
        dtype_kwargs={"categories": ["old", "adult"], "ordered": True},
    )
    craniotomy_area: Series[float] = pa.Field(gt=0.0)
    collaterals: Series[int] = pa.Field(ge=0)
    collaterals_per_area: Series[float] = pa.Field(ge=0.0)


def load_data() -> pd.DataFrame:
    out = pd.read_excel(RAW_DATA_FILE, sheet_name="For R")
    assert out is not None
    return out


def prepare_data(
    raw: pd.DataFrame,
) -> tuple[DataFrame[CollateralSchema], DataFrame[MouseSchema]]:
    dropna_cols = ["Distance", "CurvedLength", "Mean_diameter", "SD"]
    Age = pd.CategoricalDtype(categories=["adult", "old"], ordered=True)
    # filtering
    collaterals = (
        raw.dropna(subset=dropna_cols)
        .loc[lambda df: df["Distance"].le(df["CurvedLength"])]
        .copy()
    )
    # new columns
    collaterals["collateral_id"] = (
        collaterals["Date"]
        .astype(str)
        .str.cat(collaterals["CollateralNumber"].astype(str))
    )
    collaterals["mouse_id"] = collaterals["Date"].astype(str)
    collaterals["age"] = collaterals["Age"].str.lower().astype(Age)
    collaterals["diameter_mean"] = collaterals["Mean_diameter"]
    collaterals["diameter_sd"] = collaterals["SD"]
    collaterals["curved_length"] = collaterals["CurvedLength"]
    collaterals["straight_line_distance"] = collaterals["Distance"]
    collaterals["tortuosity"] = collaterals["CurvedLength"] / collaterals["Distance"]
    for ln_col in ["diameter_mean", "curved_length", "tortuosity"]:
        collaterals[f"ln_{ln_col}"] = np.log(collaterals[ln_col])
    gmice = collaterals.groupby("Date")
    mice = pd.DataFrame(
        {
            "mouse_id": gmice["Date"].first().astype(str),
            "age": gmice["age"].first(),
            "craniotomy_area": gmice["Craniotomy_area"].first() * 1e-6,
            "collaterals": gmice.size(),
        }
    )
    mice["collaterals_per_area"] = mice["collaterals"] / mice["craniotomy_area"]
    mice["ln_collaterals_per_area"] = np.log(mice["collaterals_per_area"])
    return collaterals, mice  # type: ignore


def main():
    msts_raw = load_data()
    collaterals, mice = prepare_data(msts_raw)
    collaterals.to_csv(PREPARED_DIR / "collaterals.csv")
    mice.to_csv(PREPARED_DIR / "collaterals-mice.csv")
    formula_mice = bmb.Formula(
        FORMULA_AGE.format(y="ln_collaterals_per_area"),
        "sigma ~ age",
    )
    model_ctls_per_area = bmb.Model(formula=formula_mice, data=mice)
    idata_ctls_per_area = model_ctls_per_area.fit(target_accept=0.9)
    model_ctls_per_area.predict(
        idata_ctls_per_area,
        kind="response",
        inplace=True,
    )
    model_ctls_per_area.predict(
        idata_ctls_per_area,
        kind="response_params",
        inplace=True,
    )
    idata_ctls_per_area.to_netcdf(IDATA_DIR / "ctls_per_area.nc")
    for ycol in ["ln_diameter_mean", "ln_curved_length", "ln_tortuosity"]:
        model = bmb.Model(FORMULA_AGE.format(y=ycol), data=collaterals)
        idata = model.fit()
        model.predict(idata, kind="response", inplace=True)
        model.predict(idata, kind="response_params", inplace=True)
        idata.to_netcdf(IDATA_DIR / f"{ycol}.nc")


if __name__ == "__main__":
    main()
