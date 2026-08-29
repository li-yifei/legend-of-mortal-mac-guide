# 사례: Wine 10 / x86 《활협전》에서 일본어 Mod 로드 복구

[한국어 가이드로 돌아가기](../guide.ko.md) · [繁體中文](../guide.zht.md) · [简体中文](japanese-mod.zhs.md) · [日本語](japanese-mod.ja.md)

## 결론

일본어 Mod v2.4 파일은 게임 디렉터리에 올바르게 배치되어 있었으나, 플러그인 로드 프로세스는 Chainloader 초기화 전에 멈춰 있었습니다. 최종적으로 정상 동작에 도달한 구성은 다음과 같습니다.

- `Mortal.exe`에 한정한 `winhttp = native,builtin` DLL override 설정;
- Unity `2020.3.49f1` 버전과 완전히 일치하는 전체 corlibs;
- `BepInEx/unstripped_corlib`를 최우선으로 검색하는 Doorstop 설정;
- BepInEx의 Wine 초기화 수정(PR #1254)이 포함된 x86 Mono 버전 `6.0.0-be.785`;
- BepInEx 기본 진입점(`Application::.cctor`);
- 게임 내 언어 설정: 중국어 간체.

복구 후 Chainloader가 5개 플러그인을 정상적으로 로드하였고 일본어 텍스트 72,977줄이 주입(인젝션)되었습니다. 이전에 작동하지 않던 DiceMaster 역시 동일한 Doorstop / corlibs / BepInEx Wine 복구 절차(DLL override, 완전한 Unity corlibs, 수정된 BepInEx 코어)를 통해 정상적으로 로드 및 동작하게 되었습니다.

## 검증 조건

| 항목 | 조건 |
| --- | --- |
| 게임 | Steam AppID `1859910`, Build ID `20337760` |
| Unity | `2020.3.49f1` |
| 프로세스 | `Mortal.exe`, PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [일본어 Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 이전 BepInEx | `6.0.0-be.692` |
| 동작 버전 | `6.0.0-be.785` x86 Mono |
| 검증일 | 2026-08-29 |

## 1. 아카이브 안전성 검사

ZIP 무결성, 절대 경로, `..` 경로 탐색(Path Traversal) 위험, 외부 디렉터리 구조, 네이티브 DLL의 x86 호환성, 기존 파일과의 충돌을 확인했습니다. 첫 다운로드 시 서로 다른 이어받기 방식이 혼재되어 Central Directory가 손상되었습니다. 단일 클라이언트로 다시 내려받은 완전한 ZIP 아카이브만 사용했습니다.

덮어쓸 기존 파일을 타임스탬프 백업 디렉터리에 저장하고, 병합 후 해시값을 재검증했습니다. 기존 DiceMaster DLL 및 설정 파일의 해시값이 유지되었음을 확인했습니다.

## 2. Doorstop 로드

`winecfg`의 라이브러리 설정에서 `Mortal.exe`에 대한 애플리케이션 전용 DLL override를 추가했습니다.

```text
winhttp = native,builtin
```

이를 통해 로컬 `winhttp.dll`과 Preloader가 프로세스에 정상 로드되었습니다. 그러나 처리는 여전히 Chainloader 초기화 전에 멈춰 있었으며, 매니지드 진입점 측에 다음 장애 요인이 있음을 확인했습니다.

## 3. 완전한 Unity corlibs 사용

```text
게임 기본 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 전체 버전    4,065,792 bytes
```

정식 절차로 확보한 동일 Unity 버전의 완전한 corlibs를 `BepInEx/unstripped_corlib/`에 배치하고 `doorstop_config.ini`를 설정했습니다.

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

상세 로그에서 Preloader 호출 및 `Done` 출력을 확인했습니다. corlibs는 Unity 버전을 엄격히 일치시키고 Unity 라이선스 조항을 준수하여 확보·사용해야 합니다.

## 4. BepInEx의 Wine 초기화 오류 복구

Preloader 실행 후 다음 예외가 발생했습니다.

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

이는 BepInEx의 Wine/Proton 환경 초기화 단계에서 발생하는 알려진 문제입니다.

- [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)
- [수정 PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)

기존 `BepInEx/core`를 완전히 백업한 후, PR #1254 수정이 포함된 x86 Mono 빌드 `6.0.0-be.785` 일체로 교체했습니다. 진입점은 기본 `Application::.cctor`로 복원했습니다.

## 5. 최종 확인

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

DiceMaster 및 일본어 Mod 플러그인(총 5개)이 Chainloader에 의해 정상 로드되었으며, 일본어 텍스트 72,977줄의 주입(인젝션) 성공 및 새로운 Error/Fatal 로그가 발생하지 않음을 확인했습니다. DiceMaster를 단독으로 사용하는 경우에도 장애 요인(Doorstop 미로드, corlibs 스트립, BepInEx Wine 초기화 예외)은 동일하므로 완전히 동일한 Doorstop / corlibs / BepInEx Wine 복구 절차를 통해 정상 동작합니다. 게임 내 언어는 '중국어 간체'를 선택하고, 게임 중 `F5` 키로 이름 후리가나(루비), `F7` 키로 표시 모드를 전환할 수 있습니다.

## 6. 롤백 경계

Mod 도입 전, corlibs 설정 전, `be.785` 업데이트 전의 3단계 백업을 유지합니다. 복원 작업을 진행할 때는 반드시 게임, Windows용 Steam 및 해당 래퍼의 wineserver를 종료한 상태에서 동일 레이어 일체를 복원하십시오. 서로 다른 BepInEx 빌드의 core DLL을 혼합해서는 안 됩니다.
