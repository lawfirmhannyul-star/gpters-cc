# cardnews-maker — 프로젝트 스펙

> Claude가 스킬 파일을 작성하거나 수정할 때 지켜야 할 규칙.
> 스킬을 만들거나 고칠 때 이 문서를 항상 함께 공유하세요.

---

## 기술 스택

| 영역 | 선택 | 이유 |
|------|------|------|
| 스킬 형식 | Claude Code 슬래시 커맨드 (`.claude/commands/cardnews-maker.md`) | 가장 빠른 실행 방법. `/cardnews-maker <URL>` 한 줄이면 끝 |
| 크롤링 | insane-search engine (`python3 -m engine <URL>`) | 매일경제·조선일보 등 WAF 차단 뉴스 사이트 자동 우회 |
| 이미지 | Unsplash 직접 URL (`images.unsplash.com/photo-{ID}?w=1080&q=80`) | API 키 불필요. 카드 주제 키워드별 photo-ID를 Claude가 직접 조립 |
| HTML 스타일링 | Tailwind CDN + 인라인 CSS | 설치 불필요. `<script src="https://cdn.tailwindcss.com">` 한 줄로 로드 |
| 폰트 | Google Fonts — Noto Sans KR + Noto Serif KR | 한국어 웹폰트 표준. `@import` 또는 `<link>` 로 로드 |
| 저장 위치 | `50-my-work/cardnews-maker/` | 프로젝트 CLAUDE.md 저장 규칙 준수 |

---

## 스킬 파일 구조

```
.claude/
└── commands/
    └── cardnews-maker.md     ← 슬래시 커맨드 본체

50-my-work/
└── cardnews-maker/
    ├── PRD/                  ← 이 문서들
    ├── lawyer_profile.json   ← Phase 2에서 추가
    └── {파일명}.html         ← 생성 결과물
```

---

## 카드 구조 고정 규칙

스킬은 항상 아래 8장 구조를 유지해야 합니다. 임의로 장을 추가하거나 순서를 바꾸지 않습니다.

| 장 | type | 역할 | 필수 요소 |
|----|------|------|----------|
| 1 | cover | 후킹 표지 | 충격적이거나 공감되는 짧은 문장 (15자 이내) |
| 2 | situation | 사건 배경 | 등장인물·상황·결과 3단 흐름 |
| 3 | claim | 상대방 주장 | 인용구 박스 형식 |
| 4 | shock | 충격 포인트 | 리스트 형식 (①②③) |
| 5 | court | 법원·전문가 판단 | 인용구 박스 + 결과 아이콘 |
| 6 | result | 최종 결과 | 큰 숫자 또는 핵심 한 줄 강조 |
| 7 | tips | 핵심 팁 3가지 | "저장해두세요" 문구 포함 |
| 8 | cta | 변호사 프로필 | 이름·연락처·저장 유도 버튼 |

---

## 이미지 매칭 규칙

각 card type별 Unsplash 키워드 가이드 (영어로 검색):

| type | 키워드 예시 |
|------|------------|
| cover | `law justice gavel`, `insurance document` |
| situation | `car accident road`, `hospital medical` |
| claim | `documents paperwork office` |
| shock | `investigation magnifying glass` |
| court | `courthouse gavel judge` |
| result | `money bills court victory` |
| tips | `notepad checklist notes` |
| cta | `lawyer handshake professional` |

이미지 URL 조립 규칙:
```
https://images.unsplash.com/photo-{PHOTO_ID}?w=1080&h=1080&fit=crop&q=80
```

Claude는 위 키워드로 적절한 Unsplash photo-ID를 직접 선택합니다.
(Claude 학습 데이터에 포함된 공개 Unsplash 이미지 ID를 사용)

---

## HTML 생성 규칙

```html
<!-- 필수 헤드 구성 -->
<script src="https://cdn.tailwindcss.com"></script>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;700;900&family=Noto+Serif+KR:wght@700;900&display=swap" rel="stylesheet">

<!-- 카드 1개당 고정 크기 -->
width: 600px;   /* 화면 미리보기용 — 스크린샷 시 1080px로 변환 */
height: 600px;

<!-- 인스타 출력 시 권장 -->
/* 브라우저 줌 150%로 열면 실제 1080×1080px에 근접 */
```

카드 간격은 `gap: 16px`, 전체 배경은 `#111` (다크).

---

## 절대 하지 마 (DO NOT)

- **Unsplash API 키 사용 금지** — 직접 URL 방식만 허용. API 키 발급 절차 불필요
- **이미지 AI 생성 금지** — DALL·E, Stable Diffusion, Imagen 호출 금지
- **반응형 레이아웃 금지** — 1080×1080 고정. `@media` 쿼리로 크기 변경하지 않기
- **투자 조언 표현 금지** — 보험 기사 분석 시 "매수·매도·수익 보장" 표현 절대 사용 금지
- **기사 내용 임의 추가 금지** — 원문에 없는 사실·수치를 카드에 넣지 않기
- **변호사 정보 임의 생성 금지** — CTA 카드의 이름·연락처가 설정되지 않았으면 `[이름]`, `[연락처]` 플레이스홀더 사용
- **기존 생성 파일 덮어쓰기 금지** — 같은 날짜 파일이 있으면 `-v2`, `-v3` 접미사 추가

---

## 항상 해 (ALWAYS DO)

- 크롤링 전에 "URL 크롤링 시작합니다" 안내 출력
- 8장 구조 분석 후 카드별 제목·키워드를 표로 사용자에게 보여주고 진행 여부 확인
- 생성 완료 후 "브라우저에서 열기: `{경로}`" 안내
- 이미지 로드 실패 가능성 있는 카드는 폴백 배경색(`background: linear-gradient(...)`) 함께 설정
- 기사 출처(언론사·날짜)를 HTML 주석에 기재

---

## 커맨드 실행 방법

```bash
# 기본 실행
/cardnews-maker https://www.mk.co.kr/news/economy/12056458

# Phase 2 이후 옵션 (참고용)
/cardnews-maker <URL> --light       # 라이트 테마
/cardnews-maker <URL> --cards 6     # 6장
```

---

## 환경변수

없음. API 키 불필요 설계.

> Phase 2에서 `lawyer_profile.json`을 도입하면 환경변수 대신 JSON 파일로 관리합니다.

---

## [NEEDS CLARIFICATION]

- [ ] 변호사 이름·연락처·CTA 문구 → Phase 1 스킬 파일 작성 전에 확정 필요
- [ ] 브라우저 스크린샷을 인스타에 올리는 구체적인 방법 (캡처 가이드 포함 여부)
- [ ] Unsplash 이미지 폴백 시 카드 type별 기본 그라디언트 색상 팔레트 결정
