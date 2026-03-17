---
name: igortest
description: Reference documentation for IgorTest, the Igor Universal Testing Framework (IUTF) used for all MIES unit tests. Use when writing, reviewing, or debugging test cases under Packages/tests, when choosing assertions or logical flags, when setting up test suites or data generators, or when questions come up about test hooks and test execution.
---

# IgorTest (Igor Universal Testing Framework)

IgorTest is the testing framework MIES uses for all automated tests (see the
`Writing Tests` section in the project instructions for MIES-specific
conventions layered on top of this framework, such as test cases needing to
be `static` and free of wave leaks).

This skill only covers the framework itself: test suites, test cases,
assertions, flags, and advanced features like test hooks. Read the relevant
file below rather than guessing at API details or assertion names.

## Reference files

- [introduction.rst](introduction.rst) - What the framework is for and why tests matter; start here if unfamiliar with IgorTest.
- [basic.rst](basic.rst) - Core structure: Test Suites, Test Cases, and Assertions, and how they relate.
- [guided-tour.rst](guided-tour.rst) - Step-by-step walkthrough of creating and executing a first test.
- [examples.rst](examples.rst) - Worked examples of writing tests with this framework.
- [advanced.rst](advanced.rst) - Advanced usage, including test hooks that run at the start/end of a test run, suite, or case.
- [flags.rst](flags.rst) - Reference for logical flags used to modify assertion behavior (e.g. wave comparison flags), which can be combined.

## When to load which file

- Writing a brand-new test file or unsure of the basic layout: read `introduction.rst` and `basic.rst` first, then `guided-tour.rst`.
- Need a concrete pattern to copy: read `examples.rst`.
- Implementing setup/teardown logic, or anything that runs before/after a test run, suite, or case: read `advanced.rst`.
- Picking the right assertion or unsure what a flag does: read `flags.rst`.
