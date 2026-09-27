# AutoTranslator

macOS のメニューバー常駐アプリ。選択した英文をオンデバイス翻訳で日本語に変換し、カーソル付近にポップアップ表示します。

## 対応アプリ

- Safari（Web ページ）
- Preview（PDF ファイル）
- Amazon Kindle

## 動作環境

- macOS 15 以上（Apple の Translation フレームワークを使用）
- Swift 6 / Xcode 26 以上

## ビルド・実行

```sh
make app      # ビルドして AutoTranslator.app を生成
make run      # 生成して起動
make install  # /Applications にインストール（任意）
make clean
```

## 使い方

1. 初回起動時、システム設定 > プライバシーとセキュリティ > アクセシビリティ で **AutoTranslator** を許可します。
2. 対応アプリで英文を選択すると、カーソル付近に翻訳ポップアップが表示されます。
3. メニューバーのアイコンから、有効/無効の切り替えと翻訳元言語の選択ができます。

## 仕組み

- Accessibility API で選択テキストを取得（`AXSelectedText`、未対応アプリでは選択範囲の文字列にフォールバック）
- Translation フレームワークで端末上翻訳（英 → 日）
- 署名は `security find-identity` が見つけた証明書を自動使用（無ければ ad-hoc）

## 注意

- 対象アプリは `Sources/AutoTranslator/AllowedApps.swift` で定義しています。
- アクセシビリティ権限はコード署名に紐づきます。ad-hoc 署名の場合、再ビルドのたびに再許可が必要です。
