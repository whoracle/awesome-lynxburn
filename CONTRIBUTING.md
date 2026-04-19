# Contributing

This repository accepts contributions, but it is still a personal AwesomeWM
config first.

Contributions are evaluated primarily on fit, maintainability, and whether the
change can be verified in practice.

## Scope

Contributions that are generally welcome:

- bugfixes
- focused features
- documentation fixes or improvements
- cleanup that clearly reduces maintenance cost

Contributions are less likely to be accepted if they:

- expand the project far beyond its current scope
- reshape the repo or config surface without prior discussion
- add behavior that is hard to verify in the maintainer's environment
- increase long-term maintenance burden without a clear payoff

## Before You Start

Please discuss larger changes before implementing them.

This especially applies to:

- substantial new feature work
- changes to the user-facing config shape
- changes that cross multiple modules or shared infrastructure
- changes to ownership boundaries between modules, theme, and config

Small targeted fixes usually do not need advance discussion.

## Technical Expectations

Keep changes focused.

If a change touches behavior, explain:

- what changed
- why it changed
- how it was tested or verified

If a change reshapes module/config/theme behavior, update the relevant
documentation in the same contribution when practical.

Avoid unrelated churn in the same patch.

## Commit Format

This repository now validates commit messages through commitizen and
`pre-commit`.

Use:

`<type>: [<component>] <message>`

Exception:

`bump: <message>`

Examples:

- `feature: [lxmedia] add device popup keyboard shortcut`
- `bugfix: [core] guard popup cycle teardown on missing dismiss state`
- `docs: [theme] refresh lynxburn README`
- `bump: version 1.0.0 → 1.1.0`

Allowed types:

- `feature`
- `bugfix`
- `refactor`
- `docs`
- `chore`
- `break`
- `bump`

Allowed components:

- `core`
- `theme`
- any current `lx*` module or shared package

Version bump intent:

- `break` -> major
- `feature` -> minor
- `bugfix` -> patch
- `bump` -> patch
- `refactor`, `docs`, `chore` -> no bump

## Licensing

This repository has a mixed licensing situation. See [`LICENSE.md`](./LICENSE.md).

By submitting a contribution, you confirm that:

- you have the right to submit the change
- the change is compatible with the repository's licensing model
- your contribution may be redistributed under the repository's applicable
  license terms

Do not submit third-party code, assets, or copied material with unclear
provenance or incompatible licensing.

If a contribution adds or modifies third-party material, include the relevant
license and provenance details with the change.

## Acceptance

Acceptance of contributions is discretionary.

A contribution may be declined if it:

- does not fit the project direction
- is difficult to verify reliably
- introduces licensing uncertainty
- adds maintenance cost the project does not want to carry
