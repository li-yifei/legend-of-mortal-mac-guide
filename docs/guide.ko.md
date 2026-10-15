---
layout: page
title: "Apple Silicon Mac에서 《활협전》 실행하기: 설치·글꼴·Mod 복구"
permalink: /docs/guide.ko/
redirect_from:
  - /docs/guide.ko.html
---

[홈](../README.md) · [简体中文](guide.zhs.md) · [繁體中文](guide.zht.md) · [日本語](guide.ja.md)

> **이 문서는 게임 1.06(Build `25953419`, 64비트)을 기준으로 합니다.** 2026년 10월 15일에 직접 사용하는 환경에서 검증했습니다.
> - 1.05에서 업데이트한 뒤 Mod가 한꺼번에 작동하지 않는 경우: [1.05에서 1.06으로 업그레이드](#upgrade)를 바로 보십시오.
> - 아직 1.05(Build `20337760`, 32비트)를 사용하는 경우: 문서 끝의 [1.05 이전 구성](#legacy)을 보십시오.
{: .callout}

이 문서는 Apple Silicon Mac에서 직접 구매한 정품 《활협전》을 플레이하려는 분을 위한 안내서입니다. Sikarugir, Wine, Windows용 Steam으로 게임을 설치하고, 그래픽 초기화 실패, 상점 문자 누락, Mod 로드 실패 같은 흔한 문제를 해결하는 방법을 다룹니다.

* 목차
{:toc}

## 검증된 환경

| 항목 | 검증된 구성 |
| --- | --- |
| 게임 | Steam AppID `1859910`, Build `25953419`, 1.06 |
| Unity | `2020.3.49f1` |
| 실행 파일 | `Mortal.exe`, `UnityPlayer.dll`, PE32+ / x64 |
| 래퍼 런타임 | Sikarugir Creator `1.0.2`, Template `1.0.22` |
| Wine | Sikarugir Wine `10.0 revision 8` |
| 그래픽 백엔드 | 템플릿에 포함된 DXMT `v0.80-244-g7c8dee1`, D3D11 → Metal |
| Mod 진입점 | Doorstop `4.4.0` Windows x64 (`winhttp.dll`) |
| Mod 프레임워크 | BepInEx `6.0.0-be.785` Unity.Mono 매니지드 코어 |
| 검증일 | 2026-10-15 |

이 환경은 1.05 시절에 만든 Wine prefix를 그대로 업그레이드한 것이며, 글꼴, 레지스트리, DLL override도 당시 설정을 이어받았습니다. Wine, Steam, macOS, 게임 자체의 업데이트에 따라 결과가 달라질 수 있습니다. 설정을 바꾸기 전에 버전 번호를 기록하고 타임스탬프가 붙은 백업을 만들어 두십시오.

## 증상별 빠른 해결 색인

해당 증상이 나타날 때만 그 항목을 수행하십시오. 게임이 정상적으로 실행된다면 추가 작업은 필요하지 않습니다.

| 증상 또는 목적 | 해당 항목 |
| --- | --- |
| 처음 설치 | [1. Windows용 Steam 래퍼 만들기](#install) |
| 1.06으로 업데이트한 뒤 Mod가 모두 작동하지 않음 | [1.05에서 1.06으로 업그레이드](#upgrade) |
| 실행 직후 종료 / D3D11 오류 | [2. D3D11 그래픽 초기화 실패 복구](#graphics) |
| 화면이 흐리거나 UI가 너무 작음 | [3. Retina와 해상도](#retina) |
| 상점의 단가와 합계가 비어 있음 | [4. 상점 가격 공백 복구](#fonts) |
| Mod가 적용되지 않거나 오류가 남 | [5. BepInEx Mod 설치와 복구](#mods) |
| 일본어 Mod를 설치하고 싶음 | [6. 일본어 Mod v2.5](#jpmod) |
| 창을 전환한 뒤 키보드·마우스가 반응하지 않음 | [7. 알려진 문제](#focus) |
| 장시간 방치, 절전 후 복귀 | [8. 일상 운영 팁](#daily) |
| 현재 환경 점검 | [9. 읽기 전용 점검 스크립트](#diagnostics) |

## 핵심 용어

| 용어 | 간단한 설명 |
| --- | --- |
| 래퍼(Wrapper) | macOS의 `.app` 번들로, Wine과 Windows 프로그램을 하나로 묶은 것입니다. |
| Wine / Wine prefix | Wine은 Windows 프로그램을 macOS에서 실행하게 해 줍니다. prefix는 래퍼 내부에 만들어지는 가상 Windows 환경(가상 C 드라이브와 레지스트리)입니다. |
| Winetricks | prefix에 Windows 런타임과 글꼴을 설치해 주는 보조 도구입니다. |
| DXMT | Direct3D 11 그래픽 명령을 Apple Metal로 번역하는 변환 레이어입니다. |
| BepInEx | Unity 게임에서 많이 쓰는 Mod 로딩 프레임워크입니다. |
| Doorstop | Mod의 진입점 도구입니다. `winhttp.dll`로 위장해 게임이 시작될 때 로드되고, BepInEx를 게임 안으로 불러옵니다. |
| 네이티브 DLL / 매니지드 DLL | 네이티브 DLL(예: `winhttp.dll`)은 게임과 같은 64비트여야 합니다. 매니지드 DLL(C#으로 만든 BepInEx와 Mod 플러그인)은 대부분 비트 수를 가리지 않습니다. |

<a id="install"></a>

## 1. Windows용 Steam 래퍼 만들기

준비물:

- Apple Silicon Mac, macOS 14 이상, Rosetta 2 설치;
- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir) (Creator와 Template은 최신 버전을 사용하십시오. 직접 검증한 버전은 Creator `1.0.2` / Template `1.0.22`입니다);
- 개인 Steam 계정으로 구매한 [《활협전》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/);
- 충분한 디스크 여유 공간(래퍼, Steam, 게임 본체에 약 12 GB, 백업 공간은 별도).

Sikarugir Creator로 독립 래퍼(예: `SteamWin.app`)를 만든 다음, 그 래퍼 전용 Wine prefix에서 다음 순서로 진행합니다.

1. prefix를 초기화하고 `Program Files`와 `Program Files (x86)`가 모두 있는지 확인합니다.
2. Winetricks로 `cjkfonts`를 설치합니다.
3. 레지스트리 설정 `hidewineexports=enable`을 적용합니다.
4. Windows용 Steam을 설치하고 실행 대상을 `C:\Program Files (x86)\Steam\steam.exe`로 지정합니다.
5. Steam에 로그인하고 AppID `1859910`을 다운로드합니다.

macOS용 Steam과 Windows용 Steam은 함께 둘 수 있습니다. 로그인이나 네트워크에 문제가 생기면 같은 계정의 세션이 서로 밀어내지 않도록 다른 쪽 클라이언트를 완전히 종료하십시오.

### 게임이 64비트인지 확인

macOS 터미널에서 실행합니다(`/path/to/LegendOfMortal`은 실제 게임 폴더로 바꾸십시오).

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

1.06의 결과:

```text
PE32+ executable (GUI) x86-64, for MS Windows
```

`PE32+` / `x86-64`는 64비트라는 뜻입니다. 이후의 모든 **네이티브** 구성 요소(`winhttp.dll`, DXMT 모듈)는 64비트 버전을 선택해야 합니다. `PE32` / `Intel 80386`이 표시된다면 아직 1.05이므로 [1.05 이전 구성](#legacy)을 보십시오.

<a id="upgrade"></a>

## 1.05에서 1.06으로 업그레이드

1.06에서 `Mortal.exe`와 `UnityPlayer.dll`이 32비트에서 64비트로 바뀌었습니다. 예전 가이드대로 설치한 Mod 진입점 `winhttp.dll`은 여전히 32비트이므로 64비트 게임이 이를 건너뛰고 Wine 내장 `winhttp.dll`을 사용하게 됩니다. 그 결과 **게임은 실행되지만 모든 Mod가 한꺼번에 작동하지 않습니다.** 이 파일 하나만 교체하면 됩니다.

> 실제로 교체하는 것은 `winhttp.dll`뿐입니다. `doorstop_config.ini`, `BepInEx/unstripped_corlib`, `BepInEx/core`(be.785), DiceMaster, 세이브 확장 같은 매니지드 플러그인은 **모두 그대로 둡니다.** 게임이 64비트가 되었다고 BepInEx를 통째로 교체하지 마십시오.
{: .callout .warn}

1. **저장하고 종료**: 게임 안에서 저장하고 종료한 뒤, Windows용 Steam 메뉴의 `Steam → Exit`로 Steam도 종료합니다.
2. **백업**: 게임 폴더의 `winhttp.dll`, `doorstop_config.ini`, `BepInEx` 폴더 전체를 타임스탬프가 붙은 폴더에 복사합니다. 세이브 데이터(`drive_c/users/<사용자명>/AppData/LocalLow/Obb Studio/Mortal`)도 따로 복사해 둡니다.
3. **비트 수 확인**:
   ```bash
   file "/path/to/LegendOfMortal/Mortal.exe"
   file "/path/to/LegendOfMortal/winhttp.dll"
   ```
   앞의 결과가 `PE32+ … x86-64`이고 뒤의 결과가 `PE32 … Intel 80386`이라면 바로 이 문제입니다.
4. **x64 Doorstop으로 교체**: [UnityDoorstop 4.4.0 릴리스 페이지](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0)에서 Windows용을 내려받아, 그 안의 **x64** 폴더에 있는 `winhttp.dll`로 게임 루트 폴더의 같은 이름 파일을 덮어씁니다.
5. **DLL override가 남아 있는지 확인**: 래퍼의 `winecfg`에서 Applications 탭의 `Mortal.exe`를 선택하고, Libraries 탭에 `winhttp = native,builtin`이 있어야 합니다.
6. **실행하고 이번 로그 확인**: `BepInEx/LogOutput.log`를 열어, 수정 시각이 이번 실행 이후인지 먼저 확인하고(오래된 로그는 오판의 원인이 됩니다) 다음 내용이 있는지 봅니다.
   ```text
   Process bitness: 64-bit (x64)
   Chainloader initialized
   Chainloader startup complete
   ```
7. **게임에서 실제 기능 확인**: 로그에 `Loading [플러그인 이름]`이 나타나는 것은 플러그인이 로드되기 시작했다는 뜻일 뿐입니다. 기능이 실제로 작동하는지는 게임에 들어가 확인하십시오.

직접 사용하는 환경에서 이 절차로 복구한 뒤 DiceMaster `1.0.0`과 세이브 확장 `1.2.0`이 모두 다시 로드되었습니다. 세이브 확장은 작동을 확인했고, DiceMaster는 선택지 이익 표시가 나타나는 것까지 확인했습니다. DiceMaster의 수치 정확성, 새 스토리 분석, 주사위 제어는 아직 검증하지 않았습니다.

**선택 사항: 런타임 구성 요소도 함께 업그레이드.** 같은 날 래퍼를 Template `1.0.11` / Wine `10.0`에서 Template `1.0.22` / Wine `10.0 revision 8`로 올렸습니다. 이 작업은 Mod 진입점 복구와는 관계가 없으므로, 어느 단계에서 문제가 생겼는지 알 수 있도록 따로 진행하고 따로 백업하는 것을 권장합니다. Wine `11.0 revision 1`은 직접 사용하는 환경에서 `wineboot` 초기화 중에 멈췄으므로 현재로서는 권장하지 않습니다.

전체 점검 과정, 검증 범위, 되돌리는 방법은 [1.06 업데이트 사례](cases/game-1.06.ko.md)를 참고하십시오.

<a id="graphics"></a>

## 2. D3D11 그래픽 초기화 실패 복구

대표적인 증상: Steam에 '실행 중'으로 표시된 뒤 게임이 곧 종료되거나, `Player.log`에 다음 내용이 기록됩니다.

```text
Failed to initialize graphics.
d3d11: failed to create device and context (80004005)
```

1. 래퍼 설정을 열고 그래픽 설정에서 DXMT를 켭니다.
2. 게임을 실행하여 메인 메뉴까지 들어가는지 확인합니다.

켠 뒤에도 오류가 계속되면, 먼저 `WINEDEBUG=+loaddll` 로그로 DXMT가 실제로 로드되는지 확인하십시오. 로드되지 않는 것이 확인된 경우에만 Engine의 모듈을 직접 교체합니다.

1. 로그에서 실제로 적용되는 Engine 폴더를 확인합니다.
2. 기존 64비트 WineD3D 모듈을 백업하고 SHA-256을 기록합니다.
3. 해당 버전의 DXMT 모듈(`d3d10core.dll`, `d3d11.dll`, `dxgi.dll`, `winemetal.dll`)을 `x86_64-windows` 폴더에 넣습니다.
4. 짝이 맞는 `winemetal.so`를 `x86_64-unix` 폴더에 넣습니다.
5. 교체한 뒤의 SHA-256을 기록합니다.

성공하면 `Player.log`에 다음과 같이 표시됩니다.

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
```

평소 실행에는 `steam.exe -applaunch 1859910`을 사용하는 것을 권장합니다.

<a id="retina"></a>

## 3. Retina와 해상도

Wine Retina 모드의 레지스트리 항목:

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina와 게임 UI 배율은 별개이며, 《활협전》의 UI는 Windows DPI 설정을 거의 따르지 않습니다. 해상도가 높을수록 화면은 선명해지고 UI는 작아집니다. 해상도가 낮으면 UI는 커지지만 화면이 흐려집니다. 게임이 직접 고른 해상도를 기억하게 두고(직접 사용하는 환경은 `1920×1200`), 실행 인자에서 강제로 지정한 `-screen-width` / `-screen-height`를 제거하는 것을 권장합니다.

<a id="fonts"></a>

## 4. 상점 가격 공백 복구

증상: 중국어 대화, 일반 숫자, 엽전 아이콘은 모두 정상인데 상점의 단가와 합계만 비어 있습니다.

1. Windows용 Steam을 완전히 종료합니다.
2. `drive_c/windows/Fonts`, `system.reg`, `user.reg`, `userdef.reg`를 백업합니다.
3. Winetricks를 열고 `fonts → allfonts`를 설치합니다.
4. 래퍼를 다시 시작하고 게임을 실행하여 상점 금액이 정상적으로 표시되는지 확인합니다.

<details markdown="1">
<summary>원인과 테스트 기록</summary>

`MoneyValue` / `MoneyText` 컴포넌트는 내장 글꼴 `SourceHanSerifTC-Bold`를 사용하며 글꼴 아틀라스에도 `0–9`가 들어 있습니다. 문제는 prefix의 글꼴 세트와 글꼴 매핑이 불완전한 데 있었습니다. 처음 만든 prefix에는 `sourcehansans.ttc`와 `unifont.ttf`만 있었고, `allfonts`를 설치하자 121개 파일(약 284 MB)로 늘었습니다. 이 수치는 환경에 따라 다를 수 있습니다.

각 글꼴에는 각각의 라이선스가 있습니다. Winetricks를 통해 원래 출처에서 설치하십시오. 이 저장소는 글꼴을 일절 배포하지 않습니다.

</details>

<a id="mods"></a>

## 5. BepInEx Mod 설치와 복구

### 로드 흐름

1. **Doorstop**: Wine이 게임 폴더의 `winhttp.dll`을 로드하고, 이것이 BepInEx Preloader를 시작합니다.
2. **Preloader**: Unity 기본 라이브러리(corlibs)를 로드하고 환경을 준비합니다.
3. **Chainloader**: `BepInEx/plugins/` 아래의 Mod를 차례로 로드합니다.

세 단계는 Wine에서 각각 함정이 하나씩 있으며, 아래의 세 단계가 이에 대응합니다. 1.05 시절에 이미 설치를 마치고 1.06으로 업그레이드만 한 분은 [1.05에서 1.06으로 업그레이드](#upgrade)만 보시면 됩니다.

### 설치 전 점검

Mod 압축 파일마다 다음을 수행합니다.

1. 압축 파일 안의 경로를 확인하여 절대 경로와 `..`가 없는지 봅니다.
2. `file`로 `winhttp.dll` 같은 네이티브 DLL이 64비트(`PE32+`)인지 확인합니다.
3. 덮어쓰게 될 파일 목록을 만들고, 먼저 타임스탬프가 붙은 백업 폴더에 복사합니다.
4. 압축을 푼 뒤 SHA-256을 대조합니다.
5. 실행한 뒤 `LogOutput.log`가 이번 실행에서 생성된 것인지 확인합니다.

> 일본어 파일명이 들어 있는 압축 파일은 Finder나 `ditto -x -k`로 푸십시오. macOS 기본 `unzip`은 일본어 파일명에서 오류를 내고 불완전한 파일을 남깁니다.
{: .callout}

### 1단계: Wine이 Doorstop을 로드하게 하기

Wine은 기본적으로 내장 `winhttp.dll`을 우선 사용합니다. `winecfg`의 Applications 탭에서 `Mortal.exe`를 선택한 뒤 Libraries 탭에 다음을 추가합니다.

```text
winhttp = native,builtin
```

게임 폴더의 `winhttp.dll`은 반드시 64비트여야 합니다. 직접 검증한 것은 [UnityDoorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0) Windows **x64** 버전입니다.

### 2단계: 완전한 corlibs 제공

게임에 포함된 `Mortal_Data/Managed/mscorlib.dll`은 일부 코드가 제거된 버전(`3,906,048` 바이트)입니다. Unity `2020.3.49f1`의 완전한 버전은 `4,065,792` 바이트입니다. 적법하게 확보한, 버전이 일치하는 완전한 corlibs를 `BepInEx/unstripped_corlib/`에 넣고 `doorstop_config.ini`를 편집합니다.

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs는 Unity 버전과 완전히 일치해야 하며 Unity의 라이선스를 지켜야 합니다. 이 저장소는 corlibs를 배포하지 않습니다. 1.06에서도 여전히 필요한지는 따로 검증하지 않았으며, 직접 검증한 구성에는 그대로 포함되어 있습니다.

### 3단계: Wine 수정이 포함된 BepInEx 6 사용

예전 BepInEx 6(예: `be.692`)은 Wine에서 다음 예외를 일으킬 수 있습니다.

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

이 문제는 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)에 보고되었고 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)에서 수정되었습니다. 먼저 `BepInEx/core`를 백업한 뒤 `6.0.0-be.785`의 Unity.Mono 코어로 교체하십시오.

직접 사용하는 환경에서 실제로 쓴 것은 be.785 매니지드 코어와 Doorstop 4.4.0 x64 `winhttp.dll`입니다. 매니지드 코어는 비트 수를 가리지 않으므로, 1.05 시절에 설치한 be.785를 1.06에서도 계속 쓸 수 있습니다. 새로 설치한다면 BepInEx의 win-x64 패키지를 그대로 써도 되지만, 패키지 안의 `winhttp.dll`이 64비트인지는 확인하십시오.

성공하면 로그에 다음 내용이 포함됩니다.

```text
BepInEx 6.0.0-be.785
Process bitness: 64-bit (x64)
Chainloader initialized
```

<a id="jpmod"></a>

## 6. 일본어 Mod v2.5

일본어 Mod v2.5는 64비트 게임을 대상으로 바뀌었고 게임 내 업데이트 기능이 추가되었습니다. README에는 '전부 덮어쓰기'라고 되어 있지만, Mac에서 통째로 덮어쓰면 BepInEx 코어가 예전 `be.692`로 되돌아가고 `doorstop_config.ini`에서도 `unstripped_corlib` 경로가 사라집니다.

**실측 완료(2026-10-15):** README대로 전부 덮어쓴 뒤 두 가지만 하면 됩니다. ① `BepInEx/core`를 덮어쓰기 전의 be.785로 되돌리고, ② `doorstop_config.ini`를 `dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"`로 고칩니다. 그러면 일본어 Mod, DiceMaster, 세이브 슬롯 확장까지 8개 플러그인이 모두 오류 없이 로드됩니다. v2.5에 포함된 64비트 `winhttp.dll`은 그대로 써도 됩니다. 덮어쓰기만 하면 be.692가 `PlatformHelper.Current` 오류로 멈추고 모든 Mod가 작동하지 않습니다.

Mac에서의 설치 절차와 검증 결과는 일본어 페이지(일본어)인 [日本語化 Mod v2.5 を Mac で導入する](cases/japanese-mod-v2.5.ja.md)를 참고하십시오.

<a id="focus"></a>

## 7. 알려진 문제: 창 전환 후 제목 표시줄을 클릭해야 함

다른 macOS 앱에서 《활협전》으로 돌아오면 화면은 정상적으로 갱신되지만 키보드, 마우스, 컨트롤러가 반응하지 않는 경우가 있습니다.

1. `Mortal` 게임 창으로 돌아옵니다.
2. 창 상단의 어두운 제목 표시줄(아래 그림의 빨간 화살표 위치)을 한 번 클릭합니다.
3. 게임으로 돌아가 조작을 이어갑니다.

![Mortal 창 제목 표시줄을 클릭해 게임 입력 복구](assets/window-titlebar-focus-recovery.png)

Steam 전역 오버레이와 이 게임의 오버레이를 끄면 발생 빈도를 줄일 수 있습니다. 이 현상은 1.05 실기에서 재현했고 해결 방법도 확인했으며, 1.06에서는 따로 다시 시험하지 않았습니다. 근본 원인은 아직 조사 중이며, Wine, Unity, macOS 사이의 포커스 전달 이상에서 나타나는 특징과 일치합니다.

<a id="daily"></a>

## 8. 일상 운영 팁

- Steam 전역 오버레이와 이 게임의 오버레이를 끕니다.
- 플레이 중에는 `caffeinate`로 시스템이 잠들지 않게 할 수 있습니다. 덮개를 닫아 절전에 들어갔거나, 화면을 잠갔거나, 외장 모니터를 연결·분리한 뒤에는 저장하고 게임, Steam, 래퍼를 다시 시작하는 것을 권장합니다.
- 종료할 때는 먼저 게임 안에서 저장한 뒤 Windows용 Steam의 `Steam → Exit`를 사용합니다. Dock의 Wine 아이콘은 창 대리 역할일 뿐입니다.
- Windows용 Steam을 오랫동안 백그라운드에 두면 `-applaunch`에 반응하지 않을 수 있습니다. `gameprocess_log.txt`에 새 기록이 없으면 이 래퍼의 Steam과 Wine 세션을 다시 시작하십시오.

<a id="diagnostics"></a>

## 9. 읽기 전용 점검 스크립트

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

이 스크립트는 래퍼 설정, 게임 아키텍처, Steam 매니페스트, 레지스트리, 글꼴 수, DXMT 모듈 해시, BepInEx 로그, 현재 프로세스를 읽기만 하며, 어떤 프로세스도 시작하거나 종료하지 않고 파일도 수정하지 않습니다. 스크립트는 [프로젝트 저장소](https://github.com/li-yifei/legend-of-mortal-mac-guide)에 있습니다.

## AI 어시스턴트의 도움 받기

Wine이나 터미널이 낯선 분은 이 가이드를 AI 코딩 어시스턴트에게 건네고, 먼저 읽기 전용으로 환경을 점검하게 한 뒤 증상에 따라 처리하게 할 수 있습니다. 다음 사항을 지키십시오.

- Steam 로그인은 직접 수동으로 하고, AI에게 계정 비밀번호나 토큰을 제공하지 않습니다.
- 파일 교체와 위험한 명령은 먼저 사람이 확인합니다.
- Engine, prefix, 게임 폴더를 수정하기 전에 타임스탬프가 붙은 백업을 만듭니다.

<a id="legacy"></a>

## 1.05 이전 구성

<details markdown="1">
<summary>1.05(Build <code>20337760</code>, 32비트)의 검증 환경과 차이점</summary>

2026-08-29에 검증했습니다.

| 항목 | 구성 |
| --- | --- |
| 게임 | Build `20337760`, `release_1.0.5000.13` |
| 실행 파일 | `Mortal.exe`, PE32 / x86 |
| 래퍼 | Sikarugir Template `1.0.11`, Wine `10.0` |
| 그래픽 백엔드 | 32비트 DXMT |
| Mod | Doorstop x86 `winhttp.dll`, BepInEx `6.0.0-be.785` x86 Mono |

1.06과의 차이점:

- `file Mortal.exe`가 `PE32 executable (GUI) Intel 80386`을 표시합니다.
- 네이티브 구성 요소는 모두 32비트를 선택합니다. `winhttp.dll`은 x86 버전을 쓰고, DXMT를 직접 교체할 때는 `i386-windows` / `i386-unix`에 넣습니다.
- D3DMetal은 64비트만 지원하므로 1.05에서는 쓸 수 없으며, DXMT가 32비트 D3D10/11 모듈을 제공합니다.
- 일본어 Mod v2.4와 DiceMaster의 로드 과정은 [일본어 Mod v2.4 사례](cases/japanese-mod.ko.md)를 참고하십시오.

</details>

## 참고 자료

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [UnityDoorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0)
- [BepInEx Wine 수정 패치(PR #1254)](https://github.com/BepInEx/BepInEx/pull/1254)
- [《활협전》 일본어 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
