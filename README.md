# mecab-api

mecabをAPIとして使う

## 動作条件

rubyのmecabバインディングであるnattoを利用しているため、
APIが動作する環境上にmecabのインストールが必要です。

## ローカルでの起動方法

bundlerとforemanが無い場合は導入

```
$ gem install bundler foreman
```

リポジトリのcloneと起動

```
$ git clone https://github.com/knjcode/mecab-api
$ bundle install --path vendor/bundle
$ foreman start
```

これで、`localhost:5000`にAPIサーバが起動します。

## APIの使い方

application/json形式のPOSTで形態素解析したい文字列を含むjsonデータを送信

### エンドポイント

**サーバURL/mecab**

ローカルでforemanで起動した場合は

**localhost:5000/mecab**

### リクエストパラメータ

|名前|説明|
|:---|:----------|
|request_id |リクエストを識別するID（任意）<br>省略した場合は"リクエスト受付時刻[タブ文字]連番"|
|sentence   |形態素解析する文字列（必須）|
|dictionary|辞書指定（任意）<br>default（mecabのデフォルト辞書を利用）<br>mecab-ipadic-neologd（mecab-ipadic-NEologdを使用）<br>mecab-unidic-neologd（mecab-unidic-NEologdを使用）<br>省略時はデフォルト辞書を利用|
|normalize  |文字列の正規化処理（任意）<br>trueで正規化処理を実施、true以外や省略時は何もしない|

正規化処理は、mecab-ipadic-NEologdで紹介されている[正規化処理](https://github.com/neologd/mecab-ipadic-neologd/wiki/Regexp.ja)に基づく処理を行います。

### レスポンスパラメータ

|名前|説明|
|:---|:----------|
|request_id |リクエストを識別するID<br>指定した場合はリクエスト時と同一|
|word_list  |形態素解析結果（改行区切りの配列）|
|dictionary |形態素解析に利用した辞書|
|normalized |文字列の正規化処理の有無<br>正規化した場合はtrue、していない場合はfalse|

### mecabコマンドの辞書を指定する

mecab-ipadic-NEologdやmecab-unidic-NEologdの辞書を利用するためには、API実行環境に[mecab-ipadic-NEologd](https://github.com/neologd/mecab-ipadic-neologd/blob/master/README.ja.md)や[mecab-unidic-NEologd](https://github.com/neologd/mecab-unidic-neologd/blob/master/README.ja.md)を導入し、環境変数 `MECAB_IPADIC_NEOLOGD_DICDIR`と`MECAB_UNIDIC_NEOLOGD_DICDIR`に辞書のパスを指定します。

#### 辞書を指定する例

```bash
# mecabの辞書のパスを確認
$ mecab-config --dicdir
/usr/local/Cellar/mecab/0.996/lib/mecab/dic

# インストールされている辞書を確認
$ ls /usr/local/Cellar/mecab/0.996/lib/mecab/dic
ipadic               mecab-ipadic-neologd mecab-unidic-neologd unidic

# mecab-ipadic-NEologdとmecab-unidic-NEologdを指定
$ export MECAB_IPADIC_NEOLOGD_DICDIR="/usr/local/Cellar/mecab/0.996/lib/mecab/dic/mecab-ipadic-neologd"
$ export MECAB_UNIDIC_NEOLOGD_DICDIR="/usr/local/Cellar/mecab/0.996/lib/mecab/dic/mecab-unidic-neologd"
```

## 入出力サンプル

### 入力例

```json
{
  "sentence": "アップルは Apple Watchを4月24日に国内発売します。",
  "dictionary": "mecab-unidic-neologd"
}
```

### 出力例

```json
{
  "request_id": "1435530815\t0",
  "word_list": [
    "アップル\tアップル\tアップル\tアップル-apple\t名詞-普通名詞-一般\t\t",
    "は\tワ\tハ\tは\t助詞-係助詞\t\t",
    "Apple Watch\tアップルウォッチ\tアップルウォッチ\tApple Watch\t名詞-固有名詞-一般\t\t",
    "を\tオ\tヲ\tを\t助詞-格助詞\t\t",
    "4月24日\tシガツニジュウヨッカ\tシガツニジュウヨッカ\t4月24日\t名詞-固有名詞-一般\t\t",
    "に\tニ\tニ\tに\t助詞-格助詞\t\t",
    "国内\tコクナイ\tコクナイ\t国内\t名詞-普通名詞-一般\t\t",
    "発売\tハツバイ\tハツバイ\t発売\t名詞-普通名詞-サ変可能\t\t",
    "し\tシ\tスル\t為る\t動詞-非自立可能\tサ行変格\t連用形-一般",
    "ます\tマス\tマス\tます\t助動詞\t助動詞-マス\t終止形-一般",
    "。\t\t\t。\t補助記号-句点\t\t",
    "EOS"
  ],
  "dictionary": "mecab-unidic-neologd",
  "normalized": false
}
```

## コマンドラインでのテスト方法

```bash
curl -H "Content-type: application/json" -X POST -d '{"sentence":"アップルは Apple Watchを4月24日に国内発売します。","dictionary":"mecab-unidic-neologd"}' 'localhost:5000/mecab'
# ->
{
  "request_id": "1435530815\t0",
  "word_list": [
    "アップル\tアップル\tアップル\tアップル-apple\t名詞-普通名詞-一般\t\t",
    "は\tワ\tハ\tは\t助詞-係助詞\t\t",
    "Apple Watch\tアップルウォッチ\tアップルウォッチ\tApple Watch\t名詞-固有名詞-一般\t\t",
    "を\tオ\tヲ\tを\t助詞-格助詞\t\t",
    "4月24日\tシガツニジュウヨッカ\tシガツニジュウヨッカ\t4月24日\t名詞-固有名詞-一般\t\t",
    "に\tニ\tニ\tに\t助詞-格助詞\t\t",
    "国内\tコクナイ\tコクナイ\t国内\t名詞-普通名詞-一般\t\t",
    "発売\tハツバイ\tハツバイ\t発売\t名詞-普通名詞-サ変可能\t\t",
    "し\tシ\tスル\t為る\t動詞-非自立可能\tサ行変格\t連用形-一般",
    "ます\tマス\tマス\tます\t助動詞\t助動詞-マス\t終止形-一般",
    "。\t\t\t。\t補助記号-句点\t\t",
    "EOS"
  ],
  "dictionary": "mecab-unidic-neologd",
  "normalized": false
}
```
