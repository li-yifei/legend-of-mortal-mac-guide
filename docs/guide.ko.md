---
layout: page
title: Apple Silicon Mac에서 《활협전》 실행하기: 설치·글꼴·Mod 복구
permalink: /docs/guide.ko/
---

[홈](../README.md) · [繁體中文](guide.zht.md) · [简体中文](guide.zhs.md) · [日本語](guide.ja.md)

이 문서는 2026년 8월 실제 기기에서 검증된 구성 방안을 정리한 기술 가이드입니다. Sikarugir, Wine 및 Windows용 Steam을 활용하여 직접 구매한 정품 《활협전(Legend of Mortal)》을 Apple Silicon Mac에서 실행하고, 글꼴 및 BepInEx Mod 관련 문제를 해결하는 과정을 다룹니다.

## 검증 환경

| 항목 | 검증된 구성 |
| --- | --- |
| 게임 | Steam AppID `1859910`, Build ID `20337760`, `release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 실행 파일 | `Mortal.exe`, PE32 / x86 |
| 래퍼(Wrapper) | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| 그래픽 백엔드 | 32-bit DXMT, D3D11 → Metal |
| Mod 프레임워크 | BepInEx `6.0.0-be.785` x86 Mono |

Wine, Steam, macOS 및 게임 자체의 업데이트에 따라 호환성 및 실행 결과가 달라질 수 있습니다. 환경을 변경하거나 문제를 조치할 때는 항상 버전 정보를 기록하고 로그를 보관하며, 타임스탬프가 포함된 백업을 생성하십시오.

## 1. Windows용 Steam 전용 래퍼 생성

사전 준비 사항:

- Apple Silicon Mac 및 macOS 14 이상
- Rosetta 2
- [Sikarugir 공식 GitHub](https://github.com/Sikarugir-App/Sikarugir)
- Steam 계정에 구매 등록된 [《활협전》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)
- 충분한 디스크 여유 공간(래퍼, Steam, 게임 본편 및 단계별 백업 저장용)

Sikarugir Creator를 사용하여 독립 래퍼(예: `SteamWin.app`)를 생성합니다. 래퍼 전용 Wine prefix에서 다음 순서대로 작업을 진행합니다.

1. Wine prefix를 초기화하고, `Program Files`와 `Program Files (x86)` 디렉터리가 모두 생성되었는지 확인합니다.
2. Winetricks를 통해 `cjkfonts`를 설치합니다.
3. 레지스트리에 `hidewineexports=enable` 설정을 적용합니다.
4. Windows용 Steam을 설치합니다.
5. 실행 대상을 `C:\Program Files (x86)\Steam\steam.exe`로 지정합니다.
6. Steam에 로그인한 후 AppID `1859910`을 다운로드 및 설치합니다.

macOS 네이티브 Steam과 Windows용 Steam은 동일 머신에서 공존할 수 있습니다. 로그인이나 네트워크 연결 오류가 발생할 경우, 세션 충돌 및 강제 로그아웃을 방지하기 위해 다른 한쪽의 클라이언트를 완전히 종료하십시오.

### 게임 바이너리 아키텍처 확인

Steam 상점 페이지의 시스템 요구사항 표기만으로는 실제 바이너리 아키텍처를 확정할 수 없습니다. 다음 명령으로 바이너리 아키텍처를 확인합니다.

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

실제 검증된 빌드(Build)의 확인 결과:

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

Windows용 Steam 자체는 32비트 부트스트래퍼를 주로 사용하지만, 그래픽 백엔드 선택은 게임 메인 실행 파일인 `Mortal.exe`의 PE32(32비트) 아키텍처를 기준으로 판단해야 합니다.

## 2. D3D11 그래픽 초기화 실패 복구

대표 증상: Steam에서 잠시 '실행 중'으로 표시된 후 게임이 비정상 종료되거나, 오류 대화상자가 발생하며 `Player.log`에 다음 로그가 기록됩니다.

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

검증 환경에서 여러 그래픽 렌더링 백엔드를 테스트한 결과는 다음과 같습니다.

- Unity OpenGL: 게임 자체에 해당 그래픽 장치(Graphics Device) 지원이 포함되어 있지 않습니다.
- WineD3D + MoltenVK: Apple GPU는 인식되지만 Direct3D 기능 수준(Feature Level) 협상 단계에서 실패합니다.
- D3DMetal: 주로 64비트 D3D11/D3D12를 지원하므로 32비트 게임에는 직접 적용할 수 없습니다.
- DXMT: 완전한 32비트 D3D10/11 모듈을 제공하여 32비트(PE32) 게임 환경에 적합합니다.

### DXMT 적용 여부 검증

래퍼 설정 UI에서 DXMT 토글을 활성화하는 것은 설정값을 기록하는 단계입니다. 런타임에서 실제로 정상 적용되었는지는 다음 항목으로 검증해야 합니다.

- `WINEDEBUG=+loaddll` 로그에서 대상 `d3d11.dll`, `dxgi.dll`, `winemetal.dll`이 실제로 로드되었는지 확인
- 현재 로드된 Engine DLL의 SHA-256 해시가 대상 DXMT 파일과 일치하는지 대조
- `Player.log`에서 Direct3D 11 level 11.1 및 Apple GPU가 정상 출력되는지 확인

검증 환경에서는 래퍼 UI에서 DXMT를 활성화한 후에도 Engine 디렉터리의 기본 WineD3D가 우선 로드되는 현상이 있었습니다. 이에 따라 안전하게 롤백할 수 있는 Engine 계층 교체 방식을 적용했습니다.

1. 기존 32비트 WineD3D 모듈을 백업합니다.
2. 해당 버전의 DXMT 모듈(`d3d10core.dll`, `d3d11.dll`, `dxgi.dll`, `winemetal.dll`)을 실제 검색 경로인 `i386-windows` 디렉터리에 배치합니다.
3. 대응하는 `winemetal.so`를 해당 Unix 모듈 디렉터리에 배치합니다.

Engine에 따라 디렉터리 구조가 다를 수 있으므로, 반드시 로드 로그에서 실제 검색 경로를 확인한 후 교체하십시오. 교체 전후의 모든 파일에 대해 SHA-256 해시를 기록해 두어야 합니다.

DLL 로드 성공 로그 예시:

```text
Loaded C:\windows\system32\winemetal.dll
Loaded C:\windows\system32\DXGI.DLL
Loaded C:\windows\system32\d3d11.dll
```

Unity 초기화 성공 로그 예시:

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
Begin MonoManager ReloadAssembly
```

일상적인 게임 실행에는 Steam AppID 명령줄 인자 사용을 권장합니다.

```text
steam.exe -applaunch 1859910
```

## 3. Retina 디스플레이 및 해상도 설정

Wine Retina 모드 관련 레지스트리 경로:

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 렌더링과 Unity UI 스케일링은 서로 독립적으로 작동합니다. 《활협전》의 Unity UI 로직은 Windows DPI 설정을 거의 반영하지 않습니다. 높은 해상도를 설정하면 화면이 선명하고 섬세해지지만 UI가 상대적으로 작아지며, 낮은 해상도에서는 UI가 커지는 대신 화면 확대에 따른 흐림(블러) 현상이 발생합니다.

게임 런처 바로가기 등에서 `-screen-width` 및 `-screen-height` 강제 해상도 인자를 제거하고, 게임 내에서 설정한 창 해상도를 유지하도록 구성하는 방식을 권장합니다. 검증 환경에서는 `1920×1200` 해상도를 사용했습니다.

## 4. 상점 가격 및 총액 미표시 문제 해결

대표 증상: 게임 내 중국어 대사, 일반 수치, 엽전 아이콘 등은 정상 출력되지만, 상점 인터페이스의 상품 단가와 총 결제 금액만 빈칸(공백)으로 표시됩니다.

Unity 리소스를 분석한 결과, `MoneyValue` 및 `MoneyText` UI 컴포넌트에는 임베디드 폰트인 `SourceHanSerifTC-Bold`가 연결되어 있으며 기본 텍스트 `50`과 `0~9` 숫자 글리프가 정상 포함되어 있었습니다. 문제의 근본 원인은 Wine prefix 내부의 글꼴 집합 및 시스템 폰트 매핑 누락이었습니다.

초기 생성된 Wine prefix에는 다음 글꼴 파일만 존재합니다.

```text
sourcehansans.ttc
unifont.ttf
```

`cjkfonts`를 설치한 상태에서도 필요한 글꼴 매핑 범위가 부족할 수 있습니다. Winetricks에서 다음 항목을 설치하여 해결합니다.

```text
fonts → allfonts
```

작업 전 Windows용 Steam을 완전히 종료하고 다음 디렉터리 및 레지스트리 파일을 백업하십시오.

- `drive_c/windows/Fonts`
- `system.reg`
- `user.reg`
- `userdef.reg`

설치 완료 후 폰트 디렉터리의 파일이 2개에서 121개(약 284MB)로 확장되며, Arial, Tahoma, Calibri, Meiryo, WenQuanYi 등의 레지스트리 항목이 정상 등록됩니다. wineserver 프로세스를 재시작하고 게임을 다시 실행하면 상점 금액이 정상적으로 표시됩니다.

각 글꼴에는 고유한 소프트웨어 라이선스가 적용됩니다. 글꼴은 반드시 Winetricks를 통해 원본 소스에서 직접 다운로드하여 설치해야 하며, 공개 저장소와 배포용 래퍼 패키지는 폰트 파일을 일체 포함하지 않는 원칙(Zero Font Redistribution)을 유지합니다.

## 5. Doorstop 및 BepInEx Mod 로드 복구

상세한 원인 분석 및 단계별 복구 과정은 사례 연구 문서를 참조하십시오: [사례: Wine 10 / x86 《활협전》에서 일본어 Mod 로드 복구](cases/japanese-mod.ko.md).

### Mod 설치 전 파일 단위 백업 및 무결성 검사

Mod 압축 파일을 적용하기 전에 다음 절차를 수행합니다.

1. 압축 파일 내부 경로를 검사하여 절대 경로 및 `..` 경로 탐색(Path Traversal) 보안 취약점이 없는지 확인합니다.
2. `winhttp.dll` 및 각 플러그인 DLL이 x86(32비트) 아키텍처인지 검증합니다.
3. 덮어쓰게 될 기존 파일 목록을 확인합니다.
4. 동일한 이름의 기존 파일을 타임스탬프가 지정된 백업 디렉터리에 복사합니다.
5. 압축을 해제하여 병합한 후 SHA-256 해시를 대조 검증합니다.
6. 게임을 실행한 후 로그 파일의 수정 시각이 현재 실행 시점과 일치하는지 확인합니다.

Mod 패키지에는 이전에 생성된 `LogOutput.log` 파일이 남아 있을 수 있습니다. 프레임워크의 정상 동작 여부는 로그 파일의 수정 시각, 현재 프로세스에 로드된 모듈, Chainloader 출력 로그를 종합적으로 대조하여 판단해야 합니다.

### 1단계: Doorstop 로드

`winecfg → Libraries`에서 게임 메인 실행 파일에 대한 설정을 추가합니다.

```text
winhttp = native,builtin
```

전역 설정 대신 `Mortal.exe`에만 적용되는 애플리케이션 수준 DLL override를 권장합니다. 게임 실행 시 프로세스 내에 게임 디렉터리의 `winhttp.dll`과 BepInEx Preloader가 정상 로드되는지 확인합니다.

### 2단계: 일치하는 Unity 버전의 완전한 corlibs 제공

바이너리를 비교한 결과, 게임에 기본 포함된 `Mortal_Data/Managed/mscorlib.dll`의 크기는 `3,906,048` 바이트인 반면, Unity `2020.3.49f1` 버전의 원본 전체(Unstripped) corlib 크기는 `4,065,792` 바이트였습니다.

정상적인 경로로 확보한 동일 Unity 버전의 완전한 corlibs를 다음 디렉터리에 배치합니다.

```text
BepInEx/unstripped_corlib/
```

`doorstop_config.ini` 파일을 편집합니다.

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs는 반드시 Unity 엔진 버전과 엄격히 일치해야 하며, Unity 소프트웨어 라이선스를 준수하여 취득·사용해야 합니다. 공개 저장소와 Mod 배포 패키지는 corlibs를 일체 포함하지 않는 원칙을 준수합니다.

### 3단계: Wine 수정 패치가 적용된 BepInEx 6 사용

구버전 BepInEx 6는 Wine 32비트 환경에서 다음과 같은 예외를 발생시킬 수 있습니다.

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

이 문제는 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)에 보고되었으며, [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)에서 해결되었습니다. 검증 환경에서는 해당 패치가 포함된 x86 Mono 빌드 `6.0.0-be.785`를 사용했습니다. 파일 교체 전 `BepInEx/core` 디렉터리 전체를 반드시 백업하십시오.

성공적인 로드 시 출력되는 로그:

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

이후 각 플러그인이 순차적으로 로드됩니다. 검증 환경에서는 DiceMaster 및 일본어 Mod 관련 5개 플러그인이 Chainloader에 의해 정상 로드되었습니다. DiceMaster 모듈 역시 Wine 환경에서 `winhttp` override 누락, corlibs 스트립(Strip), BepInEx 플랫폼 초기화 예외로 인해 실행되지 않는 문제가 발생하지만, 본 절의 Doorstop / corlibs / BepInEx Wine 복구 경로를 통해 동일하게 완벽히 복구할 수 있습니다.

## 6. 일상 운영 및 문제 해결 권장 사항

- Steam 오버레이(Overlay)를 전역 설정 및 《활협전》 개별 설정에서 비활성화하면, 다른 애플리케이션으로 전환한 후 키보드/마우스 입력이 먹통이 되는(잠기는) 현상을 예방할 수 있습니다.
- 플레이 중에는 `caffeinate` 명령을 활용하여 시스템 절전 모드 진입을 방지하는 것을 권장합니다. 맥북 상판을 덮어 절전 모드로 진입했거나 화면 잠금 해제, 외장 디스플레이 연결/해제가 발생한 경우에는 게임, Windows용 Steam 및 wineserver 세션을 완전히 종료한 후 재시작하십시오.
- Windows용 Steam이 장시간 백그라운드에 머무를 경우 `-applaunch` 실행 요청에 반응하지 않을 수 있습니다. Steam의 `gameprocess_log.txt`에 신규 로그가 기록되지 않는다면 해당 prefix의 Steam과 Wine 세션을 재시작하십시오.
- 게임 및 Steam을 종료할 때는 Windows용 Steam 메뉴의 `Steam → Exit`를 사용하여 정상적으로 종료하십시오. macOS Dock에 표시되는 Wine 아이콘은 단순 창 프록시입니다.

## 7. 읽기 전용 진단 스크립트 활용

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

이 스크립트는 래퍼 설정, 게임 바이너리 아키텍처, Steam 매니페스트(manifest), 레지스트리 설정, 글꼴 수, DXMT 모듈 해시, BepInEx 로그 및 실행 중인 프로세스를 오직 읽기 전용(Read-Only)으로 검사합니다. 임의로 파일을 수정하거나 Wine, Steam, 게임 세션을 시작 또는 종료하지 않습니다.

## 참고 자료

- [Sikarugir 공식 GitHub](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT 프로젝트](https://github.com/3Shain/dxmt)
- [BepInEx Wine 초기화 수정 PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)
- [《활협전》 일본어 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
