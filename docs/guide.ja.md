# Apple Silicon Macで『活俠傳』を動かす：インストール・フォント・Mod修復

[ホーム](../README.md) · [繁體中文](guide.zht.md) · [简体中文](guide.zhs.md) · [한국어](guide.ko.md)

本書は、2026年8月に実機検証を行い動作を確認した構成手順をまとめたものです。Sikarugir、Wine、およびWindows版Steamを経由して、自身で購入した正規版『活俠傳』（Legend of Mortal）をApple Silicon Mac上でプレイしたいユーザーを対象としています。

## 検証済み環境

| 項目 | バージョンまたはテスト結果 |
| --- | --- |
| ゲーム | Steam AppID `1859910`、Build ID `20337760`、`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 実行ファイル | `Mortal.exe`、PE32 / x86 |
| ラッパー（Wrapper） | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| グラフィックバックエンド | 32ビット DXMT、D3D11 → Metal |
| Modフレームワーク | BepInEx `6.0.0-be.785` x86 Mono |

Wine、Steam、macOS、およびゲーム本体のアップデートはいずれも互換性や動作結果に影響を与える可能性があります。設定を変更・調整する際は、必ずバージョン番号を記録し、ログを保存し、タイムスタンプ付きのバックアップを作成してください。

## 1. 独立したWindows版Steamラッパーを作成する

事前に以下のものを用意します。

- Apple Silicon Mac（macOS 14以降）
- Rosetta 2
- [Sikarugir公式プロジェクト](https://github.com/Sikarugir-App/Sikarugir)
- 自身のSteamアカウントで購入済みの[『活俠傳』](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)
- 十分な空きディスク容量（ラッパー、Steam、ゲーム本体、および各段階のバックアップ用）

Sikarugir Creatorを使用して独立したラッパー（例：`SteamWin.app`）を作成します。ラッパー専用のprefix内で以下の手順を順番に完了させます。

1. Wine prefixを初期化し、`Program Files`と`Program Files (x86)`の両ディレクトリが正しく生成されていることを確認する。
2. Winetricks経由で`cjkfonts`をインストールする。
3. レジストリ設定`hidewineexports=enable`を適用する。
4. Windows版Steamをインストールする。
5. 起動ターゲットを`C:\Program Files (x86)\Steam\steam.exe`に設定する。
6. Steamにログインし、AppID `1859910`をダウンロード・インストールする。

macOSネイティブ版SteamとWindows版Steamは共存可能です。ログインやネットワーク接続で問題が発生した場合は、同一アカウントでのセッション競合や強制ログアウトを防ぐため、もう一方のクライアントを完全に終了してください。

### 事前にゲームのアーキテクチャを確認する

Steamストアページのシステム要件表示は、実際のバイナリアーキテクチャの確認の代わりにはなりません。以下のコマンドを実行します。

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

検証済みビルド（Build）での確認結果：

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

Windows版Steamではx86ブートストラップ（bootstrap）が一般的です。グラフィックバックエンドは、`Mortal.exe`自体のPE32（32ビット）アーキテクチャに基づいて選択する必要があります。

## 2. D3D11グラフィック初期化エラーを修復する

典型的な症状：Steam上で一瞬「実行中」と表示された直後にゲームが終了する。エラーダイアログや`Player.log`に以下のログが記録される。

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

検証済みビルド（Build）において各グラフィックレンダリングパスをテストした結果は以下の通りです。

- Unity OpenGL：ゲームビルドに対象となるグラフィックデバイス（graphics device）のサポートが含まれていない。
- WineD3D + MoltenVK：Apple GPUは認識されるものの、D3D feature level（機能レベル）のネゴシエーションに失敗する。
- D3DMetal：主に64ビットのD3D11/12を対象としている。
- DXMT：完全な32ビットD3D10/11モジュールを提供しており、今回のPE32ゲームに適合する。

### DXMTスイッチが実際に有効化されているかを判断する

ラッパーのUI上でDXMTを有効にしても、設定が書き込まれたことしか意味しません。実行時に以下の証拠を検証する必要があります。

- `WINEDEBUG=+loaddll`のログで、対象の`d3d11.dll`、`dxgi.dll`、`winemetal.dll`が実際にロードされているか。
- 現在有効になっているEngine DLLのSHA-256ハッシュ値が、対象のDXMTバージョンと一致しているか。
- `Player.log`にDirect3D 11 level 11.1およびApple GPUが正しく記録されているか。

今回の検証環境では、初起動時にDXMTを有効にした際、ゲームは実際にはEngineディレクトリ内のWineD3Dを読み込んでいました。最終的にはロールバック可能なEngineレベルの修復を実施しました。まず元の32ビットWineD3Dモジュールをバックアップし、対応するバージョンのDXMT `d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll`を実際に有効な`i386-windows`ディレクトリに配置し、対応する`winemetal.so`を有効なUnix moduleディレクトリに配置しました。

Engineによってディレクトリ構成が異なる場合があります。ロードログから実際の検索パスを解析してから置換を行い、各ファイルについて置換前後のSHA-256ハッシュ値を必ず記録してください。

DLLロード成功ログの例：

```text
Loaded C:\windows\system32\winemetal.dll
Loaded C:\windows\system32\DXGI.DLL
Loaded C:\windows\system32\d3d11.dll
```

Unity初期化成功ログの例：

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
Begin MonoManager ReloadAssembly
```

日常的な起動には、Steam AppIDのコマンドライン引数を使用することを推奨します。

```text
steam.exe -applaunch 1859910
```

## 3. Retinaと解像度

Wine Retinaモードに対応するレジストリパス：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

RetinaレンダリングとUnity UIスケーリングは互いに独立した仕組みです。『活俠傳』のUnity UIロジックは基本的にWindowsのDPI設定を無視します。高解像度では精細で美しい描画が得られますがUIは比較的小さくなり、低解像度ではUIが大きく表示されますが引き伸ばしによるぼやけが目立ちます。

ランチャー側で解像度を強制指定せず、ゲーム側にユーザーが選択したウィンドウ解像度を記憶させる構成を推奨します。検証環境では最終的に`1920×1200`を採用し、デスクトップショートカットの起動オプションから強制的な`-screen-width`および`-screen-height`引数を削除しました。

## 4. ショップの価格および合計金額が空白になる問題の修復

典型的な症状：ゲーム内の中国語テキスト、通常の数値、銅銭アイコンは正常に表示されるものの、ショップ画面のアイテム単価と合計金額だけが空白で表示されない。

リソース確認の結果、`MoneyValue`および`MoneyText` UIコンポーネントには内蔵フォント`SourceHanSerifTC-Bold`が紐付けられており、デフォルトテキストに`50`が含まれ、フォントアトラスにも`0–9`の数字文字が揃っていました。問題の根本原因は、Wine prefix内のフォントセットおよびシステムフォントのマッピングが不完全であることにありました。

初期作成時のprefixに含まれるフォントファイルは以下のみです。

```text
sourcehansans.ttc
unifont.ttf
```

事前に`cjkfonts`をインストールしていても、カバー範囲は限定的です。実際の修復策として、Winetricksから以下をインストールします。

```text
fonts → allfonts
```

作業を行う前にWindows版Steamを完全に終了し、以下のファイルをバックアップしてください。

- `drive_c/windows/Fonts`
- `system.reg`
- `user.reg`
- `userdef.reg`

インストール完了後、フォントディレクトリ内のファイル数は2個から121個（約284 MB）に増加し、Arial、Tahoma、Calibri、Meiryo、WenQuanYiなどのフォント用レジストリエントリがすべて正常に書き込まれました。wineserverプロセスを終了してゲームを再起動すると、ショップの金額表示が正常に復旧します。

各種フォントにはそれぞれのソフトウェアライセンスが適用されます。フォントは必ずWinetricks経由でオリジナルの提供元からダウンロード・インストールし、公開リポジトリや配布用ラッパーにはフォントバイナリを含めない（ゼロ配布を維持する）ようにしてください。

## 5. DoorstopとBepInEx Modの読み込みを修復する

詳細な調査・修復事例は、日本語ケーススタディ：[ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む](cases/japanese-mod.ja.md)を参照してください。

### Mod導入前にファイル単位のバックアップを行う

各ZIPアーカイブに対して以下の確認・手順を実行します。

1. アーカイブ内のパスを確認し、絶対パスや`..`によるパストラバーサル（Path Traversal）のセキュリティリスクを排除する。
2. `winhttp.dll`およびプラグインDLLがx86（32ビット）アーキテクチャであることを検証する。
3. 上書き対象となる既存ファイルのリストを作成する。
4. すべての同名ファイルをタイムスタンプ付きのバックアップディレクトリに退避・コピーする。
5. 展開・統合後に各ファイルのSHA-256ハッシュ値を照合する。
6. ゲームを起動し、ログファイルの更新日時が今回の実行時刻と一致していることを確認する。

Modパッケージには過去の`LogOutput.log`が残留している場合があります。フレームワークの動作状況は、ログの更新日時、現在プロセスがロードしているモジュール、およびChainloaderの出力ログを総合して判断してください。

### ステップ1：Doorstopをロードする

`winecfg → Libraries`を開き、ゲームメインプログラム向けに設定を追加します。

```text
winhttp = native,builtin
```

`Mortal.exe`のみに適用されるアプリケーションレベルのDLL overrideを優先して使用します。ゲーム実行時、プロセス内にローカルの`winhttp.dll`とBepInEx Preloaderがロードされていることを確認します。

### ステップ2：Unityバージョンに一致する完全なcorlibsを配置する

比較検証の結果、検証済みゲームに同梱されている`Mortal_Data/Managed/mscorlib.dll`のサイズは`3,906,048`バイトであるのに対し、Unity `2020.3.49f1`に適合する完全な未ストリップ版（unstripped）のサイズは`4,065,792`バイトでした。

正規の手順で入手した、バージョンが正確に一致する完全なcorlibsを以下に配置します。

```text
BepInEx/unstripped_corlib/
```

`doorstop_config.ini`を編集します。

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibsはUnityエンジンのバージョンと完全に一致している必要があり、かつUnityのソフトウェア利用許諾規約に従う必要があります。本リポジトリおよびMod配布パッケージにはcorlibsバイナリを含めません（ゼロ配布を維持します）。

### ステップ3：Wine修正パッチを含むBepInEx 6を使用する

旧バージョンのBepInEx 6は、Wine 32ビット環境下で以下の例外を発生させることがあります。

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

この問題は[BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)に報告され、[PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)で修正されています。検証環境では、この修正パッチを含むx86 Monoビルド`6.0.0-be.785`を採用しました。差し替える前に`BepInEx/core`を完全にバックアップしてください。

ロード成功時のログ例：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

その後、各プラグインが順番にロードされるログが記録されます。検証環境では、DiceMasterおよび日本語化Modの計5個のプラグインがすべてChainloaderによって正常にロードされました。

## 6. 日常の運用・メンテナンス

- Steamの全体設定および『活俠傳』個別設定の「ゲーム内オーバーレイ（Overlay）」を無効化することを推奨します。アプリのウィンドウ切り替え後にキー入力がロックされる確率を低減できます。
- プレイ中は`caffeinate`コマンドを併用してMacのシステムスリープを抑止することを推奨します。MacBookのディスプレイを閉じてスリープさせたり、画面ロック、外部ディスプレイの抜き差し（ホットプラグ）が発生した場合は、ゲーム、Windows版Steam、およびwineserverセッションを完全に再起動することをお勧めします。
- Windows版Steamを長時間バックグラウンドで待機させた場合、`-applaunch`起動コマンドに応答しなくなることがあります。Steamの`gameprocess_log.txt`に新たなログが追加されない場合は、該当prefixのSteamおよびWineセッションを再起動してください。
- ゲームおよびSteamを終了する際は、Windows版Steamメニューの`Steam → Exit`から正常に終了してください。macOSのDockに表示されるWineアイコンは単なるウィンドウプロキシに過ぎません。

## 7. リポジトリ同梱の読み取り専用診断スクリプトを使用する

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

このスクリプトは、ラッパーの設定、ゲームアーキテクチャ、Steamマニフェストファイル（manifest）、レジストリ設定、フォント数、DXMTモジュールのハッシュ値、BepInExログ、および現在実行中のプロセスを読み取り専用で検査します。Wine、Steam、ゲームプロセスを勝手に起動・終了することはなく、いかなるファイルも変更しません。

## 参考リンク

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine修正パッチ](https://github.com/BepInEx/BepInEx/pull/1254)
- [『活俠傳』日本語化Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
