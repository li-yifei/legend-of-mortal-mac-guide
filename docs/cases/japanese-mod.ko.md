---
layout: page
title: 사례: Wine 10 / x86 《활협전》에서 일본어 Mod 로드 복구
permalink: /docs/cases/japanese-mod.ko/
---

[한국어 가이드로 돌아가기](../guide.ko.md) · [繁體中文](../guide.zht.md) · [简体中文](japanese-mod.zhs.md) · [日本語](japanese-mod.ja.md)

## 결론

일본어 Mod v2.4 파일이 게임 디렉터리에 올바르게 배치되었음에도 플러그인 로드 프로세스는 Chainloader 초기화 전에 중단되었습니다. 최종적으로 정상 작동을 확인한 구성은 다음과 같습니다.

- `Mortal.exe` 전용 애플리케이션 수준 DLL override: `winhttp = native,builtin`
- Unity `2020.3.49f1` 버전과 정확히 일치하는 원본 전체(Unstripped) corlibs
- `BepInEx/unstripped_corlib`를 최우선으로 검색하도록 지정한 Doorstop 설정
- BepInEx의 Wine 초기화 패치(PR #1254)가 적용된 x86 Mono 빌드 `6.0.0-be.785`
- BepInEx 기본 매니지드 진입점(`Application::.cctor`)
- 게임 내 언어 설정: '중국어 간체'

복구 후 Chainloader가 5개 플러그인을 성공적으로 로드하였으며, 72,977행의 일본어 텍스트가 정상적으로 인젝션(주입)되었습니다. 해당 환경에서 함께 동작하지 않던 DiceMaster 모듈 역시 동일한 Doorstop / corlibs / BepInEx Wine 복구 경로(애플리케이션 전용 DLL override, 일치하는 완전한 Unity corlibs, 패치된 BepInEx 코어)를 통해 정상적으로 로드 및 작동합니다.

## 검증 조건

| 항목 | 조건 |
| --- | --- |
| 게임 | Steam AppID `1859910`, Build ID `20337760` |
| Unity | `2020.3.49f1` |
| 프로세스 아키텍처 | `Mortal.exe`, PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [일본어 Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 기존 BepInEx | `6.0.0-be.692` |
| 검증 성공 버전 | `6.0.0-be.785` x86 Mono |
| 검증일 | 2026-08-29 |

## 1. 압축 파일 안전성 및 무결성 검사

설치 전 ZIP 압축 파일의 무결성, 절대 경로 포함 여부, `..` 경로 탐색(Path Traversal) 위험, 외곽 디렉터리 구조, 네이티브 DLL의 x86(32비트) 호환성 및 기존 파일과의 충돌 가능성을 면밀히 검사했습니다. 최초 다운로드 시 서로 다른 이어받기 도구가 혼용되어 Central Directory가 손상되는 문제가 발생하였으나, 단일 다운로더를 통해 완전한 ZIP 압축 파일을 다시 내려받아 무결성 검증을 마쳤습니다.

덮어쓸 대상 파일은 모두 타임스탬프가 지정된 백업 디렉터리에 사전 보관하였으며, 압축 해제 및 병합 후 파일 해시값을 재검증하여 기존 DiceMaster DLL 및 설정 파일의 해시값이 온전하게 유지됨을 확인했습니다.

## 2. Doorstop 로드

`winecfg`의 라이브러리(Libraries) 설정에서 `Mortal.exe`에 대한 애플리케이션 전용 DLL override를 추가했습니다.

```text
winhttp = native,builtin
```

이를 통해 로컬 `winhttp.dll`과 Preloader가 프로세스에 정상 로드되었습니다. 그러나 로드 과정은 여전히 Chainloader 초기화 단계에 진입하지 못하고 중단되었으며, 다음 원인이 매니지드(Managed) 진입점 측에 있음을 확인했습니다.

## 3. 완전한 Unity corlibs 사용

```text
게임 기본 mscorlib.dll          3,906,048 bytes
Unity 2020.3.49 전체 버전       4,065,792 bytes
```

정상적인 경로로 확보한 동일 Unity 버전의 원본 전체(Unstripped) corlibs를 `BepInEx/unstripped_corlib/` 디렉터리에 배치하고 `doorstop_config.ini`를 다음과 같이 설정했습니다.

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

상세 로그를 통해 Preloader 호출 및 `Done` 출력을 확인했습니다. corlibs는 Unity 엔진 버전을 엄격히 일치시켜야 하며, Unity 소프트웨어 라이선스 조항을 준수하여 확보 및 사용해야 합니다.

## 4. BepInEx의 Wine 초기화 예외 해결

Preloader 실행 후 다음과 같은 예외가 발생했습니다.

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

이는 BepInEx가 Wine/Proton 환경에서 초기화될 때 발생하는 알려진 문제입니다.

- [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)
- [수정 PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)

기존 `BepInEx/core` 디렉터리를 완전히 백업한 후, PR #1254 수정 패치가 포함된 x86 Mono 빌드 `6.0.0-be.785` 전체로 교체했습니다. 진입점은 기본값인 `Application::.cctor`로 복원했습니다.

## 5. 최종 검증

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

성공적으로 로드된 플러그인 목록:

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

DiceMaster 및 일본어 Mod 플러그인(총 5개)이 Chainloader에 의해 정상 로드되었으며, 72,977행의 일본어 텍스트가 정상적으로 인젝션(주입)되고 새로운 Error/Fatal 로그가 발생하지 않음을 확인했습니다. DiceMaster를 단독으로 사용하는 경우에도 macOS/Wine 환경에서의 장애 원인(Doorstop 미로드, corlibs 스트립으로 인한 Preloader 중단, BepInEx 플랫폼 초기화 예외)은 완전히 동일하므로, 본 문서의 동일한 Doorstop / corlibs / BepInEx Wine 복구 경로를 통해 정상 작동합니다. 게임 내 언어 설정은 '중국어 간체(简体中文)'를 선택하십시오. 게임 내에서 `F5` 키로 인명 후리가나(루비) 표시를 전환하고, `F7` 키로 표시 모드를 전환할 수 있습니다.

## 6. 롤백 경계

Mod 적용 전, corlibs 설정 전, `be.785` 교체 전의 3단계 백업을 독립적으로 유지합니다. 롤백(복원) 작업을 진행할 때는 반드시 게임, Windows용 Steam 및 해당 래퍼의 wineserver 프로세스를 완전히 종료한 상태에서 동일 계층의 파일 전체를 복원하십시오. 서로 다른 BepInEx 빌드의 core DLL 파일을 혼용해서는 안 됩니다.
