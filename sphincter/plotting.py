import matplotlib.pyplot as plt
import matplotlib.colors as cl
import numpy as np
import pandas as pd
import xarray as xr

DEFAULT_CMAP = plt.get_cmap("Set2")


def plot_obs(
    ax: plt.Axes,
    obs: pd.Series,
    cat: pd.Series | None = None,
    cmap: cl.ListedColormap = DEFAULT_CMAP,  # type: ignore
    **scatter_kwargs,
):
    """Scatter plot sorted by groups with colors."""
    if cat is None:
        cat = pd.Series(
            "obs", dtype=pd.CategoricalDtype(["obs"]), index=obs.index
        )
    pd.testing.assert_index_equal(obs.index, cat.index)
    cat_sorted = cat.sort_values()
    obs_sorted = obs.reindex(cat_sorted.index)
    x = pd.Series(np.linspace(0, 1, len(obs)), index=cat_sorted.index)
    colors = list(cmap.colors)
    scts = []
    for i, (cati, obsi) in enumerate(obs.groupby(cat, observed=True)):
        color = colors[i % len(colors)]
        x_i = x.loc[obsi.index]
        sct = ax.scatter(x_i, obsi, label=cati, color=color, **scatter_kwargs)
        scts.append(sct)
    return scts


def plot_predictive(
    ax: plt.Axes,
    yrep: xr.DataArray,
    cat: pd.Series | None = None,
    cmap: cl.ListedColormap = DEFAULT_CMAP,  # type: ignore
    **vlines_kwargs,
):
    if cat is None:
        _, _, ix = yrep.coords.values()
        cat = pd.Series(
            "obs", dtype=pd.CategoricalDtype(["obs"]), index=ix.values
        )
    cat_sorted = cat.sort_values()
    qs = pd.DataFrame(
        yrep.quantile([0.01, 0.99], dim=["chain", "draw"]).values.T,  # type: ignore
        index=cat.index,
        columns=["q1", "q99"],
    ).reindex(cat_sorted.index)
    x = pd.Series(np.linspace(0, 1, len(cat)), index=cat_sorted.index)
    lines = None
    for i, (cati, subdf) in enumerate(qs.groupby(cat, observed=True)):
        lines = ax.vlines(
            x.loc[subdf.index],
            subdf["q1"],
            subdf["q99"],
            color="gainsboro",
            **vlines_kwargs,
        )
    return lines
