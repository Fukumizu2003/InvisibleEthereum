# zk-SNARK Groth16 Ceremony

## 前提

Groth16 における zkey は、以下の2つの段階を経ることにより、trusted setup の安全性を確保する。

1. **Contribution**
   複数の参加者が zkey に対して秘密のエントロピーを提供する。各参加者は、自身が提供したエントロピーを破棄する必要がある。少なくとも1人の参加者が自身のエントロピーを破棄していれば、他の参加者のエントロピーが漏洩した場合でも trusted setup の安全性は維持される。

2. **Beacon**
   Contribution の完了時点では予測できない公開ランダム値を zkey に対して追加のエントロピーとして適用する。これにより、Contribution に使用された秘密情報が漏洩していたとしても、Contribution の時点で最終的な setup の秘密情報を事前に知ることができないようにする。

## 本書の目的

本書執筆時点では Contribution が完了しており、Beacon は未実施である。

Beacon に使用する値が Contribution の時点で予測不可能であったことを第三者が検証できるようにするため、本書執筆時点ではまだ生成されていない Ethereum Mainnet の Block Height をあらかじめ宣言し、そのブロックの Block Hash を Beacon 値として採用する。

Block Height の宣言は、対象ブロックの生成および Block Hash の確定より前に本書を GitHub 上で公開することによって行う。

## 宣言

* 本書公開時点の Ethereum Mainnet Block Height: **25,960,000 未満**
* Beacon に使用する Block Height: **25,980,000**
* Beacon hash iterations: 2^15

対象ブロックが生成された後、その Block Hash を Beacon 値として使用し、最終的な zkey を生成する。
このBeacon値の適用範囲は以下のとおりである。
* out/deposit_1.zkey
* out/transfer_1.zkey
* out/withdraw_1.zkey

対象ブロックの Block Height および Block Hash、Beacon の実行結果、生成された最終 zkey の検証結果は、Beacon 実施後に本書へ追記する。
