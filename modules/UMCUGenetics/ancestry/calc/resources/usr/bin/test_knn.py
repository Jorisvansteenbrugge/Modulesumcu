"""Unit tests for knn.py helper functions."""

import numpy as np
import pandas as pd
import pytest
import typer

from knn import (
    get_pc_columns,
    predict_knn,
    sort_pc_columns,
    split_train_predict,
    standardize_train_query,
)


# ---------------------------------------------------------------------------
# sort_pc_columns
# ---------------------------------------------------------------------------

def test_sort_pc_columns_numeric_order():
    assert sort_pc_columns(["PC10", "PC2", "PC1"]) == ["PC1", "PC2", "PC10"]


def test_sort_pc_columns_non_numeric_suffix_last():
    result = sort_pc_columns(["PCx", "PC2", "PC1"])
    assert result[:2] == ["PC1", "PC2"]
    assert result[-1] == "PCx"


def test_sort_pc_columns_single_element():
    assert sort_pc_columns(["PC1"]) == ["PC1"]


# ---------------------------------------------------------------------------
# get_pc_columns
# ---------------------------------------------------------------------------

def test_get_pc_columns_returns_matching_columns():
    df = pd.DataFrame(columns=["#IID", "PC1", "PC2", "SuperPop"])
    assert set(get_pc_columns(df)) == {"PC1", "PC2"}


def test_get_pc_columns_case_insensitive():
    df = pd.DataFrame(columns=["#IID", "pc1", "PC2"])
    assert set(get_pc_columns(df)) == {"pc1", "PC2"}


def test_get_pc_columns_raises_when_none_found():
    df = pd.DataFrame(columns=["#IID", "SuperPop"])
    with pytest.raises(typer.BadParameter):
        get_pc_columns(df)


# ---------------------------------------------------------------------------
# split_train_predict
# ---------------------------------------------------------------------------

def _make_merged_df(labeled_n: int, unlabeled_n: int) -> pd.DataFrame:
    rows = []
    for i in range(labeled_n):
        rows.append({"#IID": f"ref_{i}", "PC1": float(i), "SuperPop": "EUR"})
    for i in range(unlabeled_n):
        rows.append({"#IID": f"sample_{i}", "PC1": float(i + 100), "SuperPop": np.nan})
    return pd.DataFrame(rows)


def test_split_train_predict_sizes():
    df = _make_merged_df(labeled_n=10, unlabeled_n=3)
    train, predict = split_train_predict(df, label_col="SuperPop")
    assert len(train) == 10
    assert len(predict) == 3


def test_split_train_predict_raises_no_train():
    df = _make_merged_df(labeled_n=0, unlabeled_n=3)
    with pytest.raises(typer.BadParameter, match="No labeled"):
        split_train_predict(df, label_col="SuperPop")


def test_split_train_predict_raises_no_predict():
    df = _make_merged_df(labeled_n=5, unlabeled_n=0)
    with pytest.raises(typer.BadParameter, match="Nothing to predict"):
        split_train_predict(df, label_col="SuperPop")


# ---------------------------------------------------------------------------
# standardize_train_query
# ---------------------------------------------------------------------------

def test_standardize_zero_mean_unit_std():
    train = np.array([[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]])
    query = np.array([[3.0, 4.0]])
    train_std, query_std = standardize_train_query(train, query)
    np.testing.assert_allclose(train_std.mean(axis=0), 0.0, atol=1e-10)
    np.testing.assert_allclose(train_std.std(axis=0), 1.0, atol=1e-10)
    # query center-of-training → all zeros after standardization
    np.testing.assert_allclose(query_std, [[0.0, 0.0]], atol=1e-10)


def test_standardize_zero_variance_column_unchanged():
    """Columns with zero variance must not cause division-by-zero."""
    train = np.array([[1.0, 5.0], [1.0, 7.0]])  # column 0 has std=0
    query = np.array([[1.0, 6.0]])
    train_std, _ = standardize_train_query(train, query)
    # zero-variance column is left unchanged (divided by 1 after clamp)
    np.testing.assert_allclose(train_std[:, 0], 0.0, atol=1e-10)


# ---------------------------------------------------------------------------
# predict_knn
# ---------------------------------------------------------------------------

def _simple_train():
    """Two clusters far apart: A around 0, B around 10."""
    train_features = np.array(
        [[0.0], [0.1], [0.2], [10.0], [10.1], [10.2]]
    )
    train_labels = np.array(["A", "A", "A", "B", "B", "B"])
    return train_features, train_labels


def test_predict_knn_clear_majority():
    train_features, train_labels = _simple_train()
    query = np.array([[0.05], [10.05]])
    labels, confs = predict_knn(train_features, train_labels, query, k=3)
    assert list(labels) == ["A", "B"]
    np.testing.assert_allclose(confs, [1.0, 1.0])


def test_predict_knn_confidence_range():
    train_features, train_labels = _simple_train()
    query = np.array([[5.0]])  # equidistant — confidence will be < 1
    labels, confs = predict_knn(train_features, train_labels, query, k=6)
    assert 0.0 <= confs[0] <= 1.0


def test_predict_knn_k_exceeds_training_size():
    """k larger than training set should not raise, just use all neighbors."""
    train_features = np.array([[0.0], [1.0]])
    train_labels = np.array(["A", "A"])
    query = np.array([[0.5]])
    labels, confs = predict_knn(train_features, train_labels, query, k=100)
    assert labels[0] == "A"
    assert confs[0] == 1.0


def test_predict_knn_k_less_than_1_raises():
    train_features = np.array([[0.0]])
    train_labels = np.array(["A"])
    with pytest.raises(typer.BadParameter, match="k must be"):
        predict_knn(train_features, train_labels, np.array([[0.0]]), k=0)
