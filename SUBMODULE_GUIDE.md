# share_lib 가이드

`share_lib`는 Git dependency로 참조합니다.

---

## 의존성 설정

`pubspec.yaml`:

```yaml
share_lib:
  git:
    url: https://github.com/smartcompany/flutter_share_lib.git
    ref: main
```

---

## 로컬에서 flutter_share_lib 개발 시

로컬에서 share_lib를 수정하면서 테스트하려면 `dependency_overrides`를 사용하세요:

```yaml
dependency_overrides:
  share_lib:
    path: ../../flutter_share_lib
```

이렇게 하면 로컬의 `flutter_share_lib` 폴더를 우선 사용합니다.
