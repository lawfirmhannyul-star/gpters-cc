---
description: This skill should be used when the user asks to "카드뉴스 만들어줘", "이 기사 카드뉴스로", "인스타 콘텐츠 만들어", "/cardnews-maker", "보험 기사 정리해줘", "sns 콘텐츠 만들어줘", "유튜브 카드뉴스", "make card news", "instagram content". Generates an 8-card 1080×1080 Instagram HTML card news from a news article URL or YouTube URL — crawls with insane-search or yt-dlp, auto-matches Unsplash images, and inserts 한세영 변호사 CTA. Make sure to use this skill whenever the user provides a news article URL or YouTube URL and wants card news, Instagram content, or SNS content.
---

# cardnews-maker

뉴스 기사 URL 또는 유튜브 URL → 한세영 변호사 전용 인스타그램 카드뉴스 HTML 자동 생성.

## 사용법

```
/cardnews-maker <URL>
```

예시:
```
/cardnews-maker https://www.mk.co.kr/news/economy/12056458
/cardnews-maker https://www.youtube.com/watch?v=XXXXXXX
```

---

## Step 1: URL 검증 + 타입 감지 [prompt]

$ARGUMENTS 에서 URL을 추출한다.

**검증:**
- URL이 비어있으면: "URL을 함께 입력해주세요. 예: `/cardnews-maker https://...`" 출력 후 종료.
- `http://` 또는 `https://`로 시작하지 않으면: "올바른 URL 형식이 아닙니다." 출력 후 종료.
- URL이 여러 개이면: 첫 번째 URL만 사용.

**타입 감지:**
- URL에 `youtube.com/watch`, `youtu.be/`, `youtube.com/shorts/` 포함 → **YouTube 모드** → Step 2-YT 실행
- 그 외 모든 URL → **기사 모드** → Step 2-Article 실행

---

## Step 2-Article: 뉴스 기사 크롤링 [script]

Jina Reader로 먼저 시도하고, 실패 시 insane-search로 폴백한다.

**1차 시도 — Jina Reader:**
```
WebFetch: https://r.jina.ai/{URL}
prompt: 기사의 제목, 날짜, 본문 전문을 한국어로 추출해줘
```

**2차 시도 — insane-search (Jina 실패 시):**
```bash
cd "$env:USERPROFILE/.claude/plugins/cache/gptaku-plugins/insane-search/0.4.1/skills/insane-search"
python -m engine "<URL>" --selector "article, .article_body, .news_body, p" 2>&1
```

**실패 처리:**
- 둘 다 실패 시 `50-my-work/cardnews-maker/raw_failed_{YYYYMMDD_HHMMSS}.txt` 저장 후 종료
- "기사를 가져오지 못했습니다. URL을 확인하거나 본문을 직접 붙여넣어 주세요." 출력

**보험 키워드 확인:**
보험·법원·배상·보상·보험금·면책·특약 등 없으면:
"보험 관련 콘텐츠가 아닐 수 있습니다. 계속 진행할까요? (Y/N)"

---

## Step 2-YT: 유튜브 콘텐츠 추출 [script]

**1단계 — 메타데이터 + 자막 추출:**
```bash
yt-dlp --dump-json "<URL>" 2>&1
```
→ 제목(`title`), 설명(`description`), 채널명(`channel`) 추출

**2단계 — 한국어 자막 우선 추출:**
```bash
yt-dlp --write-sub --write-auto-sub --sub-lang ko,en --skip-download --sub-format vtt -o "50-my-work/cardnews-maker/tmp/yt_%(id)s" "<URL>" 2>&1
```
→ `50-my-work/cardnews-maker/tmp/` 안에 생성된 `.vtt` 파일을 Glob으로 탐색 후 Read로 내용 읽기
→ 파일명 패턴: `yt_{ID}.ko.vtt`, `yt_{ID}.ko-KR.vtt`, `yt_{ID}.en.vtt` 등 다양할 수 있으므로 `Glob("50-my-work/cardnews-maker/tmp/yt_*.vtt")`로 탐색

**자막 없을 때 폴백:**
- `description` 필드만으로 카드 생성 (내용이 얕을 수 있음을 안내)

**콘텐츠 구성:**
- 제목: yt-dlp `title` 필드
- 본문: 자막 전문 (없으면 description)
- 출처 표기: `YouTube — {channel} ({날짜})`

→ 내용 확보 후 Step 3으로 진행 (기사 모드와 동일)

---

## Step 3: 8장 카드 콘텐츠 생성 [prompt → generate]

추출된 콘텐츠를 분석해 8장 구조로 생성한다.

**카드 구조 (고정):**

| 장 | type | 역할 | 작성 규칙 |
|----|------|------|----------|
| 1 | cover | 후킹 표지 | 제목: 독자가 멈추는 충격 문장 16자 이내. 부제: 핵심 상황 1줄 |
| 2 | situation | 사건 배경 | 제목: 상황 요약. 본문: 3단계 흐름 (번호+설명) |
| 3 | claim | 상대방 주장 | 제목: 주장자 관점 제목. 본문: 인용구 박스 형식 |
| 4 | shock | 충격 포인트 | 제목: "이런 사실이 있었습니다" 스타일. 본문: ①②③ 리스트 |
| 5 | court | 판단/결론 | 제목: "법원·전문가 판단". 본문: 인용구 + ✓ 결론 |
| 6 | result | 최종 결과 | 제목: 핵심 한 줄. 본문: 큰 수치 또는 결과 강조 |
| 7 | tips | 핵심 팁 3가지 | 제목: "꼭 저장하세요". 본문: 번호+팁 3개 |
| 8 | cta | 변호사 프로필 | 고정 (하단 참조) |

**콘텐츠 작성 규칙:**
- 제목: 16자 이내 (카드에 크게 표시됨)
- 본문: 한 항목 2줄 이내, 한 줄 18자 이내
- 법률 용어 → 쉬운 말. "인과관계" → "사고 때문인지 여부"
- 투자 조언 표현 금지
- 출처에 없는 사실 추가 금지

**Unsplash 이미지 (카드별 photo-ID):**

| type | 추천 photo-ID |
|------|--------------|
| cover | 1503387762-592deb58ef4e |
| situation | 1568605114967-8130f3a36994 |
| claim | 1450101499163-c8848c66ca85 |
| shock | 1614064641938-3bbee52942c7 |
| court | 1589829545856-d10d557cf95f |
| result | 1607863680198-23d4b2565df0 |
| tips | 1484480974693-6ca0a78fb36b |
| cta | 1521791136064-7986c2920216 |

콘텐츠 주제에 따라 더 적합한 photo-ID로 교체 가능.

---

## Step 4: HTML 렌더링 [generate]

**디자인 원칙:**
- 폰트: `Outfit`(제목·숫자·영문) + `Noto Sans KR`(한국어 본문) — 모던하고 깔끔
- 카드 크기: 600×600px (브라우저 **180% 줌** 시 1080×1080px = 인스타 정확한 크기)
- 레이아웃: 카드 유형마다 다름 — cover는 중앙 정렬, 나머지는 하단 정렬
- 배경 오버레이: **밝게 유지** — 이미지가 충분히 보이도록 오버레이 투명도 최대 0.65 이하
- 제목: 32–40px / 부제·본문: **20px** / step 텍스트: **18px** / 보조 설명: **15px**

**고정 변수:**
- 변호사 이름: `한세영 변호사`
- 전화번호: `1533-0854`
- 주소: `서울시 서초구 서초대로 332, 9층`
- CTA 문구: `저장해두고 필요할 때 연락하세요`

**HTML 공통 CSS (모든 카드에 적용):**

```css
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;700;900&family=Noto+Sans+KR:wght@400;700;900&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: 'Noto Sans KR', sans-serif !important;
  background: #0a0a0a !important;
  display: flex; flex-direction: column; align-items: center;
  gap: 20px; padding: 40px 20px;
}
.card {
  width: 600px; height: 600px; position: relative; overflow: hidden;
  border-radius: 8px; display: flex; flex-direction: column;
  box-shadow: 0 20px 60px rgba(0,0,0,0.8);
}
.card-bg {
  position: absolute; inset: 0;
  background-size: cover; background-position: center;
}
.card-overlay { position: absolute; inset: 0; }
/* 커버 카드: 중앙 정렬 */
.card-center {
  justify-content: center; align-items: flex-start;
}
/* 일반 카드: 하단 정렬 */
.card-bottom { justify-content: flex-end; }

.card-body { position: relative; z-index: 10; padding: 44px; }
.card-body-center {
  position: relative; z-index: 10; padding: 44px;
  display: flex; flex-direction: column; justify-content: center;
  height: 100%;
}
.label {
  font-family: 'Outfit', sans-serif !important;
  font-size: 10px !important; font-weight: 700;
  letter-spacing: 4px; text-transform: uppercase;
  opacity: 0.75; margin-bottom: 16px;
}
.card-title {
  font-family: 'Outfit', 'Noto Sans KR', sans-serif !important;
  font-weight: 900 !important; line-height: 1.15 !important;
  margin-bottom: 18px; word-break: keep-all;
}
.card-sub {
  font-family: 'Noto Sans KR', sans-serif !important;
  font-size: 20px !important; line-height: 1.7 !important;
  opacity: 0.9; word-break: keep-all;
}
.accent-bar { width: 36px; height: 3px; margin-bottom: 20px; }
.badge {
  display: inline-flex; align-items: center;
  font-family: 'Outfit', sans-serif !important;
  font-size: 12px !important; font-weight: 700;
  letter-spacing: 2px; text-transform: uppercase;
  padding: 6px 16px; border-radius: 3px; margin-bottom: 18px;
}
.step-row { display: flex; align-items: flex-start; gap: 14px; margin-bottom: 18px; }
.step-dot {
  width: 34px; height: 34px; border-radius: 50%; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-family: 'Outfit', sans-serif !important;
  font-weight: 900; font-size: 15px;
}
.step-content { flex: 1; }
.step-main {
  font-family: 'Noto Sans KR', sans-serif !important;
  font-size: 18px !important; font-weight: 700; line-height: 1.5;
  word-break: keep-all;
}
.step-sub {
  font-family: 'Noto Sans KR', sans-serif !important;
  font-size: 15px !important; line-height: 1.6;
  opacity: 0.7; margin-top: 4px; word-break: keep-all;
}
.quote-wrap {
  border-left: 4px solid; padding: 16px 20px;
  margin: 14px 0; border-radius: 0 6px 6px 0;
}
.quote-text {
  font-family: 'Noto Sans KR', sans-serif !important;
  font-size: 19px !important; font-weight: 700;
  line-height: 1.65; word-break: keep-all;
}
.big-stat {
  font-family: 'Outfit', sans-serif !important;
  font-weight: 900 !important; line-height: 1 !important;
  letter-spacing: -2px;
}
.verdict-row {
  display: flex; align-items: center; gap: 12px; margin-top: 18px;
}
.verdict-icon {
  width: 36px; height: 36px; border-radius: 50%; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px; font-weight: 900;
}
.verdict-text {
  font-family: 'Outfit', sans-serif !important;
  font-size: 19px !important; font-weight: 700;
}
```

**카드별 HTML 구조:**

**[카드 1 — cover: 중앙 정렬, 임팩트 레이아웃]**
```html
<div class="card card-center">
  <div class="card-bg" style="background-image:url('https://images.unsplash.com/photo-{cover_id}?w=1080&h=1080&fit=crop&q=80');"></div>
  <div class="card-overlay" style="background:linear-gradient(135deg,rgba(0,0,0,0.1) 0%,rgba(0,0,0,0.55) 100%);"></div>
  <div class="card-body-center">
    <div class="badge" style="background:#b91c1c;color:#fff;">실제 판결 사례</div>
    <div class="card-title" style="font-size:38px;color:#fff;">{cover_title}</div>
    <div class="accent-bar" style="background:#ef4444;"></div>
    <div class="card-sub" style="color:#fff;">{cover_body}</div>
  </div>
</div>
```

**[카드 2 — situation: 하단 정렬, 3단계 흐름]**
```html
<div class="card card-bottom">
  <div class="card-bg" style="background-image:url('https://images.unsplash.com/photo-{situation_id}?w=1080&h=1080&fit=crop&q=80');"></div>
  <div class="card-overlay" style="background:linear-gradient(180deg,rgba(0,0,0,0.0) 0%,rgba(0,0,0,0.68) 48%);"></div>
  <div class="card-body">
    <div class="label" style="color:#94a3b8;">CASE 01</div>
    <div class="card-title" style="font-size:32px;color:#fff;">{situation_title}</div>
    <div class="step-row">
      <div class="step-dot" style="background:rgba(255,255,255,0.15);color:#fff;">1</div>
      <div class="step-content">
        <div class="step-main" style="color:#fff;">{step1_main}</div>
      </div>
    </div>
    <div class="step-row">
      <div class="step-dot" style="background:rgba(255,255,255,0.15);color:#fff;">2</div>
      <div class="step-content">
        <div class="step-main" style="color:#fff;">{step2_main}</div>
      </div>
    </div>
    <div class="step-row">
      <div class="step-dot" style="background:#b91c1c;color:#fff;">3</div>
      <div class="step-content">
        <div class="step-main" style="color:#fca5a5;">{step3_main}</div>
      </div>
    </div>
  </div>
</div>
```

**[카드 3 — claim: 하단 정렬, 인용구]**
```html
<div class="card card-bottom">
  <div class="card-bg" style="background-image:url('https://images.unsplash.com/photo-{claim_id}?w=1080&h=1080&fit=crop&q=80');"></div>
  <div class="card-overlay" style="background:linear-gradient(180deg,rgba(5,5,5,0.0) 0%,rgba(5,5,5,0.68) 48%);"></div>
  <div class="card-body">
    <div class="label" style="color:#94a3b8;">CASE 02</div>
    <div class="card-title" style="font-size:30px;color:#fff;">{claim_title}</div>
    <div class="quote-wrap" style="border-color:#ef4444;background:rgba(239,68,68,0.1);">
      <div class="quote-text" style="color:#fca5a5;">{claim_quote}</div>
    </div>
    <div class="card-sub" style="color:#cbd5e1;">{claim_body}</div>
  </div>
</div>
```

**[카드 4 — shock: 하단 정렬, ①②③ 리스트]**
```html
<div class="card card-bottom">
  <div class="card-bg" style="background-image:url('https://images.unsplash.com/photo-{shock_id}?w=1080&h=1080&fit=crop&q=80');"></div>
  <div class="card-overlay" style="background:linear-gradient(180deg,rgba(0,0,0,0.0) 0%,rgba(0,0,0,0.70) 48%);"></div>
  <div class="card-body">
    <div class="badge" style="background:rgba(239,68,68,0.25);color:#fca5a5;border:1px solid rgba(248,113,113,0.5);">{shock_badge}</div>
    <div class="card-title" style="font-size:30px;color:#fff;margin-bottom:20px;">{shock_title}</div>
    <div class="step-row">
      <div class="step-dot" style="background:#7f1d1d;color:#fca5a5;">①</div>
      <div class="step-content">
        <div class="step-main" style="color:#fff;">{shock1_main}</div>
        <div class="step-sub" style="color:#9ca3af;">{shock1_sub}</div>
      </div>
    </div>
    <div class="step-row">
      <div class="step-dot" style="background:#7f1d1d;color:#fca5a5;">②</div>
      <div class="step-content">
        <div class="step-main" style="color:#fff;">{shock2_main}</div>
        <div class="step-sub" style="color:#9ca3af;">{shock2_sub}</div>
      </div>
    </div>
    <div class="step-row">
      <div class="step-dot" style="background:#7f1d1d;color:#fca5a5;">③</div>
      <div class="step-content">
        <div class="step-main" style="color:#fca5a5;">{shock3_main}</div>
      </div>
    </div>
  </div>
</div>
```

**[카드 5 — court: 하단 정렬, 판결 인용구]**
```html
<div class="card card-bottom">
  <div class="card-bg" style="background-image:url('https://images.unsplash.com/photo-{court_id}?w=1080&h=1080&fit=crop&q=80');"></div>
  <div class="card-overlay" style="background:linear-gradient(180deg,rgba(0,20,10,0.0) 0%,rgba(0,20,10,0.68) 48%);"></div>
  <div class="card-body">
    <div class="label" style="color:#6ee7b7;">COURT RULING</div>
    <div class="card-title" style="font-size:30px;color:#fff;">{court_title}</div>
    <div class="quote-wrap" style="border-color:#10b981;background:rgba(16,185,129,0.1);">
      <div class="quote-text" style="color:#6ee7b7;">{court_quote}</div>
    </div>
    <div class="verdict-row">
      <div class="verdict-icon" style="background:#10b981;color:#fff;">✓</div>
      <div class="verdict-text" style="color:#6ee7b7;">{court_conclusion}</div>
    </div>
  </div>
</div>
```

**[카드 6 — result: 중앙 정렬, 큰 숫자 강조]**
```html
<div class="card card-center">
  <div class="card-bg" style="background-image:url('https://images.unsplash.com/photo-{result_id}?w=1080&h=1080&fit=crop&q=80');"></div>
  <div class="card-overlay" style="background:linear-gradient(135deg,rgba(0,0,0,0.35) 0%,rgba(0,0,0,0.62) 100%);"></div>
  <div class="card-body-center">
    <div class="label" style="color:#fbbf24;">FINAL RULING</div>
    <div class="big-stat" style="font-size:58px;color:#fbbf24;margin-bottom:8px;">{result_number}</div>
    <div style="font-family:'Outfit',sans-serif;font-size:24px;font-weight:700;color:#fff;margin-bottom:18px;">{result_verdict}</div>
    <div class="accent-bar" style="background:#fbbf24;"></div>
    <div class="card-sub" style="color:#fff;">{result_body}</div>
  </div>
</div>
```

**[카드 7 — tips: 하단 정렬, 저장 유도]**
```html
<div class="card card-bottom">
  <div class="card-bg" style="background-image:url('https://images.unsplash.com/photo-{tips_id}?w=1080&h=1080&fit=crop&q=80');"></div>
  <div class="card-overlay" style="background:linear-gradient(180deg,rgba(15,23,42,0.0) 0%,rgba(15,23,42,0.72) 45%);"></div>
  <div class="card-body">
    <div class="badge" style="background:#1e3a5f;color:#93c5fd;border:1px solid rgba(147,197,253,0.4);">꼭 저장하세요</div>
    <div class="card-title" style="font-size:28px;color:#fff;margin-bottom:20px;">{tips_title}</div>
    <div class="step-row">
      <div class="step-dot" style="background:#1d4ed8;color:#fff;">1</div>
      <div class="step-content">
        <div class="step-main" style="color:#93c5fd;">{tip1_main}</div>
        <div class="step-sub" style="color:#64748b;">{tip1_sub}</div>
      </div>
    </div>
    <div class="step-row">
      <div class="step-dot" style="background:#1d4ed8;color:#fff;">2</div>
      <div class="step-content">
        <div class="step-main" style="color:#93c5fd;">{tip2_main}</div>
        <div class="step-sub" style="color:#64748b;">{tip2_sub}</div>
      </div>
    </div>
    <div class="step-row">
      <div class="step-dot" style="background:#1d4ed8;color:#fff;">3</div>
      <div class="step-content">
        <div class="step-main" style="color:#93c5fd;">{tip3_main}</div>
        <div class="step-sub" style="color:#64748b;">{tip3_sub}</div>
      </div>
    </div>
  </div>
</div>
```

**[카드 8 — cta: 고정 내용]**
```html
<div class="card card-center">
  <div class="card-bg" style="background-image:url('https://images.unsplash.com/photo-{cta_id}?w=1080&h=1080&fit=crop&q=80');"></div>
  <div class="card-overlay" style="background:rgba(0,0,0,0.60);"></div>
  <div class="card-body-center" style="align-items:center;text-align:center;">
    <div style="font-family:'Outfit',sans-serif;font-size:32px;font-weight:900;color:#fff;line-height:1.25;margin-bottom:24px;">보험사가 거절했다고<br>포기하지 마세요</div>
    <div class="accent-bar" style="background:#ef4444;margin:0 auto 24px;"></div>
    <div style="font-family:'Noto Sans KR',sans-serif;font-size:18px;color:#e5e7eb;line-height:1.8;margin-bottom:32px;">대부분은 이유도 모르고 포기합니다<br>하지만 전문가가 보면 달라집니다</div>
    <div style="border-top:1px solid rgba(255,255,255,0.2);padding-top:28px;width:100%;">
      <div style="font-family:'Outfit',sans-serif;font-size:24px;font-weight:900;color:#fff;letter-spacing:1px;margin-bottom:6px;">한세영 변호사</div>
      <div style="font-family:'Outfit',sans-serif;font-size:20px;font-weight:700;color:#fbbf24;letter-spacing:2px;margin-bottom:6px;">1533-0854</div>
      <div style="font-family:'Noto Sans KR',sans-serif;font-size:14px;color:#94a3b8;margin-bottom:20px;">서울시 서초구 서초대로 332, 9층</div>
      <div style="display:inline-block;background:#b91c1c;color:#fff;font-family:'Noto Sans KR',sans-serif;font-size:15px;font-weight:700;padding:13px 30px;border-radius:4px;letter-spacing:1px;">저장해두고 필요할 때 연락하세요</div>
    </div>
  </div>
</div>
```

**전체 HTML 래퍼:**
```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{제목}</title>
<script src="https://cdn.tailwindcss.com"></script>
<style>
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;700;900&family=Noto+Sans+KR:wght@400;700;900&display=swap');
/* 위의 [HTML 공통 CSS] 섹션에 있는 CSS 전체를 여기에 그대로 붙여넣는다.
   * { box-sizing: ... } 부터 .verdict-text { ... } 까지 전부 포함 */
</style>
<!-- 출처: {언론사/채널} {날짜} | {URL} -->
</head>
<body>
<!-- 카드 1~8 순서대로 삽입 -->
</body>
</html>
```

---

## Step 5: 파일 저장 + 업로드 가이드 [script]

**파일명 규칙:**
- 기사: `insurance-{YYYYMMDD}.html`
- 유튜브: `yt-{YYYYMMDD}.html`
- 같은 날짜 파일 있으면 `-v2`, `-v3` 접미사

**저장 경로:** `50-my-work/cardnews-maker/`

**완료 후 출력:**
```
✅ 카드뉴스 생성 완료!

📁 파일: 50-my-work/cardnews-maker/{파일명}.html

📱 인스타그램 업로드 방법:
  1. 브라우저에서 파일 열기
  2. 각 카드 영역 스크린샷
     Windows: Win+Shift+S → 영역 선택
     Mac: Cmd+Shift+4 → 영역 선택
  3. 8장 순서대로 인스타그램 업로드

💡 팁: 브라우저 줌 180% → 1080×1080px (인스타 정확한 크기)
   파일 열기 후 2~3초 대기 후 스크린샷하세요 (폰트 로딩 대기).
```

---

## 에러 처리

| 상황 | 대응 |
|------|------|
| URL 없음 | 입력 요청 후 종료 |
| 잘못된 URL 형식 | 형식 안내 후 종료 |
| 크롤링 실패 | raw_failed_*.txt 저장 후 종료 |
| yt-dlp 미설치 | `pip install yt-dlp` 안내 후 재시도 |
| 유튜브 자막 없음 | description으로 폴백, 내용 부족 안내 |
| 비보험 콘텐츠 의심 | 확인 요청 후 진행 여부 선택 |
| 이미지 로드 실패 | CSS 그라디언트 폴백 |
| 같은 날짜 파일 존재 | -v2, -v3 접미사 자동 추가 |
