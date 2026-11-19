# 스피드랙 사내 앱 — 새 앱 데이터 구축 가이드

> **이 문서의 용도**: 새로 만드는 앱에 데이터 저장을 붙일 때, 무엇을 테이블로 만들고 코드에 어떻게 연결하고
> 어떻게 검증하는지를 다룹니다. AI(Claude Code 등)에 이 파일을 읽히면 순서대로 진행할 수 있게 썼습니다.
>
> **이 문서가 다루지 않는 것** — 같은 내용을 여기에 반복하지 않습니다.
>
> | 내용 | 원본 |
> |---|---|
> | DB 준비(AccessHub 등록 → DB 비밀번호 발급 → `DATABASE_URL` 등록 → 스키마 이름)와 변경 적용 절차 | `CLAUDE.md` 2번 |
> | 로그인, 서버 API 보호 | `supabaseauthloginguide.md` |
> | 다른 곳(Replit·Lovable·개인 PC 등)에 **쌓인 데이터를 옮기는** 일 | `migration-guide.md` |
>
> **작성**: 경영지원파트. 진행 중 막히면 코드나 이 문서를 임의로 고치지 말고 경영지원파트(박종서, 조민기)에게 먼저 문의하세요.

---

## 0. 이 문서를 쓰는 경우

- 코드를 GitHub에 만들어 놨는데, 데이터를 **어디에 어떻게 쌓을지** 정해야 한다
- 화면은 되는데 데이터가 **목업 배열·`useState`·localStorage·메모리**에만 있다 (새로고침하거나 다른 PC로 가면 사라진다)
- Replit·Lovable 등에서 만든 앱이지만 **쌓인 사용자 데이터가 없다** (테스트 데이터뿐이다)

옮겨야 할 실데이터가 있으면 이 문서가 아니라 `migration-guide.md`다. 일부는 옮기고 일부는 새로 만든다면,
옮기는 부분은 `migration-guide.md`, 새 기능은 이 문서를 따른다.

## 1. 한눈에 — 구조

```
사용자 브라우저
   │  ① 로그인: ai_data_hub (사내 계정, 전 부서 공통)
   │  ② 데이터: 앱 서버의 /api/… 만 부른다 (로그인 토큰을 붙여서)
   ▼
앱 서버 (Railway · Render · Vercel 등)  ── 토큰 검증 → 권한 판정
   │  DATABASE_URL (앱 전용 DB 계정 <스키마>_app)
   ▼
Supabase 프로젝트 안의 이 앱 스키마 ── 테이블

GitHub repo ── db/migrations/*.sql ──(main 에 merge)──▶ GitHub Actions(db-apply.yml) ──▶ 같은 스키마에 적용
```

| 구성요소 | 어디에 두나 | 비고 |
|---|---|---|
| 코드 (화면·서버) | GitHub repo | 변경은 PR (`CLAUDE.md` 1번) |
| 로그인 | `ai_data_hub` Auth | `supabaseauthloginguide.md` |
| 앱 데이터 (테이블) | AccessHub가 만들어 준 **이 앱의 스키마** | 프로젝트와 스키마는 AccessHub 심사에서 정해진다(아래) |
| 테이블 변경 | repo `db/migrations/` → merge → GitHub Actions가 적용 | `CLAUDE.md` 2번 |
| 접속 주소 (`DATABASE_URL`) | 배포 플랫폼 환경변수 + GitHub 저장소 Secret | 코드·repo·채팅에 값 금지 (`CLAUDE.md` 3번) |
| 회사 공용 데이터 (ERP 재고·BOM·직원 명단 등) | 직접 읽지 않는다. AccessHub 데이터마켓으로 신청 | 앱 키(`app_…`)로 읽는다. 자기 DB 접속과는 별개 값 |

**알아 둘 것**

- **어느 Supabase 프로젝트에 둘지는 AccessHub 심사에서 정해진다.** 관리자가 저장 위치를 고르거나, repo 이름의 부서 약어로
  자동으로 정해진다. **세션이 프로젝트를 고르지 않고, 담당 부서를 물어 추정하지도 않는다.** `CLAUDE.md` 「이 앱에 대해」에
  적힌 프로젝트·스키마를 따른다.
- **브라우저는 Supabase의 테이블을 직접 읽고 쓰지 않는다.** 그래서 Exposed schemas 등록, `anon`·`authenticated` grant,
  supabase-js의 `.schema()` 설정이 필요 없고, 하지 않는다. 노출된 스키마가 지워지거나 이름이 바뀌면 그 프로젝트의
  모든 REST API가 멈춘다(2026-10-29·30 실제 발생).
- **앱 DB 계정은 자기 스키마만** 읽고 바꿀 수 있다. `public`·`auth`·다른 앱의 스키마는 볼 수 없다.
- **서버는 DB에 직접 붙으므로 RLS가 사용자를 가려 주지 않는다.** 누가 무엇을 볼 수 있는지는 앱 서버 코드가 정한다.
  모든 API가 로그인 토큰을 검증해야 하는 이유다(5단계).

## 2. 1단계 — 준비 확인

`CLAUDE.md` 2번의 「AI 세션이 이 repo에서 DB 작업을 시작할 때」를 먼저 한다. 거기서 확인하는 것:
파일(`db-apply.yml`·`db-migrate.sh`)이 있는지, AccessHub 등록·승인·비밀번호 발급이 됐는지, 프로젝트와 스키마 이름이 무엇인지,
`DATABASE_URL`이 GitHub Secret과 배포 플랫폼 두 곳에 등록됐는지.

준비가 끝나지 않았어도 3단계(데이터 정리)와 4단계(설계 질문), SQL 파일 작성까지는 진행할 수 있다.
**적용(merge)은 준비가 끝난 뒤에 한다.**

## 3. 2단계 — 코드에서 "무슨 데이터가 필요한가" 뽑기

새 앱은 **화면과 코드가 곧 요구사항**이다. 코드를 읽어 저장해야 할 것을 정리한다.

```bash
# 1) 목업·하드코딩된 데이터 — 지금 화면이 보여 주는 가짜 데이터
grep -rn -E "mock|dummy|sample|fake|faker|seed|initialData|DEFAULT_" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" -r . | grep -v node_modules

# 2) 목록을 화면 상태로만 들고 있는 곳
grep -rn -E "useState\(\[|useState<[^>]*\[\]>\(|ref\(\[|reactive\(\[" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.vue" -r . | grep -v node_modules

# 3) 사용자가 입력하는 항목 — 저장해야 할 필드 후보
grep -rn -E "<input|<select|<textarea|register\(|name=" \
  --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.html" -r . | grep -v node_modules

# 4) 타입·검증 스키마 — 엔티티 후보
grep -rn -E "^(export )?(interface|type) [A-Z]|z\.object\(|BaseModel|@dataclass" \
  --include="*.ts" --include="*.tsx" --include="*.py" -r . | grep -v node_modules

# 5) 이미 있는 저장·API 호출 (브라우저 저장소 포함)
grep -rn -E "fetch\(|axios\.|localStorage|sessionStorage|indexedDB|/api/" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" -r . | grep -v node_modules
```

화면(기능) 하나씩 "무엇을 읽고 무엇을 쓰는가"를 적어 아래 표를 만든다.

```markdown
## 데이터 요구 정리 — <앱 이름> (<날짜>)

- 프로젝트 / 스키마: (`CLAUDE.md` 「이 앱에 대해」와 같게)
- 배포 플랫폼: (AccessHub에 등록한 것 — Vercel / Render / Railway / 기타)

| # | 화면/기능 | 읽기·쓰기 | 엔티티(테이블 후보) | 주요 필드 | 누가 보나·고치나 | 규모·증가 | 첨부 |
|---|---|---|---|---|---|---|---|
| 1 | 요청 등록 폼 | 쓰기 | requests | title, amount, status | 본인 작성, 부서장 승인 | 월 200건 | 견적서 PDF |
| 2 | 요청 목록 | 읽기 | requests | 위 + created_at | 전 직원 조회 | | |
| 3 | 즐겨찾기 | 읽기·쓰기 | favorites | request_id | 본인만 | | |
```

테이블을 나누는 기준:

- 화면 단위가 아니라 **명사 단위**로 나눈다 (요청, 요청 품목, 승인 이력).
- 같은 값을 두 곳에 저장하지 않는다. 합계·건수처럼 계산되는 값은 컬럼이 아니라 쿼리나 뷰로 낸다.
- 상태값은 `text` + `check (...)`로 막는다. 선택지가 자주 바뀌면 작은 코드 테이블로 뺀다.
- 금액은 `numeric`, 날짜는 `date`, 시각은 `timestamptz`. 문자열로 저장하지 않는다.
- 목록 필터·정렬에 쓰는 컬럼에는 인덱스를 건다.
- 구조가 정말 정해지지 않은 부분만 `jsonb`로 둔다.
- 사용자를 가리키는 컬럼은 `uuid`로 두고 로그인한 사람의 id(`ai_data_hub`의 `auth.users.id`)를 저장한다.
  앱 DB 계정은 `auth` 스키마를 볼 수 없으므로 **외래키는 걸지 않는다.**

이 표를 repo의 `docs/data-requirements.md`로 남기고 **사용자에게 보여 확인받는다. 확인 전에는 SQL을 쓰지 않는다.**
localStorage 등에 사용자별 실데이터가 이미 쌓여 있었다면 신규가 아니라 이관이다(`migration-guide.md`).

## 4. 3단계 — 설계 확정 (사용자에게 먼저 물을 것)

AI가 임의로 정하면 안 되는 항목이다. 답을 받은 뒤에 SQL을 쓴다.

1. **권한 모델** — `supabaseauthloginguide.md` §8의 질문 4개. 로그인한 직원이면 다 봐도 되는가, 본인 것만인가,
   읽기와 쓰기 권한이 다른가, 특별 권한은 무엇으로 판정하는가(부서 / 직책 / 개별 명단).
2. **권한 판정에 쓸 정보를 어디서 얻는가** — 앱 DB 계정은 `public`을 볼 수 없어서 공용 함수 `public.is_admin_user()`나
   직원 명단 테이블을 쓸 수 없다(MS_snms에서 확인). 부서·직책으로 가르려면 데이터마켓 신청이나 앱 자체 명단 테이블이
   필요하다. **명단의 실제 값은 AI가 정하지 않는다** — 자리만 만들고 담당자가 채운다.
3. **파일 첨부가 있는가** — 앱 DB 계정은 Supabase Storage 권한이 없고, 「자기 DB」 앱의 버킷 생성 절차는 아직 정해져
   있지 않다. 첨부가 필요하면 **만들기 전에 경영지원파트와 절차를 정한다.**
4. **다른 사내 앱·회사 공용 데이터를 쓰는가** — 직접 읽을 수 없다. AccessHub 데이터마켓으로 신청한다.
5. **서버에서 외부 서비스를 부르는가** — 그 서비스의 키도 배포 플랫폼 환경변수에만 둔다.

프로젝트와 스키마 이름은 여기서 정하지 않는다. AccessHub가 이미 정했다(1단계).

## 5. 4단계 — 테이블 만들기

**1) 마이그레이션 SQL을 쓴다.** 3단계 정리표와 4단계 답을 반영한 골격이다.

```sql
-- <앱 이름> 신규 구축: 테이블
-- 대상 프로젝트: <ref> / 대상 스키마: <스키마> (AccessHub로 만들어진 스키마. 주인은 <스키마>_app)
-- 설계 근거: docs/data-requirements.md
--
-- create schema 를 쓰지 않는다(승인 때 이미 만들어졌다). anon·authenticated grant 와 정책을 쓰지 않는다
-- (브라우저가 이 스키마를 직접 읽지 않는다). 사용자 구분과 권한 판정은 앱 서버 코드가 한다.

create function <스키마>.set_updated_at() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end
$$;

create table <스키마>.requests (
  id         bigint generated always as identity primary key,
  user_id    uuid not null,                      -- 로그인한 사람의 id. 외래키는 걸지 않는다(auth 스키마를 볼 수 없다)
  title      text not null,
  status     text not null default 'draft'
             check (status in ('draft', 'submitted', 'approved', 'rejected')),
  amount     numeric(14,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on <스키마>.requests (user_id);
create index on <스키마>.requests (created_at);

create trigger trg_requests_updated before update on <스키마>.requests
  for each row execute function <스키마>.set_updated_at();

-- RLS 는 켜고 정책은 만들지 않는다. 스키마 주인(<스키마>_app)은 그대로 쓰고, 다른 롤은 전부 막힌다.
alter table <스키마>.requests enable row level security;
```

- 객체 이름에는 항상 스키마를 붙인다(`<스키마>.requests`).
- 파일 안에 `begin;`/`commit;`을 넣지 않는다(스크립트가 파일 하나를 한 트랜잭션으로 묶는다).
- 코드표 같은 **초기 데이터 입력도 데이터 변경**이므로 같은 절차로, 파일을 따로 만들어 적용한다.

**2) `CLAUDE.md` 2번 순서대로 올린다.** `db/migrations/`에 파일 → `[DB]` PR → 담당자 merge → GitHub Actions가 적용 →
Actions의 「DB 적용」 실행 성공 확인. **바로 실행하지 않는다.**

**3) 만들어졌는지 확인한다.** Actions 실행이 성공하면 워크플로가 「적용할 파일 없음」까지 확인한 것이다.
세션의 Supabase MCP에 그 프로젝트가 보이면 읽기 전용 조회로 한 번 더 볼 수 있다.

```sql
select table_name from information_schema.tables where table_schema = '<스키마>';
select tablename, rowsecurity from pg_tables where schemaname = '<스키마>';   -- 전부 true
select version, name, applied_at from <스키마>.schema_history order by version;
```

프로젝트가 MCP에 안 보이면 이 조회는 건너뛰고, 보고에 그렇게 적는다.

## 6. 5단계 — 코드 연결

브라우저 → 앱 서버 API → DB 순서다. 브라우저 코드에 DB 접속이나 테이블 조회를 두지 않는다.

**1) 환경변수.** 이름은 `.env.example`에 이름만 남기고, 값은 배포 플랫폼과 로컬 `.env.local`에만 넣는다.

| 변수 | 어디서 쓰나 | 비고 |
|---|---|---|
| `DATABASE_URL` | **서버만** | AccessHub 「DB 비밀번호 발급」의 접속 주소. `NEXT_PUBLIC_`·`VITE_` 접두사 금지. GitHub 저장소 Secret에도 같은 값(`CLAUDE.md` 2번) |
| 로그인용 URL·publishable key, 계정 센터 주소 | 브라우저 | 이름과 값은 `supabaseauthloginguide.md` §3 |

배포 플랫폼은 AccessHub에 등록한 것(Vercel · Render · Railway · 기타)과 같아야 한다. 등록 위치는 플랫폼마다 다르다
(`supabaseauthloginguide.md` §3의 표).

**2) DB 연결 (서버).** `pg`·Drizzle·Prisma·SQLAlchemy 등 무엇이든 `DATABASE_URL`로 붙는다.

```ts
// 서버 전용 파일. 브라우저 코드에서 import 하지 않는다.
import { Pool } from "pg";

const url = process.env.DATABASE_URL;
if (!url) throw new Error("DATABASE_URL 환경변수가 설정되지 않았습니다.");

export const pool = new Pool({ connectionString: url /* , 풀 설정은 발급 화면의 Pool 줄 그대로 */ });
```

- **접속 수와 풀 설정은 AccessHub 「DB 비밀번호 발급」 화면의 Pool 줄을 그대로 쓴다.** 임의로 늘리지 않는다.
  앱 DB 계정은 동시 접속 수에 상한이 있고, 앱 서버·개발 PC·DB 적용 워크플로가 나눠 쓴다.
  발급 화면 기준(2026-11): 상시 서버(포트 5432)는 접속 5개에 풀 3(`max: 3, idleTimeoutMillis: 10000`),
  서버리스(포트 6543)는 접속 20개에 풀 설정이 필요 없다. 화면의 안내가 이와 다르면 화면이 맞다.
- 요청마다 서버가 새로 뜨는 플랫폼(Vercel Functions 등)은 발급 화면이 안내하는 서버리스용 주소(Transaction pooler,
  포트 6543)를 쓰고 prepared statement를 끈다. DB 적용 워크플로는 6543 주소를 넣어도 5432로 바꿔 쓴다.
- ORM을 쓰면 스키마를 지정한다(Drizzle `pgSchema("<스키마>")`, Prisma 접속 주소 `?schema=<스키마>`).
  **`drizzle-kit push`·`prisma db push` 같은 자동 반영은 쓰지 않는다**(`CLAUDE.md` 2번).
- 참조 구현: `speedrack-co/MS_snms` (Next.js + Railway).

**3) API 라우트 — 모든 라우트에서 로그인 토큰을 검증한다.** `supabaseauthloginguide.md` §7을 그대로 따른다.
빠뜨리면 로그인 없이 데이터가 열린다(2026-09 실제 사고).

```ts
// Express 예시. requireAuth 는 supabaseauthloginguide.md §7
app.use("/api", requireAuth);

app.get("/api/requests", async (req, res) => {
  const { rows } = await pool.query(
    "select id, title, status, created_at from <스키마>.requests order by created_at desc limit 50");
  res.json(rows);
});

app.post("/api/requests", async (req, res) => {
  // user_id 는 검증된 토큰에서 꺼낸다. 브라우저가 보낸 user_id 를 믿지 않는다.
  const { rows } = await pool.query(
    "insert into <스키마>.requests (user_id, title, amount) values ($1, $2, $3) returning id",
    [req.user!.sub, req.body.title, req.body.amount]);
  res.status(201).json(rows[0]);
});
```

- 값은 반드시 `$1` 같은 자리표시자로 넘긴다. 문자열을 이어 붙여 SQL을 만들지 않는다.
- "본인 것만"은 `where user_id = $1`에 **토큰의 `sub`** 를 넣어 구현한다. 수정·삭제도 같은 조건을 건다.
- 권한 판정에 `user_metadata` 값을 쓰지 않는다(본인이 고칠 수 있다, `supabaseauthloginguide.md` §8).
- **라우트 보호 테스트를 둔다.** 토큰 검증으로 감싸지 않은 API 라우트가 있으면 실패하는 테스트를 만들어, 새 라우트를
  추가할 때 검증을 빠뜨리면 걸리게 한다(참조: `speedrack-co/MS_snms`의 `src/server/routes.test.ts`).
  이 테스트는 자동으로 돌지 않으므로 PR을 올리기 전에 직접 실행하고 결과를 PR에 적는다.

**4) 브라우저 — 목업을 API 호출로 바꾼다.** 화면과 기능은 건드리지 않고 데이터 출처만 바꾼다. 목업 코드는 남기지 않고 지운다.

```ts
// 전: const [requests, setRequests] = useState(MOCK_REQUESTS);
// 후:
const [requests, setRequests] = useState<Request[]>([]);
useEffect(() => {
  (async () => {
    const { data: { session } } = await supabase.auth.getSession();   // 로그인용 클라이언트
    const res = await fetch("/api/requests", { headers: { Authorization: `Bearer ${session!.access_token}` } });
    if (!res.ok) throw new Error(`요청 목록을 불러오지 못했습니다 (${res.status})`);
    setRequests(await res.json());
  })().catch((e) => setError(String(e)));   // setError: 실패를 화면에 보여 주는 상태
}, []);
```

실패를 삼키지 않는다. 저장이 안 됐는데 된 것처럼 보이면 안 된다.

**5) 환경변수를 배포 플랫폼에 등록하고 재배포한다.**

**6) 안 될 때 순서대로 본다.**

| 증상 | 원인 | 확인·조치 |
|---|---|---|
| Actions 「DB 적용」 실패: "Secret DATABASE_URL 이 없습니다" | GitHub 저장소 Secret 미등록 | Settings → Secrets and variables → Actions에 등록 후 Actions에서 다시 실행 |
| Actions 실패: "스키마 이름이 없습니다" | `db-apply.yml`의 `DB_SCHEMA`가 비어 있음 | 「이 앱에 대해」의 스키마 이름을 적는다 |
| Actions 실패: `스키마 "…" 가 없습니다` | `DB_SCHEMA`가 실제 스키마 이름과 다르거나, 접속 주소가 다른 프로젝트 | AccessHub 승인 내용과 대조 |
| Actions 실패: "Secret DATABASE_URL 모양이 맞지 않습니다" | 비밀번호의 특수문자 | 안내대로 `%40` 등으로 바꿔 다시 등록 |
| `permission denied for schema …` | 다른 스키마를 건드림 | 앱 DB 계정은 자기 스키마만 쓴다. 공용 데이터는 데이터마켓 |
| `relation "…" does not exist` | 테이블 이름에 스키마를 안 붙였거나 아직 적용 전 | `<스키마>.테이블`로 쓰고, Actions 실행 기록 확인 |
| `too many connections` / 접속 대기 | 접속 상한 초과 | 풀 설정이 발급 화면의 Pool 줄과 같은지, 서버리스면 6543 주소인지 확인 |
| 서버가 "DATABASE_URL 환경변수가 설정되지 않았습니다" | 배포 플랫폼에 미등록, 또는 등록 후 재배포 안 함 | 플랫폼 환경변수 확인 → 재배포 |
| API가 전부 401 | 브라우저가 토큰을 안 붙였거나 서버의 검증 주소 설정 오류 | `supabaseauthloginguide.md` §7 |

## 7. 6단계 — 검증: 정말 DB에 쌓이는가

1. **배포본**(로컬 말고)에서 로그인해 저장 동작을 종류별로 1건씩 한다 (등록·수정·삭제).
2. **브라우저 저장이 아님을 확인한다.** 새로고침 후에도 남고, **같은 계정을 다른 브라우저나 다른 PC에서 열어도 같은 데이터**가 보여야 한다.
3. **다른 계정**으로 로그인해 4단계의 권한 모델대로 보이거나 막히는지 본다.
4. **로그인 없이 API를 부르면 막히는지** 본다. 모든 쓰기 API에 대해:
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" -X POST https://<배포주소>/api/requests -H "Content-Type: application/json" -d '{}'
   # 기대: 401
   ```
5. **빌드 결과물에 비밀값이 없는지** 본다: `grep -rE "postgres(ql)?://|sb_secret_|service_role" <빌드 폴더>` → 0건.
6. **목업 잔존 확인**: `grep -rn -E "mock|dummy|sample|localStorage" src`가 0건이거나, 남았다면 UI 설정처럼 저장 대상이 아닌 것임을 확인한다.
7. 세션의 Supabase MCP에 프로젝트가 보이면 읽기 전용으로 행을 확인한다. `user_id`가 로그인한 계정의 id와 같아야 한다.
   ```sql
   select * from <스키마>.requests order by created_at desc limit 5;
   ```
   안 보이면 2·3번의 화면 확인으로 대신하고 보고에 그렇게 적는다.

## 8. 7단계 — 기록하고 끝내기

- `CLAUDE.md` 「이 앱에 대해」와 README의 DB·배포 항목을 최종 값으로 채운다(`DATABASE_URL` 등록 상태 포함. 값은 적지 않는다).
- `docs/data-requirements.md`(3단계 정리표)와 검증 결과를 repo에 남긴다.
- `[DB]` PR이 merge되고 Actions의 「DB 적용」 실행이 성공했는지 확인한다.
- Notion 「레포 인덱스」의 DB 위치를 `<프로젝트> / <스키마>`로 갱신한다.

## 9. 완료 체크리스트

- [ ] `CLAUDE.md` 2번의 준비 확인 완료 (AccessHub 승인, 프로젝트·스키마 이름, `DATABASE_URL` 두 곳 등록, `DB_SCHEMA` 기입)
- [ ] 데이터 요구 정리표 작성 → 사용자 확인
- [ ] 설계 질문 답 확보 (권한 모델, 권한 판정 정보, 첨부, 공용 데이터)
- [ ] 마이그레이션 SQL: `[DB]` PR merge → Actions 「DB 적용」 성공
- [ ] 모든 테이블 RLS 켜짐. grant·정책·Exposed schemas 등록 없음
- [ ] 서버: `DATABASE_URL`로 접속, 풀 설정은 발급 화면대로, 모든 API 라우트 토큰 검증 + 라우트 보호 테스트, 값은 자리표시자로
- [ ] 브라우저: 목업·localStorage 제거, API 호출로 교체, 실패 처리
- [ ] 환경변수: `.env.example`에 이름만, 배포 플랫폼 등록, 재배포
- [ ] 7절 검증 (다른 브라우저에서 같은 데이터, 다른 계정 권한, 토큰 없는 호출 401, 빌드 결과물에 비밀값 없음)
- [ ] 8절 기록 (`CLAUDE.md`, README, docs, Notion 인덱스)

## 10. AI에게

1. **`CLAUDE.md` 2번의 「AI 세션이 이 repo에서 DB 작업을 시작할 때」를 먼저 하라.** 너는 GitHub Secret과 배포 플랫폼
   환경변수를 볼 수 없다. 등록됐는지 사용자에게 확인하고, 안 됐으면 SQL을 쓰기 전에 안내하라. 값을 채팅으로 받지 마라.
2. **프로젝트와 스키마를 네가 정하지 마라.** AccessHub 심사에서 이미 정해졌다. 담당 부서를 물어 추정하지 말고,
   `list_projects`에 보이는 것으로 추정하지도 마라. 「이 앱에 대해」에 없으면 AccessHub 승인 내용을 사용자에게 물어라.
3. **코드를 먼저 읽고 정리표를 만들어 사용자에게 보여라.** 확인받기 전에 SQL을 쓰지 마라.
4. DDL·INSERT는 바로 실행하지 마라. `db/migrations/`에 파일로 올리고 merge를 기다려라. `apply_migration`·`execute_sql`로
   넣지 마라. 읽기 전용 SELECT는 바로 실행해도 된다.
5. **브라우저가 테이블을 직접 읽는 구조(supabase-js `.from()`)를 만들지 마라.** Exposed schemas 등록을 요청하지 마라.
6. **토큰 검증 없는 API 라우트를 만들지 마라.** `supabaseauthloginguide.md` §7이 이 작업의 필수 범위다.
7. 권한 명단·기준의 실제 값을 정하지 마라. 자리만 만들고 담당자가 채우게 하라.
8. 파일 첨부가 필요하면 만들기 전에 멈추고 경영지원파트 확인이 필요하다고 알려라(4절의 3).
9. 목업을 API 호출로 바꿀 때 화면과 기능은 건드리지 마라. 목업 코드는 남기지 말고 지워라.
10. 검증(7절) 결과를 보고에 포함하라. "코드를 연결했다"는 완료가 아니다. **배포본에서 만든 데이터가 다른 브라우저에서도
    보이고, 토큰 없는 호출이 401인 것을 확인한 시점**이 완료다. 확인하지 못한 항목은 이유와 함께 명시하라.
