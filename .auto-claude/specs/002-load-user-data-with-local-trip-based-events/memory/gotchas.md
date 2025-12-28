# Gotchas & Pitfalls

Things to watch out for in this codebase.

## [2025-12-28 19:41]
dart and flutter CLI commands are not available in this environment. Static analysis verification must be done manually by reading and inspecting files.

_Context: Discovered during subtask-3-3 when attempting to run 'dart analyze lib/main.dart lib/services/' for verification._
