[English](guide.en.md) | [日本語](guide.ja.md)

# Satisficing ユーザーガイド（日本語）

**対応バージョン：0.2.0**
**公式リファレンスとは別の解説資料**
[GitHub リポジトリ](https://github.com/soheidon/Satisficing)

## 1. このガイドについて

`Satisficing` は、質問紙調査における *satisficing*（回答に必要な認知的努力の省略）の兆候や、不注意回答・低努力回答に関連する回答パターンを調べるRパッケージです。v0.2.0には、独自の3関数（`stline()`、`matching()`、`rawnn()`）と、`careless` v1.2.2から移植した7関数が含まれます。

本ガイドは、ヘルプページの引数一覧を繰り返すのではなく、「何を調べられるか」「どのように結果を読むか」「どのような限界があるか」を説明します。**どの指標も、それだけで回答者の不注意や不誠実さを確定するものではありません。** 分析の目的、項目内容、提示順序、尺度特性などと併せて解釈してください。

### 1.1 どの関数を使うか

| 知りたいこと | 関数 | 主な結果 |
|---|---|---|
| 指定項目の回答がすべて同じか | [`stline()`](functions/stline.ja.md) | 1 / 0 / NA のフラグを追加 |
| 同じ回答が最大何項目続いたか | `longstring()` | 最大連続長、平均連続長 |
| 回答のばらつきはどの程度か | `irv()` | 回答者内標準偏差 |
| 尺度の奇数・偶数項目に一貫性があるか | `evenodd()` | 回答者内相関 |
| 正に相関する項目対への回答が整合しているか | `psychsyn()` | 回答者内相関 |
| 負に相関する項目対への回答が整合しているか | `psychant()` | 回答者内相関 |
| どの項目対を整合性検査に利用するか | `psychsyn_critval()` | 項目対と相関係数の一覧 |
| 他の回答者と比べて多変量的に特異か | `mahad()` | マハラノビス距離の二乗、フラグ |
| 任意の条件に一致する行を示したい | `matching()` | 1 / 0 / NA のフラグを追加 |
| 列名と列番号を確認したい | `rawnn()` | コンソール出力 |

### 1.2 インストールとサンプルデータ

```r
# 未インストールの場合（GitHub版）
# install.packages("remotes")
# remotes::install_github("soheidon/Satisficing")

library(Satisficing)

data("careless_dataset", package = "Satisficing")
data("careless_dataset2", package = "Satisficing")

dim(careless_dataset)   # 200人 × 50項目
dim(careless_dataset2)  # 1000人 × 100項目
```

`careless_dataset` は、通常回答・ストレートライン・ランダム回答を含むシミュレーションデータです。10下位尺度×5項目で構成されています。`careless_dataset2` は、通常回答・長い同一回答の連続・全般的に不注意な回答を模した10下位尺度×10項目のデータです。どちらも実際の調査データではありません。

### 1.3 入力データの基本

多くの関数では、**行が回答者、列が項目**となるデータフレームまたは行列を渡します。識別番号・回答日時などを含めず、分析対象の項目だけを選択してください。特に`longstring()`と分割IRVでは列順が重要です。逆転得点化した項目の並びで「実際にどのボタンを続けて押したか」を評価することはできません。

以下の説明では、必要に応じて次の小さなデータを使います。

```r
answers <- data.frame(
  id = 1:4,
  q1 = c(3, 3, 1, 4),
  q2 = c(3, 3, 2, 4),
  q3 = c(3, 4, 3, 4),
  q4 = c(3, 4, 4, 2),
  q5 = c(3, 4, 5, 2)
)
items <- answers[paste0("q", 1:5)]
```

## 2. `stline()`：指定した項目が同じ回答になっているか

**目的：** 指定した複数項目について、各回答者の非欠測値がすべて同一かどうかを判定します。

```r
flagged <- stline(
  answers,
  columns = paste0("q", 1:5),
  result_column_name = "straight_line"
)
flagged[c("id", "straight_line")]
```

`stline()` は元のデータフレームに整数列を追加します。`1`は非欠測値が少なくとも2個あり、すべて同一であること、`0`は回答値が異なること、`NA`は非欠測値が0～1個しかないことを示します。例では回答者1はすべて3なので`1`です。回答者2は3と4を使っているため`0`です。

特定の回答値を一致判定の対象から除外したい場合は、`exclude_values` を使います。

```r
stline(answers, paste0("q", 1:5), exclude_values = 3)
```

この場合、全項目が3の回答者も`0`になります。「中立」の選択肢を除外するなどの操作はできますが、その根拠を研究計画で明示してください。

**解釈上の注意：** 5項目すべて同じ回答でも、項目内容から自然に生じた可能性があります。また、`3333344444` のように途中で回答値が切り替わる場合は検出されません。そのようなパターンには次の`longstring()`が適しています。

## 3. `longstring()`：同一回答がどこまで連続したか

**目的：** 項目の並びに沿って、隣り合う回答が何個続けて一致したかを調べます。

```r
longstring(items)
longstring(items, avg = TRUE)
```

デフォルトでは、各回答者の**最大連続同一回答数**をベクトルで返します。`avg = TRUE` では、最大値を表す`longstr`と、連続する同一回答区間の平均長を表す`avgstr`を含むデータフレームを返します。

例えば `3,3,3,4,4,4,4,3` では、同じ値の連続区間は長さ3、4、1です。最大連続長は4、平均区間長は(3+4+1)/3 = 2.67です。**すべて同じ選択肢である必要はありません。**

```r
pattern <- data.frame(
  q1 = 3, q2 = 3, q3 = 3, q4 = 4,
  q5 = 4, q6 = 4, q7 = 4, q8 = 3
)
longstring(pattern, avg = TRUE)
```

**解釈上の注意：** 項目順序を並べ替えると値が変わります。提示した順序のまま分析してください。欠測値を挟むケースでの厳密な扱いは、対象バージョンの関数実装も確認してください。長い同一回答列があることだけでは、不注意回答を確定できません。

## 4. `irv()`：回答者内のばらつきを測る

**目的：** 回答者ごとに、項目を横断した回答値の標準偏差（intra-individual response variability; IRV）を計算します。

```r
irv(items)
irv(careless_dataset, split = TRUE, num.split = 4)
```

値が小さいほど回答が似通っており、極端に小さければ同じ値の反復が疑われます。一方、極端に大きい値は乱雑な回答の候補にもなります。ただし、質問内容に応じた本来の回答の多様性もIRVに影響します。

`split = TRUE` にすると、全体の`irvTotal`に加えて、列を指定した区間数に分割した`irv1`、`irv2`などが返されます。例えば調査の後半だけ急に回答変動が減る場合を調べられます。`na.rm = TRUE` が初期設定で、欠測を除いて計算します。

```r
v <- irv(careless_dataset, split = TRUE, num.split = 4)
boxplot(v$irv1, v$irv2, v$irv3, v$irv4,
        names = paste0("区間", 1:4), ylab = "IRV")
```

**解釈上の注意：** 項目が異なる尺度で採点されている場合や、下位尺度が混ざる場合には、数値の大小が何を意味するか慎重に検討してください。逆転項目を含む尺度の得点化方針によって解釈も変わります。

## 5. `evenodd()`：奇数・偶数項目間の一貫性

**目的：** 各因子の項目を奇数番目・偶数番目に分けて得点を構成し、その得点系列間の回答者内相関を求めます。単純に質問紙全体の奇数列と偶数列を相関させる関数ではありません。

```r
eo <- evenodd(careless_dataset, factors = rep(5, 10))
eo_diag <- evenodd(careless_dataset, factors = rep(5, 10), diag = TRUE)
head(eo_diag)
```

`factors = rep(5, 10)` は、5項目から成る因子（下位尺度）が10個、順番に並んでいることを表します。`diag = FALSE` では相関値の数値ベクトル、`diag = TRUE` では`eo_cor`と`eo_missing`を含むデータフレームを返します。公式マニュアルでは`eo_missing`を、計算に利用できる非欠測の奇数・偶数ペア数として説明しています。列名だけから「欠測数」と解釈しないでください。

**解釈上の注意：** 因子の境界と項目順序を正しく指定しなければ意味のある一貫性指標になりません。相関が低いというだけで不注意回答を断定せず、下位尺度の項目構成や逆転項目も考慮してください。

## 6. `psychsyn_critval()`：整合性検査に用いる項目対を探す

**目的：** データ中の項目対の相関を求め、その関係を確認します。`psychsyn()`や`psychant()`に先立つ補助関数です。

```r
pairs_pos <- psychsyn_critval(careless_dataset)
head(pairs_pos)

pairs_neg <- psychsyn_critval(careless_dataset2, anto = TRUE)
head(pairs_neg)
```

戻り値は`var1`、`var2`、`cor`の列を持つデータフレームです。`anto = FALSE`では正の相関が強い項目対を、`anto = TRUE`では負の相関が強い項目対を確認できます。

**解釈上の注意：** これはデータから得られた相関です。内容的に類義・反義かどうかを自動判定するわけではありません。項目対の候補が少ない場合や、サンプルが小さい場合には指標が不安定になることがあります。

## 7. `psychsyn()`：正に相関する項目対の整合性

**目的：** 標本全体で正に強く相関する項目対を選び、各回答者がそれらの項目にどの程度整合的に回答したかを、回答者内相関で表します。

```r
syn <- psychsyn(careless_dataset, critval = 0.60)
syn_diag <- psychsyn(careless_dataset, critval = 0.60, diag = TRUE)
head(syn_diag)
```

`critval = 0.60` は、項目対を選択するための相関係数の基準です。`diag = FALSE`では相関値のベクトルを、`diag = TRUE`では`numPairs`（利用した項目対の数）と`cor`（整合性スコア）のデータフレームを返します。

`resample_na = TRUE` がデフォルトです。公式マニュアルによると、スコアがNAの場合に再サンプリングを試みる動作があります。再現性を重視する分析では、この引数の挙動を確認し、必要に応じて乱数種を固定してください。

**解釈上の注意：** 類義項目対の数、項目の内容、相関基準の設定によって結果が変わります。計算できる項目対がほとんどない場合は、結果の解釈を控えてください。

## 8. `psychant()`：負に相関する項目対の整合性

**目的：** 標本全体で負に強く相関する項目対について、回答者の整合性を調べます。`psychsyn(..., anto = TRUE)`を呼び出す簡便なラッパーです。

```r
ant <- psychant(careless_dataset2, critval = -0.60)
ant_diag <- psychant(careless_dataset2, critval = -0.60, diag = TRUE)
head(ant_diag)
```

`diag = TRUE`の戻り値は`numPairs`と`cor`です。デフォルトの`critval`は`-0.6`です。`psychsyn()`の正の相関に対する基準値と混同しないようにしてください。

**解釈上の注意：** 「負に相関する」ことと、項目が内容的に真正の反義語であることは同じではありません。また、逆転項目のコード化や尺度の因子構造によって、負の相関の意味が変わる場合があります。

## 9. `mahad()`：多変量的に特異な回答を探す

**目的：** 項目群全体で、他の回答者と比べて特異な回答パターンを示す回答者を見つけます。`psych::outlier()`を利用してマハラノビス距離を計算します。

```r
# 既定ではQQプロットが描画されます
out <- mahad(careless_dataset, plot = FALSE)
out_flag <- mahad(careless_dataset, plot = FALSE,
                  flag = TRUE, confidence = 0.99)
head(out_flag)
```

`flag = FALSE`ならマハラノビス距離の**二乗**（`d_sq`）の数値ベクトルを返します。`flag = TRUE`なら`d_sq`と論理値の`flagged`を含むデータフレームを返します。`confidence`はフラグ付けの信頼水準で、初期値は`0.99`です。`plot = TRUE`が初期値なので、グラフが不要なら明示的に`FALSE`を指定します。

**解釈上の注意：** 距離が大きいことは「珍しい回答」であることを示しますが、不注意回答であるとは限りません。特徴的な性格プロフィールを持つ回答者も検出され得ます。項目数と標本数、相関構造、欠測値の影響を確認してください。

## 10. `matching()`：任意の論理条件で行をフラグ付けする

**目的：** 研究者が定義した条件に合う回答者を抽出しやすくします。satisficing専用の自動判定法ではなく、**データフレーム内で論理式を行ごとに評価する汎用関数**です。

```r
x <- data.frame(id = 1:4, a = c(1, 2, 3, NA), b = c(3, 2, 1, 4))
matching(x, a > b)
matching(x, a == b, result_col = "same_answer")
```

戻り値は元のデータフレームに整数列を追加したものです。条件が`TRUE`なら`1`、`FALSE`なら`0`、`NA`なら`NA`です。条件式はデータフレームの列名を直接参照できます。

例えば「ある項目で高得点、別の項目で低得点」という条件の組合せを探索することにも利用できます。ただし、ある回答の組合せが矛盾しているかは設問内容に依存します。条件が成立したからといって不注意回答とみなすことはできません。

## 11. `rawnn()`：列番号と項目名を確認する

**目的：** データフレームの各列について、1始まりの列番号と列名をコンソールに表示します。

```r
rawnn(answers)
```

結果は `1: id`、`2: q1` のように表示されます。見落としやすい列名の確認、分析対象項目の範囲の把握などに利用できます。データは変更せず、返り値は不可視の`NULL`です。

## 12. 実際の質問紙データでの使用例：35項目のBFIを想定

ここでは、`bfi_data`というデータフレームに`BFI1`～`BFI35`の35項目が含まれているとします。**これは説明用の変数名であり、パッケージにBFIデータが同梱されているという意味ではありません。**

```r
library(Satisficing)

bfi_items <- paste0("BFI", 1:35)
x <- bfi_data[bfi_items]  # 実際の提示順序に合わせる

# 完全な同一回答かどうか
result <- stline(bfi_data, columns = bfi_items)

# 最大・平均連続同一回答数
runs <- longstring(x, avg = TRUE)
result$longstr <- runs$longstr
result$avgstr <- runs$avgstr

# 回答者内の回答変動
result$irv <- irv(x)

# 確認用の一覧
head(result[c("straight_line", "longstr", "avgstr", "irv")])
```

**読み方：** 35項目すべてが3なら、`straight_line`は1で最大連続長は35です。最初の20項目が3、その後の15項目が4なら、`straight_line`は0ですが、最大連続長は20です。3と4が交互なら、最大連続長は1になります。一方、使用した値の割合が同じであれば、個人内標準偏差は並び方によって変わりません。

**重要：** BFIが複数の性格因子を測ること、逆転項目があること、項目提示順序が調査によって異なり得ることを踏まえてください。35項目をひとまとまりにしたLongstringと、因子別の指標は、問いの立て方が異なります。

## 13. 分析結果の報告と注意事項

### 13.1 複数の指標を併用する

完全同一回答、長い同一回答列、低IRV、高IRV、整合性の低さ、多変量外れ値は、それぞれ異なる性質の回答パターンを捉えます。単一のスコアや一律のカットオフで回答者を自動的に除外するのではなく、指標の分布と設問内容を確認することを勧めます。

### 13.2 分析前に決めておくこと

- どの項目・下位尺度を指標の対象にするか。
- 項目の提示順序と、得点化・逆転処理のどちらのデータを利用するか。
- 欠測値をどう扱うか。
- どの指標を、どの目的で使用するか。
- 問題が疑われる回答者を除外するのか、感度分析で比較するのか。

### 13.3 論文での記載例

> 回答品質の探索的評価のため、RパッケージSatisficing（version 0.2.0）を用いた。指定項目における完全同一回答（`stline`）、最大連続同一回答数（`longstring`）、回答者内標準偏差（`irv`）を算出した。これらは不注意回答の確定診断ではなく、回答パターンの指標として扱った。

実際の論文では、用いた関数、解析項目、欠測処理、閾値の根拠（採用した場合）、除外人数、感度分析を具体的に記してください。

## 14. 文献・出典・ライセンス

- Johnson, J. A. (2005). Ascertaining the validity of individual protocols from web-based personality inventories. *Journal of Research in Personality, 39*, 103–129. https://doi.org/10.1016/j.jrp.2004.09.009
- Meade, A. W., & Craig, S. B. (2012). Identifying careless responses in survey data. *Psychological Methods, 17*, 437–455. https://doi.org/10.1037/a0028085
- Dunn, A. M., Heggestad, E. D., Shanock, L. R., & Theilgard, N. (2018). Intra-individual response variability as an indicator of insufficient effort responding. *Journal of Business and Psychology, 33*, 105–121.
- Marjanovic, Z., Holden, R., Struthers, W., Cribbie, R., & Greenglass, E. (2015). The inter-item standard deviation (ISD). *Personality and Individual Differences, 84*, 79–83.
- Yentes, R., & Wilhelm, F. `careless` R package, version 1.2.2. https://CRAN.R-project.org/package=careless

v0.2.0の`evenodd()`、`irv()`、`longstring()`、`mahad()`、`psychsyn()`、`psychant()`、`psychsyn_critval()`、および2つのサンプルデータは、`careless` v1.2.2から移植されています。著作権・ライセンス表示については、リポジトリに同梱されたファイルも参照してください。本ガイドは利用方法の解説であり、ソースコードのライセンス告知に代わるものではありません。

---

*本ガイドはSatisficing v0.2.0付属の公式リファレンス（2026年10月17日版）に基づき作成しました。関数の挙動の最終的な確認には、使用中のパッケージの`?関数名`およびソースコードを参照してください。*
