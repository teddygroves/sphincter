"""Provides functions prepare_data_x.

These functions should take in a dataframe of measurements and return a
PreparedData object.

"""
import json
import os

import numpy as np
import pandas as pd
import pandera as pa
from pandera.typing import DataFrame, Series
from pandera.dtypes import Category
from pydantic import BaseModel, ConfigDict

from sphincter import util

NAME_FILE = "name.txt"
COORDS_FILE = "coords.json"
MEASUREMENTS_FILE = "measurements.csv"

HERE = os.path.dirname(__file__)
DATA_DIR = os.path.join(HERE, "..", "data")
RAW_DIR = os.path.join(DATA_DIR, "raw")
PREPARED_DIR = os.path.join(DATA_DIR, "prepared")
RAW_DATA_FILES = {
    "measurements": os.path.join(RAW_DIR, "data_sphincter_paper.csv")
}

Age = pd.CategoricalDtype(categories=["adult", "old"], ordered=True)
TreatmentQ1 = pd.CategoricalDtype(
    categories=["baseline", "after_hyper", "after_ablation"],
    ordered=True,
)
TreatmentQ2 = pd.CategoricalDtype(
    categories=["baseline", "hyper", "after_hyper", "after_ablation", "hyper2"],
    ordered=True,
)
VesselTypeQ1 = pd.CategoricalDtype(
    categories=["pen_art", "sphincter", "bulb", "cap1", "cap2"],
    ordered=True,
)
VesselTypeQ2 = pd.CategoricalDtype(
    categories=["pen_art", "bulb", "cap1", "cap2", "cap3", "cap4", "cap5"],
    ordered=True,
)


class Q1MeasurementDF(pa.SchemaModel):
    """A dataframe that can be used to answer question 1

    Other columns are also allowed!
    """

    age: Series[Age] = pa.Field(coerce=True, nullable=False)
    mouse: Series[Category] = pa.Field(coerce=True, nullable=False)
    vessel_type: Series[VesselTypeQ1] = pa.Field(coerce=True, nullable=False)
    treatment: Series[TreatmentQ1] = pa.Field(coerce=True, nullable=False)
    pressure_d: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    diam_before: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    diam_after: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    diam_change: Series[float] = pa.Field(coerce=True, nullable=False)
    diam_log_ratio: Series[float] = pa.Field(coerce=True, nullable=False)
    diam_rel_change: Series[float] = pa.Field(coerce=True, nullable=False)


class Q2MeasurementDF(pa.SchemaModel):
    """A dataframe that can be used to answer question 1

    Other columns are also allowed!
    """

    age: Series[Age] = pa.Field(coerce=True, nullable=False)
    mouse: Series[Category] = pa.Field(coerce=True, nullable=False)
    vessel_type: Series[VesselTypeQ2] = pa.Field(coerce=True, nullable=False)
    treatment: Series[TreatmentQ2] = pa.Field(coerce=True, nullable=False)
    pd1: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    pd2: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    pd3: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    pd_sum: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    pd_ratio: Series[float] = pa.Field(coerce=True, ge=0, nullable=False)
    pc1: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    pc2: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    pc3: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    pc_sum: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    pc_ratio: Series[float] = pa.Field(coerce=True, ge=0, nullable=False)
    pressure_d: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)


class PreparedData(BaseModel):
    """A prepared dataset."""

    name: str
    coords: util.CoordDict
    measurements: pd.DataFrame
    model_config = ConfigDict(arbitrary_types_allowed=True)


class Q1Dataset(PreparedData):
    """A dataset that can answer question 1."""

    name: str
    coords: util.CoordDict
    measurements: DataFrame[Q1MeasurementDF]


class Q2Dataset(PreparedData):
    """A dataset that can answer question 1."""

    name: str
    coords: util.CoordDict
    measurements: DataFrame[Q2MeasurementDF]


def prepare_data():
    """Run main function."""
    print("Reading raw data...")
    raw_data = {
        k: pd.read_csv(v, index_col=None) for k, v in RAW_DATA_FILES.items()
    }
    data_preparation_functions_to_run = [prepare_data_q1, prepare_data_q2]
    print("Preparing data...")
    for dpf in data_preparation_functions_to_run:
        print(f"Running data preparation function {dpf.__name__}...")
        prepared_data = dpf(raw_data["measurements"])
        output_dir = os.path.join(PREPARED_DIR, prepared_data.name)
        print(f"\twriting files to {output_dir}")
        if not os.path.exists(PREPARED_DIR):
            os.mkdir(PREPARED_DIR)
        write_prepared_data(prepared_data, output_dir)


def load_prepared_data(directory: str) -> PreparedData:
    """Load prepared data from files in directory."""
    with open(os.path.join(directory, COORDS_FILE), "r") as f:
        coords = json.load(f)
    with open(os.path.join(directory, NAME_FILE), "r") as f:
        name = f.read()
    measurements = pd.read_csv(
        os.path.join(directory, MEASUREMENTS_FILE), index_col=0
    )
    dftype = Q1MeasurementDF if name == "q1" else Q2MeasurementDF
    return PreparedData(
        name=name,
        coords=coords,
        measurements=DataFrame[dftype](measurements),
    )


def write_prepared_data(prepped: PreparedData, directory):
    """Write prepared data files to a directory."""
    if not os.path.exists(directory):
        os.mkdir(directory)
        prepped.measurements.to_csv(os.path.join(directory, MEASUREMENTS_FILE))
    with open(os.path.join(directory, COORDS_FILE), "w") as f:
        json.dump(prepped.coords, f)
    with open(os.path.join(directory, NAME_FILE), "w") as f:
        f.write(prepped.name)


def prepare_data_q1(raw: pd.DataFrame) -> Q1Dataset:
    """Prepare data for question 1."""
    measurements = process_measurements_q1(raw)
    return Q1Dataset(
        name="q1",
        measurements=measurements,
        coords=util.CoordDict(
            {
                "mouse": measurements["mouse"].cat.categories,
                "vessel_type": measurements["vessel_type"].cat.categories,
                "age": measurements["age"].cat.categories,
                "treatment": measurements["treatment"].cat.categories,
                "observation": measurements.index.map(str).tolist(),
            }
        ),
    )


def process_measurements_q1(raw: pd.DataFrame) -> DataFrame[Q1MeasurementDF]:
    """Process the measurements dataframe."""

    def filter(df: pd.DataFrame) -> pd.Series:
        return (
            df["diam_max_after_stim"].notnull()
            & df["diam_mean_before_stim"].notnull()
        )

    new_names = {
        "diam_mean_before_stim": "diam_before",
        "diam_max_after_stim": "diam_after",
        "vessel": "vessel_type",
    }
    cols = list(
        Q1MeasurementDF.get_metadata()["Q1MeasurementDF"]["columns"].keys()
    )
    return DataFrame[Q1MeasurementDF](
        raw.loc[filter]
        .rename(columns=new_names)
        .assign(
            mouse=lambda df: df["mouse"].astype(str),
            diam_change=lambda df: df["diam_after"] - df["diam_before"],
            diam_log_ratio=lambda df: np.log(
                df["diam_after"] / df["diam_before"]
            ),
            diam_rel_change=lambda df: (df["diam_after"] - df["diam_before"])
            / df["diam_before"],
        )[cols]
        .sort_values(["age", "mouse", "vessel_type", "treatment"])
    )


def prepare_data_q2(raw: pd.DataFrame) -> Q2Dataset:
    """Prepare data for question 1."""
    measurements = process_measurements_q2(raw)
    return Q2Dataset(
        name="q2",
        measurements=measurements,
        coords=util.CoordDict(
            {
                "mouse": measurements["mouse"].cat.categories,
                "vessel_type": measurements["vessel_type"].cat.categories,
                "age": measurements["age"].cat.categories,
                "treatment": measurements["treatment"].cat.categories,
                "observation": measurements.index.map(str).tolist(),
            }
        ),
    )


def process_measurements_q2(raw: pd.DataFrame) -> DataFrame[Q2MeasurementDF]:
    """Process the measurements dataframe."""

    def filter(df: pd.DataFrame) -> pd.Series:
        return df["power_diam_h1"].notnull() & df["power_center_h1"].notnull()

    new_names = {
        "vessel": "vessel_type",
        "power_diam_h1": "pd1",
        "power_diam_h2": "pd2",
        "power_diam_h3": "pd3",
        "power_center_h1": "pc1",
        "power_center_h2": "pc2",
        "power_center_h3": "pc3",
    }
    cols = list(
        Q2MeasurementDF.get_metadata()["Q2MeasurementDF"]["columns"].keys()
    )
    return DataFrame[Q2MeasurementDF](
        raw.loc[filter]
        .rename(columns=new_names)
        .assign(
            mouse=lambda df: df["mouse"].astype(str),
            pd_sum=lambda df: df[["pd1", "pd2", "pd3"]].sum(axis=1).fillna(0),
            pc_sum=lambda df: df[["pc1", "pc2", "pc3"]].sum(axis=1).fillna(0),
            pd_ratio=lambda df: df["pd2"].fillna(0.0) / df["pd_sum"],
            pc_ratio=lambda df: df["pc2"].fillna(0.0) / df["pc_sum"],
        )[cols]
        .sort_values(["age", "mouse", "vessel_type", "treatment"])
    )
