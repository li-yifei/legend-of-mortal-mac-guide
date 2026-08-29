# Apple Silicon Macで『活俠傳』を動かす：導入・フォント・Mod修復

[Home](../README.md) · [简体中文](guide.zh-CN.md) · [한국어](guide.ko.md)

このガイドは、2026年8月に実機で確認した構成をまとめたものです。自分で購入した『活俠傳 / Legend of Mortal』をSikarugir、Wine、Windows版SteamでApple Silicon Mac上に動かす手順と、フォント・BepInEx Modの修復方法を扱います。

## 検証済み環境

| 項目 | 検証値 |
| --- | --- |
| ゲーム | Steam AppID `1859910`、Build ID `20337760`、`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 実行ファイル | `Mortal.exe`、PE32 / x86 |
| Wrapper | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| Renderer | 32-bit DXMT、D3D11 → Metal |
| Mod基盤 | BepInEx `6.0.0-be.785` x86 Mono |

Steam、ゲーム、Wine、BepInEx、macOSの更新によって結果は変化します。作業時にはバージョン、ログ、タイムスタンプ付きバックアップを残してください。

## 1. Windows版Steam専用Wrapperを作る

必要なもの：

- Apple Silicon Mac、macOS 14以降；
- Rosetta 2；
- [Sikarugir公式GitHub](https://github.com/Sikarugir-App/Sikarugir)；
- Steamで購入した[『活俠傳』](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)；
- Wrapper、Steam、ゲーム、バックアップ用の空き容量。

Sikarugir Creatorで独立したWrapper（例：`SteamWin.app`）を作成します。Wrapper専用prefixで次の順に設定します。

1. Wine prefixを初期化し、`Program Files`と`Program Files (x86)`を確認する；
2. Winetricksで`cjkfonts`を導入する；
3. `hidewineexports=enable`を適用する；
4. Windows版Steamを導入する；
5. 起動先を`C:\Program Files (x86)\Steam\steam.exe`にする；
6. Steamへログインし、AppID `1859910`をインストールする。

ゲーム本体のアーキテクチャを確認します。

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

検証済みBuildでは`PE32 executable ... Intel 80386`と表示されます。Renderer選択は`Mortal.exe`自身のx86判定を基準にします。

## 2. D3D11初期化エラーを修復する

代表的なログ：

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

このBuildではUnity OpenGLが対象graphics deviceを含まず、WineD3DはD3D feature levelの確立に失敗しました。D3DMetalは主に64-bit D3D11/12を対象とします。PE32版`Mortal.exe`には32-bit D3D10/11を提供するDXMTを使用しました。

WrapperのDXMTスイッチに加えて、次の実行時証拠を確認します。

- `WINEDEBUG=+loaddll`で`d3d11.dll`、`dxgi.dll`、`winemetal.dll`の実ロード元を確認する；
- 稼働中EngineのDLLと対象DXMTファイルのSHA-256を比較する；
- Unity `Player.log`でD3D11 level 11.1とApple GPUを確認する。

検証環境ではEngine側のWineD3Dが優先されていました。元の32-bitモジュールを退避し、DXMTの`d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll`を実際の`i386-windows`検索先へ、対応する`winemetal.so`をUnix module検索先へ配置しました。Engineごとに実パスをログから確認し、置換前後のSHA-256を記録します。

成功時のUnityログ：

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
Begin MonoManager ReloadAssembly
```

通常起動は`steam.exe -applaunch 1859910`を使用します。

## 3. Retinaと解像度

Wine Retina Modeは次のレジストリ値です。

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina描画とUnity UIスケーリングは別々に動作します。高解像度では描画が鮮明になりUIが小さくなります。低解像度ではUIが大きくなり、拡大によるぼけが増えます。

ランチャーから固定解像度オプションを外し、ゲーム側にウィンドウ解像度を保存させる構成を推奨します。検証環境では`1920×1200`を使用しました。

## 4. ショップの価格・合計金額が消える問題

中国語、一般の数字、通貨アイコンは表示され、ショップ価格と合計だけが空欄になる症状です。

Unityリソース上の`MoneyValue`と`MoneyText`は内蔵`SourceHanSerifTC-Bold`を参照し、既定値`50`と数字グリフも存在しました。Wine prefix側には`sourcehansans.ttc`と`unifont.ttf`の2ファイルしかなく、フォント集合とマッピングを補いました。

Windows版Steamを終了し、`drive_c/windows/Fonts`、`system.reg`、`user.reg`、`userdef.reg`をバックアップします。その後Winetricksで次を実行します。

```text
fonts → allfonts
```

導入後はフォントが2ファイルから121ファイル、約284MBへ増え、Arial、Tahoma、Calibri、Meiryo、WenQuanYiなどが登録されました。wineserverを終了してゲームを再起動すると、金額表示が復旧しました。

フォントの再配布は各ライセンスに従ってください。このリポジトリはフォントを収録しません。

## 5. Doorstop/BepInEx Modを修復する

実際の調査と修復の全記録：[ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む](cases/japanese-mod.ja.md)。

### Doorstop

`winecfg → Libraries`でゲーム用に設定します。

```text
winhttp = native,builtin
```

`Mortal.exe`限定のDLL overrideを推奨します。現在のプロセスにローカル`winhttp.dll`とBepInEx Preloaderが読み込まれることを確認します。

### Unity corlibs

ゲーム同梱`mscorlib.dll`は`3,906,048` bytes、Unity `2020.3.49f1`に対応する完全版は`4,065,792` bytesでした。正規に入手した同一Unity版のcorlibsを次へ配置します。

```text
BepInEx/unstripped_corlib/
```

`doorstop_config.ini`：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibsはUnityバージョンを一致させ、Unityのライセンス条件に従って使用してください。このリポジトリはcorlibsを収録しません。

### BepInEx 6 Wine修正

旧Buildでは`Cannot set the value of PlatformHelper.Current once it has been accessed.`が発生しました。[BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)と[PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)が対応する問題と修正です。検証環境ではx86 Mono版`6.0.0-be.785`を使用しました。更新前に`BepInEx/core`を丸ごとバックアップします。

成功時：

```text
BepInEx 6.0.0-be.785
Process bitness: 32-bit (x86)
Chainloader initialized
```

DiceMasterと日本語化Modを含む5プラグインの読み込みを確認しました。

## 6. 運用上の注意

- Steam Overlayを全体設定とゲーム個別設定の両方で無効にすると、アプリ切替後の入力ロックを抑えられます。
- プレイ中は`caffeinate`を使用します。スリープ、ロック解除、ディスプレイ接続変更後はゲーム、Windows版Steam、wineserverを終了して再起動します。
- 長時間稼働したSteamが`-applaunch`を受理しない場合、`gameprocess_log.txt`を確認してprefixのSteam/Wineセッションを更新します。
- Steamの終了にはWindows版Steamの`Steam → Exit`を使います。

## 7. 読み取り専用インスペクタ

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

Wrapper、実行ファイル、manifest、レジストリ、フォント数、DXMTハッシュ、BepInExログ、プロセス状態を読み取ります。ファイル変更や、Wine・Steam・ゲームセッションの起動と終了は行いません。
