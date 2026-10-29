# resource/lessons

What the outside world taught this project: platform behavior,
environment surprises, harness quirks, durable domain knowledge.

## Naming

- `domain.<YYYYMMDD>.<title>.md` — durable knowledge, valid for the
  life of the project.
- `edge.<YYYYMMDD>.<title>.md` — something the happy path missed;
  discovered by incident or close call.

## Shape

Each file carries: what happened (or what was observed), why it
happened, the fix or rule, and the lesson that falls out of it. Written
while the evidence is in front of you, before the related work is
committed.

## Split rule

A lesson is something the outside world does. If this codebase did it
wrong, that is a bug and it goes in `resource/bugs/` instead.
