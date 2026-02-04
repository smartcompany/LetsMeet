# share_lib Git Submodule 가이드

`flutter_share_lib`는 Git submodule로 포함되어 있어 CI/CD와 협업 시 일관된 버전을 사용합니다.

---

## 1. 이미 설정된 경우

저장소를 clone한 후 submodule을 가져오려면:

```bash
git clone --recurse-submodules <저장소_URL>
```

또는 이미 clone했다면:

```bash
git submodule update --init --recursive
```

---

## 2. 처음 submodule 추가하는 경우 (이미 완료됨)

client 저장소 루트에서 실행:

```bash
cd /path/to/client
git submodule add https://github.com/smartcompany/flutter_share_lib.git flutter_share_lib
```

이미 위 명령으로 추가되어 있으므로, 다른 환경에서 submodule만 추가할 때 참고용입니다.

---

## 3. share_lib 업데이트

다른 브랜치/커밋으로 업데이트하려면:

```bash
cd flutter_share_lib
git fetch origin
git checkout main   # 또는 원하는 브랜치/태그
cd ..
git add flutter_share_lib
git commit -m "chore: update share_lib"
```

---

## 4. 주의사항

- **push 시**: submodule 변경사항(`.gitmodules`, `flutter_share_lib` 커밋 해시)을 함께 커밋·푸시해야 합니다.
- **CI**: GitHub Actions의 `checkout`에 `submodules: true`가 설정되어 있어 자동으로 submodule을 가져옵니다.
- **Private 저장소**: submodule이 private이면 CI에서 `actions/checkout`에 `token`을 전달해야 합니다.
