# Methodology

## The Problem

AI coding agents start writing code immediately. No plan, no review, no structured verification. This works for small changes. For anything non-trivial — multi-file features, architectural changes, coordinated refactors — it produces code that compiles but doesn't integrate well, or works today but breaks something adjacent.

The failure mode isn't capability. It's process.

## The Approach

Phased Workflow applies separation of concerns with independent verification. The agent that writes the plan doesn't review it. The agent that implements the code doesn't QA it. Each stage gets a fresh agent with no context from previous stages.

This creates structural independence. A fresh reviewer has no investment in the plan — it reads what's actually there, not what was intended. A fresh QA agent has no knowledge of implementation struggles — it verifies what's in the code, not what was attempted.

## Principles

### Fresh Agents Per Stage

Every stage uses a new sub-agent. This is the mechanism that makes independent review possible. An agent that just wrote a plan will read it charitably. An agent that just implemented code will verify it optimistically. Fresh context removes that bias.

### Evidence Before Claims

Every verification statement must cite evidence — command output, file content, or concrete data. "Should pass" and "looks correct" are not acceptable. The implementer runs every DoD check and records output. The QA agent runs verification fresh, never trusting results from prior stages.

### Human Approval Gate

The pipeline stops after planning and review. It presents the reviewed plan and waits for explicit approval. This is the point where human judgment matters most — you can see exactly what will change before any code is written.

### Plans as Implementation Checklists

Plans are not outlines or descriptions. They are step-by-step checklists with exact code, exact file paths, and verification commands. If the implementer has to make a decision the planner should have made, the plan is incomplete.

## When to Use This

Use phased workflow for changes that touch multiple files, involve architectural decisions, or would be expensive to reverse. Skip it for single-file fixes or changes you can verify by inspection.
