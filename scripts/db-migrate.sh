#!/usr/bin/env bash
# 앱 스키마 마이그레이션 적용기 — CLAUDE.md 2번
#
#   DATABASE_URL=<접속 주소> DB_SCHEMA=<앱 스키마> scripts/db-migrate.sh            # 적용 (main 에서만)
#   DATABASE_URL=<접속 주소> DB_SCHEMA=<앱 스키마> scripts/db-migrate.sh --dry-run  # 적용될 파일만 표시
#   DATABASE_URL=<접속 주소> DB_SCHEMA=<앱 스키마> scripts/db-migrate.sh --baseline db/migrations/<기준선>.sql
#                                                  # 실행하지 않고 「적용됨」으로만 기록 (처음 넘어올 때 1회)
#
# db/migrations/YYYYMMDDHHMMSS_설명.sql 을 번호순으로, 파일 하나씩 한 트랜잭션으로 적용하고
# <앱 스키마>.schema_history 에 버전·내용 해시·적용 계정·커밋을 남긴다.
# 이력 테이블이 앱 스키마 안에 있으므로 다른 앱·프로젝트 공용 기록 테이블(supabase_migrations)과 엮이지 않는다.
# 필요한 것: psql(PostgreSQL 클라이언트), git, sha256sum 또는 shasum.
set -euo pipefail

DIR="${MIGRATIONS_DIR:-db/migrations}"
: "${DATABASE_URL:?DATABASE_URL 이 필요합니다 (앱 DB 접속 주소)}"
: "${DB_SCHEMA:?DB_SCHEMA 가 필요합니다 (이 앱의 스키마 이름)}"

MODE=apply
BASELINE=""
case "${1:-}" in
  "") ;;
  --dry-run) MODE=dry ;;
  --baseline) MODE=baseline; BASELINE="${2:?--baseline 뒤에 기준선 파일 경로를 적으세요}" ;;
  *) echo "알 수 없는 옵션: $1" >&2; exit 2 ;;
esac

hash_of() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }
# q: 표준입력의 SQL 실행. :'schema'·:"schema" 로 스키마 이름을 안전하게 넣는다(psql 은 -c 문자열엔 변수를 안 넣는다)
q() { psql -X -q -t -A -v ON_ERROR_STOP=1 -v schema="$DB_SCHEMA" "$DATABASE_URL"; }
qs() { printf '%s\n' "$1" | q; }

# 적용·기준선 기록은 merge 된 main 에서만 — 리뷰 안 된 SQL 이 운영에 들어가지 않게
if [ "$MODE" != dry ]; then
  [ "$(git rev-parse --abbrev-ref HEAD)" = main ] || { echo "main 에서만 적용합니다 (지금: $(git rev-parse --abbrev-ref HEAD)). 미리 보기는 --dry-run" >&2; exit 1; }
  git fetch -q origin main
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "main 이 origin/main 과 다릅니다. git pull 후 다시 실행하세요" >&2; exit 1; }
  [ -z "$(git status --porcelain -- "$DIR")" ] || { echo "$DIR 에 커밋 안 된 변경이 있습니다" >&2; exit 1; }
fi

# 스키마가 있는지, 이력 테이블이 있는지
[ "$(qs "select count(*) from pg_namespace where nspname = :'schema'")" = 1 ] \
  || { echo "스키마 \"$DB_SCHEMA\" 가 없습니다. 접속 주소·스키마 이름을 확인하세요" >&2; exit 1; }
if [ "$MODE" != dry ]; then
  q <<'SQL'
set client_min_messages = warning;
create table if not exists :"schema".schema_history (
  version    text primary key,
  name       text not null,
  checksum   text not null,
  applied_at timestamptz not null default now(),
  applied_by text not null default current_user,
  git_commit text,
  baseline   boolean not null default false
);
SQL
fi
APPLIED=""
if [ "$(qs "select to_regclass(format('%I.schema_history', :'schema')) is not null")" = t ]; then
  APPLIED="$(qs "select version || ' ' || checksum from :\"schema\".schema_history order by version")"
fi
MAXV="$(printf '%s\n' "$APPLIED" | awk 'NF{v=$1} END{print v}')"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
QS="$(qs "select quote_ident(:'schema')")"   # 적용 단계에선 파일 내용에 psql 변수를 섞지 않으려고 미리 따옴표 처리

record() {  # $1 버전 $2 이름 $3 해시 $4 baseline(true/false)
  printf "insert into %s.schema_history (version, name, checksum, git_commit, baseline) values ('%s', '%s', '%s', '%s', %s);\n" "$QS" "$1" "$2" "$3" "$COMMIT" "$4"
}

if [ "$MODE" = baseline ]; then
  f="$BASELINE"; base="$(basename "$f")"
  [[ "$base" =~ ^([0-9]{14})_([a-z0-9_]+)\.sql$ ]] || { echo "파일 이름 규칙(YYYYMMDDHHMMSS_설명.sql) 위반: $base" >&2; exit 1; }
  [ -z "$APPLIED" ] || { echo "이미 이력이 있습니다. 기준선은 처음 한 번만 기록합니다" >&2; exit 1; }
  record "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$(hash_of "$f")" true | q
  echo "기준선 기록: $base (실행하지 않음)"
  exit 0
fi

shopt -s nullglob
PENDING=()
for f in "$DIR"/*.sql; do
  base="$(basename "$f")"
  [[ "$base" =~ ^([0-9]{14})_([a-z0-9_]+)\.sql$ ]] || { echo "파일 이름 규칙(YYYYMMDDHHMMSS_설명.sql) 위반: $base" >&2; exit 1; }
  v="${BASH_REMATCH[1]}"; h="$(hash_of "$f")"
  old="$(printf '%s\n' "$APPLIED" | awk -v v="$v" '$1==v{print $2}')"
  if [ -n "$old" ]; then
    [ "$old" = "$h" ] || { echo "이미 적용된 파일의 내용이 바뀌었습니다: $base — 고치려면 새 파일을 추가하세요" >&2; exit 1; }
    continue
  fi
  if [ -n "$MAXV" ] && [[ "$v" < "$MAXV" ]]; then
    echo "적용된 마지막 번호($MAXV)보다 앞선 새 파일입니다: $base — 번호를 더 큰 값으로 바꾸세요" >&2; exit 1
  fi
  if grep -qiE '^[[:space:]]*(begin|commit|rollback)[[:space:]]*;' "$f"; then
    echo "파일 안에 begin/commit 을 넣지 마세요(스크립트가 묶습니다): $base" >&2; exit 1
  fi
  PENDING+=("$f")
done

if [ ${#PENDING[@]} -eq 0 ]; then echo "적용할 파일 없음 (스키마 $DB_SCHEMA, 마지막 ${MAXV:-없음})"; exit 0; fi
printf '적용할 파일 %d개:\n' "${#PENDING[@]}"; printf '  %s\n' "${PENDING[@]}"
[ "$MODE" = dry ] && exit 0

for f in "${PENDING[@]}"; do
  base="$(basename "$f")"; [[ "$base" =~ ^([0-9]{14})_([a-z0-9_]+)\.sql$ ]]
  { echo 'begin;'; cat "$f"; echo; echo ';'; record "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$(hash_of "$f")" false; echo 'commit;'; } \
    | psql -X -q -v ON_ERROR_STOP=1 "$DATABASE_URL"
  echo "적용: $base"
done
