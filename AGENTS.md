# Satisficing Project Instructions

## Release Artifacts

- All release artifacts must strictly be placed and consolidated in the single `Release/` directory at the project root (`Release/Satisficing_<VERSION>.tar.gz` and `Release/Satisficing.pdf`).
- Do NOT create version-specific release folders such as `Release-v0.2.0/` or `Release-v<VERSION>/`.
- `Satisficing.pdf` in `Release/` is updated to reflect the reference manual corresponding to the latest release candidate.
- Historical source package tarballs (e.g. `Satisficing_0.1.0.tar.gz`, `Satisficing_0.2.0.tar.gz`) are preserved together in `Release/`.

## Git Identity and Release Operations

- Preferred Git author, committer, and annotated-tag tagger: `soheidon <soheidon@yahoo.co.jp>`
- Do not add `Co-Authored-By` trailers or generated-by/AI attribution in commits, tags, or release metadata.
- Remote-impacting mutations (commit, push, tag, GitHub release publication) require separate explicit user authorization.
