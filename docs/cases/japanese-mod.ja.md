---
layout: page
title: ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む
permalink: /docs/cases/japanese-mod.ja/
---

[日本語ガイドへ戻る](../guide.ja.md) · [繁體中文](../guide.zht.md) · [简体中文](japanese-mod.zhs.md) · [한국어](japanese-mod.ko.md)

## 結論

日本語化Mod v2.4の各種ファイルはゲームディレクトリへ正しく配置されていたものの、プラグインの読み込み処理はChainloaderの初期化前で停止していました。最終的に正常動作に至った構成は以下の通りです。

- `Mortal.exe`に限定した`winhttp = native,builtin`のDLL override設定
- Unity `2020.3.49f1`とバージョンが完全一致するcorlibs
- `BepInEx/unstripped_corlib`を最優先で検索するDoorstop設定
- BepInExのWine初期化修正（PR #1254）を含んだx86 Mono版`6.0.0-be.785`
- BepInEx既定のエントリポイント（`Application::.cctor`）
- ゲーム内言語設定：簡体字中国語

修復後、Chainloaderが5個のプラグインを正常に読み込み、日本語テキスト72,977行が注入（インジェクション）されました。これまで動作していなかったDiceMasterも、同一のDoorstop / corlibs / BepInEx Wine修復手順（DLL override、完全なUnity corlibs、修正版BepInEx core）を経由することで正常にロード・動作するようになります。

## 検証条件

| 項目 | 条件 |
| --- | --- |
| ゲーム | AppID `1859910`、Build ID `20337760` |
| Unity | `2020.3.49f1` |
| プロセス | `Mortal.exe`、PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [日本語化Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 旧BepInEx | `6.0.0-be.692` |
| 動作版 | `6.0.0-be.785` x86 Mono |
| 検証日 | 2026-08-29 |

## 1. アーカイブの安全性確認

ZIPの完全性、絶対パス、`..`によるパストラバーサル、外側ディレクトリ構成、ネイティブDLLのx86互換性、および既存ファイルとの競合を確認しました。初回のダウンロード時、複数の異なるレジューム方式が混在したことでセントラルディレクトリ（Central Directory）が破損していました。単一クライアントで再取得した完全なZIPアーカイブのみを使用しました。

上書き対象となる既存ファイルをタイムスタンプ付きディレクトリへバックアップし、マージ後にハッシュ値を再検証しました。既存のDiceMaster DLLおよび設定ファイルのハッシュ値が保持されていることを確認しました。

## 2. Doorstopをロードする

`winecfg`のライブラリ設定にて、`Mortal.exe`に対するアプリケーション固有のDLL overrideを追加しました。

```text
winhttp = native,builtin
```

これにより、ローカルの`winhttp.dll`とPreloaderがプロセスに正常にロードされるようになりました。しかし、処理は依然としてChainloaderの初期化前で停止しており、マネージドエントリポイント側に次の障害要因があることが判明しました。

## 3. 完全なUnity corlibsを使用する

```text
ゲーム同梱 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 完全版        4,065,792 bytes
```

正規の手順で入手した同一Unityバージョンの完全なcorlibsを`BepInEx/unstripped_corlib/`へ配置し、`doorstop_config.ini`を設定しました。

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

詳細ログにてPreloaderの呼び出しと`Done`の出力を確認しました。corlibsはUnityのバージョンを厳密に一致させ、Unityのライセンス条項を遵守して取得・使用してください。

## 4. BepInExのWine初期化エラーを修復する

Preloaderの実行後、以下の例外が発生しました。

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

これはBepInExのWine/Proton環境における初期化時の既知の問題です。

- [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)
- [修正PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)

既存の`BepInEx/core`を完全にバックアップした上で、PR #1254の修正を含むx86 Monoビルド`6.0.0-be.785`の一式へと置き換えました。エントリポイントは既定の`Application::.cctor`に戻しました。

## 5. 最終確認

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

読み込まれたプラグイン一覧：

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

DiceMasterおよび日本語化Modプラグイン群（計5個）がChainloaderによって正常に読み込まれ、日本語テキスト72,977行の注入（インジェクション）が成功し、新たなError/Fatalログが発生していないことを確認しました。DiceMasterを単体で使用する場合でも、阻害要因（Doorstop未ロード、corlibsストリップ、BepInExのWine初期化例外）は同一であるため、まったく同じDoorstop / corlibs / BepInEx Wine修復手順によって正常に動作します。ゲーム内言語は「簡体字中国語」を選択し、ゲーム中に`F5`キーで名前のルビ表示、`F7`キーで表示モードの切り替えが可能です。

## 6. ロールバック境界

Mod導入前、corlibs設定前、`be.785`更新前の3段階のバックアップを保持します。復元作業を行う際は、必ずゲーム、Windows版Steam、および該当ラッパーのwineserverを終了した状態で、同一レイヤー一式を復元してください。異なるBepInExビルドのcore DLLを混在させてはなりません。
