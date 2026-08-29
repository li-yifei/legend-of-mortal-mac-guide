# 사례: Wine 10 / x86 《활협전》에서 일본어 Mod 로드 복구

[한국어 가이드로 돌아가기](../guide.ko.md) · [简体中文](japanese-mod.zh-CN.md) · [日本語](japanese-mod.ja.md)

## 결론

일본어 Mod v2.4 파일은 게임 디렉터리에 올바르게 병합되어 있었습니다. 플러그인 로드는 Chainloader 초기화 전에 멈췄습니다. 최종 동작 구성은 다음과 같습니다.

- `Mortal.exe` 전용 `winhttp = native,builtin`;
- Unity `2020.3.49f1`과 일치하는 전체 corlibs;
- `BepInEx/unstripped_corlib`를 우선하는 Doorstop 설정;
- BepInEx Wine 수정 PR #1254를 포함한 x86 Mono `6.0.0-be.785`;
- BepInEx 기본 `Application::.cctor` 진입점;
- 게임 언어를 중국어 간체로 설정.

복구 후 Chainloader가 5개 플러그인을 로드했고 일본어 문자열 72,977줄이 주입되었습니다. 장기간 작동하지 않던 DiceMaster도 같은 원인 수정으로 복구되었습니다.

## 검증 조건

| 항목 | 조건 |
| --- | --- |
| 게임 | AppID `1859910`, Build ID `20337760` |
| Unity | `2020.3.49f1` |
| 프로세스 | `Mortal.exe`, PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [일본어 Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 이전 BepInEx | `6.0.0-be.692` |
| 최종 BepInEx | `6.0.0-be.785` x86 Mono |
| 검증일 | 2026-08-29 |

## 1. 아카이브 안전 검사

ZIP 무결성, 절대 경로, `..`, 외부 디렉터리, native DLL의 x86 호환성, 기존 파일 충돌을 검사했습니다. 첫 다운로드는 서로 다른 재개 방식을 섞어 중앙 디렉터리가 손상되었습니다. 단일 다운로더로 다시 받은 ZIP만 사용했습니다.

덮어쓸 파일을 타임스탬프 백업 디렉터리에 저장하고 병합 후 해시를 확인했습니다. DiceMaster DLL과 설정은 기존 해시를 유지했습니다.

## 2. 오래된 로그로 인한 오판

기존 `BepInEx/LogOutput.log`에는 DiceMaster 로드 기록이 있었습니다. 수정 시각은 2024년이었고 Mod 아카이브에 포함된 과거 로그였습니다.

현재 실행은 다음 세 가지로 판단합니다.

- 로그 수정 시각이 현재 실행과 일치함;
- 현재 프로세스가 로컬 `winhttp.dll`과 Preloader를 로드함;
- 새 로그에 `Chainloader initialized`와 각 플러그인 버전이 나타남.

## 3. Doorstop 로드

`Mortal.exe` 전용 DLL override를 추가했습니다.

```text
winhttp = native,builtin
```

로컬 `winhttp.dll`과 Preloader가 프로세스에 들어왔습니다. 다음 중단 지점은 managed entry 내부였습니다.

## 4. 전체 Unity corlibs 사용

```text
게임 포함 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 전체 버전    4,065,792 bytes
```

합법적으로 확보한 동일 Unity 버전의 corlibs를 `BepInEx/unstripped_corlib/`에 배치하고 Doorstop을 설정했습니다.

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

상세 로그에서 Preloader 호출과 `Done`을 확인했습니다. corlibs는 Unity 버전을 일치시키고 Unity 라이선스에 따라 사용합니다.

## 5. BepInEx Wine 초기화 복구

다음 예외를 확인했습니다.

```text
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

이 문제는 BepInEx의 Wine/Proton 초기화 순서와 관련됩니다.

- [issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)
- [수정 PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)

기존 `BepInEx/core` 전체를 백업하고 PR #1254가 포함된 x86 Mono `6.0.0-be.785`로 같은 build의 core를 일괄 교체했습니다. 진입점은 기본 `Application::.cctor`로 복원했습니다.

## 6. 최종 검증

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

로드된 플러그인:

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

일본어 문자열 72,977줄 주입과 새로운 Error/Fatal 부재를 확인했습니다. 게임 언어는 중국어 간체를 선택합니다. `F5`는 이름 후리가나, `F7`은 후리가나 표시 모드를 전환합니다.

## 7. 롤백

Mod 병합 전, corlibs 설정 전, `be.785` 교체 전의 세 백업 지점을 유지합니다. 게임, Windows용 Steam, 해당 wineserver를 종료한 뒤 같은 레이어의 파일을 한 세트로 복원합니다. 서로 다른 BepInEx build의 core DLL을 혼합하지 않습니다.
