# 환경 이식 스크립트

이 폴더의 `setup-env.ps1`은 이 컴퓨터에서 설정한 Claude Code 환경을 다른 Windows 컴퓨터에도 그대로 재현합니다.

## 포함되는 것

- `cc`, `ccd`, `ccr` PowerShell 별칭 (`claude`, `claude --dangerously-skip-permissions`, `claude --resume --dangerously-skip-permissions`)
- 완료/확인 알림 hook (beep + 메시지), 위험 명령(`rm -rf`, `git reset --hard`, `sudo`) 차단 hook
- GPTaku marketplace 등록 + 플러그인 7종 설치 (`show-me-the-prd`, `skillers-suda`, `kkirikkiri`, `insane-search`, `insane-research`, `insane-harness`, `insane-design`)

## 포함되지 않는 것 (알아둘 점)

- 이 저장소 자체는 `git clone`으로 옮겨야 합니다. 스크립트는 `~/.claude/`와 PowerShell 프로필만 건드립니다.
- [Claude Code CLI](https://docs.claude.com/claude-code)가 새 컴퓨터에 미리 설치되어 있어야 `claude plugin` 명령이 동작합니다.
- 인터넷 연결이 필요합니다 (marketplace/플러그인은 GitHub에서 내려받습니다).

## 사용법

```powershell
git clone https://github.com/lawfirmhannyul-star/gpters-cc.git
cd gpters-cc
.\scripts\setup-env.ps1
```

다시 실행해도 안전합니다 (멱등적) — 이미 설정된 부분은 건너뜁니다.

실행 후 **새 터미널을 열고** `cc`로 Claude Code를 다시 시작해야 hook/플러그인/환경변수가 반영됩니다.
