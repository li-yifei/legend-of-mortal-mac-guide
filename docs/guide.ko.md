# Apple Silicon Mac에서 《활협전》 실행하기: 설치·글꼴·Mod 복구

[Home](../README.md) · [繁體中文](guide.zht.md) · [简体中文](guide.zhs.md) · [日本語](guide.ja.md)

이 문서는 2026년 8월 실제 장비에서 검증한 구성을 정리한 가이드입니다. 직접 구매한 《활협전 / Legend of Mortal》을 Sikarugir, Wine, Windows용 Steam으로 Apple Silicon Mac에서 실행하고 글꼴 및 BepInEx Mod 문제를 복구하는 과정을 다룹니다.

## 검증 환경

| 항목 | 검증값 |
| --- | --- |
| 게임 | Steam AppID `1859910`, Build ID `20337760`, `release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 실행 파일 | `Mortal.exe`, PE32 / x86 |
| Wrapper | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| Renderer | 32-bit DXMT, D3D11 → Metal |
| Mod 프레임워크 | BepInEx `6.0.0-be.785` x86 Mono |

Steam, 게임, Wine, BepInEx, macOS 업데이트에 따라 결과가 달라질 수 있습니다. 버전, 로그, 타임스탬프가 포함된 백업을 함께 기록하십시오.

## 1. Windows용 Steam 전용 Wrapper 만들기

준비물:

- Apple Silicon Mac 및 macOS 14 이상;
- Rosetta 2;
- [Sikarugir 공식 GitHub](https://github.com/Sikarugir-App/Sikarugir);
- Steam에서 구매한 [《활협전》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/);
- Wrapper, Steam, 게임, 백업을 저장할 공간.

Sikarugir Creator로 독립 Wrapper(예: `SteamWin.app`)를 만듭니다. 전용 prefix에서 다음 순서로 구성합니다.

1. Wine prefix를 초기화하고 `Program Files`와 `Program Files (x86)`를 확인합니다;
2. Winetricks에서 `cjkfonts`를 설치합니다;
3. `hidewineexports=enable`을 적용합니다;
4. Windows용 Steam을 설치합니다;
5. 실행 대상을 `C:\Program Files (x86)\Steam\steam.exe`로 설정합니다;
6. Steam에 로그인하고 AppID `1859910`을 설치합니다.

게임 파일의 실제 아키텍처를 확인합니다.

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

검증된 Build는 `PE32 executable ... Intel 80386`으로 표시됩니다. Renderer 선택은 `Mortal.exe`의 x86 아키텍처를 기준으로 합니다.

## 2. D3D11 초기화 실패 복구

대표 로그:

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

검증된 Build에서 Unity OpenGL 경로는 해당 graphics device를 포함하지 않았고 WineD3D는 D3D feature level 협상에 실패했습니다. D3DMetal은 주로 64-bit D3D11/12를 대상으로 합니다. PE32 `Mortal.exe`에는 32-bit D3D10/11을 제공하는 DXMT를 사용했습니다.

Wrapper의 DXMT 토글과 함께 런타임 증거를 확인합니다.

- `WINEDEBUG=+loaddll`에서 `d3d11.dll`, `dxgi.dll`, `winemetal.dll`의 실제 경로 확인;
- 활성 Engine DLL과 대상 DXMT 파일의 SHA-256 비교;
- Unity `Player.log`에서 D3D11 level 11.1과 Apple GPU 확인.

검증 환경에서는 Engine의 WineD3D가 우선 로드되었습니다. 기존 32-bit 모듈을 백업한 뒤 DXMT의 `d3d10core.dll`, `d3d11.dll`, `dxgi.dll`, `winemetal.dll`을 실제 `i386-windows` 검색 경로에 배치하고 대응하는 `winemetal.so`를 Unix module 경로에 배치했습니다. 실제 경로는 로그로 확인하고 교체 전후 SHA-256을 기록합니다.

성공한 Unity 로그:

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
Begin MonoManager ReloadAssembly
```

일상 실행은 `steam.exe -applaunch 1859910`을 사용합니다.

## 3. Retina와 해상도

Wine Retina Mode 레지스트리 값:

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 렌더링과 Unity UI 스케일링은 별도 동작입니다. 높은 해상도는 선명한 화면과 작은 UI를 제공하고 낮은 해상도는 큰 UI와 확대 흐림을 제공합니다.

런처의 강제 해상도 인자를 제거하고 게임이 창 해상도를 저장하도록 구성하는 방법을 권장합니다. 검증 환경에서는 `1920×1200`을 사용했습니다.

## 4. 상점 가격과 합계가 사라지는 문제

중국어, 일반 숫자, 화폐 아이콘은 표시되고 상점 가격과 합계만 빈칸이 되는 증상입니다.

Unity 리소스의 `MoneyValue`와 `MoneyText`는 내장 `SourceHanSerifTC-Bold`를 사용하며 기본값 `50`과 숫자 글리프도 존재했습니다. Wine prefix에는 `sourcehansans.ttc`와 `unifont.ttf` 두 파일만 존재해 글꼴 집합과 매핑을 보완했습니다.

Windows용 Steam을 종료하고 `drive_c/windows/Fonts`, `system.reg`, `user.reg`, `userdef.reg`를 백업합니다. Winetricks에서 다음을 실행합니다.

```text
fonts → allfonts
```

설치 후 글꼴은 2개에서 121개, 약 284MB로 증가했고 Arial, Tahoma, Calibri, Meiryo, WenQuanYi 등이 등록되었습니다. wineserver와 게임을 다시 시작한 뒤 금액 표시가 복구되었습니다.

글꼴 재배포에는 각 라이선스가 적용됩니다. 이 저장소는 글꼴 파일을 포함하지 않습니다.

## 5. Doorstop/BepInEx Mod 복구

전체 조사 및 복구 과정: [사례: Wine 10 / x86 《활협전》에서 일본어 Mod 로드 복구](cases/japanese-mod.ko.md).

### Doorstop 로드

`winecfg → Libraries`에서 게임 전용 설정을 추가합니다.

```text
winhttp = native,builtin
```

`Mortal.exe`에만 적용되는 DLL override를 권장합니다. 실행 중인 프로세스에서 로컬 `winhttp.dll`과 BepInEx Preloader를 확인합니다.

### Unity corlibs

게임에 포함된 `mscorlib.dll`은 `3,906,048` bytes, Unity `2020.3.49f1`에 맞는 전체 버전은 `4,065,792` bytes였습니다. 합법적으로 확보한 동일 Unity 버전의 corlibs를 다음 위치에 둡니다.

```text
BepInEx/unstripped_corlib/
```

`doorstop_config.ini`:

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs는 Unity 버전을 일치시키고 Unity 라이선스를 따라 사용하십시오. 이 저장소는 corlibs를 포함하지 않습니다.

### BepInEx 6 Wine 수정

이전 Build에서는 `Cannot set the value of PlatformHelper.Current once it has been accessed.`가 발생했습니다. [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)과 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)가 해당 문제와 수정입니다. 검증 환경에서는 x86 Mono `6.0.0-be.785`를 사용했습니다. 교체 전에 `BepInEx/core` 전체를 백업합니다.

성공 로그:

```text
BepInEx 6.0.0-be.785
Process bitness: 32-bit (x86)
Chainloader initialized
```

DiceMaster와 일본어 Mod를 포함한 5개 플러그인의 로드를 확인했습니다.

## 6. 알려진 문제

### 창 전환 후 제목 표시줄 클릭으로 조작 복구

검증된 Build `20337760` 및 Sikarugir Wine `10.0` 환경에서 게임을 다른 macOS 앱으로 전환했다가 《활협전》으로 복귀했을 때, 화면은 정상 표시되지만 키보드·마우스·컨트롤러 입력이 게임 창에 즉시 인식되지 않는 현상이 발생할 수 있습니다.

복구 순서:

1. 《활협전》의 `Mortal` 창으로 다시 전환합니다.
2. 창 상단의 macOS 제목 표시줄(아래 그림의 빨간색 화살표가 가리키는 어두운 영역)을 한 번 클릭합니다.
3. 게임 화면으로 돌아가 조작을 계속합니다.

![Mortal 창 제목 표시줄을 클릭해 게임 입력 복구](assets/window-titlebar-focus-recovery.png)

Steam 전역 Overlay와 《활협전》 개별 Overlay를 끄면 발생 빈도를 낮출 수 있습니다. 제목 표시줄 클릭은 현재 검증된 즉시 복구 방법입니다. 근본 원인은 조사 중이며 Wine, Unity, macOS 사이의 창 포커스 전달과 관련된 동작으로 보입니다.

| 게임 버전 | 발생 조건 | 결과 | 증거 | 신뢰도 |
| --- | --- | --- | --- | --- |
| Build `20337760` / `release_1.0.5000.13` | 다른 macOS 앱에서 Wine 게임 창으로 복귀 | `Mortal` 제목 표시줄 클릭 후 게임 조작 복구 | 실제 환경 재현 및 스크린샷 | 높음 |

## 7. 운영 팁

- Steam Overlay를 전역 및 게임별 설정에서 끄면 앱 전환 후 입력 잠금 가능성을 줄일 수 있습니다.
- 플레이 중 `caffeinate`를 사용합니다. 절전, 잠금 해제, 디스플레이 연결 변경 후 게임, Windows용 Steam, wineserver 세션을 새로 시작합니다.
- 장시간 실행한 Steam이 `-applaunch`를 처리하지 않을 때 `gameprocess_log.txt`를 확인하고 해당 prefix의 Steam/Wine 세션을 갱신합니다.
- Steam 종료에는 Windows용 Steam 메뉴의 `Steam → Exit`를 사용합니다.

## 8. 읽기 전용 검사기

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

Wrapper, 실행 파일, manifest, 레지스트리, 글꼴 수, DXMT 해시, BepInEx 로그, 프로세스 상태를 읽습니다. 파일을 변경하거나 Wine·Steam·게임 세션을 시작·종료하지 않습니다.
