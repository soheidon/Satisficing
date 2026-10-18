[English](flag-respondents.en.md) | [日本語](flag-respondents.ja.md)

# `flag_respondents()`：条件式から回答者フラグを作成する

## 1. 概要

`flag_respondents()` は、回答者単位の指標を含むデータフレームに対して、利用者が指定した論理条件を評価し、条件ごとのフラグ列を作成する関数です。たとえば、`longstring` や不整合度などの指標を計算した後、研究者が定めた条件に該当する回答者を確認できます。

この関数は条件を評価して論理値を返します。回答者を自動的に除外したり、閾値の妥当性を判断したりはしません。フラグは回答パターンを確認するための情報として扱い、除外の判断には研究上の根拠と感度分析を用いてください。

## 2. 基本的な使い方

```r
flag_respondents(indicators, ..., id = NULL)
```

| 引数 | 説明 |
|---|---|
| `indicators` | 回答者単位の指標を含むデータフレーム。列名は欠損・空でなく、一意である必要があります。 |
| `...` | 評価する1つ以上の論理式。各式は行数と同じ長さの論理ベクトルを返す必要があります。 |
| `id` | 結果に保持する識別列名。`NULL`（既定値）の場合、`id`列があれば自動的に保持します。 |

式ではデータフレームの列名を直接使えます。名前付きの式はその名前で出力されます。

```r
library(Satisficing)

indicators <- data.frame(
  id = 1:4,
  longstring = c(12, 5, 15, 3),
  inconsistency = c(0.8, 0.2, 0.9, 0.1)
)

flags <- flag_respondents(
  indicators,
  high_longstring = longstring >= 10,
  high_inconsistency = inconsistency >= 0.75
)
flags
```

結果は次のようなデータフレームです。

```text
  id high_longstring high_inconsistency
1  1            TRUE               TRUE
2  2           FALSE              FALSE
3  3            TRUE               TRUE
4  4           FALSE              FALSE
```

## 3. 条件式の評価

各式は `indicators` の列を参照する環境で評価されます。列にないオブジェクトは、関数を呼び出した環境から参照できます。

```r
longstring_cutoff <- 10

flags <- flag_respondents(
  indicators,
  longstring >= longstring_cutoff
)
```

式に名前を付けなかった場合、式を表す文字列が列名になります。分析コードを読みやすく保つため、通常は名前付きの条件式を推奨します。

各条件式は、**論理型**で、かつ `nrow(indicators)` と同じ長さでなければなりません。数値の `0` / `1` を論理値として扱う変換や、長さ1の値を複数行に繰り返す処理は行われず、その場合はエラーになります。

## 4. 欠測値の扱い

条件式の結果に含まれる `NA` はそのままフラグ列に残ります。たとえば、指標値が欠測していると比較結果も `NA` になり得ます。

```r
indicators_with_missing <- data.frame(
  id = 1:3,
  score = c(0.9, NA, 0.2)
)

flag_respondents(
  indicators_with_missing,
  high_score = score >= 0.75
)
```

この結果の `high_score` は `TRUE`, `NA`, `FALSE` です。`NA` を自動的に `FALSE` とみなしたり、行を削除したりしません。欠測フラグを後続処理でどう扱うかは、分析者が明示的に決めてください。

## 5. 識別列と返り値

返り値は入力行の順序を保ったデータフレームです。出力には、指定または自動検出された識別列が先頭に置かれ、その後に `...` の条件式に対応する論理列が指定順で並びます。

- `id = NULL` で入力に `id` 列がある場合、その列を保持します。
- `id = "respondent_id"` のように指定すると、その列を保持します。指定列がない場合はエラーです。
- `id` を指定せず、入力に `id` 列もない場合、識別列は返り値に含まれません。
- 識別列の一意性はこの関数では検証しません。識別列として使う列は、分析上適切なものを選んでください。

重複した条件名、空の条件名、または条件名と保持する識別列名の衝突はエラーになります。入力の列名も一意である必要があります。

## 6. 他の関数との組合せ

`flag_respondents()` はフラグを作成し、`filter_respondents()` はそのフラグを使って回答データを抽出し、監査情報を作成します。フラグの作成と抽出を分けることで、条件ごとの判定を先に点検できます。

```r
flags <- flag_respondents(
  indicators,
  high_longstring = longstring >= 10,
  high_inconsistency = inconsistency >= 0.75
)

# 抽出を行う場合は、filter_respondents() の規則とNAの扱いを明示する
# filtered <- filter_respondents(
#   survey_data, flags,
#   strategy = "any", id = "id", na_action = "keep"
# )
```

`filter_respondents()` に渡す場合は、指標と調査データの識別列が対応していることを確認し、複数フラグをどう組み合わせるか、欠測による判定不能をどう扱うかを指定してください。

## 7. 利用上の注意

- 条件式と閾値は研究者が定義します。この関数は普遍的な判定基準を提供しません。
- 複数のフラグは異なる回答パターンを捉えることがあります。単一のフラグだけで不注意回答と断定しないでください。
- フラグに `NA` が含まれるときは、後続処理での扱いを確認してください。
- 分析報告では、使用した指標、条件式、閾値、欠測値の扱いを明記してください。

---

[日本語ユーザーガイド](../guide.ja.md) | [User guide](../guide.en.md)
