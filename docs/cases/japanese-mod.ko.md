---
layout: page
title: 사례: Wine 10 / x86 《활협전》에서 일본어 Mod 로드 복구
permalink: /docs/cases/japanese-mod.ko/
---

[한국어 가이드로 돌아가기](../guide.ko.md) · [繁體中文](../guide.zht.md) · [简体中文](japanese-mod.zhs.md) · [日本語](japanese-mod.ja.md)

> 이 문서는 2026-08-29, Build `20337760`에서 검증한 구버전 절차이며 32비트 구성 요소 선택은 해당 환경을 기준으로 합니다. 게임 1.06(Build `25953419`)의 64비트 진입점 복구는 [1.06 업데이트 사례](game-1.06.ko.md)를 참고하십시오. 각 기능의 검증 범위도 해당 문서에 구분해 두었습니다.

본 문서는 macOS Wine 환경에서 일본어 Mod v2.4를 적용한 실기 검증 사례를 바탕으로, 문제 파악부터 3단계 복구, 동작 검증, 롤백 보호까지의 실제 과정을 다룹니다.

## 핵심 용어 안내

| 용어 | 설명 |
| --- | --- |
| Doorstop | 시작 진입점 주입 도구. 위장된 `winhttp.dll`을 통해 게임 실행 시점에 개입하여 Preloader를 호출합니다. |
| corlibs | Unity Mono 런타임의 기본 클래스 라이브러리. 불필요한 코드가 제거된 스트립(stripped) 버전과 완전한 비스트립(unstripped) 버전이 있습니다. |
| BepInEx | Unity 게임용 범용 Mod 플러그인 로드 및 관리 프레임워크입니다. |
| Preloader | BepInEx의 사전 로더. 게임 본체 로직이 실행되기 전에 런타임 환경을 초기화하고 필수 종속성을 준비합니다. |
| Chainloader | BepInEx의 체인 로더. `BepInEx/plugins/` 디렉터리에 있는 개별 Mod 플러그인을 순차적으로 로드합니다. |

## 검증 조건

| 항목 | 조건 |
| --- | --- |
| 게임 | Steam AppID `1859910`, Build ID `20337760` |
| Unity | `2020.3.49f1` |
| 프로세스 아키텍처 | `Mortal.exe`, PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [일본어 Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 이전 BepInEx | `6.0.0-be.692` |
| 동작 확인 버전 | `6.0.0-be.785` x86 Mono |
| 검증일 | 2026-08-29 |

## 1. 발생 문제 및 압축 파일 안전성 검사

일본어 Mod v2.4를 게임 디렉터리에 압축 해제한 직후, 게임 자체는 정상 실행되었으나 일본어 번역이 전혀 반영되지 않았습니다. 로그를 확인한 결과 로드 흐름이 Chainloader 초기화 전에 멈춰 있었습니다.

설치 및 문제 분석 전에 Mod 압축 파일의 안전성 검사를 진행했습니다:
1. ZIP 압축 파일의 무결성을 검증하여 파일 손상을 방지합니다.
2. 압축 파일 내부 경로를 확인하여 절대 경로 및 `..` 경로 탐색 위험을 배제합니다.
3. 압축 파일 내 네이티브 DLL이 32비트(x86) 아키텍처인지 확인합니다.
4. 덮어쓰게 될 기존 파일을 타임스탬프가 지정된 독립 디렉터리에 백업합니다.
5. 압축 해제 및 병합 후 파일 해시값을 대조하여 기존 DiceMaster DLL과 설정 파일이 유지되었음을 확인합니다.

## 2. 3단계 복구 절차와 원인 분석

### 1단계: Doorstop 로드 (진입점 미개입 문제 해결)

원인 분석: Wine은 기본적으로 내장 `winhttp.dll`을 우선 로드하므로, 게임 디렉터리에 배치한 Mod 부팅용 `winhttp.dll`이 실행되지 않습니다.

조치 방법: `winecfg`의 라이브러리(Libraries) 설정에서 `Mortal.exe`에 애플리케이션 수준의 DLL override 설정을 추가합니다:

```text
winhttp = native,builtin
```

동작 결과: 프로세스에 로컬 `winhttp.dll`이 로드되고 Preloader가 호출되었습니다. 다만 로드 흐름은 여전히 Chainloader 직전에 중단되어 다음 장애 요인이 있음을 확인했습니다.

### 2단계: Unity 버전에 맞는 완전한 corlibs 배치 (기본 라이브러리 누락 해결)

원인 분석: 게임에 포함된 Mono 라이브러리는 스트립 버전이므로 BepInEx 초기화에 필요한 완전한 API 시그니처가 부족했습니다.

```text
게임 기본 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 전체 버전    4,065,792 bytes
```

조치 방법: Unity `2020.3.49f1` 버전에 부합하는 완전한 비스트립 corlibs를 정식 절차로 확보하여 `BepInEx/unstripped_corlib/`에 배치하고 `doorstop_config.ini`에 검색 경로를 지정합니다:

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

동작 결과: Preloader가 정상 실행되고 로그에 `Done`이 출력되었습니다. corlibs는 Unity 엔진 버전과 일치해야 하며 Unity의 소프트웨어 이용 규정을 준수하여 사용합니다.

### 3단계: Wine 수정이 포함된 BepInEx 6으로 교체 (플랫폼 감지 예외 해결)

원인 분석: 이전 버전인 BepInEx `6.0.0-be.692`는 Wine 32비트 환경에서 플랫폼 도우미 클래스를 초기화할 때 예외를 발생시켰습니다:

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

해당 문제는 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)에 기록되었으며 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)에서 수정되었습니다.

조치 방법: 기존 `BepInEx/core` 디렉터리를 완전히 백업한 후, 해당 PR 수정이 포함된 x86 Mono 빌드 `6.0.0-be.785`로 교체합니다. 진입점은 기본 `Application::.cctor`를 유지합니다.

## 3. 검증 성공 및 플러그인 동작 상태

위 3가지 복구 작업을 완료하고 게임을 실행한 결과, Mod 프레임워크와 플러그인이 정상 로드되었습니다.

프레임워크 초기화 완료 로그:

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

로드된 플러그인 목록:

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

실행 검증 결과:
- Chainloader가 5개 플러그인을 모두 정상적으로 로드했습니다.
- 로그 출력으로 72,977줄의 일본어 텍스트 주입을 확인했습니다.
- 로그에 새로운 Error 또는 Fatal 수준의 예외가 발생하지 않았습니다.
- 게임 내 언어 설정을 '중국어 간체'로 선택하면 일본어 자막이 표시됩니다.
- 게임 중 `F5` 키로 이름 후리가나(루비) 표시를 전환하고, `F7` 키로 표시 모드를 전환할 수 있습니다.
- 본 테스트 환경에서 DiceMaster 모드 역시 winhttp override 부재, corlibs 스트립, BepInEx 초기화 오류의 영향을 받았으나 동일한 복구 경로를 거쳐 정상 로드되었습니다.

### 과거 환경 실측 요약

| 검증 항목 | 검증 환경 및 조건 | 결과 | 증거 및 기록 | 신뢰도 |
| --- | --- | --- | --- | --- |
| 일본어 Mod v2.4 로드 | Build `20337760`, Wine `10.0`, x86 PE32 | 5개 플러그인 정상 로드 완료 | BepInEx 로그에서 Chainloader initialized 및 72,977줄 텍스트 주입 확인 | 높음 |
| DiceMaster 모드 로드 | 동일 환경 및 동일 복구 절차 | 플러그인 정상 로드 및 초기화 | 로그에 `DiceMaster 1.0.0` 출력 및 비정상 종료 없음 | 높음 |

## 4. 롤백 및 안전 경계

안전한 원상태 복구를 위해 3단계 백업을 유지합니다:
1. **Mod 도입 전 백업**: 순수한 게임 디렉터리 보존;
2. **corlibs 설정 전 백업**: 원본 `doorstop_config.ini` 보존;
3. **be.785 교체 전 백업**: 원본 `BepInEx/core` 디렉터리 보존.

롤백 실행 요구사항: 파일을 복원하기 전에 반드시 게임 내 저장을 완료하고 게임, Windows용 Steam, 해당 래퍼의 wineserver 프로세스를 완전히 종료하십시오. 복원 시에는 동일 단계의 파일을 일체로 되돌리고 서로 다른 BepInEx 빌드의 코어 DLL을 혼합하지 않도록 하십시오.
