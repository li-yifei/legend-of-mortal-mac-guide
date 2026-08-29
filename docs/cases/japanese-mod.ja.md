---
layout: page
title: ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む
permalink: /docs/cases/japanese-mod.ja/
---

[日本語ガイドへ戻る](../guide.ja.md) · [繁體中文](../guide.zht.md) · [简体中文](japanese-mod.zhs.md) · [한국어](japanese-mod.ko.md)

## 結論

日本語化Mod v2.4の各ファイルはゲームディレクトリに正しく配置されていたものの、プラグインのロード処理はChainloaderの初期化前に停止していました。最終的に動作を確認した構成は以下の通りです。

- `Mortal.exe`を対象としたアプリケーション個別DLL override（`winhttp = native,builtin`）
- Unity `2020.3.49f1`とバージョンが完全に一致する未ストリップ版corlibs
- `BepInEx/unstripped_corlib`を最優先で探索するDoorstop設定
- BepInExのWine初期化修正（PR #1254）を取り込んだx86 Mono版`6.0.0-be.785`
- BepInExの既定マネージドエントリポイント（`Application::.cctor`）
- ゲーム内言語設定：「簡体字中国語」

修復後、Chainloaderが5個のプラグインを正常に読み込み、72,977行の日本語テキストが正常にインジェクションされました。これまで動作していなかったDiceMaster Modについても、同一のDoorstop / corlibs / BepInEx Wine修復手順（個別DLL override、未ストリップ版Unity corlibs、修正版BepInEx core）を適用することで正常にロード・動作することを確認しました。

## 検証条件

| 項目 | 条件 |
| --- | --- |
| ゲーム | Steam AppID `1859910`、Build ID `20337760` |
| Unity | `2020.3.49f1` |
| プロセス | `Mortal.exe`、PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [日本語化Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 旧BepInEx | `6.0.0-be.692` |
| 動作版 | `6.0.0-be.785` x86 Mono |
| 検証日 | 2026-08-29 |

## 1. アーカイブの安全性確認

導入前にZIPアーカイブの整合性、絶対パスや`..`によるパストラバーサル（Path Traversal）の有無、ディレクトリ構造、ネイティブDLLのx86（32ビット）互換性、および既存ファイルとの競合を確認しました。初回ダウンロード時にレジューム処理の不整合でセントラルディレクトリ（Central Directory）が破損していたため、単一ダウンローダーで再取得した完全なアーカイブを使用しています。

上書き対象となる既存ファイルをタイムスタンプ付きディレクトリに退避し、ファイル統合後にSHA-256ハッシュ値を再照合して、既存のDiceMaster DLLおよび設定ファイルの整合性が維持されていることを確認しました。

## 2. Doorstopをロードする

`winecfg`のライブラリ（Libraries）設定で、`Mortal.exe`に対するアプリケーション個別DLL overrideを追加しました。

```text
winhttp = native,builtin
```

これにより、ゲームディレクトリ内の`winhttp.dll`とPreloaderがプロセスにロードされるようになりました。ただし、この段階ではChainloaderの初期化前に停止しており、マネージドコードのエントリポイント側に次の障害要因が存在することが判明しました。

## 3. 完全なUnity corlibsを使用する

```text
ゲーム同梱 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 完全版        4,065,792 bytes
```

正規の手順で取得した、ゲームと同一バージョンの未ストリップ版Unity corlibsを`BepInEx/unstripped_corlib/`へ配置し、`doorstop_config.ini`を設定しました。

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

詳細ログにてPreloaderの呼び出しと`Done`の出力を確認しました。corlibsはUnityエンジンのバージョンと厳密に一致させる必要があり、Unityの利用規約を遵守して取得・利用してください。

## 4. BepInExのWine初期化エラーを修復する

Preloaderの実行後、以下の例外が発生しました。

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

これはWine/Proton環境におけるBepInExの初期化処理に起因する既知の問題です。

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

ChainloaderによってDiceMasterおよび日本語化Modプラグイン群（計5個）が正常に読み込まれ、日本語テキスト72,977行のインジェクションが成功したこと、および新たなError/Fatalログが発生していないことを確認しました。DiceMasterを単体で使用する場合でも、発生する障害要因（Doorstop未ロード、corlibsストリップによるPreloader停止、BepInExのプラットフォーム初期化例外）は同一であるため、まったく同じDoorstop / corlibs / BepInEx Wine修復手順によって正常に動作させることができます。ゲーム内言語は「簡体字中国語」を選択してください。ゲームプレイ中は`F5`キーで人名のルビ表示切り替え、`F7`キーで表示モードの切り替えが可能です。

## 6. ロールバック境界

Mod導入前、corlibs設定前、`be.785`更新前の3段階でバックアップを保持します。ロールバックを行う際は、必ずゲーム、Windows版Steam、および該当prefixのwineserverプロセスを終了させた上で、同一レイヤーのファイル群を一括復元してください。異なるBepInExビルドのcore DLLを混在させてはなりません。
