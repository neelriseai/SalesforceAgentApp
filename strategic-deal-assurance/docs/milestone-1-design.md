# Milestone 1 design and boundaries

This slice contains seven Opportunity fields, the evaluation object (13 fields), the policy custom metadata type (four fields) and Default record, one invocable Apex class, and its tests. It does not include Flow, LWC, REST, permissions, approval processes, seed records, or release decisions.

## Deliberate corrections to the supplied guide

- Optional Amount/Discount/Strategic inputs are not marked required on the invocable contract: null behavior must be executable.
- Evaluation sharing starts Private. A lookup does not inherit Opportunity sharing. Later controller/sharing work must enforce parent access; do not claim this is already implemented.
- The required Opportunity lookup restricts parent deletion; future explicit reset deletes evaluation children first.
- No permission grants or evidence writer in this slice. Append-only is a future runtime access contract, not a claim of immutable storage against administrators.
- Decimal inputs are normalized to scale two for hashing. Only approver presence, never its identity, is hashed. Timestamp is observational, not part of the decision/hash.
- Missing/inactive/malformed rule configuration fails closed. Discount configuration range is 0–100; minimum amount must be nonnegative; rule version must be nonblank.
- Missing approver is an input configuration error, not a missing policy configuration: approvalRequired remains true and configurationValid describes the policy configuration.
- Future Flow must create one evidence row for every relevant input mutation even if status/reason/version remain unchanged. The guide's output-changed-only path would skip such evidence.
- History tracking is deferred to the Flow/security milestone to avoid changing unrelated standard Opportunity history settings.

## Verification contract

Use `sf project deploy start --manifest manifest/milestone-1.xml --target-org caip-dev --test-level RunSpecifiedTests --tests StrategicDiscountPolicyTest --wait 20`.
Then run `sf apex run test --class-names StrategicDiscountPolicyTest --target-org caip-dev --code-coverage --result-format json --wait 20`.

Raw command results can contain private environment identifiers and must not be committed. Store only a sanitized summary and local source hashes in evidence/. No baseline tag until the complete app is verified.
