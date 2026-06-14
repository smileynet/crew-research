---
inclusion: manual
---
# Grill Context: Game Engine Project

## Domain Constraints
- Engine targets WebAssembly + native desktop (no mobile)
- Networking must support both peer-to-peer and dedicated server topologies
- Tick rate: 60Hz simulation, 20Hz network sync
- Maximum 8 players per session
- State synchronization uses delta compression

## Research Source Priority
1. Game Networking Resources (gafferongames.com) — authoritative for netcode patterns
2. Valve Developer Wiki — Source engine networking model
3. Overwatch GDC talks — ECS + networking at scale

## Domain Questions to Ask
- How does this handle client-side prediction and server reconciliation?
- What happens when a player disconnects mid-game? (state cleanup, reconnection window)
- How does this interact with the existing ECS architecture?
- What's the bandwidth budget per player?
- How will this be tested without real network latency? (deterministic replay? mock transport?)

## Cross-Reference Targets
- `docs/architecture/ecs.md` — current entity system design
- `docs/architecture/event-bus.md` — inter-system communication
- `.memory/adr/0003-transport-layer.md` — why we chose QUIC over TCP

## ADR Format
When proposing architecture decisions, use the project's format:
- Title, Status, Date
- Context (why now), Decision (what), Consequences (trade-offs)
- Keep under 30 lines
