# Mineclonia Unicode Sign Support (Fork)

このリポジトリは、Mineclonia の看板（mcl_signs）を Unicode（特に日本語）対応にするための個人フォークです。  
Luanti 側で追加した Unicode グリフ API を利用し、UTF-8 の日本語テキストを看板に表示できるようにすることを目的としています。

---

## 🔧 このフォークで行っている主な変更

- 看板描画処理（mcl_signs）を Unicode 対応に改造  
- Luanti Unicode API を利用してテクスチャを生成  
- 日本語テキストを看板に表示するためのテストコードを追加予定

---

## 📝 このフォークが必要とする環境

このフォークは **[Unicode 対応版 Luanti](https://github.com/testersakage/luanti-jtest)** を前提としています。

通常の Luanti では動作しません。

[font2unimg](https://github.com/testersakage/font2unimg)でTrueTypeフォントから生成されたatlas画像 

mineclonia/mods/ITEM/mcl_signs/textures/ に配置します。

---

## 🧪 動作確認方法

1. Unicode 対応版 Luanti をビルド  
2. この Mineclonia フォークを任意のフォルダに clone  
3. Luanti を以下のように起動：

./bin/luanti --gameid mineclonia --gamepath ~/mineclonia

4. 看板を設置して日本語を入力すると、Unicode API を通じて表示されます

---

## 📘 本家 README

このプロジェクトは Mineclonia のフォークです。  
本家の README は以下に保存しています：

👉 **[README.upstream.md](README.upstream.md)**

---

## 📄 ライセンス

Mineclonia のライセンス（LGPL / MIT / CC BY-SA など）はそのまま継承しています。

---

## 📝 補足

- コード生成に Copilot を利用しています。
