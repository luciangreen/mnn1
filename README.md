# MNN1 — Manual Neuronet 1

MNN1 is an experimental, deterministic Prolog reasoning core. It explores
whether selected learning and inference tasks can be handled with reusable
symbolic algorithms, variable-bearing templates, indexed facts and explicit
verification rather than statistical weights or gradient descent.

## Current core

The runnable foundation currently provides:

- An explicit fact store indexed by predicate, arity and first argument.
- Deterministic fact lookup, ownership-to-property reasoning, and transitive
  relation paths with data-level provenance.
- A working-memory result containing the input, bindings/output, intermediate
  facts, completed goal and selected algorithm.
- Explicit `no_applicable_algorithm` and `ambiguous(Answers)` outcomes, plus
  rendering from supported structured facts to human-readable trace sentences.
- A small S2A-style discovery step for affine numeric transformations and list
  reversal. Candidates are checked against every supplied example.
- An algorithm library that incorporates candidates only after both training
  and validation examples pass. Library files are Prolog data terms, read
  without executing imported terms.
- Configurable pipeline adapters for S2A, Starlog-shaped specifications,
  verification, Detlog-subset checks, Piglog2-shaped partitions, compilation
  and AIOC. Loop2, PLOP and AlgebraPLOP report that external implementations
  are unavailable instead of claiming to perform those optimisations.
- A reproducible 3 × 3 × 3 × 3 synthetic scene generator and explicit held-out
  combination splitting.
- Deterministic benchmark task algorithms for sequence, numeric, time-series,
  ranking, rule-chain and composition tasks, with a validation-gated pipeline
  simplifier (`benchmarks/benchmark_algorithms.pl`).

This is a starting core, not a claim that every item in the full MNN1 research
specification is implemented. In particular, general program synthesis,
typed/higher-order template gaps, contradiction handling, parallel execution,
external benchmark downloads, a browser UI, and the full Loop2/PLOP/
AlgebraPLOP ecosystem remain future work.

The benchmark algorithms are reference operations, not an NN/LLM comparison or
general-purpose optimizer. The supplied benchmark archive still requires
MNN2/NN baselines, task-safe training/test splits, and a complete run protocol
before it can produce comparative results.

## Concepts

A **Manual Neuronet** here is a network of deterministic algorithms, not a
conventional weighted neural network. A **neuroalgorithm** is an algorithm
applied to an input pattern and producing an output pattern. Ordinary Prolog
variables provide value gaps in these patterns; the present core does not yet
implement every higher-order or sequence-gap form in the specification.

Hashes and indexes narrow down candidate facts by structure; they are not
answers and are not the complete reasoning mechanism. For example,
`colour_of_owned(Person, Colour)` composes ownership and object-colour facts.
The query focuses retrieval on its required relations, which is the core's
inspectable, deterministic attention analogue.

S2A currently discovers a narrow class of algorithms from I/O examples:
integer or numeric affine mappings and list reversal. Starlog, PID, Detlog and
Piglog2 have small internal adapter representations; the named external
optimisation systems are not bundled. AIOC is deliberately conservative:
the candidate must pass all supplied training and validation examples before
it is recorded. Passing finite tests is not a proof of universal correctness.

## Run

Install SWI-Prolog (9.x), then run the automated tests:

```sh
swipl -q -s tests/run.pl
```

Example: derive a relationship from input facts and inspect its data trace:

```prolog
?- use_module(prolog/mnn).
?- remember(older(alice, bob)),
   remember(older(bob, carol)),
   solve(transitive(older, alice, carol), Answer, Trace, Memory).
Answer = transitive(older, alice, carol),
Trace = [sentence(older(alice, bob)),
         sentence(older(bob, carol)),
         sentence(transitive(older, alice, carol))].
```

Discover and validate a numerical transformation:

```prolog
?- use_module(prolog/mnn_learning).
?- discover_algorithm([io(1,2), io(2,4), io(3,6)], Algorithm, _),
   apply_algorithm(Algorithm, 137, Output, Explanation).
Algorithm = scale(2, 0),
Output = 274.
```

I/O examples are data, not executable goals. A library can be persisted with
`save_algorithm_library/1` and loaded with `load_algorithm_library/1`; loading
accepts only the core's supported algorithm terms.

`pipeline/mnn_pipeline.pl` exposes `set_pipeline_stage/2` and
`reset_pipeline_config/0` for ablation runs. The plunit tests run in GitHub
Actions on pushes and pull requests.

## Repository map

- `prolog/mnn.pl` — indexed facts, deterministic derivations, working memory
  and data-trace rendering.
- `prolog/mnn_learning.pl` — candidate discovery, verification and library.
- `pipeline/mnn_pipeline.pl` — configurable internal and external-stage adapters.
- `datasets/mnn_synthetic.pl` — systematic multivariate combinations/splits.
- `benchmarks/mnn_benchmark.pl` — exact-match evaluation against a literal
  lookup baseline and seen/unseen generalisation ratios.
- `benchmarks/benchmark_algorithms.pl` — deterministic benchmark task operations
  and equivalence-checked pipeline simplification.
- `tests/` — SWI-Prolog plunit test runner and focused tests.
