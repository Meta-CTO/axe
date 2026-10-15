# MetaCTO axe

A fork of [cameroncooke/AXe](https://github.com/cameroncooke/AXe) used by the andrew-rn E2E tests.

## Branches

- `main` mirrors upstream. Keep it in sync with GitHub's "Sync fork" button.
- `metacto` is our change on top of an upstream release. The E2E tests download a packaged build of it, never build it themselves.

## What our change adds

- `axe batch --serve`: one long-running session that reads one step per line on stdin and answers `ok` or `err <message>` per line. This saves the startup cost of a new axe process for every tap.
- A cached screen-coordinate mapping, so taps don't redo the orientation lookup each time.
- `drag` as a batch step, with a short hold at the start and end of the drag.

## Making a new release

1. Bring `metacto` up to date if needed: sync `main`, then `git rebase <upstream release tag>` on `metacto` and fix any conflicts.
2. On an Apple Silicon Mac with Xcode and xcodegen: `scripts/package-metacto.sh <version>`, for example `1.8.0-metacto.2`.
3. Run the `gh release create` command it prints.
4. In andrew-rn, set `AXE_RELEASE` in `e2e/environment.mjs` to the new version.
