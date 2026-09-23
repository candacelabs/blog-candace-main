---
title: "The cerebrospinal fluid: no IPC inside LITHE's CPU 0"
date: 2026-09-23
description: "How irritation with the cloud turned into one Go runtime for agent work, why it lands exactly on LITHE's housekeeping core, and what a proof can promise that a hardware limit cannot."
tags: ["go", "agents", "architecture", "lean", "robotics"]
---

I got irritated by the cloud. Not by any one outage or bill, but by the shape
of it: every capability sold as its own service, every service another network
hop, and every hop another thing to deploy, authenticate, serialize across and
watch. This note is about what I built instead. It is called CSF, the
Cerebrospinal Fluid, and it turned out to fit, almost exactly, into a slot
that a robotics paper had just drawn.

The paper is [LITHE](https://arxiv.org/abs/2603.07442), by He Kai Lim and Tyler
R. Clites. CSF's selling point, in LITHE's own vocabulary, is this: **CSF
prevents the avoidable IPC problem inside LITHE's CPU 0 (Housekeeping).** The
rest of this note explains what that means, how it works, where it stops, and
why I think the next step is a proof rather than another hardware limit.

## Irritated by the cloud

For a while now my infrastructure has been mine. A small edge proxy terminates
TLS for the public sites; everything behind it runs on hardware at home and
talks over a private mesh network. The game-streaming service renders on a GPU I
own and streams it through that same authenticated edge. Most of my continuous
integration runs on my own fleet of disposable runners: the controller keeps no idle
workers, starts one ephemeral Docker-in-Docker worker per queued job and
deletes it after that single job.

Owning it has taught me things a managed cloud hides. Routing container DNS
through the mesh network's resolver once broke all name resolution at the edge,
certificate renewals included, and the public sites were down for weeks. More
recently I measured why CI kept downloading the same pinned Go image: a remote
registry mirror still sends every layer over the network to every disposable
worker, because each worker's Docker storage is deleted with it. A
pull-through cache on the runner network now keeps those layers local. Required private CI
handoffs have moved off hosted artifact storage too.

None of that is a complaint about owning things. It is the argument for it. The
thesis I keep coming back to goes like this. AI, and the way compute is
concentrating in a few clouds, is pushing individual developers back toward
their own boxes; AI also makes maintaining your own software dramatically
cheaper. Meanwhile the industry's default architecture turned every useful
capability — a queue, a scheduler, a search index, a tool server — into its own
daemon with its own protocol. Microservices earned their reputation for good
reasons, but I wanted their useful properties without the hops: the
capabilities as libraries, composed into one Go runtime, with typed boundaries
between them. I have been calling that *monolithic microservices*.

There is a second reason to want one box. The day frontier-model subscriptions
stop being affordable for me, I want agents to run on a model that fits on one consumer
GPU. That only works if the agent's job is small: pick among well-typed options
in a system that already knows its own shape. More on that below.

## What CSF is

CSF is a Go library and runtime for the coordination *around* an agent system:
typed tools, sessions and worktrees, schedules, knowledge ingestion and search,
traces and retained evidence. The one-line version is **one Go runtime: agent
work, typed tools, shared knowledge, observable experiments.**

Three design rules carry most of the weight.

**Services are libraries; the binary owns the process.** CSF is a package whose
constructor takes functional options. It registers routes on the caller's router
and hands back handlers; the caller owns the HTTP server, the listener and
cancellation. The runnable composition — the one thing that owns a process —
decides what to mount. The consumer example is the whole idea in a dozen lines:

```go
func newConsumerRouter(themeDirectory string, eventPath string) (*gin.Engine, error) {
	options := []csf.Option{csf.WithWorkbenchThemeDirectory(themeDirectory)}
	if eventPath != "" {
		options = append(options, csf.WithDashboard(csf.NewDashboard(eventPath)))
	}
	service, err := csf.New(options...)
	if err != nil {
		return nil, fmt.Errorf("create CSF: %w", err)
	}
	router := httpserver.NewEngine(applicationName)
	service.Register(router)
	router.Any(mcpPath, gin.WrapH(service.MCPHandler()))
	registerConsumerSummary(router, service)
	return router, nil
}
```

CSF registers its generated routes on the caller's router and hands back an MCP
handler. The consumer's own endpoint sits beside them, calling
`service.GetSnapshot` as an ordinary Go method: same process, same types, no
client library.

**Contracts are generated once.** A protobuf schema and an annotated API
description own the wire messages and operations. Go, Python, OpenAPI, HTTP,
CLI and MCP projections are all generated from those sources, so HTTP, CLI and
MCP expose one operation set, derived together.

**The agent is a first-class consumer.** CSF is meant to be agent-native. The
intended first instruction to your coding agent is *"Learn about CSF."* The
`LearnAboutCSF` MCP operation explains the pinned version's capabilities and
extension points; when knowledge is configured, it also submits the embedded
guidance plus the consumer files you select for indexing, and returns durable
ingestion receipts with revisions and content hashes. Repeating the call is
idempotent.

Your own tools join the same MCP server, typed end to end. This is the whole
registration function:

```go
// WithMCPTool adds one typed consumer-owned tool to the same MCP server as
// CSF's generated operations. The MCP SDK derives and validates the input and
// output schemas from In and Out; CSF only supplies registration ordering and
// collision checks.
func WithMCPTool[In, Out any](tool mcp.Tool, handler mcp.ToolHandlerFor[In, Out]) Option {
	return func(service *Service) {
		service.consumerMCPTools = append(service.consumerMCPTools, func(service *Service) error {
			if !mcpToolNamePattern.MatchString(tool.Name) || handler == nil {
				return fmt.Errorf("%w: name and handler are required", ErrInvalidMCPTool)
			}
			if _, exists := service.mcpToolNames[tool.Name]; exists {
				return fmt.Errorf("%w: %q", ErrMCPToolConflict, tool.Name)
			}
			toolCopy := tool
			mcp.AddTool[In, Out](service.mcp, &toolCopy, handler)
			service.mcpToolNames[tool.Name] = struct{}{}
			return nil
		})
	}
}
```

The type parameters are the contract. The MCP SDK derives the JSON schemas from
`In` and `Out`, and a tool whose name collides with a CSF operation fails
construction instead of silently shadowing it.

Knowledge follows the same rule. Ingestion registers a source and enqueues its
projection in one PostgreSQL transaction; a small, bounded set of worker
goroutines in the same process claims those durable tasks, verifies the
retained bytes and indexes them into OpenSearch with leases and capped retries.
That is at-least-once delivery with idempotent document IDs, not an
exactly-once claim — and it is not another service.

## Just in time, and in the right place: LITHE

LITHE (Linux Isolated Threading for Hierarchical Execution) collapses a robot's
control hierarchy onto one commodity single-board computer, a Raspberry Pi 4B.
A best-effort Python **Brain** directs a real-time C++ **Spine**, and the Brain
can write, compile and hot-swap entirely new control laws into the running
Spine without interrupting its 1 kHz loop. The paper reports a worst-case
execution time under 100 µs and maximum release jitter under 4 µs under heavy
load. In its demonstration, a local 7-billion-parameter coding model acting as a
supervisor identified an arm's gravity load and deployed a gravity-compensation
controller to the moving robot; when the Brain was deliberately frozen, the
Spine kept holding the load.

The part that stopped me was how LITHE partitions the four cores (§III-B):

| Core | LITHE's role |
|---|---|
| **CPU 0 (Housekeeping)** | Linux housekeeping, SSH sessions and non-critical interrupts. It absorbs system jitter, and LITHE's loader thread loads new controllers here, off the real-time path (§III-E1). |
| CPU 1 (Spine) | The C++ control loop, alone on an isolated core. |
| CPU 2 (Brain) | The Python runtime. |
| CPU 3 (Transport) | Blocking SPI/CAN bus I/O. |

And how seriously it takes inter-process communication (§III-C): Brain and
Spine share a lock-free, zero-copy POSIX shared-memory region guarded by a
seqlock, with its layout owned by a build-time, schema-driven generator that
emits both the C++ structs and the Python bindings. The abstract names complex
middleware as one cost of the conventional alternatives.

When I read that, the framing fit exactly. I had been using Go to solve the IPC
problem for the middleware layer; LITHE gave that layer an address. Everything
an agent system needs besides reasoning and control — tools, sessions,
schedules, knowledge, observation — lives on the housekeeping side of the
partition. So I named the integration layer after the fluid around the brain and
spine. As a small, satisfying check, CSF's own knowledge search, run over a
retained corpus that included the paper, ranked LITHE's IPC section first for an
IPC query.

![CSF drawn inside LITHE's CPU 0 as one Go process containing typed tools, sessions, schedules, knowledge, observation and bounded workers. LITHE's Brain, Spine and Transport cores, their shared-memory IPC, and the external PostgreSQL, OpenSearch, Langfuse and model or simulator boundaries are drawn outside it.](cpu0.svg)

*An architectural mapping drawn by hand, not a description of a deployment.*
*LITHE's own architecture figures are in [the paper](https://arxiv.org/html/2603.07442v1#S1.F2).*

### How CSF prevents the IPC problem inside CPU 0

Build CPU 0's coordination the usual way and you get a daemon per capability: a
tool server, a scheduler, a search indexer, a trace collector, a session
manager. Each handoff between them is a socket, a serialization format and a
process lifecycle to supervise — IPC that exists only because of how the
software was packaged.

CSF composes those capabilities in one Go process instead:

- **Typed function calls, not sockets.** A service calls another service's Go
  method with Go values. There is no wire format between them to version or
  validate twice.
- **Goroutines and channels, not daemons.** Concurrent work — projection
  workers, schedules, job polling — runs as bounded goroutines owned by the
  process, and waiting on tools, storage and model calls coexists in one
  runtime.
- **Contexts and explicit ownership, not supervisors.** Contexts and explicit
  ownership give each operation a cancellation and cleanup path inside the
  process that owns it.
- **Checks, not good intentions.** Separate architecture checks inspect selected
  Go ownership and process boundaries in source. They establish those source
  constraints, not runtime timing.

The same contract-generator instinct shows up on both sides. LITHE generates its
shared-memory layout from a schema so the Brain and Spine cannot disagree about
bytes; CSF generates every surface of an operation from one protobuf and API
description so a tool, a CLI command and an HTTP route cannot disagree about
meaning.

### Where that stops

The claim is precise, so its limits should be too:

- **External boundaries stay.** PostgreSQL, OpenSearch, Langfuse and external
  model or simulator processes keep their protocols. CSF removes IPC between its
  own capabilities, not IPC with systems that genuinely live elsewhere.
- **LITHE's IPC is LITHE's.** The Brain–Spine shared-memory boundary is a
  separate integration boundary. CSF does not replace it.
- **Placement is configuration.** Pinning a CSF process to a core is deployment
  work. CSF does not implement LITHE's loader, CPU isolation or controller hot
  swap.

## Proofs, not just hardware

LITHE is admirably direct about where its safety story ends. Its user-space
real-time approach "provides a functional margin of safety, even if it lacks the
formal mathematical guarantees of a verified real-time operating system" (§V-A).
For model-written controllers, "it remains an area of active research to
implement appropriate safety and verification bounds on the model's output"
(§V-B). And in §V-C: "theoretical stability guarantees remain an open
challenge. Where control theory is unvalidated, safety must be enforced via
strict hardware-level limits on torque and velocity."

A hardware limit is a real guarantee, and every robot should have one. But it is
enforced per device, and rhetorically it answers "how bad can it get?" rather
than "what exactly will this code do?" A proof about a *language* holds for
every program written in it. That is the bridge I want CSF to build, and it is
how I think about making LITHE scale: instead of letting a model emit arbitrary
C++, narrow what it may author to a typed, bounded language whose compiler is
proved, and let the model choose within it.

Here is what exists today, stated as exactly as the Lean source states it.

CSF ships a small Lean 4 project that models the arithmetic slice of its
brain–spine protobuf contract: a typed expression language with constants, four
observation slots (an index type makes an invalid slot unrepresentable),
addition, integer scaling and clamping, over integers that saturate at ±10⁹,
compiled to a postfix stack machine. Lean machine-checks four theorems:

| Theorem | What it guarantees |
|---|---|
| `compile_correct` | For every expression, every input and any existing stack, running the compiled instructions pushes exactly the expression's value and leaves the rest of the stack untouched. |
| `evaluate_bounds` | Every expression evaluates within the saturation bound. |
| `compiled_actuator_correct` | Compiled code, run from an empty stack and passed through the actuator clamp, agrees exactly with the clamped source evaluator. |
| `compiled_actuator_bounds` | Every compiled expression produces an actuator value in [-1000, 1000]. |

The check script downloads a pinned Lean release, verifies its SHA-256, runs
Lean with `--trust=0`, and audits each theorem's axioms: only Lean's standard
`propext`, `Classical.choice` and `Quot.sound` are admitted. No `sorry`, no
`native_decide`, no custom axioms. CI runs it in its own job.

And here is what is **not** proved, because a proof story that overstates
itself is worse than none:

- The Lean model's agreement with the canonical wire semantics is a reviewed
  translation, not a theorem. The Go and Rust evaluators have conformance tests,
  not equivalence proofs.
- The verifier for `csfc`, CSF's own compiler, is a stub. It returns
  `notImplemented` for every input and issues no certificate.
- The actuator clamp proves a numeric range. It says nothing about timing,
  stability, collision avoidance, safe controller switching or physical safety.
  The hardware watchdog LITHE recommends is still necessary.
- The Lean kernel, its release build, the standard library, the operating system
  and the hardware remain trusted.

So the honest shape is: a proved compiler for a deliberately small controller
language, a stubbed verifier for the bigger compiler, and a clear list of what
must be proved next. That is a start on the gap LITHE names, not a closure of it.

## LLMs that only make decisions

This is where the pieces point. I have said for a while that if you start from a
shared, typed ontology, most of what an agent has to do reduces to
multiple-choice decisions. And if a controller can only be assembled from
options that are provable, there is very little left to worry about in the
choosing; the real work moves to deciding what should be provable and what need
not be.

CSF already has the scaffolding for that. Its vocabulary is generated from one
architecture model, so every diagram and dictionary entry names the same terms.
Operations are typed and generated, so an agent sees a fixed menu rather than a
blank page. A typed agent recipe is validated and given stable assignment
identities before any work is submitted. And the controller language above is
small enough to prove things about.

What does not exist yet is the step that joins them. In CSF's improvement loop —
observe, retrieve, choose, check, execute, evaluate, save evidence, improve —
*choose* is still marked planned. Today a bounded numerical search selects between candidate
controllers between episodes; an agent choosing among proved options is the next
step, not a shipped one. When it lands, the model's job gets small enough that a
model on one GPU at home should be able to do it. That is the whole point.

## Status and boundaries

CSF's first release is a **developer preview**. Version 0.1.0 is a breaking
integration baseline with no stability or compatibility promise: pin a
reviewed snapshot and expect interfaces to change. The source release is
in private staging and a public release is forthcoming; this note will link to
it when it exists.

What is real today: the one-process host with generated HTTP, CLI and MCP
operations; the Workbench for sessions and worktrees; typed consumer tools on
the same MCP server; agent-native onboarding; knowledge ingestion and search
with durable in-process workers; simulator job adapters with local evidence; the
bounded controller compiler and its four Lean theorems.

What is not: CSF does not implement LITHE's loader, CPU isolation or hot swap.
The *choose* step and the complete autonomous improvement loop are planned. The
`csfc` verifier is a stub. Real AWS Batch execution still needs configuration
and acceptance; autonomous neural training is not demonstrated; the Copilot
backend is a deliberate external boundary rather than an embedded model loop.
Nothing here establishes physical safety.

If you work on LITHE-style systems, read [the paper](https://arxiv.org/abs/2603.07442).
It is the clearest statement I have found of why the space between a model and
a motor deserves its own architecture. CSF is my attempt at the part of that
architecture that lives on CPU 0.
