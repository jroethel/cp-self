## Idea

Make durable-vs-temporal a first-class distinction in the cp-self pipeline.

The self-manual is supposed to hold durable behavior rules, not temporal facts.
Today the distilled manual carries at least one expiring fact: "his premium Anthropic access is ending" (self-manual.md, Who you are working with).
When that fact expires, the manual is silently wrong until the next full regen.

## Proposal

- Add a durability test to the distill skill's rule-selection criteria: a candidate only enters the manual if it would still be true a year from now absent a life change.
- Route temporal facts (subscriptions, deadlines, current constraints) out of the manual body, either dropped or emitted to a separate dated "current context" section that is clearly marked as expiring.
- Optionally have the evidence skill tag candidate facts durable/temporal at extraction time so the distill step inherits the label.

## Origin

Surfaced during a 2026-08-08 /doctor-plus context audit: the shift-5 check (auto-memory over guidance-file memory) flagged dated facts living in always-loaded guidance.
Jeremy: "self manual is supposed to be durable, not temporal. that may be a distinction worth adding to the cp-self skill".
