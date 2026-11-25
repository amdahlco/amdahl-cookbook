# Amdahl Cookbook: notes for contributors

## Opening a PR

- **Open every PR as a draft** (`gh pr create --draft`) and keep pushing while CI and fix rounds run. Drafts get GitHub's CodeQL scan, but `claude-code-review.yml` skips them, so no paid Claude review runs.
- **Mark it ready once** (`gh pr ready <n>`), when the work is done and CI is green. The `ready_for_review` event starts one full review, and every push after that starts another, so push after ready only when the review asks for a change. Why: most of the review bot's cost was re-reviews of fix-round pushes.
