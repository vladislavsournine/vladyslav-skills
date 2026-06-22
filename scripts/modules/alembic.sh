#!/usr/bin/env bash
# alembic.sh — alembic migration scaffold (no revisions).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
parse_common_args "$@"
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

write_file "alembic.ini" "[alembic]
script_location = migrations
sqlalchemy.url = postgresql://app:app@postgres:5432/app

[loggers]
keys = root

[logger_root]
level = WARN
handlers =
qualname =
"

write_file "migrations/env.py" "from alembic import context
from sqlalchemy import engine_from_config, pool
import os

config = context.config
config.set_main_option(
    'sqlalchemy.url', os.getenv('DATABASE_URL', config.get_main_option('sqlalchemy.url'))
)
target_metadata = None


def run_migrations_offline():
    context.configure(url=config.get_main_option('sqlalchemy.url'), target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section), prefix='sqlalchemy.', poolclass=pool.NullPool
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
"

write_file "migrations/versions/.gitkeep" ""
write_file "migrations/README" "Alembic migrations. Create a revision with:
  alembic revision -m \"description\"
Apply with:
  alembic upgrade head
"

emit_json "success"
exit 0
