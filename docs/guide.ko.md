# Apple Silicon Mac에서 《활협전》 실행하기: 설치·글꼴·Mod 복구

[Home](../README.md) · [繁體中文](guide.zht.md) · [简体中文](guide.zhs.md) · [日本語](guide.ja.md)

> 이 문서는 2026-08-29, Build `20337760`에서 검증한 구버전 절차이며 32비트 구성 요소 선택은 해당 환경을 기준으로 합니다. 게임 1.06(Build `25953419`)의 64비트 진입점 복구는 [1.06 업데이트 사례](cases/game-1.06.ko.md)를 참고하십시오. 각 기능의 검증 범위도 해당 문서에 구분해 두었습니다.

이 문서는 Apple Silicon Mac에서 직접 구매한 정품 《활협전 / Legend of Mortal》을 플레이하려는 사용자를 위해, Sikarugir, Wine, Windows용 Steam을 통한 설치 절차와 그래픽 초기화 실패, 상점 텍스트 공백, Mod 로드 오류 등 주요 문제의 해결 방법을 안내하는 실기 검증 가이드입니다.

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
| 최종 검증일 | 2026-08-29 |

Wine, Steam, macOS 및 게임 업데이트에 따라 호환성 및 실행 결과가 달라질 수 있습니다. 설정을 변경할 때는 버전 번호를 기록하고 타임스탬프가 포함된 백업을 생성하십시오.

## 증상별 빠른 해결 색인

각 복구 섹션은 해당 증상이 발생했을 때만 선택적으로 수행하십시오. 게임이 정상 실행된다면 추가 작업은 필요하지 않습니다.

| 증상 또는 목적 | 해당 섹션 | 핵심 조치 |
| --- | --- | --- |
| 초기 설치 및 환경 구성 | [1. 독립된 Windows용 Steam Wrapper 만들기](#install) | 래퍼 생성, Windows용 Steam 및 게임 설치 |
| 실행 즉시 종료 / D3D11 오류 | [2. D3D11 초기화 실패 복구](#graphics) | DXMT 활성화(필요 시 Engine DLL 수동 교체) |
| 화면 흐림 / UI 크기 부적합 | [3. Retina와 해상도](#retina) | 필요에 따라 RetinaMode를 켜고 보기 편한 창 해상도 선택 |
| 상점 단가 및 합계 금액 빈칸 | [4. 상점 가격과 합계가 사라지는 문제](#fonts) | 레지스트리 백업 및 Winetricks allfonts 설치 |
| Mod / 패치 미적용 및 로드 실패 | [5. Doorstop/BepInEx Mod 복구](#mods) | winhttp 설정, 완전한 corlibs 배치, BepInEx 6 교체 |
| 창 전환 후 키보드·마우스 무반응 | [6. 알려진 문제](#focus) | 창 상단 제목 표시줄을 클릭하여 입력 제어 복귀 |
| 장시간 방치 및 절전 시 충돌 방지 | [7. 운영 팁](#daily) | 오버레이 비활성화, caffeinate 사용, Steam 정상 종료 |
| 현재 환경 구성 및 로그 진단 | [8. 읽기 전용 검사기](#diagnostics) | 읽기 전용 검사 스크립트로 상태 리포트 출력 |

## 핵심 용어 안내

| 용어 | 설명 |
| --- | --- |
| 래퍼(Wrapper / App) | macOS의 `.app` 번들 형태로, Wine 실행 환경과 Windows 소프트웨어를 하나로 묶은 패키지입니다. |
| Wine | Windows 프로그램이 필요한 시스템 기능을 macOS에서 사용할 수 있게 하는 호환 계층입니다. |
| Wine prefix | 래퍼 내부에 생성되는 가상 Windows 환경(가상 C 드라이브 및 레지스트리)입니다. |
| Winetricks | Wine prefix에 필수 런타임이나 Windows 글꼴을 자동으로 설치해 주는 보조 도구입니다. |
| DXMT | Windows의 Direct3D 11 그래픽 렌더링 명령을 Apple Metal 명령으로 변환하는 그래픽 번역 레이어입니다. |
| BepInEx | Unity 엔진 게임에서 플러그인(Mod)을 로드하고 관리하는 프레임워크입니다. |
| Doorstop / 부팅 체인 | Mod 로드의 시작점 도구입니다. Doorstop이 실행 시점에 개입하여 Preloader를 호출하고, 이어 Chainloader가 각 Mod 플러그인을 로드합니다. |

<a id="install"></a>

## 1. 독립된 Windows용 Steam Wrapper 만들기

사전 준비:
- Apple Silicon Mac 및 macOS 14 이상;
- Rosetta 2 환경;
- [Sikarugir 공식 GitHub](https://github.com/Sikarugir-App/Sikarugir);
- Steam 계정에서 구매한 [《활협전》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/);
- 충분한 디스크 여유 공간(래퍼, Steam, 게임 본체, 백업 보관용).

Sikarugir Creator로 독립 래퍼(예: `SteamWin.app`)를 만듭니다. 래퍼 전용 Wine prefix에서 다음 순서로 작업을 완료합니다:

1. Wine prefix를 초기화하고 `Program Files`와 `Program Files (x86)` 디렉터리가 모두 생성되었는지 확인합니다.
2. Winetricks에서 `cjkfonts`를 설치합니다.
3. 레지스트리 설정 `hidewineexports=enable`을 적용합니다.
4. Windows용 Steam을 설치합니다.
5. 실행 대상을 `C:\Program Files (x86)\Steam\steam.exe`로 설정합니다.
6. Steam에 로그인하고 AppID `1859910`을 다운로드 및 설치합니다.

macOS 네이티브 Steam과 Windows용 Steam은 공존할 수 있습니다. 로그인이나 네트워크 통신에 문제가 생길 경우, 동일 계정 세션 충돌을 방지하기 위해 다른 한쪽 클라이언트를 완전히 종료하십시오.

### 게임 실행 파일 아키텍처 확인

Steam 상점 페이지의 시스템 요구 사항 표시는 실제 바이너리 구조 확인을 대체하지 못합니다. macOS 터미널에서 다음 명령을 실행합니다(명령의 `/path/to/...`는 실제 게임 설치 경로로 변경하는 플레이스홀더입니다):

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

실제 검증된 빌드(Build)의 확인 결과:

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

확인 결과는 PE32(32비트 x86)입니다. 이 구버전 구성에서는 네이티브 진입 DLL과 그래픽 모듈을 `Mortal.exe`의 32비트 구조에 맞춥니다. 관리형 Mod 플러그인은 빌드 설정, 종속 항목, Unity 호환성에 따라 32비트와 64비트를 함께 지원할 수 있습니다. 이후 복구는 해당 증상에 맞는 절차를 선택합니다.

<a id="graphics"></a>

## 2. D3D11 초기화 실패 복구

### 증상 및 일반 활성화

대표적인 증상: Steam에서 잠시 '실행 중'으로 표시된 후 게임이 비정상 종료됩니다. 에러 대화상자나 `Player.log`에 다음 로그가 기록됩니다:

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

일반 활성화 조치:
1. 래퍼 설정 창을 엽니다.
2. 그래픽 설정에서 DXMT 스위치를 켭니다.
3. 게임을 실행하여 타이틀 화면이 열리는지 확인합니다.

### 고급 점검: Engine DLL 수동 교체 폴백

UI에서 DXMT를 활성화한 후에도 초기화 오류가 계속된다면 로그를 통해 실제 모듈 로드 여부를 확인해야 합니다. 시스템이 DXMT 모듈을 로드하지 못하고 WineD3D를 불러오는 것이 확인되었을 때만 이 Engine 레이어 교체 폴백을 실행합니다.

교체 순서:
1. `WINEDEBUG=+loaddll` 로그를 통해 활성 Engine의 실제 검색 디렉터리를 확인합니다.
2. 기존 32비트 WineD3D 모듈을 백업하고 교체 전 원본 파일의 SHA-256 해시값을 기록합니다.
3. 대상 버전의 DXMT 모듈(`d3d10core.dll`, `d3d11.dll`, `dxgi.dll`, `winemetal.dll`)을 유효한 `i386-windows` 디렉터리에 복사합니다.
4. 일치하는 `winemetal.so`를 대응하는 Unix 모듈 디렉터리에 배치합니다.
5. 교체 후 각 파일의 SHA-256 해시값을 기록하여 버전 일치를 확인합니다.

<details markdown="1">
<summary>그래픽 렌더러 비교 및 로드 성공 로그</summary>

검증된 빌드에서 테스트한 그래픽 경로 분석:
- Unity OpenGL: 게임 빌드 자체에 해당 그래픽 장치 지원이 포함되지 않았습니다.
- WineD3D + MoltenVK: Apple GPU는 인식하지만 Direct3D 기능 수준 협상에 실패했습니다.
- D3DMetal: 주로 64비트 D3D11/12를 지원하므로 32비트 게임에는 사용할 수 없습니다.
- DXMT: 완전한 32비트 D3D10/11 모듈을 제공하므로 본 32비트(PE32) 게임에 적합합니다.

모듈 로드 성공 로그 예시:

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

</details>

평소 실행할 때는 Steam AppID 커맨드라인 매개변수를 사용하는 방식을 권장합니다:

```text
steam.exe -applaunch 1859910
```

<a id="retina"></a>

## 3. Retina와 해상도

Wine Retina Mode 레지스트리 경로:

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 렌더링과 Unity UI 배율 조정은 별도로 동작합니다. 《활협전》의 Unity UI 로직은 Windows DPI 설정을 기본적으로 무시합니다. 고해상도에서는 정밀한 화면을 얻을 수 있지만 UI가 작아지며, 저해상도에서는 UI가 커지지만 확대에 따른 흐림이 발생합니다.

게임 내부 설정에서 사용자가 선택한 창 해상도를 기억하도록 유지하는 방식을 권장합니다. 검증 환경에서는 `1920×1200`을 사용했으며, 바로가기의 실행 옵션에서 강제 지정 인자 `-screen-width`와 `-screen-height`를 제거했습니다.

<a id="fonts"></a>

## 4. 상점 가격과 합계가 사라지는 문제

### 증상 및 복구 조치

대표적인 증상: 게임 내 중국어 대화, 일반 숫자, 엽전 아이콘은 정상 출력되지만, 상점 화면의 아이템 단가 및 총 결제 금액만 빈칸으로 출력됩니다.

복구 조치:
1. Windows용 Steam을 완전히 종료합니다.
2. 다음 4곳의 파일 및 디렉터리를 백업합니다:
   - `drive_c/windows/Fonts`
   - `system.reg`
   - `user.reg`
   - `userdef.reg`
3. Winetricks를 열고 다음 항목을 선택해 설치합니다:
```text
fonts → allfonts
```
4. 현재 래퍼를 종료한 후 다시 실행하여 전용 wineserver 세션을 안전하게 재시작합니다.
5. 게임을 실행하여 상점 금액이 정상 표시되는지 확인합니다.

<details markdown="1">
<summary>글꼴 누락 원인과 테스트 관측 기록</summary>

Unity 리소스 분석 결과, `MoneyValue` 및 `MoneyText` UI 컴포넌트는 내장 글꼴 `SourceHanSerifTC-Bold`에 연결되어 있으며 기본값 `50`과 숫자 글리프 `0–9`도 모두 포함하고 있었습니다. 원인은 Wine prefix 내부의 글꼴 세트와 시스템 글꼴 매핑이 불완전했기 때문입니다.

초기 생성 시 prefix에 포함된 글꼴 파일:

```text
sourcehansans.ttc
unifont.ttf
```

실제 검증에서 `allfonts`를 설치한 결과, 글꼴 디렉터리의 파일 수는 2개에서 121개(약 284 MB)로 증가했고 Arial, Tahoma, Calibri, Meiryo, WenQuanYi 등의 레지스트리 항목이 정상 등록되었습니다. 이 파일 수와 용량은 실측 환경의 기록이며 시스템 환경에 따라 차이가 있을 수 있습니다.

각 글꼴에는 독립적인 소프트웨어 라이선스가 적용됩니다. 글꼴은 Winetricks를 통해 원본 소스에서 직접 다운로드하여 설치해야 하며, 공개 저장소나 배포용 래퍼에는 글꼴 파일을 포함하지 않는 원칙을 준수합니다.

</details>

<a id="mods"></a>

## 5. Doorstop/BepInEx Mod 복구

전체 복구 사례는 케이스 스터디: [사례: Wine 10 / x86 《활협전》에서 일본어 Mod 로드 복구](cases/japanese-mod.ko.md)를 참조하십시오.

### Mod 부팅 과정과 아키텍처 규칙

Mod 프레임워크의 실행 흐름은 다음 3단계로 구성됩니다:
1. **Doorstop 개입**: 위장된 `winhttp.dll`이 게임 실행 즉시 진입점을 확보하고 Preloader를 호출합니다.
2. **Preloader 준비**: Unity 기반 어셈블리(corlibs)를 로드하고 런타임 환경을 초기화합니다.
3. **Chainloader 실행**: 체인로더가 준비되면 `BepInEx/plugins/` 디렉터리의 각 Mod 플러그인을 순차적으로 로드합니다.

아키텍처 규칙: 네이티브 진입점인 `winhttp.dll`은 과거 검증 빌드의 32비트(PE32) 실행 파일과 일치해야 합니다. 플러그인 디렉터리에 위치하는 매니지드 DLL(C# 컴파일 어셈블리)은 아키텍처 중립적일 수 있지만 플러그인 자체의 호환 규격 및 Unity 버전을 준수해야 합니다.

### Mod 설치 전 백업 및 안전 확인

각 Mod 압축 파일마다 다음 확인 절차를 진행합니다:
1. 압축 파일 내부 경로를 확인하여 절대 경로 및 `..` 경로 탐색 위험을 배제합니다.
2. `winhttp.dll` 등 네이티브 DLL이 x86(32비트) 아키텍처인지 검증합니다.
3. 덮어쓰게 될 기존 파일 목록을 작성합니다.
4. 모든 동명 파일을 타임스탬프가 지정된 백업 디렉터리에 보관합니다.
5. 압축 해제 및 병합 후 각 파일의 SHA-256 해시값을 대조합니다.
6. 게임을 실행하고 `LogOutput.log`의 수정 시각이 이번 실행 시각과 일치하는지 확인합니다(압축 파일에 남아 있던 이전 로그와의 혼동 방지).

### 1단계: Doorstop 로드

`winecfg → Libraries`에서 게임 실행 파일을 위한 설정을 추가합니다:

```text
winhttp = native,builtin
```

`Mortal.exe`에만 한정 적용되는 애플리케이션 수준의 DLL override 설정을 권장합니다. 게임 실행 시 프로세스에 로컬 `winhttp.dll`과 BepInEx Preloader가 로드되는지 확인합니다.

### 2단계: Unity 버전에 맞는 완전한 corlibs 배치

게임에 포함된 `Mortal_Data/Managed/mscorlib.dll`은 크기가 `3,906,048` 바이트로 스트립(일부 코드 제거)되어 있습니다. 반면 Unity `2020.3.49f1` 버전에 부합하는 완전한 비스트립(unstripped) 버전 크기는 `4,065,792` 바이트입니다.

적법한 경로로 확보한 완전한 corlibs를 다음 디렉터리에 배치합니다:

```text
BepInEx/unstripped_corlib/
```

`doorstop_config.ini` 파일을 편집합니다:

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs는 Unity 엔진 버전과 일치해야 하며 Unity의 소프트웨어 이용 규정을 준수해야 합니다. 공개 저장소와 Mod 배포물에는 corlibs 바이너리를 포함하지 않습니다.

### 3단계: Wine 수정 패치가 적용된 BepInEx 6 적용

교체 전 기존 `BepInEx/core` 디렉터리를 완전히 백업합니다. 코어 파일을 PR #1254 수정 패치가 포함된 x86 Mono 빌드 `6.0.0-be.785`로 교체합니다.

정상 로드 시 기록되는 로그 특징:

```text
BepInEx 6.0.0-be.785
Process bitness: 32-bit (x86)
Chainloader initialized
```

로그에 `Chainloader initialized`가 나타나면 Mod 프레임워크 초기화가 완료된 상태입니다. 이후 각 플러그인의 로드 로그가 순차적으로 기록됩니다. 검증된 과거 환경에서 DiceMaster 역시 `winhttp` override 미적용, corlibs 스트립, BepInEx 초기화 예외의 영향을 받았으나 본 섹션과 동일한 Doorstop / corlibs / BepInEx Wine 복구 경로를 거쳐 정상 로드되었습니다(이 결론은 검증된 특정 과거 빌드 조합에 한정되며 모든 기능과 향후 버전을 보장하는 것은 아닙니다).

<details markdown="1">
<summary>BepInEx 예외 로그 및 수정 패치 출처</summary>

이전 버전의 BepInEx 6은 Wine 32비트 환경에서 다음 예외를 일으킬 수 있습니다:

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

해당 문제는 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)에 보고되었으며 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)에서 수정되었습니다.

</details>

<a id="focus"></a>

## 6. 알려진 문제

### 창 전환 후 제목 표시줄 클릭으로 조작 복구

현상: 검증 환경에서 게임을 다른 macOS 앱으로 전환했다가 《활협전》으로 복귀했을 때, 화면 렌더링은 유지되지만 키보드, 마우스, 컨트롤러 입력이 게임 창 내부에서 반응하지 않는 경우가 발생합니다.

실제 검증된 즉시 복구 절차:
1. 《활협전》의 `Mortal` 창으로 다시 전환합니다.
2. 창 상단의 macOS 제목 표시줄(아래 그림의 빨간색 화살표가 가리키는 어두운 영역)을 1회 클릭합니다.
3. 게임 화면으로 돌아가 조작을 계속합니다.

![Mortal 창 제목 표시줄을 클릭해 게임 입력 복구](assets/window-titlebar-focus-recovery.png)

Steam 전역 오버레이와 《활협전》 개별 오버레이를 끄면 발생 빈도를 줄일 수 있습니다. 제목 표시줄 클릭은 현재 높은 신뢰도로 확인된 즉시 조작 복구 방법입니다. 근본 원인은 조사 중이며 Wine, Unity, macOS 사이의 창 포커스 인수인계 동작과 관련된 현상으로 판단됩니다.

| 게임 버전 | 발생 조건 | 결과 | 증거 | 신뢰도 |
| --- | --- | --- | --- | --- |
| Build `20337760` / `release_1.0.5000.13` | 다른 macOS 앱에서 Wine 게임 창으로 복귀 | `Mortal` 제목 표시줄 클릭 후 게임 조작 복구 | 실제 환경 재현 및 스크린샷 | 높음 |

<a id="daily"></a>

## 7. 운영 팁

- Steam 전역 설정 및 《활협전》 게임별 설정의 오버레이(Overlay)를 꺼서 앱 전환 시의 입력 잠금 발생 확률을 낮춥니다.
- 플레이 중에는 `caffeinate` 명령을 활용하여 Mac의 절전 전환을 방지합니다. 화면 덮개 닫힘, 화면 잠금, 외장 모니터 연결 변경이 발생한 경우 게임을 저장한 후 게임, Windows용 Steam, 래퍼 세션을 완전히 재시작하는 것을 권장합니다.
- 게임과 Steam을 종료할 때는 게임 내 저장을 완료한 후 Windows용 Steam 메뉴의 `Steam → Exit`를 통해 정상 종료하십시오. macOS Dock의 Wine 아이콘은 창 프록시 역할을 수행합니다.
- Wine을 재시작할 때는 게임을 저장하고 종료한 뒤 해당 게임의 래퍼 세션만 다시 시작합니다.
- Windows용 Steam을 장시간 백그라운드에 방치할 경우 `-applaunch` 명령에 반응하지 않을 수 있습니다. Steam의 `gameprocess_log.txt`에 기록이 갱신되지 않으면 해당 래퍼의 Steam 및 Wine 세션을 재시작하십시오.

<a id="diagnostics"></a>

## 8. 읽기 전용 검사기

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

이 스크립트는 래퍼 설정, 바이너리 아키텍처, Steam 매니페스트 파일, 레지스트리 설정, 글꼴 수, DXMT 모듈 해시값, BepInEx 로그, 실행 중인 프로세스를 읽기 전용으로 검사합니다(명령의 `/path/to/SteamWin.app`는 래퍼의 실제 경로를 대입하는 플레이스홀더입니다). 본 스크립트는 Wine, Steam, 게임 프로세스를 임의로 실행하거나 종료하지 않으며, 어떠한 파일도 변경하지 않습니다.

## 참고 자료

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine 수정 패치](https://github.com/BepInEx/BepInEx/pull/1254)
- [《활협전》 일본어 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
