# Satisficing

調査における満足化回答の指標を検出するためのツールです。

`Satisficing` は、調査回答のパターンを確認し、データフレームの行ごとに論理条件を評価する関数を提供します。これらの関数は追加検討が必要な指標を見つける助けとなりますが、それだけで満足化を判定するものではありません。

## 機能

- `stline()` は、指定した列の回答が同一である行にフラグを付けます。論理値、数値、文字列、因子に対応し、選択列は同じ型グループである必要があります。欠損でない回答が2つ未満の行は `NA` になります。
- `matching()` は、データフレーム内で論理式を評価し、整数の判定列（`1L`、`0L`、`NA_integer_`）を追加します。論理式は行数と同じ長さの論理ベクトルを返す必要があります。
- `rawnn()` は、列名と1始まりの列番号を表示します。

## インストール

GitHub から公開版をインストールします。

```r
install.packages("remotes")
remotes::install_github("soheidon/Satisficing")
```

## 使用例

```r
library(Satisficing)

responses <- data.frame(
  q1 = c(1, 1, 1, 2, NA),
  q2 = c(1, 1, 2, 2, NA),
  q3 = c(1, 2, 3, 2, 1)
)

stline(responses, c("q1", "q2", "q3"))

respondents <- data.frame(
  age = c(25, 17, 30, NA),
  employed = c(TRUE, FALSE, TRUE, TRUE)
)
matching(respondents, age >= 18, result_col = "adult")

rawnn(iris)
```

`stline()` は、選択列の欠損でない値が0個または1個の行に `NA_integer_` を返します。値が2個以上ある行では、すべて同じで除外対象でなければ `1L`、それ以外は `0L` です。`exclude_values` で特定の回答コードを判定対象から除外できます。

## リファレンスマニュアル

パッケージのリファレンスマニュアルは [GitHub Releases ページ](https://github.com/soheidon/Satisficing/releases) の [`Satisficing.pdf`](https://github.com/soheidon/Satisficing/releases/latest/download/Satisficing.pdf) から取得できます。

## ライセンス

GPL (>= 2)。著作権表示とライセンス全文は [`LICENSE`](LICENSE) を参照してください。

## English

英語の概要は [README.md](README.md) を参照してください。
