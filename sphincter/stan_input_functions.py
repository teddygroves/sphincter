"""Functions for generating input to Stan from prepared data."""


from typing import Any, Callable, Dict

import pandas as pd
from sphincter.util import one_encode

from stanio.json import process_dictionary


def returns_stan_input(func: Callable[[Any], Dict]) -> Callable[[Any], Dict]:
    """Decorate a function so it returns a json-serialisable dictionary."""

    def wrapper(*args, **kwargs):
        return process_dictionary(func(*args, **kwargs))

    return wrapper


@returns_stan_input
def get_stan_input_whisker(mts: pd.DataFrame) -> Dict:
    """Get Stan input for whisker models."""
    age = mts.groupby("mouse")["age"].first().map({"adult": 1, "old": 2}.get)
    return {
        "N": len(mts),
        "N_age": mts["age"].nunique(),
        "N_mouse": mts["mouse"].nunique(),
        "N_treatment": mts["treatment"].nunique(),
        "N_vessel_type": mts["vessel_type"].nunique(),
        "N_train": len(mts),
        "N_test": len(mts),
        "age": age,
        "mouse": one_encode(mts["mouse"]),
        "treatment": one_encode(mts["treatment"]),
        "vessel_type": one_encode(mts["vessel_type"]),
        "ix_train": [i + 1 for i in range(len(mts))],
        "ix_test": [i + 1 for i in range(len(mts))],
        "y": mts["diam_log_ratio"],
    }


@returns_stan_input
def get_stan_input_pulsatility(mts: pd.DataFrame) -> Dict:
    mouse = one_encode(mts["mouse"])
    age = (
        mts.groupby(mouse, sort=True)["age"]
        .first()
        .map({"adult": 1, "old": 2}.get)
    )
    return {
        "N": len(mts),
        "N_age": mts["age"].nunique(),
        "N_mouse": mts["mouse"].nunique(),
        "N_treatment": mts["treatment"].nunique(),
        "N_vessel_type": mts["vessel_type"].nunique(),
        "N_train": len(mts),
        "N_test": len(mts),
        "age": age,
        "mouse": mouse,
        "treatment": one_encode(mts["treatment"]),
        "hyper": mts["treatment"].isin(["hyper", "hyper2"]).astype(int),
        "vessel_type": one_encode(mts["vessel_type"]),
        "ix_train": [i + 1 for i in range(len(mts))],
        "ix_test": [i + 1 for i in range(len(mts))],
        "y": mts[["pd_sum", "pc_sum"]].T.values,
        "pressure": mts["pressure_norm"],
        "diameter": mts["diameter"],
    }


@returns_stan_input
def get_stan_input_pulsatility_no_age(mts: pd.DataFrame) -> Dict:
    mouse = one_encode(mts["mouse"])
    age = (
        mts.groupby(mouse, sort=True)["age"]
        .first()
        .map({"adult": 1, "old": 2}.get)
    )
    return {
        "N": len(mts),
        "N_age": mts["age"].nunique(),
        "N_mouse": mts["mouse"].nunique(),
        "N_treatment": mts["treatment"].nunique(),
        "N_vessel_type": mts["vessel_type"].nunique(),
        "N_train": len(mts),
        "N_test": len(mts),
        "age": age,
        "mouse": mouse,
        "treatment": one_encode(mts["treatment"]),
        "hyper": mts["treatment"].isin(["hyper", "hyper2"]).astype(int),
        "vessel_type": one_encode(mts["vessel_type"]),
        "ix_train": [i + 1 for i in range(len(mts))],
        "ix_test": [i + 1 for i in range(len(mts))],
        "y": mts[["pd_sum", "pc_sum"]].T.values,
        "pressure": mts["pressure_d"],
        "diameter": mts["diameter"],
    }


@returns_stan_input
def get_stan_input_flow_core(mts: pd.DataFrame) -> Dict:
    mouse = one_encode(mts["mouse"])
    age = (
        mts.groupby(mouse, sort=True)["age"]
        .first()
        .map({"adult": 1, "old": 2}.get)
    )
    return {
        "N": len(mts),
        "N_age": mts["age"].nunique(),
        "N_mouse": mts["mouse"].nunique(),
        "N_treatment": mts["treatment"].nunique(),
        "N_vessel_type": mts["vessel_type"].nunique(),
        "N_train": len(mts),
        "N_test": len(mts),
        "age": age,
        "mouse": mouse,
        "treatment": one_encode(mts["treatment"]),
        "vessel_type": one_encode(mts["vessel_type"]),
        "ix_train": [i + 1 for i in range(len(mts))],
        "ix_test": [i + 1 for i in range(len(mts))],
    }


@returns_stan_input
def get_stan_input_flow_speed(mts: pd.DataFrame) -> Dict:
    return get_stan_input_flow_core(mts) | {"y": mts["speed"]}


@returns_stan_input
def get_stan_input_flow_flux(mts: pd.DataFrame) -> Dict:
    return get_stan_input_flow_core(mts) | {"y": mts["flux"]}


@returns_stan_input
def get_stan_input_hypertension(mts: pd.DataFrame) -> Dict:
    mouse = one_encode(mts["mouse"])
    age = (
        mts.groupby(mouse, sort=True)["age"]
        .first()
        .map({"adult": 1, "old": 2}.get)
    )
    return {
        "N": len(mts),
        "N_age": mts["age"].nunique(),
        "N_mouse": mts["mouse"].nunique(),
        "N_treatment": mts["treatment"].nunique(),
        "N_vessel_type": mts["vessel_type"].nunique(),
        "N_train": len(mts),
        "N_test": len(mts),
        "age": age,
        "mouse": mouse,
        "treatment": one_encode(mts["treatment"]),
        "vessel_type": one_encode(mts["vessel_type"]),
        "ix_train": [i + 1 for i in range(len(mts))],
        "ix_test": [i + 1 for i in range(len(mts))],
        "y": mts["atanh_corr_bp_diam"].values,
    }


@returns_stan_input
def get_stan_input_density(mts: pd.DataFrame) -> Dict:
    mouse = one_encode(mts["mouse"])
    age = (
        mts.groupby(mouse, sort=True)["age"]
        .first()
        .map({"adult": 1, "old": 2}.get)
    )
    return {
        "N": len(mts),
        "N_age": mts["age"].nunique(),
        "N_mouse": mts["mouse"].nunique(),
        "N_vessel_type": mts["vessel_type"].nunique(),
        "N_train": len(mts),
        "N_test": len(mts),
        "age": age,
        "mouse": mouse,
        "vessel_type": one_encode(mts["vessel_type"]),
        "ix_train": [i + 1 for i in range(len(mts))],
        "ix_test": [i + 1 for i in range(len(mts))],
        "y": mts["density_mm_per_mm3"].values,
    }
