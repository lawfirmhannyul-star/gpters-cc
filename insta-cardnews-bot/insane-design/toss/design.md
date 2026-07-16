---
schema_version: 3.2
slug: toss
service_name: Toss
site_url: https://toss.im
fetched_at: 2026-07-16
default_theme: light
brand_color: "#3182f6"
primary_font: "'Toss Product Sans', -apple-system, 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif"
font_weight_normal: 400
token_prefix: cn

bold_direction: Friendly Fintech
aesthetic_category: saas-marketing
signature_element: typo_contrast
code_complexity: low

medium: card-news
medium_confidence: high

archetype: editorial-magazine
archetype_confidence: medium
design_system_level: lv2
design_system_level_evidence: "실제 서비스 CSS에서 named token 다수 확인(brand/text/border 계층), 카드뉴스 적용을 위해 lv2로 단순화"

colors:
  brand: "#3182f6"
  brand-soft: "#e8f3ff"
  text-primary: "#191f28"
  text-secondary: "#333d4b"
  text-tertiary: "#4e5968"
  text-muted: "#6b7684"
  border: "#e5e8eb"
  border-strong: "#d1d6db"
  surface: "#ffffff"
  surface-soft: "#f2f4f6"
  surface-softer: "#f9fafb"
  accent-warn-bg: "#ffeeee"
  accent-tip-bg: "#ffe0b0"
  accent-tip-fg: "#dd7d02"

typography:
  display: "'Toss Product Sans', 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif"
  body: "'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif"
  ladder:
    - { token: hook-h1, size: "64px", weight: 700, tracking: "-0.02em" }
    - { token: card-h2, size: "40px", weight: 700, tracking: "-0.01em" }
    - { token: body, size: "28px", weight: 400, tracking: "normal" }
    - { token: caption, size: "20px", weight: 500, tracking: "normal" }
  weights_used: [400, 500, 700]
  weights_absent: [300, 600, 800, 900]

components:
  card-frame: { bg: "{colors.surface}", radius: "0px", padding: "80px 64px" }
  hook-badge: { bg: "{colors.brand-soft}", fg: "{colors.brand}", radius: "100px", padding: "10px 24px" }
  disclaimer-tag: { bg: "{colors.surface-soft}", fg: "{colors.text-muted}", radius: "12px", padding: "16px 20px" }
  tip-callout: { bg: "{colors.accent-tip-bg}", fg: "{colors.accent-tip-fg}", radius: "14px", padding: "24px" }
  cta-button: { bg: "{colors.brand}", fg: "#ffffff", radius: "100px", padding: "20px 40px" }
---

# DESIGN.md — 인스타 카드뉴스 자동화 (Toss 레퍼런스, card-news 적용)

> 실측 대상: toss.im (실제 서비스 배포 CSS에서 hex 직접 추출, 2026-07-16)
> 적용 매체: Instagram 카드뉴스 (1080×1080), 보험전문 변호사 콘텐츠

---

## §00 Visual Theme

Toss는 "복잡한 금융을 아무나 이해할 수 있게" 만드는 걸 정체성으로 삼는 서비스다. 이 카드뉴스 템플릿은 Toss를 그대로 베끼는 게 아니라, **Toss가 신뢰와 친근함을 동시에 얻어낸 방법**(정보 위계를 색으로 표시하고, 각지지 않은 형태로 긴장을 풀고, 텍스트 대비로 시선을 끄는 것)만 가져와 법률 정보 카드뉴스에 이식한다.

브랜드 블루 `#3182f6`는 채도가 높지 않은 중간 채도 블루라 "차갑고 딱딱한 로펌 느낌"이 아니라 "믿을 만한데 편안한" 인상을 준다. 텍스트는 순검정(`#000000`)이 아니라 `#191f28`(짙은 남색기 도는 다크그레이)를 써서 화면이 딱딱해 보이지 않는다. 배경도 순백 대신 `#f9fafb`/`#f2f4f6` 같은 미세하게 톤 낮춘 회백색을 섞어 쓴다.

**Key Characteristics**
- 브랜드 블루는 강조에만 쓰고, 본문 배경은 대부분 흰색/연회색
- 텍스트 계층이 5단계(`text-primary` ~ `text-muted`)로 세분화되어, 카드 안에서도 "제목/본문/보조설명"이 색만으로 구분됨
- 버튼·배지는 완전히 둥근 pill(`radius: 100px`), 카드·박스는 12~14px의 절제된 라운드
- 경고/주의 문구는 옅은 배경색 태그(예: `accent-tip-bg`)로 감싸 "각주가 아니라 읽어야 할 정보"로 격상시킴
- 순검정/순백 대비 대신 톤 다운된 그레이스케일 사용 — 이 문서 §18 참고

### BOLD Direction Summary

> **BOLD Direction**: Friendly Fintech
> **Aesthetic Category**: saas-marketing
> **Signature Element**: 이 카드뉴스는 **큰 후킹 헤드라인과 작은 본문의 타이포 대비**로 기억된다.
> **Code Complexity**: low — CSS 변수 + 정적 레이아웃, 모션 없음 (PNG 캡처용)

---

## §06 Colors

| Token | Hex | 용도 |
|---|---|---|
| brand | `#3182f6` | 강조 텍스트, 배지, CTA 버튼 |
| brand-soft | `#e8f3ff` | 후킹 카드 배경, 배지 배경 |
| text-primary | `#191f28` | 헤드라인, 핵심 문장 |
| text-secondary | `#333d4b` | 본문 |
| text-tertiary | `#4e5968` | 보조 설명 |
| text-muted | `#6b7684` | 캡션, 출처, 고지 문구 |
| border | `#e5e8eb` | 카드 경계선 |
| border-strong | `#d1d6db` | 구분선 |
| surface | `#ffffff` | 기본 카드 배경 |
| surface-soft | `#f2f4f6` | 보조 배경, 고지문구 박스 |
| surface-softer | `#f9fafb` | 은은한 섹션 배경 |
| accent-warn-bg | `#ffeeee` | 쟁점/경고 카드 배경 |
| accent-tip-bg | `#ffe0b0` | 팁 카드 배경 |
| accent-tip-fg | `#dd7d02` | 팁 카드 강조 텍스트 |

---

## §11 Layout Patterns (카드뉴스 8장 구조 적용)

- **캔버스**: 1080×1080px 고정, 안전 여백(safe padding) 상하좌우 80px
- **카드별 배경/역할 매핑**:
  1. 후킹 — `brand-soft` 배경 + `brand` 컬러 강조 헤드라인
  2. 쟁점 — `surface` 배경, `accent-warn-bg` 태그로 쟁점 키워드 강조
  3. 사례 — `surface-soft` 배경, 인용 형태 본문
  4. 법리 — `surface` 배경, 번호 매긴 리스트
  5. 결과 — `surface` 배경 + 하단에 `disclaimer-tag`(고지 문구, §18 DON'T 4 참고) 고정 배치
  6. 팁 — `accent-tip-bg` 콜아웃 카드
  7. 요약 — `brand-soft` 배경, 핵심 3줄 요약
  8. CTA — `surface` 배경 + `cta-button`(brand 배경, 흰 텍스트, pill) + 변호사 이름/연락처 플레이스홀더
- **헤드라인 위치**: 각 카드 상단 1/3 지점, 좌측 정렬
- **본문 위치**: 중앙~하단, 최대 3~4줄로 제한 (인스타 카드뉴스는 스와이프 중 읽히므로 문장 길이를 짧게)
- **일관 요소**: 모든 카드 우측 하단에 페이지 인디케이터(`1/8` 형식, `text-muted` 컬러, 작은 글씨)

---

## §13 Components

### hook-badge (후킹 카드 배지)
```html
<span class="hook-badge">보험금 지급거절?</span>
```
```css
.hook-badge {
  background: var(--brand-soft);
  color: var(--brand);
  border-radius: 100px;
  padding: 10px 24px;
  font-weight: 700;
  font-size: 24px;
}
```

### disclaimer-tag (결과 카드 고지 문구 — 광고규정 대응)
```html
<div class="disclaimer-tag">개별 사건의 결과이며, 모든 사건에 동일하게 적용되지 않습니다.</div>
```
```css
.disclaimer-tag {
  background: var(--surface-soft);
  color: var(--text-muted);
  border-radius: 12px;
  padding: 16px 20px;
  font-size: 18px;
  line-height: 1.5;
}
```

### tip-callout (팁 카드)
```css
.tip-callout {
  background: var(--accent-tip-bg);
  color: var(--accent-tip-fg);
  border-radius: 14px;
  padding: 24px;
  font-weight: 500;
}
```

### cta-button (CTA 카드)
```css
.cta-button {
  background: var(--brand);
  color: #ffffff;
  border-radius: 100px;
  padding: 20px 40px;
  font-weight: 700;
  font-size: 28px;
  display: inline-block;
}
```

---

## §15 Drop-in CSS

```css
:root {
  --brand: #3182f6;
  --brand-soft: #e8f3ff;
  --text-primary: #191f28;
  --text-secondary: #333d4b;
  --text-tertiary: #4e5968;
  --text-muted: #6b7684;
  --border: #e5e8eb;
  --border-strong: #d1d6db;
  --surface: #ffffff;
  --surface-soft: #f2f4f6;
  --surface-softer: #f9fafb;
  --accent-warn-bg: #ffeeee;
  --accent-tip-bg: #ffe0b0;
  --accent-tip-fg: #dd7d02;

  --font-display: 'Toss Product Sans', 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif;
  --font-body: 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif;

  --radius-pill: 100px;
  --radius-card: 14px;
  --radius-tag: 12px;
}

body {
  font-family: var(--font-body);
  color: var(--text-primary);
  background: var(--surface);
}
```

---

## §18 DO / DON'T

**DO**
- 텍스트는 `text-primary`(#191f28) 이하 5단계 그레이스케일만 사용
- 강조는 `brand`(#3182f6) 한 가지 색으로 통일 — 두 번째 브랜드 컬러를 만들지 않는다
- 버튼/배지는 pill(100px), 카드/박스는 12~14px 라운드로 통일
- 결과 카드에는 항상 `disclaimer-tag`를 포함한다 (변호사 광고규정 대응)

**DON'T**
- 순검정(`#000000`)이나 순백(`#ffffff`) 단독 텍스트/배경 대비 쓰지 마 (`text-primary`/`surface-soft` 계열로 대체)
- 웹툰풍 말풍선, 과장된 캐릭터 일러스트 쓰지 마 (정보성 우선 — 리서치 근거: 인스타툰 광고 연구에서 작품성은 구매의도에 유의미한 영향 없음)
- 최상급("최고", "유일") 표현이나 승소율 수치를 헤드라인에 넣지 마 (04_PROJECT_SPEC.md 법률 광고 표현 규칙 참고)
- 카드마다 다른 폰트/색을 실험적으로 바꾸지 마 — 템플릿은 승인 후 고정 재사용
