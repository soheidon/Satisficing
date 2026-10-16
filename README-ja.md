[English](README.md) | [日本語](README-ja.md)

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
- `irv()`: 個人内回答ばらつき（連続回答の標準偏差、Intra-individual Response Variability）を算出。
- `evenodd()`: 偶数項目と奇数項目の下位尺度相関に基づく偶奇一貫性（even-odd consistency）スコアを算出。
- `psychsyn()`: 計量心理学的同義語（psychometric synonyms）項目ペア間の個人内相関を算出。
- `psychant()`: 計量心理学的反義語（psychometric antonyms）項目ペア間の個人内相関を算出。
- `psychsyn_critval()`: 項目ペア間の相関を計算・順位付けし、適切な閾値（critical value）の設定を支援。
- `mahad()`: `psych::outlier` を用いてマハラノビス距離を算出し、潜在的な外れ値にフラグを付与。
- データセット: 検証および例示用のシミュレーションデータ `careless_dataset`、`careless_dataset2` を提供。

## インストール

GitHub からパッケージをインストールします。

```r
install.packages("remotes")
remotes::install_github("soheidon/Satisficing")
```

## 使用例

```r
library(Satisficing)

# ストレートライン回答の検出
responses <- data.frame(
  q1 = c(1, 1, 1, 2, NA),
  q2 = c(1, 1, 2, 2, NA),
  q3 = c(1, 2, 3, 2, 1)
)
stline(responses, c("q1", "q2", "q3"))

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
  - ソースツリー: [`inst/licenses/careless-MIT.txt`](inst/licenses/careless-MIT.txt) および [`inst/COPYRIGHTS`](inst/COPYRIGHTS)
  - インストール済みパッケージ: `licenses/careless-MIT.txt` および `COPYRIGHTS`
- **免責事項**: `Satisficing` は Sohei IDE が開発・保守している独立したパッケージであり、`careless` の原著者とは提携しておらず、支持を受けているものでもありません。

## ライセンス

GPL (>= 2)。著作権表示とライセンス全文は [`LICENSE.md`](https://github.com/soheidon/Satisficing/blob/main/LICENSE.md) を参照してください。

## English

英語の概要は [README.md](README.md) を参照してください。
