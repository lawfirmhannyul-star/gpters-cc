# 인스타 카드뉴스 자동화 -- Phase 분리 계획

> 한 번에 다 만들면 복잡해져서 품질이 떨어집니다.
> Phase별로 나눠서 각각 "진짜 동작하는 제품"을 만듭니다.
>
> **v2 변경 사항** (kkirikkiri 리뷰 반영): Phase 0에 Playwright 스모크 테스트 추가, Phase 1에 캡션/원문대조/정정기록 기능과 사실관계 체크리스트 추가, Phase 1 시작 프롬프트의 확정/미확정 사항을 명확히 구분, Phase 2에 토큰 갱신·소재 부적합 처리 추가, Phase 3에 성과 지표 추적·배치 검토 부담 항목 추가.

---

## Phase 0: 사전 준비 (Instagram 계정 확인 + 환경 확인)

> 확인 결과: 프로페셔널 계정 전환은 이미 완료됨. **Facebook 페이지는 연결하지 않기로 결정.**
> Meta가 2023년 이후 제공하는 **"Instagram API with Instagram Login"** 방식을 쓰면 Facebook 페이지 연결 없이 Instagram 계정만으로 인증·게시가 가능합니다 (구버전 "Facebook Login" 방식만 페이지가 필요). 캐러셀(카드뉴스) 게시는 이 방식에서도 동일하게 지원됩니다.

### 확인 방법
1. ~~Instagram 앱 -> 프로필 -> 설정 -> "계정 유형 및 도구"에서 프로페셔널 계정 확인~~ -- **완료됨**
2. ~~Facebook 페이지 연결~~ -- **불필요 (Instagram Login 방식 사용)**
3. [Meta for Developers](https://developers.facebook.com/)에서 앱을 등록하고, **Instagram API with Instagram Login** 제품을 추가. `instagram_business_basic` / `instagram_business_content_publish` 권한을 신청.
4. 테스트 단계(최대 25명 테스트 사용자)에서는 App Review 없이 바로 API 호출이 가능하지만, **실제 서비스로 쓰려면 Meta의 App Review 승인(보통 2~4주 소요)이 필요**합니다.
5. **Playwright 스모크 테스트**: 로컬에 Node.js가 있는지, `npx playwright install chromium` + headless 브라우저 실행이 되는지 1회 확인 (04_PROJECT_SPEC.md "테스트 방법" 참고). 이미지 생성 기능은 이 확인과 무관하게 먼저 개발 가능하지만, 실제 PNG 캡처는 이 확인이 끝나야 검증된다.

### 완료 기준
- [x] Instagram이 프로페셔널(비즈니스/크리에이터) 계정이다
- [x] Facebook 페이지 연결 여부 결정 -- 연결하지 않음 (Instagram Login 방식 사용)
- [ ] Meta 개발자 앱에 "Instagram API with Instagram Login"이 등록되어 있고, `curl https://graph.instagram.com/v21.0/me` 로 테스트 토큰 호출이 성공한다
- [x] Playwright가 로컬에서 정상 설치·실행된다 (스모크 테스트 통과 -- Chromium 설치 후 1080x1080 HTML을 실제 PNG로 캡처하는 것까지 확인함, 2026-07-15)

> 이 단계가 끝나기 전에는 Phase 1의 "Instagram API 연동"과 "이미지 PNG 캡처" 기능을 실제로 테스트할 수 없습니다. 소재 분석·카드 구조화 로직은 이 단계와 무관하게 먼저 개발/테스트 가능합니다.

---

## Phase 1: MVP

### 목표
소재(유튜브 URL/뉴스 URL/판결 URL/텍스트)를 직접 입력하면 카드뉴스 이미지 + 캡션 + 원문 대조 자료가 생성되고, 변호사가 디자인과 사실관계를 각각 승인하면 실제 인스타그램 계정에 캐러셀로 게시된다. 게시 후 오류를 발견하면 정정/삭제 상태를 기록할 수 있다.

### 기능
- [ ] 소재 입력 받기 (유튜브 URL / 뉴스 URL / 판결문 URL / 직접 텍스트)
- [ ] `text` 타입 소재는 `case_status`(확정/진행중)와 `consent_confirmed`(의뢰인 동의 확인) 입력을 함께 받음 -- 진행중이거나 동의 미확인이면 생성 차단
- [ ] 콘텐츠 분석 및 카드 구조화 (기본값 8장 내외 -- **확정 아님**, 후킹-쟁점-사례-법리-결과-팁-CTA), 04_PROJECT_SPEC.md "법률 광고 표현 규칙" 준수
- [ ] 승인된 고정 템플릿(`templates/default_v1.html`)으로 1080x1080 카드뉴스 이미지(PNG) 생성
- [ ] 캡션 + 해시태그 초안(`caption_draft`) 생성
- [ ] 원문 대조 자료(`fact_check_ref`) 생성 -- 카드별 핵심 주장이 원문 어디에 근거하는지 정리
- [ ] 로컬 폴더에 이미지 + 캡션 + 대조 자료를 함께 저장, 미리보기
- [ ] 승인: `design_approved`(디자인)와 `fact_check_confirmed`(사실관계)를 분리해서 확인받고, 둘 다 완료되면 `locked=true`로 고정
- [ ] 승인된(잠긴) 세트만 Instagram API로 캐러셀 게시
- [ ] 게시 후 오류 발견 시 정정/삭제 상태를 이력에 기록하는 명령(`mark_correction`)
- [ ] 사용한 소재를 이력 파일(`history/source_history.json`, `{type}:{source_key}` 키 객체)에 기록

### 데이터
- Source, CardSet, UploadRecord (02_DATA_MODEL.md v2 기준 -- case_status/consent_confirmed/caption_draft/fact_check_ref/design_approved/fact_check_confirmed/locked 필드 포함)

### 인증
- Instagram API with Instagram Login 액세스 토큰 (`.env`에 저장, 발급일도 `IG_TOKEN_ISSUED_AT`로 함께 저장)
- 전제 조건: Phase 0가 완료되어 있어야 함 (프로페셔널 계정 + Meta 앱 등록 + Playwright 스모크 테스트)

### "진짜 제품" 체크리스트
- [ ] 실제 이미지 파일이 로컬에 생성됨 (가짜 미리보기 X)
- [ ] 실제 Instagram API 토큰으로 연동 (하드코딩된 응답 X)
- [ ] 실제 인스타그램 계정에 실제로 게시됨 (게시 시뮬레이션 X)
- [ ] 승인 없이는 게시가 절대 일어나지 않음 (승인 게이트가 코드로 강제됨)
- [ ] 카드 문구가 원문과 대조된 상태로 변호사가 사실관계를 확인(`fact_check_confirmed`)한 뒤에만 게시됨

### Phase 1 시작 프롬프트
```
이 PRD를 읽고 Phase 1을 구현해주세요.
@PRD/01_PRD.md
@PRD/02_DATA_MODEL.md
@PRD/04_PROJECT_SPEC.md

Phase 1 범위:
- 소재 입력(유튜브/뉴스/판결/텍스트) 받기, text 타입은 case_status·consent_confirmed 함께 입력
- 콘텐츠 분석 및 카드 구조화 (카드 장수는 기본값 8장으로 시작하되 확정 값은 아니므로 이후 조정 가능하게 설계)
- 캡션/해시태그 초안 + 원문 대조 자료 생성
- 승인된 고정 템플릿으로 1080x1080 PNG 카드뉴스 생성
- 로컬 저장 및 미리보기 (이미지 + 캡션 + 대조 자료 함께)
- design_approved / fact_check_confirmed 분리 승인 -> 둘 다 완료 시 locked=true
- locked=true인 세트만 Instagram API로 캐러셀 게시
- 게시 후 정정/삭제 상태 기록 명령
- 사용한 소재를 이력 파일에 기록

착수 전 확인:
- Phase 0가 완료됐는지 (계정/앱 등록/Playwright 스모크 테스트)
- 카드뉴스 템플릿 톤앤매너가 아직 미정이면, 먼저 임시 기본 스타일로 진행하고 이후 피드백으로 조정할 것

반드시 지켜야 할 것:
- 04_PROJECT_SPEC.md의 "절대 하지 마"와 "법률 광고 표현 규칙" 준수
- 승인 없이는 어떤 경우에도 업로드하지 않음 (design_approved AND fact_check_confirmed AND locked)
- API 토큰은 .env로만 관리
```

---

## Phase 2: 확장

### 전제 조건
- Phase 1이 안정적으로 동작하고, 실제로 몇 차례 승인-업로드 사이클을 거친 상태

### 목표
소재를 직접 주지 않아도 도구가 스스로 소재를 찾아오고, 운영 중 생기는 문제(토큰 만료, 부적합한 소재)에 스스로 대응할 수 있게 된다.

### 기능
- [ ] 소재 자동 탐색: "한세영변호사tv" 채널에서 아직 다루지 않은 최신 영상을 자동 선정
- [ ] 자동 탐색한 소재가 카드뉴스로 부적합(내용이 얇거나 민감함)하면 Source.status를 `rejected`로 기록하고 다음 후보로 넘어감
- [ ] 장기 액세스 토큰 만료 임박 감지 및 갱신 안내 (발급 후 50일 경과 시 알림)
- [ ] 업로드 실패 시 재시도 로직 + 에러 메시지 안내
- [ ] 카드 장수(6/8/10)와 테마(다크/라이트) 옵션화

### 추가 데이터
- Source.status에 `auto_discovered` 케이스 추가 (수동 입력과 구분)

### 통합 테스트
- Phase 1의 수동 소재 입력 흐름이 여전히 정상 동작하는지 확인
- 자동 탐색이 이미 이력에 있는 영상을 다시 고르지 않는지 확인
- 부적합 소재를 `rejected`로 넘긴 뒤 같은 소재를 다시 고르지 않는지 확인

---

## Phase 3: 고도화

### 전제 조건
- Phase 1 + 2가 안정적으로 운영 중이며, 인스타그램 계정 성장 추이를 데이터로 볼 수 있는 상태

### 목표
운영 부담을 더 줄이고, 여러 소재를 한 번에 처리하며, 이 도구가 실제로 팔로워 성장에 기여하는지 데이터로 확인할 수 있게 된다.

### 기능
- [ ] 여러 소재 배치 처리 (한 번 실행으로 여러 개의 카드뉴스 초안 생성) -- 배치 규모에 비례해 검토 시간이 늘어나므로, 일괄 승인/반려 UX를 함께 설계
- [ ] 게시 예약(스케줄링) -- 승인은 여전히 필요, 승인된 게시물의 게시 "시각"만 예약
- [ ] 성과 지표 추적: 게시물별 도달/저장/팔로워 증감을 Instagram Insights에서 수동 또는 반자동으로 참고할 수 있는 최소 기록(게시일, 소재 유형)을 UploadRecord와 연결
- [ ] (조건부) 완전 무인 자동 업로드 모드 -- 변호사 광고 규정 검토가 끝나고, 자동 생성 품질이 충분히 검증된 뒤에만 재검토

### 주의사항
- Instagram API 요청 한도(24시간 100건)를 고려한 배치 크기 제한 필요
- 완전 무인 모드는 Phase 1/2의 성공 기준(사실관계 정확도)이 충분히 검증되기 전까지는 만들지 않는다
- 배치 처리 도입 시, 세트당 검토 시간이 병목이 될 수 있으므로 일괄 승인 UX를 먼저 검증할 것

---

## Phase 로드맵 요약

| Phase | 핵심 기능 | 상태 |
|-------|----------|------|
| Phase 0 | Instagram 계정 확인 + Meta 앱 등록 + Playwright 스모크 테스트 | 시작 전 (앱 등록/스모크 테스트 미확인) |
| Phase 1 (MVP) | 수동 소재 입력 -> 카드뉴스+캡션+원문대조 생성 -> 분리 승인 -> Instagram 업로드 -> 정정 기록 | Phase 0 완료 후 |
| Phase 2 | 소재 자동 탐색 + 부적합 소재 처리 + 토큰 갱신 감지 + 업로드 재시도 | Phase 1 완료 후 |
| Phase 3 | 배치 처리 + 예약 게시 + 성과 지표 추적 + (조건부) 완전 자동화 재검토 | Phase 2 완료 후 |
