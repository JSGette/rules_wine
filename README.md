# rules_wine

Run Windows x86_64 executables inside Bazel actions and tests on Linux, using a
pinned Wine instead of whatever is installed on the host.

Typical use: a code generator that must be *executed* as a Windows binary
(for instance because it reflects over types that only exist in a Windows
build) but whose output you want to produce or verify from Linux.

## Supported hosts

| Exec platform | How it runs | Host requirements |
| --- | --- | --- |
| Linux x86_64 | [Kron4ek Wine 11.0 amd64-wow64](https://github.com/Kron4ek/Wine-Builds/releases/tag/11.0) | glibc 2.28+ |
| Linux aarch64 | The same Wine under [box64](https://github.com/ptitSeb/box64) 0.4.3 (Debian package) | glibc 2.39+, 4K page size |

On any other platform `@rules_wine//wine:wine_run` is incompatible, so targets
using it are skipped rather than failing. The archives are only downloaded when
a compatible target is built.

FreeType is optional; without it Wine prints a warning but console programs run
fine.

## Setup

```starlark
bazel_dep(name = "rules_wine", version = "0.0.0")
```

## Usage

`wine_run <windows-exe> [args...]` runs the executable in a throwaway Wine
prefix and returns its exit code. As a `run_binary` tool it resolves for the
exec platform:

```starlark
load("@bazel_lib//lib:run_binary.bzl", "run_binary")

go_cross_binary(
    name = "gen_windows",
    platform = "@rules_go//go/toolchain:windows_amd64",
    target = ":gen",
)

run_binary(
    name = "gen_output",
    srcs = [":gen_windows"],
    outs = ["output.json"],
    args = [
        "$(execpath :gen_windows)",
        "-output=$(execpath output.json)",
    ],
    tool = "@rules_wine//wine:wine_run",
)
```

Set `WINEDEBUG` (e.g. `--action_env=WINEDEBUG=err+all`) to get Wine
diagnostics; they are silenced by default.

## License

Apache-2.0. Wine is LGPL-2.1-or-later and box64 is MIT; this module only
downloads and runs them.
