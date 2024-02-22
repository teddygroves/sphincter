"""Provides functions prepare_data_x.

These functions should take in a dataframe of measurements and return a
PreparedData object.

"""
import json
import os
from io import StringIO
from typing import Any, Dict, Union

import numpy as np
import pandas as pd
import pandera as pa
from pandera.dtypes import Category
from pandera.typing import DataFrame, Series
from pandera.typing.common import DataFrameBase
from pydantic import (
    BaseModel,
    field_serializer,
    field_validator,
)

from sphincter import util
from sphincter.stan_input_functions import (
    get_stan_input_whisker,
    get_stan_input_pulsatility,
    get_stan_input_flow_speed,
    get_stan_input_flow_flux,
    get_stan_input_hypertension,
    get_stan_input_density,
)

NAME_FILE = "name.txt"
COORDS_FILE = "coords.json"
MEASUREMENTS_FILE = "measurements.csv"

HERE = os.path.dirname(__file__)
DATA_DIR = os.path.join(HERE, "..", "data")
RAW_DIR = os.path.join(DATA_DIR, "raw")
PREPARED_DIR = os.path.join(DATA_DIR, "prepared")
RAW_DATA_FILES = {
    "measurements": os.path.join(RAW_DIR, "data_sphincter_paper.csv"),
    "measurements_hypertension": os.path.join(RAW_DIR, "hyper_challenge.csv"),
    "measurements_density": os.path.join(
        RAW_DIR, "angio-architecture", "CapillarySummary_Allcount3.xlsx"
    )
}
BAD_MICE = [310321]

Age = pd.CategoricalDtype(categories=["adult", "old"], ordered=True)
TreatmentWhisker = pd.CategoricalDtype(
    categories=["baseline", "after_hyper", "after_ablation"],
    ordered=True,
)
TreatmentPulsatility = pd.CategoricalDtype(
    categories=["baseline", "hyper", "after_hyper", "after_ablation", "hyper2"],
    ordered=True,
)
TreatmentFlow = pd.CategoricalDtype(
    categories=["baseline", "hyper", "after_hyper", "after_ablation", "hyper2"],
    ordered=True,
)
TreatmentHypertension = pd.CategoricalDtype(
    categories=["hyper1", "hyper2"], ordered=True
)
VesselTypeWhisker = pd.CategoricalDtype(
    categories=["pen_art", "sphincter", "bulb", "cap1", "cap2"],
    ordered=True,
)
VesselTypePulsatility = pd.CategoricalDtype(
    categories=["pen_art", "bulb", "cap1", "cap2", "cap3", "cap4", "cap5"],
    ordered=True,
)
VesselTypeFlow = pd.CategoricalDtype(
    categories=["sphincter", "bulb", "cap1", "cap2", "cap3", "cap4", "cap5"],
    ordered=True,
)
VesselTypeHypertension = pd.CategoricalDtype(
    categories=["pa", "sphincter", "bulb", "cap1", "cap2"], ordered=True
)
VesselTypeDensity = pd.CategoricalDtype(
    categories=[
        "pial_artery",
        "pa",
        "cap1",
        "cap2",
        "cap3",
        "cap4",
        "cap5",
        "cap6",
        "cap7",
        "cap8",
        "cap9",
        "cap10",
        "cap11",
        "cap12",
        "av",
        "pv",
    ], ordered=True
)


class WhiskerMeasurementSchema(pa.DataFrameModel):
    """A dataframe that can be used to answer question 1

    Other columns are also allowed!
    """

    age: Series[Age] = pa.Field(coerce=True, nullable=False)
    mouse: Series[Category] = pa.Field(coerce=True, nullable=False)
    vessel_type: Series[VesselTypeWhisker] = pa.Field(
        coerce=True, nullable=False
    )
    treatment: Series[TreatmentWhisker] = pa.Field(coerce=True, nullable=False)
    pressure_d: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    diam_before: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    diam_after: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    diam_change: Series[float] = pa.Field(coerce=True, nullable=False)
    diam_log_ratio: Series[float] = pa.Field(coerce=True, nullable=False)
    diam_rel_change: Series[float] = pa.Field(coerce=True, nullable=False)


class PulsatilityMeasurementSchema(pa.DataFrameModel):
    """A dataframe that can be used to answer question 1

    Other columns are also allowed!
    """

    age: Series[Age] = pa.Field(coerce=True, nullable=False)
    mouse: Series[Category] = pa.Field(coerce=True, nullable=False)
    vessel_type: Series[VesselTypePulsatility] = pa.Field(
        coerce=True, nullable=False
    )
    treatment: Series[TreatmentPulsatility] = pa.Field(
        coerce=True, nullable=False
    )
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
    pressure_d: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    pressure_norm: Series[float] = pa.Field(coerce=True, nullable=False)
    diameter: Series[float] = pa.Field(coerce=True, gt=0, nullable=False)
    diameter_norm: Series[float] = pa.Field(coerce=True, nullable=False)
    speed: Series[float] = pa.Field(coerce=True, nullable=True)


class FlowMeasurementSchema(pa.DataFrameModel):
    """A dataframe that can be used to answer questions about flow."""

    age: Series[Age] = pa.Field(coerce=True, nullable=False)
    mouse: Series[Category] = pa.Field(coerce=True, nullable=False)
    vessel_type: Series[VesselTypeFlow] = pa.Field(coerce=True, nullable=False)
    treatment: Series[TreatmentFlow] = pa.Field(coerce=True, nullable=False)
    pressure_d: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    diameter: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    speed: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)
    flux: Series[float] = pa.Field(coerce=True, gt=0, nullable=True)


class HypertensionMeasurementSchema(pa.DataFrameModel):
    """A dataframe that can be used to answer questions about flow."""

    age: Series[Age] = pa.Field(coerce=True, nullable=False)
    treatment: Series[TreatmentHypertension] = pa.Field(
        coerce=True, nullable=False
    )
    mouse: Series[Category] = pa.Field(coerce=True, nullable=False)
    vessel_type: Series[VesselTypeHypertension] = pa.Field(
        coerce=True, nullable=False
    )
    corr_bp_diam: Series[float] = pa.Field(coerce=True, ge=-1, le=1)
    atanh_corr_bp_diam: Series[float] = pa.Field(coerce=True)


class DensityMeasurementSchema(pa.DataFrameModel):
    """A dataframe that can be used to answer questions about density."""

    age: Series[Age] = pa.Field(coerce=True, nullable=False)
    mouse: Series[Category] = pa.Field(coerce=True, nullable=False)
    vessel_type: Series[VesselTypeDensity] = pa.Field(
        coerce=True, nullable=False
    )
    length_mm: Series[float]
    volume_mm3: Series[float]
    density_mm_per_mm3: Series[float]


class WhiskerDataset(BaseModel):
    """A dataset that can answer questions about whisker stimulation."""

    name: str
    coords: util.CoordDict
    measurements: Any
    stan_input: Dict

    @field_validator("measurements")
    def validate_measurements(
        cls, v: Any
    ) -> DataFrameBase[WhiskerMeasurementSchema]:
        if isinstance(v, str):
            v = pd.read_json(StringIO(v))
        return WhiskerMeasurementSchema.validate(v)

    @field_serializer("measurements")
    def serialize_measurements(
        self, measurements: DataFrame[WhiskerMeasurementSchema], _info
    ):
        return measurements.to_json()


class PulsatilityDataset(BaseModel):
    """A dataset that can answer questions about pulsatility."""

    name: str
    coords: util.CoordDict
    measurements: Any
    stan_input: Dict

    @field_validator("measurements")
    def validate_measurements(
        cls, v: Any
    ) -> DataFrameBase[PulsatilityMeasurementSchema]:
        if isinstance(v, str):
            v = pd.read_json(StringIO(v))
        return PulsatilityMeasurementSchema.validate(v)

    @field_serializer("measurements")
    def serialize_measurements(
        self, measurements: DataFrame[PulsatilityMeasurementSchema], _info
    ):
        return measurements.to_json()


class FlowDataset(BaseModel):
    """A dataset that can answer questions about red blood cell flow."""

    name: str
    coords: util.CoordDict
    measurements: Any
    stan_input: Dict

    @field_validator("measurements")
    def validate_measurements(
        cls, v: Any
    ) -> DataFrameBase[FlowMeasurementSchema]:
        if isinstance(v, str):
            v = pd.read_json(StringIO(v))
        return FlowMeasurementSchema.validate(v)

    @field_serializer("measurements")
    def serialize_measurements(
        self, measurements: DataFrame[FlowMeasurementSchema], _info
    ):
        return measurements.to_json()


class HypertensionDataset(BaseModel):
    """A dataset that can answer questions about red blood cell flow."""

    name: str
    coords: util.CoordDict
    measurements: Any
    stan_input: Dict

    @field_validator("measurements")
    def validate_measurements(
        cls, v: Any
    ) -> DataFrameBase[HypertensionMeasurementSchema]:
        if isinstance(v, str):
            v = pd.read_json(StringIO(v))
        return HypertensionMeasurementSchema.validate(v)

    @field_serializer("measurements")
    def serialize_measurements(
        self, measurements: DataFrame[HypertensionMeasurementSchema], _info
    ):
        return measurements.to_json()


class DensityDataset(BaseModel):
    name: str
    coords: util.CoordDict
    measurements: Any
    stan_input: Dict

    @field_validator("measurements")
    def validate_measurements(
        cls, v: Any
    ) -> DataFrameBase[DensityMeasurementSchema]:
        if isinstance(v, str):
            v = pd.read_json(StringIO(v))
        return DensityMeasurementSchema.validate(v)

    @field_serializer("measurements")
    def serialize_measurements(
        self, measurements: DataFrame[DensityMeasurementSchema], _info
    ):
        return measurements.to_json()


def prepare_data():
    """Run main function."""
    print("Reading raw data...")
    raw_data = {
        k: pd.read_csv(v, index_col=None) 
        if k not in ["measurements_density"]
        else pd.read_excel(v)
        for k, v in RAW_DATA_FILES.items()
    }
    data_preparation_functions_to_run = [
        (prepare_data_whisker, raw_data["measurements"]),
        (prepare_data_pulsatility, raw_data["measurements"]),
        (prepare_data_pulsatility_no_hyper, raw_data["measurements"]),
        (prepare_data_flow_speed, raw_data["measurements"]),
        (prepare_data_flow_flux, raw_data["measurements"]),
        (prepare_data_hypertension, raw_data["measurements_hypertension"]),
        (prepare_data_density, raw_data["measurements_density"]),
    ]
    print("Preparing data...")
    for dpf, raw in data_preparation_functions_to_run:
        print(f"Running data preparation function {dpf.__name__}...")
        prepared_data = dpf(raw)
        output_file = os.path.join(PREPARED_DIR, prepared_data.name + ".json")
        print(f"\twriting prepared_data to {output_file}")
        if not os.path.exists(PREPARED_DIR):
            os.mkdir(PREPARED_DIR)
        with open(output_file, "w") as f:
            f.write(prepared_data.model_dump_json())


def prepare_data_whisker(raw: pd.DataFrame) -> WhiskerDataset:
    """Prepare data for question 1."""
    measurements = process_measurements_whisker(raw)
    stan_input = get_stan_input_whisker(measurements)
    return WhiskerDataset(
        name="whisker",
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
        stan_input=stan_input,
    )


def process_measurements_whisker(
    raw: pd.DataFrame,
) -> DataFrameBase[WhiskerMeasurementSchema]:
    """Process the measurements dataframe."""

    def filter(df: pd.DataFrame) -> pd.Series:
        return (
            df["diam_max_after_stim"].notnull()
            & df["diam_mean_before_stim"].notnull()
            & ~df["mouse"].isin(BAD_MICE)
        )

    new_names = {
        "diam_mean_before_stim": "diam_before",
        "diam_max_after_stim": "diam_after",
        "vessel": "vessel_type",
    }
    cols = list(
        WhiskerMeasurementSchema.get_metadata()["WhiskerMeasurementSchema"][
            "columns"
        ].keys()
    )
    return WhiskerMeasurementSchema.validate(
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


def prepare_data_pulsatility(raw: pd.DataFrame) -> PulsatilityDataset:
    """Prepare data for question 1."""
    measurements = process_measurements_pulsatility(raw)
    stan_input = get_stan_input_pulsatility(measurements)
    return PulsatilityDataset(
        name="pulsatility",
        measurements=measurements,
        coords=util.CoordDict(
            {
                "measurement_type": ["diameter", "center"],
                "mouse": measurements["mouse"].cat.categories,
                "vessel_type": measurements["vessel_type"].cat.categories,
                "age": measurements["age"].cat.categories,
                "treatment": measurements["treatment"].cat.categories,
                "observation": measurements.index.map(str).tolist(),
            }
        ),
        stan_input=stan_input,
    )


def prepare_data_pulsatility_no_hyper(raw: pd.DataFrame) -> PulsatilityDataset:
    """Prepare pulsatility data, excluding hypertension treatments."""
    measurements = (
        process_measurements_pulsatility(raw)
        .loc[lambda df: ~df["treatment"].isin(["hyper", "hyper2"])]
        .assign(
            treatment=lambda df: df["treatment"].cat.remove_unused_categories()
        )
    )
    stan_input = get_stan_input_pulsatility(measurements)
    return PulsatilityDataset(
        name="pulsatility-no-hyper",
        measurements=measurements,
        coords=util.CoordDict(
            {
                "measurement_type": ["diameter", "center"],
                "mouse": measurements["mouse"].cat.categories,
                "vessel_type": measurements["vessel_type"].cat.categories,
                "age": measurements["age"].cat.categories,
                "treatment": measurements["treatment"].cat.categories,
                "observation": measurements.index.map(str).tolist(),
            }
        ),
        stan_input=stan_input,
    )


def prepare_data_flow_speed(raw: pd.DataFrame) -> FlowDataset:
    """Prepare data for question 1."""
    measurements = process_measurements_flow(raw, ycol="speed")
    stan_input = get_stan_input_flow_speed(measurements)
    return FlowDataset(
        name="flow-speed",
        measurements=measurements,
        coords=util.CoordDict(
            {
                "mouse": measurements["mouse"].cat.categories,
                "vessel_type": measurements["vessel_type"].unique(),
                "age": measurements["age"].cat.categories,
                "treatment": measurements["treatment"].cat.categories,
                "observation": measurements.index.map(str).tolist(),
            }
        ),
        stan_input=stan_input,
    )


def prepare_data_flow_flux(raw: pd.DataFrame) -> FlowDataset:
    """Prepare data for question 1."""
    measurements = process_measurements_flow(raw, ycol="flux")
    stan_input = get_stan_input_flow_flux(measurements)
    return FlowDataset(
        name="flow-flux",
        measurements=measurements,
        coords=util.CoordDict(
            {
                "mouse": measurements["mouse"].cat.categories,
                "vessel_type": measurements["vessel_type"].unique(),
                "age": measurements["age"].cat.categories,
                "treatment": measurements["treatment"].cat.categories,
                "observation": measurements.index.map(str).tolist(),
            }
        ),
        stan_input=stan_input,
    )


def prepare_data_hypertension(raw: pd.DataFrame) -> HypertensionDataset:
    """Prepare hypertension challenge data."""
    measurements = process_measurements_hypertension(raw)
    stan_input = get_stan_input_hypertension(measurements)
    return HypertensionDataset(
        name="hypertension",
        measurements=measurements,
        coords=util.CoordDict(
            {
                "measurement_type": ["diameter", "center"],
                "mouse": measurements["mouse"].cat.categories,
                "vessel_type": measurements["vessel_type"].cat.categories,
                "age": measurements["age"].cat.categories,
                "treatment": measurements["treatment"].cat.categories,
                "observation": measurements.index.map(str).tolist(),
            }
        ),
        stan_input=stan_input,
    )
    
def prepare_data_density(raw: pd.DataFrame) -> DensityDataset:
    """Prepare hypertension challenge data."""
    measurements = process_measurements_density(raw)
    stan_input = get_stan_input_density(measurements)
    return DensityDataset(
        name="density",
        measurements=measurements,
        coords=util.CoordDict(
            {
                "measurement_type": ["diameter", "center"],
                "mouse": measurements["mouse"].cat.categories,
                "vessel_type": measurements["vessel_type"].cat.categories,
                "age": measurements["age"].cat.categories,
                "observation": measurements.index.map(str).tolist(),
            }
        ),
        stan_input=stan_input,
    )


def process_measurements_pulsatility(
    raw: pd.DataFrame,
) -> DataFrameBase[PulsatilityMeasurementSchema]:
    """Process the measurements dataframe."""

    def filter(df: pd.DataFrame) -> pd.Series:
        return (
            df["power_diam_h1"].notnull()
            & df["power_center_h1"].notnull()
            & df["pressure_d"].notnull()
            & ~df["mouse"].isin(BAD_MICE)
        )

    new_names = {
        "vessel": "vessel_type",
        "power_diam_h1": "pd1",
        "power_diam_h2": "pd2",
        "power_diam_h3": "pd3",
        "power_center_h1": "pc1",
        "power_center_h2": "pc2",
        "power_center_h3": "pc3",
        "diam_mean": "diameter",
    }
    cols = list(
        PulsatilityMeasurementSchema.get_metadata()[
            "PulsatilityMeasurementSchema"
        ]["columns"].keys()
    )
    return PulsatilityMeasurementSchema.validate(
        raw.loc[filter]
        .rename(columns=new_names)
        .assign(
            mouse=lambda df: df["mouse"].astype(str),
            pd_sum=lambda df: df[["pd1", "pd2", "pd3"]].sum(axis=1).fillna(0),
            pc_sum=lambda df: df[["pc1", "pc2", "pc3"]].sum(axis=1).fillna(0),
            pd_ratio=lambda df: df["pd2"].fillna(0.0) / df["pd_sum"],
            pc_ratio=lambda df: df["pc2"].fillna(0.0) / df["pc_sum"],
            pressure_norm=lambda df: df["pressure_d"]
            - df.groupby(["age"])["pressure_d"].transform("mean"),
            diameter_norm=lambda df: df["diameter"]
            - df.groupby(["vessel_type"])["diameter"].transform("mean"),
        )[cols]
        .sort_values(["age", "mouse", "vessel_type", "treatment"])
    )


def process_measurements_flow(
    raw: pd.DataFrame, ycol: str
) -> DataFrameBase[PulsatilityMeasurementSchema]:
    """Process the measurements dataframe."""

    def filter(df: pd.DataFrame) -> pd.Series:
        return df[ycol].notnull() & ~df["mouse"].isin(BAD_MICE)

    new_names = {
        "vessel": "vessel_type",
        "diam_mean": "diameter",
    }
    cols = list(
        FlowMeasurementSchema.get_metadata()["FlowMeasurementSchema"][
            "columns"
        ].keys()
    )
    return FlowMeasurementSchema.validate(
        raw.loc[filter]
        .assign(mouse=lambda df: df["mouse"].astype(str))
        .rename(columns=new_names)[cols]
        .sort_values(["age", "mouse", "vessel_type", "treatment"])
    )


def process_measurements_hypertension(
    raw: pd.DataFrame,
) -> DataFrameBase[HypertensionMeasurementSchema]:
    """Process hypertension data."""
    out = (
        raw.melt(
            id_vars=["age", "treatment", "mouse"],
            value_vars=["pa", "sphincter", "bulb", "cap1", "cap2"],
            var_name="vessel_type",
            value_name="corr_bp_diam",
        )
        .dropna(subset=["corr_bp_diam"])
        .assign(
            mouse=lambda df: df["mouse"].astype(str),
            atanh_corr_bp_diam=lambda df: np.arctanh(df["corr_bp_diam"]),
        )
        .loc[lambda df: ~df["mouse"].astype(int).isin(BAD_MICE)]
        .sort_values(["age", "treatment", "vessel_type", "mouse"])
    )

    return HypertensionMeasurementSchema.validate(out)


def process_measurements_density(raw: pd.DataFrame) -> DataFrameBase[DensityMeasurementSchema]:
    """Process density data."""
    vessel_type_names = {
        "PialArtery": "pial_artery",
        "pa": "pa",
        "1stCap": "cap1",
        "2ndCap": "cap2",
        "3rdCap": "cap3",
        "4thCap": "cap4",
        "5thCap": "cap5",
        "6thCap": "cap6",
        "7thCap": "cap7",
        "8thCap": "cap8",
        "9thCap": "cap9",
        "10thCap": "cap10",
        "11thCap": "cap11",
        "12thCap": "cap12",
        "AscVenule": "av",
        "PialVein": "pv",
    }
    out = (
        pd.DataFrame({
            "mouse": raw["MouseID"].astype(str),
            "age": raw["Condition"].str.lower(),
            "vessel_type": raw["CapOrder"].map(vessel_type_names.get).astype(VesselTypeDensity),
            "length_mm": raw["CapVesLL"] * 10e6,
            "volume_mm3": raw["Volume"] * 10e-9,
        })
        .assign(density_mm_per_mm3=lambda df: df["length_mm"] / df["volume_mm3"])
    )
    return DensityMeasurementSchema.validate(out)

def load_prepared_data(
    path_to_data: str,
) -> Union[
    WhiskerDataset, 
    PulsatilityDataset,
    FlowDataset,
    HypertensionDataset,
    DensityDataset,
]:
    with open(path_to_data) as f:
        raw = json.load(f)
    if raw["name"].startswith("whisker"):
        return WhiskerDataset(**raw)
    elif raw["name"].startswith("pulsatility"):
        return PulsatilityDataset(**raw)
    elif raw["name"].startswith("flow"):
        return FlowDataset(**raw)
    elif raw["name"].startswith("hypertension"):
        return HypertensionDataset(**raw)
    elif raw["name"].startswith("density"):
        return DensityDataset(**raw)
    else:
        raise ValueError(f"Unexpected name {raw['name']}.")
