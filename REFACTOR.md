# Refactor Follow-Ups

This file tracks cleanup items that are not worth interrupting current SPEC
work for, but should be revisited in the final refactor pass.

## Open Items

- `config/override/` compatibility examples and docs
  Current role: historical scaffolding now that top-level `./config.lua` is the
  intended user config entrypoint and runtime no longer reads split override
  files.
  Later option: remove or rewrite the directory once the example/documentation
  story is settled.
