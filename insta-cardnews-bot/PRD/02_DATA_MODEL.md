# 인스타 카드뉴스 자동화 -- 데이터 모델

> 이 문서는 도구가 다루는 핵심 데이터의 구조를 정의합니다.
> 개발자가 아니어도 이해할 수 있는 "개념적 ERD"입니다.
>
> **v2 변경 사항** (kkirikkiri 리뷰 반영): Source의 상태 관리를 CardSet/UploadRecord로 일원화, 캡션·원문대조·사실확인 필드 추가, 사건 소재 안전장치(진행상태·동의확인) 추가, 업로드 후 정정/삭제 상태 추가.

---

## 전체 구조

```
[Source(소재)] --1:N--> [CardSet(카드뉴스 세트)] --1:N--> [UploadRecord(업로드 이력)]
```

---

## 엔티티 상세

### Source (소재)
유튜브 영상, 뉴스 기사, 판결문, 또는 직접 입력한 사건 처리 텍스트 -- 카드뉴스의 원재료.

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| id | 고유 식별자 (자동 생성) | src_20260715_001 | O |
| type | 소재 종류 | youtube / news / ruling / text | O |
| source_key | 중복 판단 기준값 (유튜브 영상 ID, 또는 뉴스/판결 URL) | dQw4w9WgXcQ | O |
| title | 소재 제목 | "보험금 지급거절, 이렇게 뒤집었습니다" | O |
| raw_content | 원문(자막/기사본문/판결요지/직접입력 텍스트) | (텍스트 전문) | O |
| case_status | 사건 진행 상태 (`text` 타입 소재에만 해당, 그 외는 "해당없음") | 확정 / 진행중 / 해당없음 | O |
| consent_confirmed | 의뢰인 동의 확인 여부 (`text` 타입 소재에만 해당, 그 외는 "해당없음") | true / false / 해당없음 | O |
| fetched_at | 원문을 수집한 시각 | 2026-07-15T10:00:00 | O |
| used_at | 마지막으로 카드뉴스 제작에 쓰인 시각 (미사용이면 비어있음) | 2026-07-15T10:05:00 | X |
| status | 소재 자체의 처리 상태 (승인·업로드 상태는 CardSet/UploadRecord가 관리 -- 아래 "왜 이 구조인가" 참고) | pending / analyzed / rejected | O |

> **`case_status`가 "진행중"이면 이 소재는 소재 자동 탐색·수동 입력 모두에서 사용을 차단하거나 경고한다.** 확정되지 않은 사건 결과를 확정된 것처럼 카드화하는 위험을 막기 위함.
> **`consent_confirmed`가 false거나 미기록이면 이 소재로 카드뉴스를 생성하지 않는다.** (04_PROJECT_SPEC.md "절대 하지 마" 참고)

### CardSet (카드뉴스 세트)
하나의 소재로부터 생성된 카드뉴스 이미지 + 캡션 묶음.

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| id | 고유 식별자 (자동 생성) | cardset_20260715_001 | O |
| source_id | 어떤 소재로 만들었는지 (Source 참조) | src_20260715_001 | O |
| card_count | 카드 장수 | 8 | O |
| template_style | 사용한 비주얼 템플릿 이름 (승인된 고정 템플릿 파일을 참조 -- 매번 새로 디자인하지 않음) | default_v1 | O |
| image_paths | 생성된 PNG 파일 경로 목록 (경로에 이 CardSet의 id를 포함해 재생성 시 이전 버전을 덮어쓰지 않음) | ["output/.../cardset_20260715_001/card_1.png", ...] | O |
| caption_draft | 게시용 캡션 + 해시태그 초안 (승인 검토 대상에 이미지와 함께 포함됨) | (캡션 + 해시태그 전문) | O |
| fact_check_ref | 원문 대조 자료 경로 -- 카드별 핵심 주장이 원문 어디에 근거하는지 정리한 텍스트 파일 | fact-check/cardset_20260715_001.md | O |
| design_approved | 이미지 디자인 승인 여부 ("보기 좋은가"에 대한 승인) | true / false | O |
| fact_check_confirmed | 사실관계 확인 여부 (원문 대조를 거쳤다는 승인 -- design_approved와 분리) | true / false | O |
| locked | 승인 후 이 세트를 고정하고 재생성을 막는 플래그 (승인된 버전과 실제 업로드 버전이 달라지는 것을 방지) | true / false | O |
| generated_at | 이미지 생성 시각 | 2026-07-15T10:10:00 | O |
| approved_at | 두 승인(design_approved, fact_check_confirmed)이 모두 완료된 시각 | 2026-07-15T11:00:00 | X |

> **업로드는 `design_approved=true` AND `fact_check_confirmed=true` AND `locked=true`인 CardSet만 대상으로 한다.** 디자인만 보고 대충 승인하는 상황을 막기 위해 두 승인을 분리했다.

### UploadRecord (업로드 이력)
승인된 카드뉴스 세트를 실제로 인스타그램에 올린 기록과, 게시 이후의 상태 변화.

| 필드 | 설명 | 예시 | 필수 |
|------|------|------|------|
| id | 고유 식별자 (자동 생성) | upload_20260715_001 | O |
| card_set_id | 어떤 카드뉴스 세트를 올렸는지 (CardSet 참조, `locked=true`인 정확한 버전만 참조) | cardset_20260715_001 | O |
| instagram_media_id | Instagram이 반환한 게시물 ID | 179xxxxxxxxxx | X (성공 시에만) |
| caption | 실제로 게시된 최종 캡션 (CardSet.caption_draft에서 최종 확정된 버전) | (캡션 전문) | O |
| posted_at | 게시 시각 | 2026-07-15T11:05:00 | O |
| status | 업로드/게시물 상태 | success / failed / corrected / deleted | O |
| status_updated_at | status가 마지막으로 바뀐 시각 (정정·삭제 시 갱신) | 2026-07-20T09:00:00 | X |
| error_message | 실패 시 에러 내용 | "token expired" | X |

> **`corrected`/`deleted`는 게시 후 사실관계 오류를 발견했을 때 수동으로 기록한다.** (04_PROJECT_SPEC.md "항상 해" 참고 -- Instagram 앱에서 실제 정정/삭제 후, 도구에 "정정했어"/"삭제했어"라고 알리면 이력에 반영)

### 관계
- Source 1개는 CardSet을 1개 이상 가질 수 있음 (재생성 시 여러 버전이 생길 수 있으므로 1:N)
- CardSet 1개는 UploadRecord를 1개 이상 가질 수 있음 (업로드 실패 후 재시도 시 여러 기록이 남으므로 1:N)

---

## 중복 방지 이력 파일 구조

`history/source_history.json`은 배열이 아니라 **`{type}:{source_key}`를 키로 하는 객체(dict)**로 저장한다.

```json
{
  "youtube:dQw4w9WgXcQ": { "source_id": "src_20260715_001", "used_at": "2026-07-15T10:05:00" },
  "news:https://example.com/article-123": { "source_id": "src_20260715_002", "used_at": "2026-07-14T09:00:00" }
}
```

중복 체크는 반드시 이 키로 조회하는 공통 함수 하나만 거치도록 한다 (04_PROJECT_SPEC.md "절대 하지 마" 참고 -- 스크립트마다 직접 비교 로직을 재구현하지 않는다).

---

## 왜 이 구조인가

- **Source.status를 "소재 자체의 상태"로만 좁힌 이유**: 이전 버전은 Source.status에 `approved`/`uploaded`까지 넣었는데, Source 1개가 CardSet 여러 개(재생성)를 가질 수 있는 구조와 충돌했다. 어떤 CardSet이 승인·업로드됐는지는 Source 하나의 값으로 표현할 수 없으므로, "승인"과 "업로드"는 각각 CardSet과 UploadRecord에만 두고 Source는 `pending/analyzed/rejected`(수집·분석·부적합 판정)만 관리한다.
- **CardSet과 UploadRecord를 분리한 이유**: 이미지는 만들었지만 아직 승인/업로드 전인 상태(검토 단계)가 실제로 존재하기 때문에, "생성됨"과 "게시됨"을 다른 엔티티로 나눠야 승인 게이트가 데이터 구조에서도 명확해진다.
- **design_approved와 fact_check_confirmed를 분리한 이유**: 승인이 "이미지 훑어보기" 한 번으로 끝나면 사실관계 왜곡을 잡아내기 어렵다. 두 체크박스를 분리해 "예쁜가"와 "사실관계가 맞는가"를 각각 명시적으로 확인하게 한다.
- **locked 필드를 둔 이유**: 승인 후에도 같은 Source로 재생성이 가능한 구조라, 락 없이는 "승인한 버전"과 "업로드 스크립트가 집어드는 버전"이 달라질 수 있다. 업로드는 반드시 `locked=true`인 CardSet만 대상으로 한다.
- **확장성**: Phase 2의 배치 처리, Phase 3의 예약 게시가 추가되어도 이 3개 엔티티 뼈대는 그대로 유지되고 필드만 늘어난다 (예: CardSet에 scheduled_at 필드 추가).
- **단순성**: 개인 도구 규모이므로 DB 대신 로컬 JSON 파일로 구현 가능한 구조로 설계했다.

---

## [NEEDS CLARIFICATION]

- [ ] 카드 장수를 8장으로 고정할지, Phase 1부터 가변으로 둘지 (01_PRD.md 가정 원장 #3 참고)
