# Decisions

Architectural decisions for the native fork. Populated as work proceeds.

- **Security baseline (step 1).** The fork is a heavily modified Telegram-iOS whose
  git history diverged from the public Telegram repo in 2019, so a merge-base diff
  is not a usable fork delta. Audit used whole-tree grep + fork-delta by author and
  file-presence (see SECURITY_REVIEW.md). Verdict clean.
- Pending: re-estimate of Swift line count after the feature inventory (step 3).
- Pending (step 2): replace hardcoded fork api_id/api_hash (27989480) with owner's
  own credentials via secrets; confirm the exact secret names the workflow reads.
