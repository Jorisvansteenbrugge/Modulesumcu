#!/usr/bin/env -S uv run --script --no-cache
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "argparse",
#     "pandas",
# ]
# ///

import argparse
import pandas as pd

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--PRS", help = "Table with PRS scores")
    parser.add_argument(
        "--mu",
        help="Population average for calculating Z-scores",
        required=True,
        type=float
    )
    parser.add_argument(
        "--SD",
        help="Population standard deviation for calculating Z-scores",
        required=True,
        type=float
    )
    parser.add_argument(
        "-o", "--output",
        help="Output file",
        required=True
    )

    return parser.parse_args()


def score_to_z_score(scores, mu, SD):
    z_scores = (scores - args.mu) / args.SD

    return z_scores

if __name__ == "__main__":
    args = get_args()

    df = pd.read_csv(args.PRS, sep='\t')

    df["SUM_Z"] = score_to_z_score(df["SCORE1_SUM"], mu=args.mu, SD=args.SD)

    df.to_csv(args.output, sep='\t', index=False)
