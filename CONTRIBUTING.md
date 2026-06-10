# Contributing to NoLimits.jl

Contributions and feedback are welcome — bug reports, feature requests, documentation
improvements, and code. This file is a quick orientation; the full guides live in the
documentation:

- **[How to Contribute](https://manuhuth.github.io/NoLimits.jl/dev/how-to-contribute)** — the issue
  and pull-request workflow.
- **[Developers Guide](https://manuhuth.github.io/NoLimits.jl/dev/developers-guide)** — codebase
  layout, local setup, testing strategy, documentation workflow, and the release process.

## Reporting issues and asking questions

Open an issue on [GitHub](https://github.com/manuhuth/NoLimits.jl/issues) to report a bug, request a
feature, or ask a question. For bug reports, please include a minimal reproducible example and the
output of `versioninfo()` together with your NoLimits.jl version.

## Contributing code

1. Fork the repository and create a topic branch from `main`.
2. Install the development environment:
   ```bash
   julia --project -e 'using Pkg; Pkg.instantiate()'
   ```
3. Follow the project conventions (see the Developers Guide). Two are load-bearing:
   - all differentiated code must be **ForwardDiff-compatible** (non-mutating on the differentiated
     paths), and
   - struct fields are accessed through `get_*` **accessor functions** rather than direct field
     access.
4. Add or extend tests under `test/`, kept wired into `test/runtests.jl`, and run the suite before
   opening a pull request:
   ```bash
   julia --project -e 'using Pkg; Pkg.test()'
   ```
5. If your change is user-facing, update the relevant documentation page and docstrings (the latter
   are rendered into the [API Reference](https://manuhuth.github.io/NoLimits.jl/dev/api)).
6. Open a pull request describing the change and its motivation. Continuous integration runs the test
   suite and builds the documentation on every pull request.

For larger features or design changes, opening an issue to discuss the approach first is encouraged.

## Contact

Questions can also be directed to the lead developer and maintainer, Manuel Huth, at
<manuel.huth@uni-bonn.de>.
