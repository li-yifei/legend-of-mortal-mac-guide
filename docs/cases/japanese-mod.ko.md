---
layout: page
title: 사례: Wine 10 / x86 《활협전》에서 일본어 Mod 로드 복구
permalink: /docs/cases/japanese-mod.ko/
---

[한국어 가이드로 돌아가기](../guide.ko.md) · [繁體中文](../guide.zht.md) · [简体中文](japanese-mod.zhs.md) · [日本語](japanese-mod.ja.md)

## 결론

macOS 환경에서 Wine 10.0을 통해 32비트(x86) 《활협전》을 실행할 때, 일본어 Mod v2.4 및 DiceMaster 압축 파일을 게임 디렉터리에 해제하더라도 기본 상태에서는 로드에 실패합니다. 근본 원인은 **Wine의 DLL 오버라이드 미적용**, **게임 기본 corlibs의 스트립(제거)으로 인한 Preloader 중단**, 그리고 **구버전 BepInEx 6의 Wine 환경 플랫폼 초기화 예외**라는 3중 장애 요인 때문입니다.

애플리케이션 전용 `winhttp` override 설정, Unity `2020.3.49f1` 버전과 일치하는 원본 전체(Unstripped) corlibs 배치 및 탐색 경로 설정, Wine 초기화 패치가 적용된 BepInEx `6.0.0-be.785`(x86 Mono) 코어로 교체함으로써 로드 체인을 정상화할 수 있습니다. 이를 통해 Chainloader가 5개 플러그인을 모두 정상 로드하고 72,977행의 일본어 텍스트 주입을 완료합니다.

해당 환경에서 함께 작동하지 않던 **DiceMaster 모듈** 역시 동일한 BepInEx 런타임 환경에 기반하므로, **본 사례의 동일한 Doorstop / corlibs / BepInEx Wine 복구 경로를 통해 정상적으로 로드 및 작동합니다**.

## 적용 조건

| 항목 | 적용 / 검증 조건 |
| --- | --- |
| 게임 버전 | Steam AppID `1859910`, Build ID `20337760` (`release_1.0.5000.13`) |
| Unity 엔진 | `2020.3.49f1` |
| 프로세스 아키텍처 | `Mortal.exe`, PE32 / x86 (32비트) |
| 실행 환경 | Sikarugir Wine `10.0` (64비트 Prefix / 32비트 DXMT) |
| 대상 Mod | [일본어 Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/), DiceMaster 1.0.0 |
| BepInEx 버전 | 초기 `6.0.0-be.692` → 수정 검증 버전 `6.0.0-be.785` x86 Mono |
| 검증일 | 2026-08-29 |

## 최단 복구 경로

1. **DLL Override 설정**: `winecfg`의 라이브러리(Libraries) 탭에서 `Mortal.exe`에 대해 `winhttp = native,builtin`을 추가합니다.
2. **Unstripped corlibs 배치**: Unity `2020.3.49f1` 버전의 원본 전체(Unstripped) corlibs를 `BepInEx/unstripped_corlib/`에 배치하고, `doorstop_config.ini`에 `dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"`를 설정합니다.
3. **BepInEx Core 업그레이드**: `BepInEx/core` 디렉터리를 Wine 초기화 패치(PR #1254)가 포함된 x86 Mono 빌드 **`6.0.0-be.785`**로 일괄 교체합니다(진입점은 기본값인 `Application::.cctor` 유지).
4. **게임 내 언어 설정**: 게임을 실행하고 게임 내 설정에서 언어를 '중국어 간체(简体中文)'로 지정합니다.

## 성공 판정 기준

- [x] **로그 정상 출력**: `BepInEx/LogOutput.log`에 `BepInEx 6.0.0-be.785`, `Process bitness: 32-bit (x86)`, `Chainloader initialized`가 기록됨.
- [x] **5개 플러그인 로드 완료**: 모든 플러그인(`plugin by Binarizer 1.0.0`, `DiceMaster 1.0.0`, `LOM JP Font Patch 0.2.44`, `LOM JP Ruby Prototype 0.15.113`, `LOM JP String Vault 0.1.0`)이 오류 없이 로드됨.
- [x] **텍스트 및 단축키 동작**: 게임 내 72,977행의 텍스트가 정상 치환 주입되고 Error/Fatal 오류가 발생하지 않음. 게임 내에서 `F5` 키로 루비(후리가나) 표시 전환, `F7` 키로 표시 모드 전환 가능.
- [x] **DiceMaster 정상 작동**: 게임 내에서 DiceMaster 콘솔 및 기능이 정상적으로 호출 및 동작함.

---

## 1. 문제 현상 및 근본 원인

### 문제 현상

일본어 Mod v2.4 또는 DiceMaster 압축 파일을 게임 디렉터리에 해제한 후 게임을 실행하면 다음과 같은 문제가 발생합니다.
- 게임은 정상 실행되나 Mod가 전혀 적용되지 않고 언어가 중국어로 유지되며 Mod UI가 나타나지 않음.
- `BepInEx/LogOutput.log` 파일이 생성되지 않거나 갱신되지 않으며, Preloader 단계에서 조용히 실행이 중단됨.
- 디버그 콘솔을 활성화한 경우 초기화 도중 `PlatformHelper.Current` 예외가 발생하며 중단됨.

### 근본 원인 분석

Mod 로드 실패는 다음 3가지 기술적 요인이 연쇄 작용하여 발생합니다.
1. **Doorstop 인젝션 미작동**: Wine의 기본 동작은 내장(builtin) `winhttp.dll`을 우선 로드하므로 게임 디렉터리의 네이티브(native) Doorstop 프록시 DLL이 무시되어 Preloader가 실행되지 않습니다.
2. **corlibs 스트립(Strip) 처리**: 게임에 포함된 `mscorlib.dll`(약 3.90MB)은 메타데이터와 타입 정의가 축소되어 있어 BepInEx Preloader의 리플렉션 및 어셈블리 해석 과정에서 조용히 실패합니다.
3. **BepInEx 6의 Wine 플랫폼 초기화 결함**: 구버전 빌드(`6.0.0-be.692` 등)는 Wine 32비트 환경에서 플랫폼 아키텍처 식별 로직 오류로 인해 읽기 전용 속성 중복 할당 예외를 발생시킵니다.

<details>
<summary>기술 세부사항: 예외 스택 추적 및 호출 체인 분석</summary>

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
  at BepInEx.PlatformHelper.set_Current (BepInEx.PlatformHelper+Platform value)
  at BepInEx.Unity.Mono.Preloader.Preloader.Run ()
```

- **이슈 추적**: [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)에 보고되었으며 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)에서 수정되었습니다.
- **Doorstop 후킹 원리**: Windows용 Unity 프로세스는 시작 시 `winhttp.dll`을 동적 로드합니다. Doorstop은 동일한 이름의 DLL 후킹을 통해 Unity Mono 런타임 초기화 직전에 Preloader를 주입하고, Preloader가 Chainloader를 호출하여 플러그인을 로드합니다.

</details>

---

## 2. 장애 점검 및 사전 진단

복구 작업을 진행하기 전 다음 항목을 차례대로 점검합니다.

1. **프로세스 아키텍처 확인**: `Mortal.exe`가 32비트(PE32 / x86) 실행 파일인지 확인합니다.
2. **DLL Override 등록 상태 점검**: Wine prefix 레지스트리 또는 `winecfg`에서 `Mortal.exe`에 대한 `winhttp` 설정 여부를 확인합니다.
3. **corlibs 파일 크기 대조**: 게임 디렉터리의 `mscorlib.dll`과 원본 전체 버전의 크기를 비교합니다.
4. **BepInEx Core 버전 확인**: `BepInEx/core` 내 어셈블리가 Wine 초기화 패치가 적용된 버전인지 확인합니다.
5. **Mod 압축 파일 안전성 점검**: 압축 해제 전 내부에 절대 경로 및 `..` 경로 탐색(Path Traversal) 구조가 없는지 확인하고 네이티브 DLL이 x86용인지 검증합니다.

<details>
<summary>기술 세부사항: 압축 파일 보안 점검 및 파일 대조 목록</summary>

- **파일 크기 비교**:
  ```text
  게임 기본 mscorlib.dll          3,906,048 bytes (스트립 버전 / Stripped)
  Unity 2020.3.49 전체 버전       4,065,792 bytes (원본 전체 / Unstripped)
  ```
- **라이선스 및 안전 경계**: corlibs는 Unity 엔진 버전(`2020.3.49f1`)과 엄격히 일치해야 하며, Unity 소프트웨어 사용권 계약을 준수하여 합법적인 경로로 확보해야 합니다. 공개 저장소 및 배포 패키지는 폰트 및 corlibs 무재배포 원칙을 유지합니다.
- **해시 검증 및 백업**: 파일 덮어쓰기 전 기존 DiceMaster DLL 및 설정 파일의 SHA-256 해시를 확인하고 백업하여 설정 손실을 방지합니다.

</details>

---

## 3. 단계별 복구 절차

### 1단계: 애플리케이션 전용 DLL Override 설정

해당 Wine prefix의 `winecfg`를 실행합니다.
1. **라이브러리(Libraries)** 탭으로 이동합니다.
2. **애플리케이션(Applications)** 목록에서 `Mortal.exe`를 추가하고 선택합니다.
3. **라이브러리 오버라이드 새로 만들기(New override for library)** 에 `winhttp`를 입력하고 추가합니다.
4. 로드 순서가 다음과 같이 설정되었는지 확인합니다.
   ```text
   winhttp = native,builtin
   ```

### 2단계: Unity 2020.3.49f1 원본 corlibs 배치 및 Doorstop 구성

1. 게임 루트 디렉터리의 `BepInEx` 폴더 내에 `unstripped_corlib` 디렉터리를 생성합니다.
   ```text
   BepInEx/unstripped_corlib/
   ```
2. Unity `2020.3.49f1` 버전과 정확히 일치하는 원본 전체(Unstripped) corlibs를 해당 폴더에 복사합니다.
3. 게임 루트 디렉터리의 `doorstop_config.ini` 파일을 생성하거나 수정하여 다음과 같이 작성합니다.
   ```ini
   [General]
   enabled = true
   target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

   [UnityMono]
   dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
   ```

### 3단계: BepInEx Core를 패치 버전(6.0.0-be.785)으로 업그레이드

1. 기존 `BepInEx/core` 폴더 전체를 백업합니다.
2. `BepInEx/core` 디렉터리를 PR #1254 패치가 적용된 x86 Mono 빌드 **`6.0.0-be.785`** 파일 일체로 교체합니다.
3. 매니지드 진입점은 기본값인 `Application::.cctor`를 유지합니다.

### 4단계: 게임 내 언어 설정

1. 게임을 실행하고 메인 메뉴의 설정으로 이동합니다.
2. 언어를 **'중국어 간체(简体中文)'** 로 선택합니다(일본어 Mod는 간체 중국어 텍스트 파이프라인에 후킹됩니다).

<details>
<summary>기술 세부사항: Doorstop 설정 항목 및 Mono 어셈블리 탐색 메커니즘</summary>

- `dll_search_path_override` 매개변수는 Mono 런타임이 핵심 어셈블리를 로드할 때 `BepInEx\unstripped_corlib`를 최우선 검색하도록 지정하여 `Mortal_Data\Managed`의 스트립 어셈블리를 재정의합니다.
- 기본 진입점인 `Application::.cctor`는 Unity 엔진의 `UnityEngine.Application` 클래스 정적 생성자가 실행될 때 Preloader를 호출하므로 가장 안정적인 호환성을 제공합니다.

</details>

---

## 4. 동작 검증 및 실행 테스트

### 1. 로그 정상 출력 확인

게임을 실행한 후 `BepInEx/LogOutput.log` 파일을 열어 다음 내용이 기록되었는지 확인합니다.

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

### 2. 플러그인 로드 목록 확인

Chainloader가 5개 플러그인을 오류(Error/Fatal) 없이 모두 로드했는지 확인합니다.

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

### 3. 게임 내 기능 및 단축키 검증

- **텍스트 주입**: 게임 본편에 진입하여 UI 및 대화 텍스트가 일본어로 정상 표시되는지(72,977행 주입 완료) 확인합니다.
- **단축키 동작**:
  - **`F5`**: 인명 루비(후리가나) 표시 전환.
  - **`F7`**: 표시 모드 전환.

### 4. DiceMaster 및 다중 Mod 공존 안내

**DiceMaster 모듈**은 일본어 Mod와 동일한 BepInEx 6 프레임워크 기반에서 동작합니다. Wine 환경에서 DiceMaster를 단독으로 적용할 때 발생하는 장애 원인(`winhttp` 미후킹, corlibs 스트립으로 인한 Preloader 중단, BepInEx 플랫폼 예외)은 완전히 동일합니다. 따라서 **본 복구 절차를 적용하면 DiceMaster 역시 일본어 Mod와 함께 정상적으로 로드 및 동작합니다**.

<details>
<summary>기술 세부사항: 전체 검증 로그 출력</summary>

```text
[Message:   BepInEx] BepInEx 6.0.0-be.785 - Mortal
[Info   :   BepInEx] System platform: Windows 10 (Wine 10.0) 64-bit
[Info   :   BepInEx] Process bitness: 32-bit (x86)
[Message:   BepInEx] Preloader started
[Info   :   BepInEx] Loaded 1 patcher method from [BepInEx.Preloader 6.0.0.785]
[Info   :   BepInEx] 1 patcher result: 1 patch applied
[Message:   BepInEx] Preloader finished
[Message:   BepInEx] Chainloader ready
[Message:   BepInEx] Chainloader initialized
[Info   :   BepInEx] Loading [plugin by Binarizer 1.0.0]
[Info   :   BepInEx] Loading [DiceMaster 1.0.0]
[Info   :   BepInEx] Loading [LOM JP Font Patch 0.2.44]
[Info   :   BepInEx] Loading [LOM JP Ruby Prototype 0.15.113]
[Info   :   BepInEx] Loading [LOM JP String Vault 0.1.0]
```

</details>

---

## 5. 롤백 경계 및 안전 조치

### 3단계 롤백 경계

복구 작업 중 문제 발생 시 단계별로 안전하게 상태를 되돌릴 수 있도록 경계를 유지합니다.

1. **1단계: Mod 설치 전 원본 상태로 복원**
   - 게임 디렉터리의 `BepInEx`, `doorstop_config.ini`, `winhttp.dll` 및 Mod 리소스 파일을 삭제합니다.
   - 사전 백업한 원본 게임 파일을 복원합니다.
2. **2단계: corlibs 설정 전 상태로 복원**
   - `BepInEx/unstripped_corlib` 디렉터리를 삭제합니다.
   - `doorstop_config.ini`의 `dll_search_path_override` 설정을 초기화하거나 제거합니다.
3. **3단계: BepInEx Core 교체 전 상태로 복원**
   - `BepInEx/core` 디렉터리를 삭제합니다.
   - 백업해 둔 기존 `BepInEx/core`(`be.692` 등) 폴더를 복원합니다.

### 안전 작업 수칙

- **프로세스 완전 종료**: 파일 백업, 덮어쓰기 또는 롤백 전 반드시 게임, Windows용 Steam 및 해당 prefix의 wineserver 프로세스를 완전히 종료(`wineserver -k`)하십시오.
- **원자적 일괄 교체**: `BepInEx/core` 복원 및 교체 시 디렉터리 단위로 작업하며 서로 다른 빌드의 DLL을 혼용하지 마십시오.
- **인증 정보 격리**: Mod 설치 및 트러블슈팅 과정에서 Steam 계정 토큰이나 로그인 인증 정보에는 일체 접근하지 않습니다.

<details>
<summary>기술 세부사항: Wineserver 프로세스 정리 및 보안 경계</summary>

- **Wine 세션 종료 명령**:
  ```bash
  wineserver -k
  ```
- **프로세스 정리 확인**: `Mortal.exe`, `Steam.exe`, `wineserver` 프로세스가 완전히 종료된 후 파일 복원 및 덮어쓰기 작업을 진행하십시오.
</details>
