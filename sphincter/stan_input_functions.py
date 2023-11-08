"""Functions for generating input to Stan from prepared data."""


from typing import Dict

import pandas as pd
from sphincter.data_preparation import Q1Dataset, Q2Dataset
from sphincter.util import one_encode


def get_stan_input_q1_base(mts: pd.DataFrame) -> Dict:
    """Get Stan input for q1a."""
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
    }


def get_stan_input_q1_rel(prepared_data: Q1Dataset) -> Dict:
    mts = prepared_data.measurements
    out = get_stan_input_q1_base(mts)
    out["y"] = mts["diam_rel_change"].tolist()
    return out


def get_stan_input_q1_log_ratio(prepared_data: Q1Dataset) -> Dict:
    mts = prepared_data.measurements
    out = get_stan_input_q1_base(mts)
    out["y"] = mts["diam_log_ratio"].tolist()
    return out


def get_stan_input_q2(prepared_data: Q2Dataset) -> Dict:
    mts = prepared_data.measurements
    return {
        "N": len(mts),
        "N_age": mts["age"].nunique(),
        "N_mouse": mts["mouse"].nunique(),
        "N_treatment": mts["treatment"].nunique(),
        "N_vessel_type": mts["vessel_type"].nunique(),
        "N_train": len(mts),
        "N_test": len(mts),
        "age": one_encode(mts["age"]),
        "mouse": one_encode(mts["mouse"]),
        "treatment": one_encode(mts["treatment"]),
        "vessel_type": one_encode(mts["vessel_type"]),
        "ix_train": [i + 1 for i in range(len(mts))],
        "ix_test": [i + 1 for i in range(len(mts))],
        "y": mts["pd1"],
    }
