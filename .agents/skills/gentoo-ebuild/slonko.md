# slonko overlay conventions

Rules specific to the slonko overlay (`~/repos/slonko`). Generic ebuild
knowledge lives in SKILL.md + reference.md (+ language files) — this
file only covers what differs here.

## Manifest / digests

- Always `ebuild <file> digest` (not `pkgdev manifest`) — this repo is
  kept digest-synced by hand. `metadata/md5-cache/` is regenerated
  alongside but stays **untracked** — never commit it.

## Before bumping an overlay package

- Check whether `::gentoo` has caught up first (`eix -e <pn>` or the
  tree). If the tree now has an equal/newer version and our ebuild
  carries no real delta (patches/USE/logic), surface that instead of
  bumping — dropping the package is the user's call. If we diverge
  deliberately, diff against the tree's ebuild to see the delta before
  rebasing it on the new version.

## Package preferences

- Go packages: prefer `EGO_SUM` over dependency/vendor tarballs — no
  extra distfile to host or regenerate per bump (details + wiring in
  `go.md`). The deprecation QA notice is accepted until it turns
  fatal.

## Repository identity

- Registered under repo id `[local]` (→ this git tree). Verify with
  `cat /etc/portage/repos.conf/*.conf` and
  `portageq get_repo_path / <id>`.
- `profiles/repo_name` must never be updated or committed: the public
  GitHub repo carries `slonko`, this local development checkout
  carries `local` (matching its id in repos.conf). Portage errors when
  repo_name doesn't match the registered repository, and there is no
  good way to serve both roles (development + normal use) from one
  checkout — so the file always stays as-is.

## metadata.xml

- Maintainer must be Marcin; keep the `<upstream>` section (bugs-to /
  remote-id / doc) per overlay convention.

## Cleanup during bumps

- "Clean up" = temporary/scratch files only. Never delete old ebuilds
  or `files/` patches unless explicitly asked.

## Session constraints

- Build/test only: no `emerge` installs into the live system, no
  `/etc/portage` edits (use throwaway `PORTAGE_CONFIGROOT` for scoped
  pretend checks instead).
