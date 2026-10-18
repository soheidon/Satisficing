[English](https://github.com/soheidon/Satisficing/blob/main/README.md) | [日本語](https://github.com/soheidon/Satisficing/blob/main/docs/README-ja.md) | [User Guide](https://github.com/soheidon/Satisficing/blob/main/docs/guide.en.md) | [日本語ガイド](https://github.com/soheidon/Satisficing/blob/main/docs/guide.ja.md)

# Satisficing

調査における満足化回答の指標を検出するためのツールです。

`Satisficing` は、調査回答のパターンを確認し、データフレームの行ごとに論理条件を評価する関数を提供します。本バージョンでは、元の独自ツールに加え、CRANパッケージ `careless` (バージョン 1.2.2) から移植された不真面目回答・不十分な努力回答（careless / insufficient effort responding）の検出指標を取り込みました。これらの関数は追加検討が必要な指標を見つける助けとなりますが、それだけで満足化を判定するものではありません。

## 機能

### 独自のツール
- `stline()` は、指定した列の回答が同一である行にフラグを付けます。論理値、数値、文字列、因子に対応し、選択列は同じ型グループである必要があります。欠損でない回答が2つ未満の行は `NA` になります。
- `matching()` は、データフレーム内で論理式を評価し、整数の判定列（`1L`、`0L`、`NA_integer_`）を追加します。論理式は行数と同じ長さの論理ベクトルを返す必要があります。
- `rawnn()` は、列名と1始まりの列番号を表示します。

### 'careless' から移植された指標
- `longstring()`: 同一回答の最長連続数（および平均長）を算出。
- `irv()`: 個人内回答変動（指定項目に対する回答者内標準偏差、Intra-individual Response Variability）を算出。項目順に依存する同一回答の連続長は `longstring()` で測定します。
- `evenodd()`: 偶数項目と奇数項目の下位尺度相関に基づく偶奇一貫性（even-odd consistency）スコアを算出。
- `psychsyn()`: 計量心理学的同義語（psychometric synonyms）項目ペア間の個人内相関を算出。
- `psychant()`: 計量心理学的反義語（psychometric antonyms）項目ペア間の個人内相関を算出。
- `psychsyn_critval()`: 項目ペア間の相関を計算・順位付けし、適切な閾値（critical value）の設定を支援。
- `mahad()`: `psych::outlier` を用いてマハラノビス距離を算出し、潜在的な外れ値にフラグを付与。
- データセット: 検証および例示用のシミュレーションデータ `careless_dataset`、`careless_dataset2` を提供。

### ストレートライン測度（Kim et al., 2019 / straightliner 規約）
- 正準 straightliner API:
  - `meanRootPairs()`: 項目ペア間の平均平方根差（Mean Root of Pairs）を行ごとに算出し、Kim et al. (2019) の論文式に基づき標本内正規化したスコアを算出。
  - `maxIdenticalRating()`: 最頻回答カテゴリーの割合（Maximum Identical Rating）を算出。
  - `question_sd()`: 回答者ごとのバッテリー項目標準偏差を算出。
  - `scale_point_variation()`: カテゴリー割合に基づく尺度点多様性（Scale Point Variation）を算出（欠測を1カテゴリーとして扱う straightliner 規約に準拠）。
  - `nondiff()`: 単純無分化（Simple Nondifferentiation）を論理ベクトル（行内の全回答が同一なら `TRUE`、異なれば `FALSE`）として算出。
  - `straightlining()`: 複数の個人レベル指標（`mrp`, `mir`, `qsd`, `spv`, `nondiff`）を一括算出するコンビニエンス関数（元データへの列結合オプションあり）。
  - `straightlining_qset()`: 複数バッテリーにわたる集計サマリーを算出し、専用の `print()` 形式を備えた `straightliner` クラスオブジェクトとして返却。
- 互換用ラッパー:
  - `mrp()`, `mir()`, `spv()`: 後方互換性のために維持。入力データフレームに計算結果列を追加して返却。
- 既存の `stline()`（単純無分化の整数フラグ）および `irv()`（項目回答値の個人内標準偏差）と合わせ、Kim et al. (2019) で検討された5つのストレートライン測度を網羅します。なお、`nondiff()` が厳密な全項目同一性を論理値で返すのに対し、`stline()` は2つ以上の非欠測回答がある行について観察された回答が同一かを整数フラグ（`1L`/`0L`/`NA_integer_`）で返すという仕様上の差異があります。

### 意味的不整合（Semantic Inconsistency）
- `semantic_inconsistency()`: 利用者が指定した項目ペアの期待関係（同方向 `same` または逆方向 `opposite`）に基づき、回答の意味的不整合度を算出（尺度理論値の範囲 [0, 1] に正規化）。

### 回答者スクリーニングおよび抽出（Screening and Filtering）
- `flag_respondents()`: 利用者定義の論理条件に基づき、品質指標からスクリーニングフラグ（論理値列）を生成（data-mask 評価、ID 列の自動/明示保持）。
- `filter_respondents()`: 品質フラグに基づき、明示的 ID 照合、三値論理集約（`any`, `all`, `at_least`）、および監査ログ（audit）を伴う回答者データの抽出・除外を実行。

## インストール

GitHub からパッケージをインストールします。

```r
install.packages("remotes")
remotes::install_github("soheidon/Satisficing")
```

## 使用例

```r
library(Satisficing)

# 調査回答の例
responses <- data.frame(
  q1 = c(1, 1, 1, 2, NA),
  q2 = c(1, 1, 2, 2, NA),
  q3 = c(1, 2, 3, 2, 1)
)

# ストレートライン回答の検出（独自ツール）
stline(responses, c("q1", "q2", "q3"))

# 項目ペア間の意味的不整合度
item_pairs <- data.frame(
  item1 = c("q1", "q1"),
  item2 = c("q2", "q3"),
  relation = c("same", "opposite"),
  stringsAsFactors = FALSE
)
semantic_scores <- semantic_inconsistency(
  responses, item_pairs,
  scale_min = 1, scale_max = 5
)

# 正準 straightliner 関数（Kim et al., 2019）
straightlining(responses, varnames = c("q1", "q2", "q3"))
maxIdenticalRating(responses, varnames = c("q1", "q2", "q3"))
meanRootPairs(responses, varnames = c("q1", "q2", "q3"))
nondiff(responses, varnames = c("q1", "q2", "q3"))

# 論理条件による行判定
respondents <- data.frame(
  age = c(25, 17, 30, NA),
  employed = c(TRUE, FALSE, TRUE, TRUE)
)
matching(respondents, age >= 18, result_col = "adult")

# 列番号の確認
rawnn(iris)

# careless 指標の算出
data(careless_dataset)
ls_scores <- longstring(careless_dataset)
irv_scores <- irv(careless_dataset)
syn_scores <- psychsyn(careless_dataset, critval = 0.60)
maha_dist <- mahad(careless_dataset, plot = FALSE)
```

## リファレンスマニュアル

パッケージのリファレンスマニュアルは [GitHub Releases ページ](https://github.com/soheidon/Satisficing/releases) の [`Satisficing.pdf`](https://github.com/soheidon/Satisficing/releases/latest/download/Satisficing.pdf) から取得できます。

## 謝辞とサードパーティコード

`Satisficing` は、Richard Yentes 氏および Francisco Wilhelm 氏が作成した R パッケージ `careless` (version 1.2.2) から移植された関数、データセット、ドキュメントを含んでいます。

- **移植コンポーネント**: `longstring`, `irv`, `evenodd`, `psychsyn`, `psychant`, `psychsyn_critval`, `mahad`, `careless_dataset`, `careless_dataset2`
- **ライセンス**: 移植されたコンポーネントは MIT License (c) 2016 Richard Yentes の下で許諾されています。
  - ソースツリー: [`inst/licenses/careless-MIT.txt`](../inst/licenses/careless-MIT.txt) および [`inst/COPYRIGHTS`](../inst/COPYRIGHTS)
  - インストール済みパッケージ: `licenses/careless-MIT.txt` および `COPYRIGHTS`
- **免責事項**: `Satisficing` は Sohei IDE が開発・保守している独立したパッケージであり、`careless` の原著者とは提携しておらず、支持を受けているものでもありません。

## 参考文献

- Kim, Y., Dykema, J., Stevenson, J., Black, P., & Moberg, D. P. (2019). Straightlining: Overview of Measurement, Comparison of Indicators, and Effects in Mail–Web Mixed-Mode Surveys. *Social Science Computer Review*, 37(2), 214–233. <https://doi.org/10.1177/0894439317752406>

## ライセンス

GPL (>= 2)。著作権表示とライセンス全文は [`LICENSE.md`](https://github.com/soheidon/Satisficing/blob/main/LICENSE.md) を参照してください。
