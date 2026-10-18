[English](semantic-inconsistency.en.md) | [日本語](semantic-inconsistency.ja.md)

# `semantic_inconsistency()`: 項目ペア間の意味的不整合度

## 1. 概要

`semantic_inconsistency()` は、利用者が指定した項目ペアの期待関係（同方向 `same` または逆方向 `opposite`）に基づき、回答の意味的不整合度を算出する関数です。

質問紙調査において、注意深く回答している回答者は、同義的な項目対には近い評定を、反義的・逆転項目対には対照的な評定を行うことが期待されます。不整合度スコアは、観察された回答がこれらの期待関係からどれだけ乖離しているかを定量化します。すべての不整合度は尺度理論範囲 \([0, 1]\) に正規化され、0は完全整合、1は最大不整合を表します。

意味的不整合度は回答パターンの探索的指標であり、それ単体で不注意回答や不誠実な回答を確定診断するものではありません。

## 2. 数値的定義

尺度の理論的最小値を \(L\)、最大値を \(U\)、尺度幅を \(R = U - L\) とします。回答者 \(k\) の有効な項目回答 \(x_i, x_j\) について：

### 同方向ペア (`relation = "same"`)
同じ評定が期待される場合：
\[
\text{Inconsistency} = \frac{|x_i - x_j|}{U - L}
\]

### 逆方向ペア (`relation = "opposite"`)
逆方向の評定が期待される場合：
\[
\text{Inconsistency} = \frac{|(x_i - L) - (U - x_j)|}{U - L} = \frac{|x_i + x_j - (L + U)|}{U - L}
\]

どちらの計算式も項目の順序入替えに対して対称であり、\(x_i\) と \(x_j\) を入れ替えても値は同一です。

### 5件法尺度での計算例 (\(L = 1, U = 5, R = 4\)):

| \(x_i\) | \(x_j\) | 関係 | 計算式 | スコア | 解釈 |
|---:|---:|---|---|---:|---|
| 5 | 5 | same | \(|5 - 5| / 4\) | 0.00 | 完全整合 |
| 5 | 3 | same | \(|5 - 3| / 4\) | 0.50 | 中程度の不整合 |
| 5 | 1 | same | \(|5 - 1| / 4\) | 1.00 | 最大不整合 |
| 5 | 1 | opposite | \(|(5 - 1) - (5 - 1)| / 4\) | 0.00 | 完全整合 |
| 5 | 3 | opposite | \(|(5 - 1) - (5 - 3)| / 4\) | 0.50 | 中程度の不整合 |
| 5 | 5 | opposite | \(|(5 - 1) - (5 - 5)| / 4\) | 1.00 | 最大不整合 |
| 3 | 3 | opposite | \(|(3 - 1) - (5 - 3)| / 4\) | 0.00 | 完全整合（中央値同士） |

## 3. 基本的な使い方

```r
semantic_inconsistency(
  data,
  pairs,
  scale_min,
  scale_max,
  threshold = 0.75,
  min_valid_pairs = 1L,
  details = FALSE
)
```

| 引数 | 説明 |
|---|---|
| `data` | 回答者を行、項目を列とする行列またはデータフレーム。対象列は bare な数値（integer または double）である必要があります。 |
| `pairs` | `item1`, `item2`, `relation` 列を含むデータフレーム。`relation` は `"same"` または `"opposite"`。重複ペアや自己ペアは不可。 |
| `scale_min` | 尺度の理論的最小値（有限の数値スカラー）。 |
| `scale_max` | 尺度の理論的最大値（有限の数値スカラー、`scale_min < scale_max`）。 |
| `threshold` | 高不整合とみなす閾値（\([0, 1]\) の有限数値スカラー、不整合度 \(\ge\) `threshold`）。既定値 `0.75` は例示用であり妥当化されたカットオフではありません。 |
| `min_valid_pairs` | 要約指標を計算するために必要な最小有効ペア数（\(\ge 1\) の整数スカラー）。既定値は `1L`。 |
| `details` | 詳細表を同時に返すかどうかの論理値スカラー。既定値は `FALSE`。 |

### 使用例

以下では尺度の最小値を1、最大値を5とします。`q1`と`q2`は同方向ペア、`q1`と`q3`は逆方向ペアとして指定しています。

```r
library(Satisficing)

responses <- data.frame(
  q1 = c(5, 5, 1, NA),
  q2 = c(5, 3, 5, 1),
  q3 = c(1, 5, 5, NA)
)

item_pairs <- data.frame(
  item1 = c("q1", "q1"),
  item2 = c("q2", "q3"),
  relation = c("same", "opposite")
)

scores <- semantic_inconsistency(
  responses,
  pairs = item_pairs,
  scale_min = 1,
  scale_max = 5
)
scores
```

1人目は2ペアとも不整合度が0です。2人目は同方向ペアが0.5、逆方向ペアが1となり、平均は0.75です。4人目は`q1`が欠測のため有効ペアがなく、要約スコアは`NA`になりますが、ペア数の集計は確認できます。

この例の主要な出力は次のようになります（数値列の表示形式は環境により異なることがあります）。

```text
  mean_inconsistency max_inconsistency sum_inconsistency n_valid_pairs n_missing_pairs
1              0.00              0.00              0.00             2               0
2              0.75              1.00              1.50             2               0
3              0.50              1.00              1.00             2               0
4                NA                NA                NA             0               2
```

3人目は同方向ペアが最大不整合（1）、逆方向ペアが完全整合（0）で、平均は0.5です。`n_high_inconsistency`と`prop_high_inconsistency`は、既定の`threshold = 0.75`以上のペアを数えます。

## 4. 返り値

### 回答者単位の要約 (`details = FALSE`)
入力と同じ行順のデータフレームを返します：

1. `mean_inconsistency` (double): 有効ペアの不整合度平均。
2. `max_inconsistency` (double): 有効ペアの最大不整合度。
3. `sum_inconsistency` (double): 有効ペアの不整合度合計。
4. `n_valid_pairs` (integer): 両項目ともに回答が存在する有効ペア数。
5. `n_missing_pairs` (integer): 少なくとも一方が欠測 (`NA`) のペア数。
6. `n_high_inconsistency` (integer): 不整合度が `threshold` 以上の有効ペア数。
7. `prop_high_inconsistency` (double): `n_high_inconsistency / n_valid_pairs`。

`n_valid_pairs < min_valid_pairs` の場合、要約スコア列（1–3, 6–7）は適切な型の `NA` となり、カウント列（4–5）は観測数を返します。

### ペア単位の詳細出力 (`details = TRUE`)
以下の要素を持つリストを返します：
- `$respondents`: 上記の回答者要約データフレーム。
- `$pairs`: 回答者行順・ペア行順（row-major）のデータフレーム（列：`respondent_row`, `pair_id`, `item1`, `item2`, `relation`, `inconsistency`）。

例えば、`semantic_inconsistency(responses, item_pairs, 1, 5, details = TRUE)`は要約表と、回答者ごとの各ペアのスコアを返します。`respondent_row`は`data`内の1始まりの行位置、`pair_id`は`pairs`内の1始まりの行位置です。

```r
result <- semantic_inconsistency(
  responses,
  item_pairs,
  scale_min = 1,
  scale_max = 5,
  details = TRUE
)

result$respondents  # 回答者単位の要約
result$pairs        # 回答者・項目ペア単位のスコア
```

`result$pairs`には欠測ペアも行として含まれ、その`inconsistency`は`NA`です。このため、ペアごとの欠測状況や、要約値の根拠を確認できます。

## 5. 分析上の注意事項

- **ペア指定への依存:** 不整合度スコアは、研究者が指定した項目ペアと想定関係に直接依存します。
- **項目の重複:** 同一項目が複数のペアに含まれても構いませんが、得られたペアスコアは相互に独立ではありません。集計値を独立な証拠の数として解釈しないでください。
- **閾値と除外基準:** 0.75 などの閾値は例示に過ぎません。特定のカットオフで回答者を機械的に除外するのではなく、設問内容の検討や感度分析を併用してください。

### 欠測回答と最小有効ペア数

ペアの両方の回答が観測されたときだけ、そのペアのスコアを計算します。どちらかが`NA`なら`n_missing_pairs`に数え、スコア要約から除外します。有効ペア数が`min_valid_pairs`を下回ると、`mean_inconsistency`、`max_inconsistency`、`sum_inconsistency`、`n_high_inconsistency`、`prop_high_inconsistency`は`NA`になります。`n_valid_pairs`と`n_missing_pairs`には観測数が残ります。既定の`min_valid_pairs = 1`では、有効ペアがない回答者の要約値は`NA`です。

### 項目ペアと尺度範囲の指定

`scale_min`と`scale_max`には、標本内で観測された最小値・最大値ではなく、回答尺度の理論上の端点を指定します。対象項目は通常の数値列（integerまたはdouble）で、非欠測値は指定範囲内でなければなりません。`NaN`、無限値、カテゴリ型の列、宣言した範囲外の値はエラーになります。

`same`または`opposite`は、関数へ渡す値に対して期待する関係を表します。逆転得点化を行うと、記録された回答値に対する関係と異なる場合があります。スコアを解釈する前に、得点化方法とペアの指定を決めてください。

### 解釈

この関数は、研究者が指定したペア関係からの距離を計算します。項目の意味を自動判定したり、ペアを選んだり、妥当性が検証された共通のカットオフを提示したりするものではありません。高いスコアは指定した関係からの乖離を示すため、設問文、尺度の符号化、欠測状況、他の回答品質指標と併せて解釈してください。これだけで不注意回答を診断することはできません。

---

[ユーザーガイド](../guide.ja.md) | [User guide](../guide.en.md)
