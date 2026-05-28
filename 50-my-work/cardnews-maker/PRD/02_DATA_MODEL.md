# cardnews-maker — 데이터 모델

> 이 문서는 스킬이 다루는 핵심 데이터의 구조를 정의합니다.
> 개발자가 아니어도 이해할 수 있는 "개념적 흐름도"입니다.

---

## 전체 구조

```
[Input]
  url (string)
    │
    ▼
[Article]  ←── insane-search가 채움
  title / date / body / source
    │
    ▼
[CardSet]  ←── Claude가 분석해서 채움
  cards[8]
    │
    ├─ [Card × 8]
    │    card_no / type / title / body
    │    image_keyword / bg_url
    │
    └─ [LawyerProfile]  ←── 코드에 하드코딩 (Phase 1)
         name / phone / office / cta_text
    │
    ▼
[Output]
  filename / size / save_path / html_content
```

---

## 엔티티 상세

### Input
사용자가 슬래시 커맨드에 입력하는 값.

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| url | 뉴스 기사 전체 URL | https://www.mk.co.kr/news/economy/12056458 | O |

---

### Article
insane-search가 URL을 크롤링해서 채우는 기사 데이터.

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| title | 기사 제목 | "다친게 아니라 원래 안좋았던거 아냐?" | O |
| date | 발행일 | 2026-05-24 | X |
| body | 기사 본문 전문 | "교통사고로 골반이 손상된..." | O |
| source | 언론사명 | 매일경제 | X |

---

### CardSet
Article을 Claude가 분석해 8장 카드 구조로 변환한 묶음.

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| cards | Card 8개의 배열 | [Card1, Card2, ..., Card8] | O |
| lawyer_profile | CTA 카드에 들어갈 변호사 정보 | LawyerProfile 객체 | O |

---

### Card (8장 고정)

각 카드의 역할(type)은 아래와 같이 고정됩니다.

| card_no | type | 역할 |
|---------|------|------|
| 1 | cover | 후킹 표지 — 독자가 멈추게 만드는 충격 문장 |
| 2 | situation | 사건 배경 — A씨에게 일어난 일 |
| 3 | claim | 보험사 주장 — 인용구 형식 |
| 4 | shock | 충격 팩트 — 보험사가 꺼낸 자료들 |
| 5 | court | 법원 판단 — 인용구 + 인정/기각 |
| 6 | result | 결과 — 금액·판결 요약 |
| 7 | tips | 핵심 팁 3가지 — 저장 유도 |
| 8 | cta | 변호사 프로필 + 행동 유도 |

각 Card의 필드:

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| card_no | 카드 번호 (1~8) | 1 | O |
| type | 카드 역할 | cover | O |
| title | 화면에 크게 나오는 제목 | "제왕절개 기록까지 뒤졌습니다" | O |
| body | 화면에 나오는 설명 문장 | "보험사가 과거 출산 기록을..." | O |
| image_keyword | Unsplash 검색 키워드 (영어) | "car accident road" | O |
| bg_url | 자동 조립된 Unsplash 이미지 URL | https://images.unsplash.com/photo-XXX?w=1080&q=80 | O |

---

### LawyerProfile
8장 CTA에 고정 삽입되는 변호사 정보. Phase 1에서는 스킬 파일에 하드코딩.

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| name | 변호사 이름 | 홍길동 변호사 | O |
| phone | 연락처 | 02-000-0000 | O |
| office | 사무소명 | 법무법인 OO | X |
| cta_text | 저장 유도 문구 | "저장해두고 필요할 때 연락하세요" | O |

---

### Output
최종 생성되는 파일 정보.

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| filename | 저장 파일명 | insurance-20260528.html | O |
| size | 각 카드 픽셀 크기 | 1080 × 1080 px | O |
| save_path | 저장 경로 | 50-my-work/cardnews-maker/ | O |
| html_content | 생성된 HTML 전문 | `<!DOCTYPE html>...` | O |

---

## 왜 이 구조인가

- **8장 고정**: 인스타그램 카드뉴스는 6~10장이 최적. 8장으로 고정해 매번 일관된 분량 보장
- **type 고정**: 장마다 역할을 명확히 해야 Claude가 항상 동일한 품질로 콘텐츠를 채움
- **LawyerProfile 분리**: Phase 1에서는 하드코딩이지만, Phase 2에서 JSON 파일로 분리해 코드 수정 없이 변경 가능하도록 설계
- **Unsplash 직접 URL**: API 키 불필요, 인터넷 연결만 있으면 이미지 로드 가능

---

## [NEEDS CLARIFICATION]

- [ ] `image_keyword`를 영어로만 할지, 한국어도 허용할지 (Unsplash는 영어 검색이 더 정확)
- [ ] Unsplash 이미지 로드 실패 시 폴백 배경색 팔레트 (카드 type별 기본 그라디언트 색상)
