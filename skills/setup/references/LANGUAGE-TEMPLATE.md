# Project Language

> Architectural vocabulary — deeper than CONTEXT.md.
> Use when discussing module boundaries, layers, refactoring targets.
>
> CONTEXT.md = "what" (domain terms).
> LANGUAGE.md = "how" (structure terms).

## Layers

**Domain layer** — pure business logic. No I/O, no frameworks, no DB.
- Lives in: `{e.g. src/domain/}`
- Contains: entities, value objects, domain services, domain events
- Cannot depend on: application, infrastructure, UI, framework code

**Application layer** — orchestrates domain. Use cases, command/query handlers.
- Lives in: `{e.g. src/application/}`
- Depends on: domain (only)

**Infrastructure / Adapters** — implementations of ports.
- Lives in: `{e.g. src/infrastructure/}`
- Contains: DB clients, HTTP clients, message queues, external APIs
- Implements interfaces defined by application/domain

**UI / Presentation** — entry points for users or other systems.
- Lives in: `{e.g. src/web/, apps/webapp/}`
- Depends on: application (via use cases / commands)

(Edit layer names + paths to match your project. If you don't have layered architecture, list the actual top-level dirs and what each one owns.)

## Architectural patterns

**Deep module** — small interface, lots of behavior behind.
Example: `UserRepository.findByEmail(email)` — one method, complex caching/locking inside. Good.

**Shallow module** — large interface, little behind.
Example: a service that exposes 30 thin pass-through methods. Refactor target: collapse or relocate.

**Seam** — a point where a dependency can be substituted (for testing or swapping).
Example: `Clock` interface so tests can fast-forward time.

**Adapter** — bridges domain to external system.
Example: `EmailSender` interface (domain) ← `SendgridEmailSender` (infrastructure).

**Port** — interface owned by inner layer that outer layer implements.
Example: domain defines `PaymentGateway` port; infrastructure provides `StripePaymentGateway` adapter.

## Project-specific terms

> Edit during `/improve-codebase-architecture` or `/grill-with-docs`.

**{Pattern name}**:
{What it is in this project, where it shows up, why we use it.}

## Anti-patterns we've decided to avoid

> When you remove a pattern from the codebase, document it here so it doesn't sneak back.

- `{pattern}` — removed because {reason}. Use `{replacement}` instead.
