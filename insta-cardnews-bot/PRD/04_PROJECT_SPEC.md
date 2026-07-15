# 인스타 카드뉴스 자동화 -- 프로젝트 스펙

> AI가 코드를 짤 때 지켜야 할 규칙과 절대 하면 안 되는 것.
> 이 문서를 AI에게 항상 함께 공유하세요.
>
> **v2 변경 사항** (kkirikkiri 리뷰 반영): 테스트 명령어 버그 수정, 변호사 광고 표현 규칙 추가, 이미지 저작권·템플릿 고정·토큰 갱신 규칙 추가.

---

## 기술 스택

| 영역 | 선택 | 이유 |
|------|------|------|
| 실행 환경 | Claude Code (로컬 스킬/스크립트) | 오늘 설치한 insane-search(유튜브/뉴스 크롤링), insane-design 등을 재사용할 수 있고, 별도 서버 호스팅이 필요 없음 |
| 소재 수집 | insane-search 플러그인 (yt-dlp, 뉴스/판결 사이트 접근) | 이미 설치되어 있고, 차단된 사이트도 우회 가능 |
| 콘텐츠 분석/요약 | Claude (수집된 원문을 직접 분석) | 별도 LLM API 키 없이 Claude Code 안에서 바로 실행 |
| 이미지 렌더링 | HTML+CSS 템플릿 -> Playwright로 PNG 캡처 | 기존 cardnews-maker의 HTML 카드뉴스 자산을 이미지로 승격시키는 가장 낮은 리스크 경로. 무료 |
| Instagram 연동 | Instagram API with Instagram Login (`graph.instagram.com`) | Facebook 페이지 연결 없이 프로페셔널 계정만으로 캐러셀 게시 가능. 대용량 비디오 재개 업로드가 필요 없는 이미지 전용 프로젝트라 Facebook Login 방식이 필요 없음 |
| 이력 저장 | 로컬 JSON 파일 (`history/source_history.json`, `{type}:{source_key}` 키 객체) | 개인 도구 규모에 DB는 과함. git으로 이력도 함께 버전 관리 가능 |

---

## 프로젝트 구조

```
insta-cardnews-bot/
├── PRD/                        # 이 디자인 문서들
├── sources/                    # 수집된 원문(자막/기사/판결) 캐시
├── history/
│   └── source_history.json     # 중복 방지 이력 ({type}:{source_key} 키 객체)
├── templates/
│   └── default_v1.html         # 승인된 고정 비주얼 템플릿 (임의 재생성 금지)
├── fact-check/
│   └── {cardset_id}.md         # 카드별 핵심 주장 -> 원문 인용 위치 대조 자료
├── output/
│   └── {날짜}_{소재제목}_{cardset_id}/   # 생성된 PNG 카드뉴스 세트 (재생성 시 버전 보존)
├── scripts/
│   ├── generate_cardnews.*     # 소재 -> 카드뉴스 이미지 + 캡션 초안 + 원문대조 자료
│   ├── mark_correction.*       # 게시 후 정정/삭제 상태를 이력에 기록
│   └── upload_instagram.*      # 승인된(잠긴) 세트 -> Instagram 게시
└── .env                        # Instagram API 토큰 등 (git 제외)
```

---

## 법률 광고 표현 규칙 (변호사 광고 규정 반영)

> 카드뉴스 문구, 캡션, CTA를 생성할 때 반드시 지켜야 하는 표현 규칙. 콘텐츠 분석/카드 구조화 단계에서부터 이 표를 기준으로 문구를 검토한다.

| 구분 | 규칙 |
|------|------|
| 금지 | "최고", "유일" 등 최상급·독점 표현 |
| 금지 | 승소율, 성공률 등 수치화된 성과 표현 |
| 금지 | 특정 사건의 결과를 모든 사건에 적용되는 것처럼 일반화·암시하는 표현 |
| 금지 | "OO 전문 로펌"처럼 로펌(법인) 단위로 전문분야를 표시하는 표현 |
| 허용 | "보험전문", "손해배상전문", "교통사고전문" 등 **개인 변호사**에게 등록된 전문분야 표현 |

> 카드 구조(후킹-쟁점-사례-법리-**결과**-팁-CTA)에서 "결과" 카드는 특히 이 규칙의 적용 대상이다. 매 카드뉴스마다 "개별 사건의 결과이며 모든 사건에 동일하게 적용되지 않는다"는 취지의 고지 문구를 CTA 근처에 포함한다.

---

## 절대 하지 마 (DO NOT)

> AI에게 코드를 시킬 때 이 목록을 반드시 함께 공유하세요.

- [ ] Instagram API 토큰이나 Meta 앱 시크릿을 코드나 커밋에 직접 쓰지 마 (`.env` 사용, `.gitignore` 등록)
- [ ] 변호사 승인 없이 이미지를 인스타그램에 게시하지 마 (Phase 1~2는 반드시 승인 게이트 유지)
- [ ] 법률 정보(판결 결과, 보상 금액 등)를 원문 확인 없이 추정해서 카드에 쓰지 마
- [ ] 이미 이력에 기록된 유튜브 영상 ID나 뉴스/판결 URL을 소재로 재사용하지 마 (중복 방지 체크를 건너뛰지 마 -- `history/source_history.json` 조회 공통 함수를 반드시 거칠 것)
- [ ] 실제 인물 정보(의뢰인 실명, 특정 가능한 사건 정보)를 비식별화 없이 카드뉴스에 노출하지 마
- [ ] 이니셜·사고유형·시기·보험사명 등 비식별 정보를 여러 개 조합해서 사실상 특정 가능하게 만들지 마 (조합 재식별 위험)
- [ ] `case_status`가 "진행중"인 사건을 확정된 것처럼 카드화하지 마
- [ ] `consent_confirmed`가 true로 확인되지 않은 사건 사례를 소재로 쓰지 마
- [ ] "최고"/"유일" 등 최상급·독점 표현, 승소율/성공률 수치 표현, 특정 사건 결과의 일반화, "OO 전문 로펌"식 법인 단위 전문 표시를 쓰지 마 (위 "법률 광고 표현 규칙" 참고 -- 개인 변호사 등록 전문분야 표현은 허용)
- [ ] 출처가 불분명한 이미지(뉴스 기사 사진, 유튜브 썸네일 등)를 무단으로 카드에 쓰지 마 -- 라이선스 프리 소스(Unsplash 등)나 자체 제작 이미지만 사용
- [ ] 승인된 템플릿 파일(`templates/`)을 임의로 재생성하거나 스타일을 바꾸지 마
- [ ] `design_approved`와 `fact_check_confirmed`가 모두 true이고 `locked=true`가 아닌 CardSet을 업로드하지 마
- [ ] Instagram API 요청 한도(24시간 100건)를 초과하는 배치 업로드를 만들지 마
- [ ] 목업 이미지나 가짜 업로드 성공 메시지로 완성됐다고 보고하지 마

---

## 항상 해 (ALWAYS DO)

- [ ] 카드뉴스 생성 시 이미지와 함께 캡션 초안(`caption_draft`)과 원문 대조 자료(`fact_check_ref`)를 같이 만들어 승인 전에 보여줘
- [ ] "디자인 승인"(`design_approved`)과 "사실관계 확인"(`fact_check_confirmed`)을 분리해서 각각 확인받아
- [ ] 사건/의뢰인 관련 소재는 비식별화 여부와 조합 재식별 위험을 항상 재검토해
- [ ] Instagram API 에러(토큰 만료, 심사 미승인 등) 발생 시 원인과 대처법을 명확히 알려줘
- [ ] 승인된 템플릿을 그대로 재사용해 (매번 스타일이 달라지지 않게 -- 신뢰도에 직결)
- [ ] 중복 방지 이력 파일은 매 실행마다 최신 상태로 갱신해
- [ ] 게시 후 오류가 발견되면 `mark_correction` 스크립트로 정정/삭제 상태를 UploadRecord 이력에 기록해
- [ ] 장기 액세스 토큰 발급일로부터 만료 임박(예: 50일 경과)이면 갱신이 필요하다고 미리 알려줘

---

## 테스트 방법

```bash
# 이미지 생성만 단독 테스트 (업로드 없이)
{Phase 1 구현 시 확정될 실행 명령}

# Playwright 스모크 테스트 -- Phase 0/1 착수 전 반드시 1회 실행해 환경을 확인
npx playwright install chromium
node -e "require('playwright').chromium.launch().then(b => { console.log('Playwright OK'); b.close(); })"

# Instagram API 토큰 유효성 테스트 (Instagram Login 방식 -- graph.instagram.com 사용, graph.facebook.com 아님)
curl -i -X GET "https://graph.instagram.com/v21.0/me?access_token=$IG_ACCESS_TOKEN"

# 실제 업로드 테스트는 테스트용 비공개 게시물로 먼저 검증
```

---

## 배포 방법

별도 배포가 필요 없는 개인 도구입니다. Claude Code가 설치된 로컬 환경에서 실행합니다.

---

## 환경변수

| 변수명 | 설명 | 어디서 발급 |
|--------|------|------------|
| IG_ACCESS_TOKEN | Instagram User access token (Instagram Login 방식) | Meta for Developers 앱 설정 -- Instagram API with Instagram Login |
| IG_USER_ID | Instagram 프로페셔널 계정 ID | Meta Graph API Explorer (`graph.instagram.com/me`) |
| IG_TOKEN_ISSUED_AT | 토큰 발급일 (만료 임박 감지용, 장기 토큰은 보통 60일 만료) | 토큰 발급 시 스크립트가 자동 기록 |

> `.env` 파일에 저장. 절대 GitHub에 올리지 마세요.

---

## [NEEDS CLARIFICATION]

- [ ] Playwright 등 이미지 캡처 도구를 설치할 수 있는 로컬 환경인지 (Node.js 필요) -- 위 스모크 테스트로 착수 전 확인
- [ ] 카드뉴스 템플릿 새 디자인의 구체적 톤앤매너
- [ ] "보험전문"/"손해배상전문"/"교통사고전문" 표현이 실제로 대한변호사협회에 등록된 전문분야인지 확인 필요 (등록 안 됐다면 표시 자체를 재검토)
