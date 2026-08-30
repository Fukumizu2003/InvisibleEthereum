# InvisibleEthereum

プライバシー保護されたEthereum送金プロトコル。zk-SNARKs（Groth16）を使用して、送信者・受信者・金額・銘柄を隠蔽した匿名送金を実現する。

## 概要

InvisibleEthereumは、EVMチェーン上でのネイティブトークン（ETH）およびERC20トークンの匿名送金を可能にするスマートコントラクトシステムです。ゼロ知識証明を用いて、取引の詳細を秘匿しながら正しい取引であることを証明します。

## 機能

| 機能 | 説明 |
|------|------|
| **Deposit** | トークンをコントラクトに預け入れる（受信者を秘匿） |
| **Transfer** | コントラクト内で匿名でトークンを移動する（全情報を秘匿） |
| **Withdraw** | コントラクトからトークンを引き出す（送信者を秘匿） |

## 技術スタック

- **ブロックチェーン**: Ethereum (EVM)
- **スマートコントラクト**: Solidity ^0.8.20
- **ゼロ知識証明**: Groth16 (BN254)
- **zk-SNARK回路**: Circom 2.0.0
- **ハッシュ関数**: Poseidon
- **開発フレームワーク**: Foundry

## プロジェクト構成

```
.
├── src/                          # スマートコントラクト
│   ├── InvisibleEthereum.sol     # メインコントラクト
│   ├── DepositVerifier.sol       # Deposit用証明検証
│   ├── TransferVerifier.sol      # Transfer用証明検証
│   ├── TransferAllVerifier.sol   # TransferAll用証明検証
│   ├── WithdrawVerifier.sol      # Withdraw用証明検証
│   └── WithdrawAllVerifier.sol   # WithdrawAll用証明検証
├── zk_snark/                     # zk-SNARK回路
│   ├── common.circom             # 共通テンプレート
│   ├── deposit.circom            # Deposit回路
│   ├── transfer.circom           # Transfer回路
│   ├── transferAll.circom        # TransferAll回路
│   ├── withdraw.circom           # Withdraw回路
│   └── withdrawAll.circom        # WithdrawAll回路
├── docs/                         # ドキュメント
├── lib/                          # 外部ライブラリ
└── foundry.toml                  # Foundry設定
```

## 主要コンポーネント

### Commitment
取引内容から算出される逆算不可能な値。
```
Poseidon(銘柄, 送金額, 所有者(レシーバ), tag)
```

### Nullifier
Commitmentの消費済みを示す値。二重消費を防止する。
```
Poseidon(Commitment, NullifyKey)
```

### シールドアドレス
コントラクト内で使用する独自フォーマットのアドレス。
```
レシーバ 32バイト || 閲覧公開鍵 32バイト
```

### 暗号化取引
AES-GCMで暗号化された取引データ。送信者・受信者ともに復号可能。

## 手数料

- 基本手数料: 0.00005 ETH
- 追加手数料: 取引金額の 0.1%

## 開発

### 必要条件
- [Foundry](https://getfoundry.sh/)
- [Node.js](https://nodejs.org/)

### ビルド
```bash
forge build
```

### テスト
```bash
forge test
```

## ライセンス

MIT