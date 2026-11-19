# CLAUDE.md

> 이 파일의 공통 규칙은 경영지원파트 박종서가 작성했습니다. 규칙 때문에 작업이
> 막히거나 이해가 안 되면 코드나 이 파일을 임의로 고치지 말고 먼저 경영지원파트
> (박종서, 조민기)에게 문의하세요.

`speedrack-co/repo-template`에서 복사된 공통 규칙입니다. 아래 「이 앱에 대해」만
앱에 맞게 채우고, 그 뒤 공통 규칙은 앱마다 다시 쓰거나 지우지 않습니다.

## 이 앱에 대해

- 하는 일:
- 담당자:
- 배포: (Vercel / Render / Railway / 기타 — AccessHub에 등록한 것과 같게)
- DB — **2번 절차가 여기서 갈립니다. 비워두지 마세요.**
  - Supabase 조직(org):
  - 프로젝트 이름 / ref: (AccessHub 심사에서 정해집니다. 세션이 고르지 않습니다 — 2번)
  - 스키마: (추측해서 적지 않습니다. AccessHub에서 새로 받았으면 보통 repo 이름을 소문자로 바꾼 이름이고,
    「이미 운영 중인 앱」으로 기존 스키마를 연결했으면 그 스키마 이름입니다. AccessHub 「내 repo 등록」 카드와 DB 비밀번호 발급
    화면에 표시된 이름을 적습니다. `db-apply.yml`의 `DB_SCHEMA`와 같아야 합니다)
  - DB 적용 계정: (`ai_data_hub` 앱 DB면 `<스키마>_app`, 부서 프로젝트면 그 프로젝트 접속. 아직 옮기지 않은 옛 `ai_data_hub` 스키마면 「`MS_supabase_schema`로 관리 중」)
  - 접속 주소(`DATABASE_URL`) 등록 — **값은 적지 않고, 등록했는지만 적습니다.** AI 세션은 아래 두 곳을 볼 수 없어서
    여기 적힌 것으로만 압니다(2번).
    - GitHub 저장소 Secret (DB 자동 적용용): 미등록 / 등록함(날짜)
    - 배포 플랫폼 환경변수 (앱 서버용. 예: Railway Variables): 미등록 / 등록함(날짜)

---

## 0. 작업을 시작하기 전에 — 먼저 읽을 문서

이 파일은 세션마다 자동으로 읽히지만, `new-app-guide.md`·`migration-guide.md`·`supabaseauthloginguide.md`는 **직접 열어야** 읽힙니다.
아래에 해당하면 **코드를 쓰기 전에** 그 문서를 처음부터 끝까지 읽고 그 순서를 따르세요.

| 요청이나 작업에 이런 것이 있으면 | 먼저 읽을 문서 |
|---|---|
| **새로 만드는 저장 기능** — 저장·불러오기·등록·수정·삭제·목록처럼 새로고침 뒤에도 남아야 하는 데이터, 테이블·DB 연결, 목업·`useState`·localStorage를 실제 저장으로 바꾸기 | `new-app-guide.md` (아래 7번) |
| **다른 곳에 쌓인 데이터 옮기기** — Replit·Lovable·개인 PC·다른 DB에서 쓰던 앱의 실데이터 이관 | `migration-guide.md` (아래 7번) |
| 로그인·로그아웃·계정·비밀번호, 권한·관리자·「본인 것만 보기」, 자체 서버 API(`/api/…`)를 만들거나 고치기 | `supabaseauthloginguide.md` — §2부터, 자체 서버가 있으면 §7 필수 (아래 6번) |
| 테이블·컬럼·뷰·RLS·함수 변경, 운영 데이터 INSERT/UPDATE/DELETE | 이 파일 2번 |

- 요청에 위 단어가 없어도 **결과적으로 해당하면** 같습니다. 「저장 버튼이 동작하게 해줘」는 데이터 저장 작업입니다.
- 새로 만드는 것인지 옮기는 것인지는 **옮길 실데이터가 있는가**로 가릅니다. 테스트 데이터뿐이면 새로 만드는 쪽입니다.
- 해당하는지 애매하면 읽는 쪽을 고릅니다. 읽지 않고 시작했다면 멈추고, 읽은 뒤 이어갑니다.
- 화면 문구·스타일 수정처럼 위에 해당하지 않는 작업은 이 파일만으로 충분합니다.
- **앱이 아닌 repo(업무 문서·RuleBook 등)에는 이 표가 해당하지 않습니다.** 문서에 「등록」「수정」「목록」 같은 단어가
  나와도 앱 가이드를 열지 않습니다.

## 1. main에 직접 커밋·푸시하지 않습니다

조직이 GitHub Free 플랜이라 **private repo에는 브랜치 보호(Rulesets / branch
protection)가 걸리지 않습니다.** 설정 화면에서 규칙을 만들어도 "won't be enforced"
경고와 함께 무시됩니다. 즉 `git push origin main`이 아무 저항 없이 성공합니다.
막아주는 장치가 없으니 규칙으로 지킵니다.

- 작업은 항상 새 브랜치에서 하고, 변경은 PR로 올립니다.
- **머지는 담당자가 합니다.** AI는 PR을 올리는 데까지만 하고 스스로 머지하지 않습니다.
- `--force` 푸시, 브랜치 삭제, 이력 재작성 금지. 되돌릴 수 없습니다.
- **예외: 공통 설명서 자동 동기화.** `speedrack-co/repo-template`의 공통 설명서 4개(`CLAUDE.md`·`CONTRIBUTING.md`·
  `migration-guide.md`·`supabaseauthloginguide.md`)를 최신으로 맞추는 PR(`template-sync/` 브랜치)은 경영지원파트의
  주간 자동화가 올리고 바로 병합합니다. 이 PR은 네 파일 외에는 아무것도 바꾸지 않고, 「이 앱에 대해」는 그대로 둡니다.
  앱에서 직접 고친 설명서는 덮어쓰지 않고 담당자 확인으로 남깁니다. 공통 부분을 바꿔야 하면 앱 repo에서 고치지 말고
  `repo-template`에 PR로 올리세요.

## 2. Supabase 스키마 변경 시 필수 절차

**이 앱 전용 스키마의 변경 이력은 이 repo에 둡니다.** (2026-10-28 변경 — 전에는 경영지원 앱은
`MS_supabase_schema`, 부서 앱은 `supabase/applied/`에 기록했습니다.)

| 바꾸려는 것 | 어디서 | 누가 merge |
|---|---|---|
| **이 앱의 스키마**(「이 앱에 대해」의 스키마) | **이 repo** `db/migrations/` → `main`에 merge되면 GitHub Actions(`.github/workflows/db-apply.yml`)가 `scripts/db-migrate.sh`로 자동 적용 | 이 앱 담당자 |
| 회사 공용 스키마(`public`·`data_access`·`erp_raw`·`smarthub` 등)나 **다른 앱의 스키마** | 직접 바꾸지 않습니다. 공용은 경영지원파트(`speedrack-co/MS_supabase_schema` PR), 다른 앱은 그 앱 담당자에게 요청 | 그쪽 담당자 |

어느 Supabase 프로젝트든 같은 방식입니다. 프로젝트마다 다른 것은 **접속 계정**뿐입니다.

| 데이터 위치 | 적용에 쓰는 접속(`DATABASE_URL`) |
|---|---|
| **AccessHub 「내 repo 등록」으로 받은 앱 스키마** (기본. `ai_data_hub`든 부서 프로젝트든 같습니다) | 그 앱 전용 DB 계정 `<스키마>_app` — AccessHub 「DB 비밀번호 발급」으로 받은 접속 정보. 이 계정은 자기 스키마만 바꿀 수 있습니다 |
| AccessHub 없이 쓰던 부서 프로젝트의 스키마 (예전 방식) | 그 프로젝트의 DB 접속 문자열(부서 관리자에게 받음) |
| `ai_data_hub`인데 아직 앱 DB로 옮기지 않은 옛 스키마 (스키마 주인이 `postgres`) | 옮기기 전까지는 예전처럼 `MS_supabase_schema` PR. 옮기는 순서는 경영지원파트가 앱별로 안내합니다 |

⚠ **어느 Supabase 프로젝트에 둘지는 AccessHub 심사에서 정해집니다.** 관리자가 저장 위치를 고르거나, repo 이름의
부서 약어로 자동으로 정해집니다. **세션은 프로젝트를 고르지 않고, 담당 부서를 물어 추정하지도 않습니다.**
「이 앱에 대해」에 적힌 프로젝트·스키마를 따르고, 비어 있으면 AccessHub 승인 내용을 사용자에게 물어 적습니다.
`list_projects`에 하나만 나온다고 그게 목적지라고 판단하지 마세요 — 세션의 Supabase MCP는 **연결이 허가된 조직의
프로젝트만** 보여줍니다.

### AI 세션이 이 repo에서 DB 작업을 시작할 때

이 repo는 **`[DB]` PR이 `main`에 merge되면 GitHub Actions가 DB에 적용하는 구조**입니다. AI 세션은 DB에 직접 붙지 않고
SQL 파일을 PR로 올리는 데까지 합니다.

**AI 세션은 GitHub 저장소 Secret과 배포 플랫폼(Railway 등)의 환경변수를 볼 수 없습니다.** 등록됐는지는
「이 앱에 대해」에 적힌 것과 사용자의 답으로만 알 수 있습니다. 그래서 이 repo의 첫 DB 작업이면 **SQL을 쓰기 전에**
아래를 확인하고, 안 된 것은 그 자리에서 사용자에게 안내합니다. PR을 올린 뒤에 알리면 merge했을 때 적용이 실패합니다.

1. **파일이 있는가** — `.github/workflows/db-apply.yml`, `scripts/db-migrate.sh`, `db/migrations/`.
   없으면 `speedrack-co/repo-template`의 것을 고치지 않고 그대로 가져옵니다.
   **이미 테이블이 있는 운영 중인 앱이면 기준선을 먼저 기록해야 합니다**(아래 「예전 기록」, `migration-guide.md` §4-1).
   기록 전에는 워크플로가 적용하지 않고 멈춥니다.
2. **DB가 준비됐는가** — 「이 앱에 대해」의 DB 항목이 비어 있으면 사용자에게 묻습니다: AccessHub 「내 repo 등록」
   (「자기 DB 사용」)이 승인됐는지, 「DB 비밀번호 발급」을 받았는지. 안 됐으면 그것부터 안내합니다 — DB가 필요한 앱은
   AccessHub 「내 repo 등록」에서 「자기 DB 사용」으로 신청하고, 관리자 승인 뒤 「DB 비밀번호 발급」으로 접속 주소를 받습니다.
3. **어느 프로젝트의 어느 스키마인가** — 「이 앱에 대해」에 없으면 **사용자에게 확인을 부탁합니다. repo 이름이나 부서로
   추측하지 않습니다.** 스키마 이름은 AccessHub 「내 repo 등록」 카드와 「DB 비밀번호 발급」 화면에 표시됩니다.
   프로젝트는 AccessHub 심사에서 정해졌습니다(위 ⚠).
   AccessHub에서 새로 받은 스키마는 보통 repo 이름을 소문자로 바꾼 것이지만(`MS_snms` → `ms_snms`), 등록할 때
   「이미 운영 중인 앱」에서 「회사 DB 에 있음 (이름이 레포와 다름)」으로 기존 스키마를 연결한 앱은 repo 이름과 다릅니다.
   대문자가 들어간 스키마(예: `MS_itemmaster`)는 자기 DB 연결 대상이 아닙니다 — 그런 이름이면 경영지원파트에 확인합니다.
   받은 이름을 **두 곳에 같은 값으로** 적습니다:
   「이 앱에 대해」의 스키마, 그리고 `.github/workflows/db-apply.yml`의 `DB_SCHEMA`(앱마다 고치는 곳은 이 한 줄뿐입니다).
   `DB_SCHEMA`가 비어 있으면 워크플로가 적용하지 않고 실패합니다.
4. **`DATABASE_URL`이 두 곳에 등록됐는가** — 「이 앱에 대해」에 「등록함」이 아니면 사용자에게 등록을 부탁합니다.
   - GitHub: 이 repo의 Settings → Secrets and variables → Actions → New repository secret, 이름 `DATABASE_URL`
   - 배포 플랫폼: 환경변수 `DATABASE_URL` (같은 값)
   - 값은 사용자가 직접 넣습니다. **채팅에 붙여 달라고 하지 않습니다**(3번).
5. **등록이 맞는지 확인** — `DB_SCHEMA`를 적은 `db-apply.yml`이 `main`에 있으면, Actions 화면에서 「DB 적용」을
   `mode=dry-run`으로 실행해 보라고 안내합니다. 성공하면 Secret·접속·스키마 이름이 모두 맞는 것입니다. DB는 바뀌지 않습니다.
6. **확인한 내용을 「이 앱에 대해」에 적습니다** — 다음 세션이 같은 질문을 반복하지 않게.

`[DB]` PR 본문에는 「merge하면 DB에 자동 적용된다」는 것과, Secret이 아직 없다면 「merge 전에 등록이 필요하다」는 것을
적습니다. merge된 뒤에는 Actions의 「DB 적용」 실행 결과를 확인해 사용자에게 알립니다.

### 순서

1. **파일 작성** — 새 브랜치에서 `db/migrations/YYYYMMDDHHMMSS_설명.sql`. 이름은 소문자·숫자·`_`만,
   번호는 이 repo 안에서만 겹치지 않으면 됩니다(다른 앱·다른 부서와 번호를 맞출 필요가 없습니다).
   SQL 안의 객체 이름은 스키마를 붙여 씁니다(`myapp.orders`). 파일 안에 `begin;`/`commit;`을 넣지 않습니다
   — 스크립트가 파일 하나를 통째로 한 트랜잭션으로 묶습니다.
2. **미리 보기**(접속 주소가 있는 환경에서만) — `DATABASE_URL=… DB_SCHEMA=<스키마> scripts/db-migrate.sh --dry-run` 으로
   적용될 파일을 확인합니다. AI 세션에 접속 주소가 없으면 건너뛰고 PR에 그렇게 적습니다. 접속 주소는 비밀값이라
   채팅으로 받지 않습니다(3번).
3. **PR** — commit → push → PR. 제목은 `[DB] <설명>`, 라벨 `supabase-migration`.
   **테이블·컬럼 삭제나 기존 데이터 수정·삭제가 들어 있으면 PR 본문 맨 위에 무엇이 사라지거나 바뀌는지 쉬운 말로 적습니다.**
   merge하는 순간 운영 DB에 적용되고, 미리 돌려 볼 환경이 없습니다.
4. **merge** — 담당자가 합니다. AI는 스스로 merge하지 않습니다(1번).
5. **적용** — **`main`에 merge되면 GitHub Actions가 자동으로 적용합니다**(`.github/workflows/db-apply.yml` →
   `scripts/db-migrate.sh`). 접속 주소는 GitHub 저장소 Secret `DATABASE_URL`에서, 스키마 이름은
   `db-apply.yml`의 `DB_SCHEMA`에서 읽습니다. 적용한 파일은 그 스키마 안의
   `schema_history` 테이블에 버전·내용 해시·적용 계정·커밋이 남습니다. 워크플로가 적용 뒤 「적용할 파일 없음」까지
   확인하므로, **Actions의 「DB 적용」 실행이 성공하면 끝입니다.** 실패하면 로그의 원인을 담당자에게 알립니다.
   - `db-apply.yml`이 없는 repo(이 워크플로가 생기기 전에 만든 앱)는 merge된 `main`에서
     `scripts/db-migrate.sh`를 직접 실행하고, `--dry-run`으로 「적용할 파일 없음」을 확인합니다.
   - `db-apply.yml`에 `pull_request` 트리거를 넣지 않습니다. 같은 repo의 PR이 Secret을 읽게 됩니다.

**"DB 적용해줘"라고 요청받으면** 먼저 이미 적용됐는지 확인하세요(Actions의 「DB 적용」 실행 기록, 또는 `--dry-run`).
같은 내용을 다른 방법으로 다시 실행하지 마세요.

### 쓰지 않는 것

- `supabase db push` · `supabase migration up` · MCP `apply_migration` — 이 셋은 **프로젝트 전체가 함께 쓰는**
  기록 테이블(`supabase_migrations.schema_migrations`)을 씁니다. 여러 앱이 그 한 테이블을 같이 쓰면 남의 번호가
  "모르는 기록(고아)"으로 보이고 번호 순서가 엇갈려 다른 앱의 배포까지 막힙니다. 앱 DB 계정은 그 테이블에
  쓸 권한도 없습니다.
- MCP `execute_sql`·대시보드 SQL 편집기로 DDL을 바로 실행하는 것 — 이 repo에 기록이 안 남습니다.
- ORM의 자동 반영(`drizzle-kit push`, `prisma db push`, TypeORM `synchronize: true`).

**Drizzle·Prisma 등 다른 도구를 써도 됩니다.** 단 이력 테이블이 **이 앱 스키마 안**에 있어야 합니다.
Drizzle은 `migrations: { schema: '<스키마>' }`(기본값 `drizzle` 스키마는 앱 DB 계정이 만들 수 없음),
Prisma는 접속 주소에 `?schema=<스키마>`. 어느 도구든 SQL 파일이 이 repo에 남고 merge 후 적용하는 순서는
같습니다. 도구를 바꾸려면 경영지원파트와 먼저 얘기하세요(이력 테이블이 둘이 되면 안 됩니다).

### 어느 방식이든 공통

- 대상은 구조 변경(테이블/뷰/컬럼/인덱스/트리거/함수/RLS/권한)과 기존 운영 데이터 수정
  (INSERT/UPDATE/DELETE)입니다. **읽기 전용 SELECT/집계는 이 절차 없이 바로 실행해도 됩니다.**
- 이미 적용한 파일은 고치지 않습니다. 틀렸으면 고치는 새 파일을 추가합니다(스크립트가 내용 해시로
  바뀐 파일을 거부합니다).
- **다른 앱의 스키마는 건드리지 않습니다.** 앱 DB 계정은 애초에 못 바꾸고, 부서 프로젝트 접속은 바꿀 수
  있어도 하지 않습니다. 다른 앱 데이터가 필요하면 데이터마켓(AccessHub)으로 신청합니다.
- **Developer 권한이나 앱 DB 계정으로 안 되는 설정은 경영지원파트에 문의합니다.** Auth·API 설정, 접속 상한 변경
  같은 프로젝트 설정이 여기에 해당합니다. SQL로 우회하지 마세요.
- **「자기 DB」 스키마는 Exposed schemas(Settings → API)에 등록하지 않습니다.** 앱 서버가 `DATABASE_URL`로 붙으므로
  필요 없고, 등록된 스키마를 지우거나 이름을 바꾸면 그 프로젝트의 모든 API가 멈춥니다(`new-app-guide.md` 1절).
- 회사 전체의 구조 변경은 DB가 자동으로도 기록합니다(경영지원 `ddl_audit`). 이 repo의 기록을 대신하지는
  않습니다 — 왜 바꿨는지는 PR에만 남습니다.

### 예전 기록 (`supabase/applied/`)

예전 방식으로 남긴 `supabase/applied/` 파일과 `MS_supabase_schema`에 쌓인 옛 마이그레이션은 **지우지 않고
이력으로 둡니다.** 새 방식으로 처음 넘어올 때는 그 시점의 스키마 구조를 **기준선** 파일 하나로 만들어
「적용된 것으로」 기록합니다 — `db/migrations/<번호>_baseline.sql`을 PR로 merge한 뒤 Actions 화면에서 「DB 적용」을
`mode=baseline`으로 실행합니다(`migration-guide.md` §4-1). 기준선 파일은 실행되지 않습니다. 이후 변경은 `db/migrations/`에만 씁니다.

**작업을 완료로 표시하기 전에 위 순서(특히 5번 — Actions 「DB 적용」 실행 성공, 워크플로가 없으면 `--dry-run` 확인)를
끝냈는지 스스로 확인하세요.**

## 3. 비밀값

- API 키, 비밀번호, service_role key 등은 **절대 코드에 하드코딩하지 않습니다.**
  설정 파일(`.replit`, `vercel.json` 등)도 코드입니다.
- 실제 값은 배포 플랫폼(Railway/Vercel 등)의 Secrets/환경변수 기능에만 입력하고,
  어떤 변수가 필요한지는 `.env.example`에 **이름만** 남깁니다.
  DB 자동 적용(2번)에 쓰는 `DATABASE_URL` 하나만 GitHub 저장소 Secret
  (Settings → Secrets and variables → Actions)에도 넣습니다.
- `service_role` 키와 DB 접속 주소(`DATABASE_URL`)는 **서버 환경변수에만** 둡니다. `VITE_`·`NEXT_PUBLIC_`처럼
  브라우저로 나가는 접두사를 붙이면 빌드 결과물에 실려 누구나 볼 수 있게 됩니다.
- **이미 커밋된 비밀값을 발견하면**, 파일에서 지우는 것만으로는 해결되지 않습니다.
  git 이력에 그대로 남기 때문에 반드시 해당 키를 재발급(rotate)해야 합니다.
  발견 즉시 담당자에게 알리고, 임의로 조용히 지우지 마세요.

## 4. 권한 구조 (참고)

왜 이런 규칙이 필요한지에 대한 배경입니다.

- 조직 기본 권한은 **No permission**입니다. repo는 **부서 Team 단위**로만 보입니다.
- 부서원은 자기 부서 repo에 **Write**까지 갖습니다. **Admin은 Owner만** 갖습니다
  (그래서 repo 삭제·이전·공개전환·외부인 초대는 Owner만 가능합니다).
- 부서원 전원이 Write를 갖지만, **담당자 지정은 GitHub 권한이 아니라 팀 내
  합의**입니다. 담당자가 아니면 Write 권한이 있어도 직접 push하지 말고,
  CONTRIBUTING.md에 따라 Issue로 남겨주세요.
- 열람만 필요한 사람은 부서 Team에 넣지 말고, 해당 repo에만 **외부
  collaborator(Read)** 로 초대합니다. 조직 멤버라도 마찬가지입니다 — Team에
  넣으면 그 부서의 다른 repo까지 다 보이게 됩니다.
- AI가 이 repo에서 할 수 있는 일의 상한은 **그 작업을 지시한 사람의 GitHub 권한**입니다.
  Read 권한만 있는 사람은 `@claude`를 불러도 수정이 거부됩니다.

## 5. 이 템플릿으로 새 repo를 만들었다면

- [ ] README와 위 「이 앱에 대해」 채우기
- [ ] 담당 부서 Team에 이 repo 접근 권한 부여 (Settings → Collaborators and teams)
- [ ] Claude App 접근 범위에 이 repo가 포함되는지 확인
      (Organization → Settings → GitHub Apps → Claude)
- [ ] Notion 「레포 인덱스」에 등록
- [ ] **DB가 필요한 앱이면** AccessHub 「내 repo 등록」(「자기 DB 사용」)을 신청하고, 2번의
      「AI 세션이 이 repo에서 DB 작업을 시작할 때」 순서대로 준비 (승인 → DB 비밀번호 발급 → `DATABASE_URL`을
      GitHub Secret과 배포 플랫폼 두 곳에 등록 → 스키마 이름 기입). DB가 필요 없으면 건너뜁니다
- [ ] 로그인 기능이 필요한 앱이면 `supabaseauthloginguide.md` 확인 — 특히 §2(형태 판별)와,
      자체 서버가 있다면 §7(API 보호)은 필수
- [ ] 데이터 구조 정하기 — 새로 만드는 앱은 `new-app-guide.md`(데이터 정리 → 테이블 생성 → 코드 연결 → 검증),
      Replit·Lovable·개인 PC 등에서 쓰던 데이터를 옮겨야 하면 `migration-guide.md`(분석 → 이관 → 검증)

## 6. 로그인 기능이 필요하면

새 앱에 사내 계정 로그인을 붙일 때는 `supabaseauthloginguide.md`를 그대로 AI에게 읽혀서
구현하면 됩니다. 비밀번호 찾기·첫 로그인 설정·비밀번호 변경은 계정 센터(`speedrack-co/MS_account`)가
하므로 앱에 만들지 않습니다(최신본: https://ms-account.vercel.app/app-guide.md).

**다만 이 앱이 자체 서버(Express 등)를 갖고 그 서버가 DB에 붙는 구조라면,
로그인 화면만으로는 부족합니다** — 그 문서의 §2에서 형태를 먼저 판별하고, 해당되면 §7의
API 보호(서버 쪽 토큰 검증)까지 반드시 구현해야 합니다. 로그인 화면만 만들고 이 부분을
빠뜨려서 로그인 없이도 데이터를 읽고 쓸 수 있었던 실제 사고가 있었습니다(2026-09,
PD_MSDS-Management).

**가이드를 읽기 전이라도 지킬 것** (이유와 방법은 가이드에 있습니다):

- 회원가입(`signUp`) 화면을 앱에 만들지 않습니다. 계정은 이미 전 직원에게 있습니다.
- 거래처 등 **외부 사람의 계정을 사내 로그인(`ai_data_hub`)에 만들지 않습니다.** 사내 계정은 직원 권한을 받아
  직원용 데이터가 외부인에게 열립니다(§8-1).
- 권한을 `user_metadata` 값으로 판정하지 않습니다. 본인이 고칠 수 있는 값입니다(§8).
  관리자 명단·기준은 AI가 정하지 않고 담당자에게 묻습니다.
- `ai_data_hub`의 `service_role` 키·JWT 비밀값을 요청하지 않고, 다른 사람의 계정 상태·비밀번호를 바꾸지 않습니다(§12).

## 7. 데이터·백엔드는 Supabase에 둡니다

회사 정책은 **코드는 GitHub, 데이터와 백엔드는 Supabase**입니다. 처음부터 새로 만든 앱도 같습니다.
아래에 해당하는 작업이면 **작업을 시작하기 전에 해당 가이드를 처음부터 끝까지 읽고** 그 순서를 따르세요.

| 작업 | 가이드 |
|---|---|
| 앱에 데이터를 저장·조회하는 기능을 새로 붙일 때 (테이블, 목업·localStorage를 실제 저장으로 바꾸기 포함) | `new-app-guide.md` |
| Replit·Lovable·개인 PC·다른 DB에서 쓰던 앱의 **쌓인 데이터**를 옮길 때 | `migration-guide.md` |

로그인은 6번(`supabaseauthloginguide.md`)입니다. DB 준비와 테이블을 만드는 절차는 위 2번이 원본이고,
두 가이드는 2번을 반복하지 않고 가리킵니다.

**가이드를 읽기 전이라도 지킬 것** (이유와 방법은 가이드에 있습니다):

- **구조는 브라우저 → 앱 서버 API → `DATABASE_URL` → 이 앱 스키마입니다.** 브라우저가 Supabase 테이블을 직접 읽는 구조
  (supabase-js `.from()`)를 새로 만들지 않고, Exposed schemas 등록을 요청하지 않습니다.
- 서버는 AccessHub가 발급한 `DATABASE_URL`(앱 DB 계정)로만 DB에 붙습니다. `postgres` 접속이나 `service_role` 키로
  붙는 구조를 새로 만들지 않습니다. 서버의 모든 API는 로그인 토큰을 검증합니다(6번).
- 프로젝트와 스키마는 AccessHub가 정합니다. AI가 고르거나 `create schema`로 만들지 않습니다(2번).
  테이블은 이 앱 스키마에만 만들고, `public`에 만들지 않습니다.
- 모든 테이블에 RLS를 켭니다. 정책과 `anon`·`authenticated` grant는 넣지 않습니다.
- 권한 모델(누가 보고 누가 고치는지)은 AI가 정하지 않고 사용자에게 먼저 묻습니다.
- 「코드를 바꿨다」는 완료가 아닙니다. **배포본에서 만든 데이터가 다른 브라우저에서도 보이는 것을 확인한 시점**이
  완료입니다.
- 이미 브라우저 직접 호출 구조로 돌고 있는 앱(예전 방식)을 고칠 때는 `migration-guide.md`의 〔옛 방식〕 표시 부분을 봅니다.
  이 앱들은 차례로 AccessHub 기반으로 바꿀 예정입니다.
