# cardnews-maker — 디자인 문서

> Show Me The PRD로 생성됨 (2026-05-28)
> 보험전문 변호사 전용 뉴스 기사 → 인스타 카드뉴스 자동 생성 스킬

## 문서 구성

| 문서 | 내용 | 언제 읽나 |
|------|------|----------|
| [01_PRD.md](./01_PRD.md) | 뭘 만드는지, 누가 쓰는지 | 스킬 만들기 전 전체 그림 파악 |
| [02_DATA_MODEL.md](./02_DATA_MODEL.md) | 입력→처리→출력 데이터 구조 | 스킬 로직 설계할 때 |
| [03_PHASES.md](./03_PHASES.md) | 단계별 제작 계획 | 어디서부터 시작할지 정할 때 |
| [04_PROJECT_SPEC.md](./04_PROJECT_SPEC.md) | Claude에게 줄 행동 규칙 | 스킬 파일 작성하거나 수정할 때마다 |

## 다음 단계

Phase 1을 시작하려면 [03_PHASES.md](./03_PHASES.md)의 **"Phase 1 시작 프롬프트"** 를 복사해서 Claude Code에 붙여넣으세요.

## 미결 사항

- [ ] 변호사 이름·연락처·CTA 문구 확정 (Phase 1 코드에 하드코딩)
- [ ] 저장 파일명 규칙 확정 (`{주제}_{YYYYMMDD}.html` 기본안)
- [ ] Unsplash 이미지 로드 실패 시 폴백 색상 팔레트 결정
