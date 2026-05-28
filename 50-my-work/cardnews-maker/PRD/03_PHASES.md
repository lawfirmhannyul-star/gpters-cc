# cardnews-maker — Phase 분리 계획

> 한 번에 다 만들면 복잡해집니다.
> Phase별로 나눠서 각각 "바로 쓸 수 있는 스킬"을 만듭니다.

---

## Phase 1: MVP — 지금 바로 만들 것

### 목표
URL 하나를 붙여넣으면 인스타 규격 HTML 카드뉴스가 자동 생성된다.

### 기능
- [x] `/cardnews-maker <URL>` 슬래시 커맨드 인터페이스
- [x] insane-search로 기사 크롤링 (차단 사이트 자동 우회)
- [x] 기사 분석 → 8장 카드 콘텐츠 자동 추출
- [x] Unsplash 이미지 카드마다 자동 연결 (API 키 불필요)
- [x] 1080×1080 HTML 생성 (다크 테마, Tailwind CDN)
- [x] 변호사 CTA 자동 삽입 (스킬 파일에 하드코딩)
- [x] `50-my-work/cardnews-maker/` 자동 저장

### 데이터
- Input, Article, CardSet, Card × 8, LawyerProfile (하드코딩), Output

### "바로 쓸 수 있는 스킬" 체크리스트
- [ ] `/cardnews-maker <URL>` 한 줄로 실행됨
- [ ] 매일경제·연합뉴스·조선일보 크롤링 성공
- [ ] 브라우저에서 열면 8장이 1080×1080으로 보임
- [ ] CTA 카드에 변호사 이름·연락처 표시됨
- [ ] 파일이 `50-my-work/cardnews-maker/`에 저장됨

### Phase 1 시작 프롬프트

아래를 복사해서 Claude Code에 붙여넣으세요:

```
다음 PRD를 읽고 cardnews-maker 슬래시 커맨드 스킬을 만들어줘.

@50-my-work/cardnews-maker/PRD/01_PRD.md
@50-my-work/cardnews-maker/PRD/02_DATA_MODEL.md
@50-my-work/cardnews-maker/PRD/04_PROJECT_SPEC.md

만들 것:
- .claude/commands/cardnews-maker.md (슬래시 커맨드 파일)

Phase 1 범위:
- URL 입력 → insane-search 크롤링
- 8장 카드 구조 자동 추출 (type: cover/situation/claim/shock/court/result/tips/cta)
- 카드마다 Unsplash 직접 URL 이미지 매칭
- 1080×1080 HTML 생성 (다크 테마)
- 변호사 CTA 하드코딩 삽입
- 50-my-work/cardnews-maker/ 자동 저장

반드시 지켜야 할 것:
- 04_PROJECT_SPEC.md의 "절대 하지 마" 목록 준수
- Unsplash API 키 사용 금지 (직접 URL만)
- 이미지 AI 생성 금지
- 1080×1080 고정 (반응형 아님)
```

---

## Phase 2: 편의 확장

### 전제 조건
- Phase 1 스킬이 안정적으로 동작하는 상태

### 목표
코드를 열지 않고도 변호사 정보를 바꿀 수 있고, 상황에 따라 테마·장수를 선택할 수 있다.

### 기능
- [ ] `lawyer_profile.json` 분리
  - `50-my-work/cardnews-maker/lawyer_profile.json` 파일로 이름·연락처·CTA 문구 관리
  - 파일 없을 시 플레이스홀더로 동작
- [ ] 테마 선택 옵션
  - `/cardnews-maker <URL> --light` 로 라이트 테마 전환
- [ ] 카드 장수 조정
  - `/cardnews-maker <URL> --cards 6` 으로 6장·8장·10장 선택

### 추가 데이터
- `lawyer_profile.json` 파일 (LawyerProfile 엔티티를 외부 파일로 분리)

---

## Phase 3: 고도화

### 전제 조건
- Phase 1 + 2가 안정적으로 동작 중

### 목표
여러 기사를 한 번에 처리하고, 플랫폼에 따라 규격을 바꿀 수 있다.

### 기능
- [ ] 배치 모드: `/cardnews-maker url1 url2 url3` 으로 여러 기사 한번에 처리
- [ ] 플랫폼별 규격 분기: `--platform facebook` (4:5), `--platform youtube` (16:9 썸네일)
- [ ] 시리즈형 스토리텔링: 연속 포스팅용 연결 카드뉴스

### 주의사항
- 배치 모드는 insane-search 호출이 N배로 늘어나 속도가 느려질 수 있음
- 플랫폼별 규격 추가 시 HTML 템플릿을 별도로 관리해야 함

---

## Phase 로드맵 요약

| Phase | 핵심 기능 | 상태 |
|-------|----------|------|
| Phase 1 (MVP) | URL 크롤링 → 8장 HTML 자동 생성 + CTA | 시작 전 |
| Phase 2 | 프로필 JSON 분리, 테마·장수 옵션 | Phase 1 완료 후 |
| Phase 3 | 배치 모드, 멀티 플랫폼 규격 | Phase 2 완료 후 |
