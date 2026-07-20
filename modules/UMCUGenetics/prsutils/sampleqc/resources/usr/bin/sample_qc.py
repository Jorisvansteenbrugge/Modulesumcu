#!/usr/bin/env -S uv run --script --no-cache
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pandas",
#     "typer",
# ]
# ///
"""Sample QC: flag samples based on PRS Z-score and ancestry thresholds."""

from __future__ import annotations

from pathlib import Path
from typing import Annotated, List

import pandas as pd
import typer

app = typer.Typer(add_completion=False, help="Sample QC for PRS pipeline.")


def QC_check(row: pd.Series, expected_ancestry: list[str], conf_threshold: float, model_matchrate: float, matchrate_threshold: float) -> pd.Series:
    """Assign QC status and comments to a single sample row.

    Args:
        row: A single row from the merged scores/ancestry DataFrame.
        expected_ancestry: Accepted predicted ancestry group labels.
        conf_threshold: Minimum KNN confidence score to pass ancestry QC.
        model_matchrate: Fraction of model variants found in the sample (0–1).
        matchrate_threshold: Minimum required model matchrate to pass QC.

    Returns:
        The input row with ``QC status`` and ``QC Comment`` columns added.
    """
    ancestry_group_pass = row['pred_group'] in expected_ancestry
    ancestry_conf_pass = row["knn_conf"] >= conf_threshold
    matchrate_pass = model_matchrate >= matchrate_threshold

    qc_comment = []
    if not ancestry_group_pass:
        qc_comment.append("REFERENCE_PANEL_MISMATCH")
    if not ancestry_conf_pass:
        qc_comment.append("LOW_REFERENCE_PANEL_CONFIDENCE")
    if not matchrate_pass:
        qc_comment.append("INSUFFICIENT_VARIANT_COVERAGE")

    row["Model matchrate"] = model_matchrate
    row["QC status"] = "PASS" if ancestry_group_pass and ancestry_conf_pass and matchrate_pass else "FAIL"
    row["QC Comment"] = ";".join(qc_comment)
    return row

def calc_model_matchrate(model_df: pd.DataFrame) -> float:
    """Calculate the fraction of model variants matched in the sample.

    Args:
        model_df: Model summary DataFrame with ``match_status`` and ``percent`` columns.

    Returns:
        Matchrate as a fraction between 0 and 1.
    """
    matched_vars = model_df[model_df["match_status"] == "matched"]
    match_rate = matched_vars["percent"].sum() / 100
    return match_rate

@app.command()
def main(
    scores: Annotated[
        Path,
        typer.Option(
            "--scores",
            "-s",
            exists=True,
            dir_okay=False,
            readable=True,
            help="Normalised PRS scores TSV with SUM_Z column.",
        ),
    ],
    ancestry: Annotated[
        Path,
        typer.Option(
            "--ancestry",
            "-a",
            exists=True,
            dir_okay=False,
            readable=True,
            help="KNN ancestry TSV with pred_group and knn_conf columns.",
        ),
    ],
    model_summary: Annotated[
        Path,
        typer.Option(
            "--model-summary",
            "-m",
            exists=True,
            dir_okay=False,
            readable=True,
            help="Model summary file"
        )
    ],
    output: Annotated[
        Path,
        typer.Option("--output", "-o", help="Output QC TSV path."),
    ],
    sample: Annotated[
        str,
        typer.Option("--sample", help="Sample ID to tag onto every row."),
    ],
    model: Annotated[
        str,
        typer.Option("--model", help="Model ID to tag onto every row."),
    ],
    alpha: Annotated[
        float,
        typer.Option("--alpha", help="Model alpha value to tag onto every row."),
    ],
    conf_threshold: Annotated[
        float,
        typer.Option("--conf-threshold", help="Minimum ancestry confidence to pass QC. (default: 0.6)"),
    ] = 0.6,
    expected_ancestry: Annotated[
        List[str],
        typer.Option("--expected-ancestry", help="Expected superpopulation label(s). Can be passed multiple times. (default: EUR)"),
    ] = ["EUR"],
    matchrate_threshold: Annotated[
        float,
        typer.Option("--matchrate-threshold", help="Minimum model matchrate (i.e., percentage of variants in the model that are in the sample. (default: 0.75) )"),
    ] = 0.75
) -> None:
    """Run sample QC checks and write a MultiQC-compatible table."""
    score_file = pd.read_csv(scores, sep='\t')
    ancestry_file = pd.read_csv(ancestry, sep='\t')
    model_df = pd.read_csv(model_summary, sep=',')

    combined_df = score_file.merge(ancestry_file, left_on="IID", right_on="#IID")

    model_matchrate = calc_model_matchrate(model_df)

    typer.echo(f"Model matchrate:{model_matchrate}")
    qc_df = combined_df.apply(QC_check, args=(expected_ancestry, conf_threshold, model_matchrate, matchrate_threshold), axis=1)

    qc_df["Sample"] = sample
    qc_df["Model"] = model
    qc_df["Model Alpha"] = alpha

    qc_df = qc_df.filter(items=[
        "Sample", "Model", "SCORE1_SUM", "SUM_Z",
        "Model Matchrate", "QC status", "QC Comment", "Model Alpha",
    ])

    qc_df.to_csv(output, sep='\t', index=False)

    typer.echo(f"Wrote {output}")


if __name__ == "__main__":
    app()
