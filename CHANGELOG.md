
## Unreleased

- support silent URL node with `?<url>` syntax, adding `silent` to `MfmURL` (follows misskey-dev/mfm.js#141)

## 1.0.7

- support Unicode emoji additions (17.0) (commits: 8e8ecb2, b38a872, 670c1a8)
- improve parser performance by avoiding substring allocations in `str` and `regexp` (commits: 8ff6fa4, d69cef9)

## 1.0.6

- include `plain` in `parseSimple` (commit: 89350da, 2024-06-18)
- fix parsing links containing invalid URLs (commit: 0da1ac2, 2024-12-21)
- allow period (`.`) in mentions (commit: 25ef40c, 2024-09-02)
- support Unicode emoji additions (15.0, 15.1, 16.0) (commits: 8c1b53b, 715ca1a, 172219b)
- handle VS16 (return/ignore as text) (commits: 8df6de1, b628b9b)
- fix mergeText ignoring text before node (commit: f07c5dc)
- other minor fixes and documentation updates (various commits)

## 1.0.5

- support MathInline, MathBlock

## 1.0.4

- fix that MfmQuote has not node (thanks for @poppingmoon)

## 1.0.3

- MfmSearch contains field

## 1.0.2

- add documentation code, support docs.

## 1.0.1

- update pubspec.yaml

## 1.0.0

- Initial version.
