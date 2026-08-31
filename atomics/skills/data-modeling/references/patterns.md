# Data Modeling — Per-Language Patterns

The technique ("model the domain so wrong states can't be constructed") is universal, but
the *enforcement mechanism* and *what a reviewer must check* differ by language. A review
can't be language-agnostic: it must verify the language-appropriate enforcement is actually
wired up, not just that the model looks tidy.

| Language | Sum-type mechanism | Exhaustiveness check | New-type wrapper | Reviewer gotcha |
|----------|-------------------|---------------------|------------------|-----------------|
| **Rust** | Native `enum` with data-carrying variants | Compiler-enforced on `match`; missing arm = compile error | Tuple struct `struct UserId(u64);` — zero-cost, distinct | A `_ =>` wildcard arm silently defeats exhaustiveness. `bool`/`u8` "state" fields bypass the benefit. |
| **TypeScript** | Discriminated union on a literal tag (`{kind:"a"} \| {kind:"b"}`) | `switch` + `default: assertNever(x)` narrows to `never` | Branded type `type UserId = string & {__brand:"UserId"}` | Erased at runtime — enforced only if `tsc` runs. `any`/casts and a `default:` without `assertNever` both break it silently. |
| **Python** | `Literal[...]`, `Enum`, or `Union`/`\|` of dataclasses | `assert_never(x)` (3.11+ / `typing_extensions`) in `else` or `case _ as unreachable:` | `NewType("UserId", int)` (static-only) or a frozen dataclass | No compile step — a type checker (mypy/pyright) MUST run in CI or nothing is enforced. `match` without the unreachable arm = zero exhaustiveness. |
| **Go** | No native support: **sealed interface** — unexported marker method `isX()` seals the set | Not built in; `//sumtype:decl` + `go-check-sumtype` linter, must be in CI | Named type `type UserId int64` (weak — implicit conversions); prefer a struct wrapper | Interfaces are nilable → a "sum type" always has an extra invalid `nil` state; account for it in every type switch. Missing linter = silent missed variant. |

## What a review must adapt per language

1. **Rust** — reject `_ =>` catch-alls in domain matches; reject `bool` where a variant belongs.
2. **TypeScript / Python** — verify the type checker runs in CI (union safety is worthless
   otherwise); require the `assertNever` / `assert_never` sentinel in the default/unreachable branch.
3. **Go** — confirm `//sumtype:decl` + `go-check-sumtype` is present and runs; account for the
   unavoidable `nil` case.
4. **All languages** — wrapper types (newtype / branded / `NewType`) must be constructed through a
   validating boundary ("parse, don't validate"). An unvalidated wrapper is theater.

## Sources

- [L4:verified] [Sum Types in Go — Applied Go](https://appliedgo.net/spotlight/sum-types-in-go/) — sealed-interface idiom, `go-check-sumtype`, `//sumtype:decl`.
- [L4:verified] [Python type hints: exhaustiveness — Adam Johnson](https://adamj.eu/tech/2022/10/14/python-type-hints-exhuastiveness-checking/) — `assert_never`, `Literal`, `match` + `case _ as unreachable`.
- [L4:verified] [Parse, don't validate — Alexis King](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) — boundary parsing, smart constructors.
- [L4:established] [Make Illegal States Unrepresentable — corrode.dev](https://corrode.dev/blog/illegal-state/) & [Using Enums to Represent State](https://corrode.dev/blog/enums/).
- [L4:established] [rust-lang api-guidelines: type-safety](https://github.com/rust-lang/api-guidelines/blob/master/src/type-safety.md).
- [L4:established] [TypeScript exhaustiveness — GeeksforGeeks](https://www.geeksforgeeks.org/typescript-exhaustiveness-checking).
