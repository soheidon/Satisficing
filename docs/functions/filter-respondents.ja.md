[English](filter-respondents.en.md) | [日本語](filter-respondents.ja.md)

# `filter_respondents()`：品質フラグに基づく回答者の抽出

## 1. 概要

`filter_respondents()` は、回答者ごとの論理フラグを使って、調査データを保持する回答者と除外する回答者に分ける関数です。フラグと回答データは回答者IDで照合し、複数フラグの集約方法と欠測フラグの扱いを指定できます。全回答者の判定過程は監査表として返されます。

この関数は指定された規則を適用します。フラグや閾値が研究目的に適切かどうかは判断しません。回答者の除外は分析結果に影響するため、条件と判断方法を記録し、除外前後の感度分析を検討してください。

## 2. 基本的な使い方

```r
filter_respondents(
  data,
  flags,
  strategy = c("any", "all", "at_least"),
  n = NULL,
  id = NULL,
  na_action = c("error", "keep", "exclude")
)
```

| 引数 | 説明 |
|---|---|
| `data` | 元の調査回答データフレーム。 |
| `flags` | ID列と1つ以上の論理フラグ列を含むデータフレーム。フラグ列名は監査表の予約列名と重複できません。 |
| `strategy` | 複数フラグの集約方法。`"any"`、`"all"`、`"at_least"` のいずれか。 |
| `n` | `strategy = "at_least"` で除外に必要なTRUEの最小数。他の戦略では `NULL` にします。 |
| `id` | 両データフレームにあるID列名。`NULL` の場合は、両方に存在する `id` 列を使います。 |
| `na_action` | 集約結果が判定不能 (`NA`) の回答者の扱い。`"error"`（既定値）、`"keep"`、`"exclude"`。 |

## 3. IDによる照合

`data` と `flags` は、両方にあるID列で照合します。行順だけを使った結合は行いません。ID値は両方のデータで欠測せず重複がなく、型とクラスが一致し、IDの集合が完全に一致している必要があります。

```r
survey <- data.frame(
  id = 1:4,
  q1 = c(5, 5, 1, 3),
  q2 = c(5, 1, 5, 3)
)

# flags は survey と異なる順序でも、IDで対応づけられる
flags <- data.frame(
  id = c(3, 1, 4, 2),
  flag_speed = c(FALSE, FALSE, FALSE, TRUE),
  flag_inconsistent = c(TRUE, FALSE, NA, TRUE)
)
```

既定では両方のデータフレームに `id` 列が必要です。別の列名を使う場合は、たとえば `id = "respondent_id"` と指定します。片方のデータにIDがない場合、ID集合が一致しない場合、またはID値に欠測・重複がある場合はエラーになります。

## 4. フラグの集約規則

`strategy` は、各回答者のフラグ列をどのように組み合わせて除外判定にするかを指定します。`TRUE` は除外条件に該当、`FALSE` は該当しないことを表します。

### `strategy = "any"`

少なくとも1つのフラグが `TRUE` なら除外判定は `TRUE` です。全フラグが `FALSE` なら `FALSE` です。`TRUE` がなく、1つ以上の `NA` がある場合は判定不能 (`NA`) です。

| フラグ | 判定 |
|---|---|
| `FALSE, FALSE` | 保持 (`FALSE`) |
| `TRUE, NA` | 除外 (`TRUE`) |
| `FALSE, NA` | 判定不能 (`NA`) |

### `strategy = "all"`

すべてのフラグが `TRUE` の場合に除外判定は `TRUE` です。1つでも `FALSE` があれば `FALSE` です。`FALSE` がなく、1つ以上の `NA` がある場合は判定不能 (`NA`) です。

### `strategy = "at_least"`

`TRUE` の数が `n` 以上なら除外判定は `TRUE` です。`TRUE` と `NA` の合計が `n` 未満なら、欠測値がすべて `TRUE` だったとしても基準に届かないため `FALSE` です。それ以外は判定不能 (`NA`) です。`n` は1以上、かつフラグ列数以下の整数でなければなりません。

## 5. 判定不能な値と `na_action`

複数フラグを集約しても除外するか決められない回答者がいる場合、`na_action` で扱いを指定します。

| `na_action` | 動作 |
|---|---|
| `"error"` | 既定値。判定不能な回答者が1人でもいればエラーにします。 |
| `"keep"` | 判定不能な回答者を保持します。最終的な `excluded` は `FALSE` になります。 |
| `"exclude"` | 判定不能な回答者を除外します。最終的な `excluded` は `TRUE` になります。 |

この設定は、集約された判定が `NA` の場合に適用されます。既に規則を満たす、または満たさないと確定している回答者の判定は変えません。たとえば `strategy = "any"` では、`TRUE, NA` は除外が確定し、`FALSE, NA` は判定不能です。

## 6. 使用例

次の例では、いずれかのフラグが `TRUE` の回答者を除外し、判定不能な回答者は保持します。フラグ行はIDで照合されるため、入力順が `survey` と異なっていても結果は正しく対応します。

```r
library(Satisficing)

res <- filter_respondents(
  survey,
  flags,
  strategy = "any",
  na_action = "keep"
)

res$data      # 保持される回答者：ID 1 と 4
res$excluded  # 除外される回答者：ID 2 と 3
res$audit     # 全回答者の判定記録
```

## 7. 返り値と監査表

関数は次の3要素を持つ名前付きリストを返します。

- `$data`: 保持された行。元の `data` の列、列順、値を保ちます。
- `$excluded`: 除外された行。元の `data` の列、列順、値を保ちます。
- `$audit`: 全回答者の判定を `data` の行順で記録するデータフレームです。

監査表の列順は、ID、`row_index`、各フラグ列、`n_flagged`、`n_missing_flags`、`decision`、`strategy`、`n_required`、`na_action`、`excluded` です。

| 列 | 内容 |
|---|---|
| ID | 回答者を識別する値。 |
| `row_index` | 元の `data` における1始まりの行番号。 |
| 各フラグ列 | IDで照合した論理フラグ。 |
| `n_flagged` | `TRUE` であるフラグの数。 |
| `n_missing_flags` | `NA` であるフラグの数。 |
| `decision` | `na_action` を適用する前の集約判定。判定不能なら `NA`。 |
| `strategy` | 適用した集約方法。 |
| `n_required` | `any` では1、`all` ではフラグ数、`at_least` では指定した `n`。 |
| `na_action` | 指定された判定不能値の処理方法。 |
| `excluded` | `na_action` 適用後の最終的な除外判定。 |

ID列名およびフラグ列名には、監査表の予約名（`row_index`、`n_flagged`、`n_missing_flags`、`decision`、`strategy`、`n_required`、`na_action`、`excluded`）を使用できません。

## 8. 利用上の注意

- `flags` にはID列以外に少なくとも1つの論理型フラグ列が必要です。数値の `0` / `1` は論理値に変換されません。
- IDの型とクラスも照合されます。たとえば、片方が整数、もう片方が文字列のIDでは照合できません。
- `na_action = "keep"` と `"exclude"` は、判定不能な回答者の扱いを変えます。選択理由を分析手順に記録してください。
- 除外規則、フラグ数、欠測値の処理は結果に影響します。規則を明示し、必要に応じて異なる設定で感度分析を行ってください。

---

[日本語ユーザーガイド](../guide.ja.md) | [User guide](../guide.en.md)
