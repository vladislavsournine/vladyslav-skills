# Backend-shared steps (Python or Go)

This fragment is composed into the `init-project` subagent prompt **once** if any backend stack (`python` or `go`) was selected. It covers the cross-stack backend infrastructure that does not depend on the chosen language.

## Docker operations doc

Read `<plugin>/skills/init-project/assets/docs/operations/docker.md` and write to `docs/operations/docker.md`. No substitutions.

If the asset cannot be located, return `status: error`: `"Cannot find skills/init-project/assets/docs/operations/docker.md in vladyslav-skills plugin. Please reinstall or run git pull."`

## nginx config (only if a domain was provided)

Skip this section entirely if `domain` is empty / not provided.

If a domain is set:

1. Create `infra/nginx/`.
2. Read `<plugin>/skills/init-project/assets/infra/nginx.conf`.
3. Write to `infra/nginx/nginx.conf`, replacing every occurrence of `APP_DOMAIN` with the actual domain.

If the asset cannot be located, return `status: error`: `"Cannot find skills/init-project/assets/infra/nginx.conf in vladyslav-skills plugin. Please reinstall or run git pull."`
