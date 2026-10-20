# rules_wine

> **Experimental.** The API, the pinned versions and the supported platforms
> may change without notice. Pin a commit and expect to adjust when you update.

Run Windows x86_64 executables inside Bazel actions and tests on Linux, using a
pinned Wine instead of whatever is installed on the host.

The typical use is a code generator that has to be *executed* as a Windows
binary, for instance because it reflects over types that only exist in a
Windows build, while you want to produce or check its output from a Linux
machine or CI runner.

## Acknowledgements

rules_wine started inside the [Datadog Agent](https://github.com/DataDog/datadog-agent)
repository, where it regenerates Windows-specific schemas from Linux. Many
thanks to [Datadog](https://www.datadoghq.com/) for supporting this work and
allowing it to be released as a standalone open source ruleset.

## How it works

`@rules_wine//wine:wine_run` is a small wrapper that runs a program in a
throwaway Wine prefix with a fixed locale and timezone, no display, and no
Mono/Gecko installation, then shuts `wineserver` down so nothing outlives the
action. Everything it needs comes from its runfiles; the host's Wine, `~/.wine`
and x86_64 libraries are never used.

| Exec platform | How it runs | Host requirements |
| --- | --- | --- |
| Linux x86_64 | Wine directly | glibc 2.28+ |
| Linux aarch64 | The same Wine under box64 | glibc 2.39+, 4K page size |

On any other platform `wine_run` is incompatible, so targets using it are
skipped rather than failing, and nothing is downloaded.

## Third-party software

rules_wine does not build or vendor any of the following. It downloads pinned
binaries, verified by sha256, when a compatible target is built:

| Component | Source | License |
| --- | --- | --- |
| Wine 11.0 (amd64, WoW64) | [Kron4ek/Wine-Builds](https://github.com/Kron4ek/Wine-Builds/releases/tag/11.0) | LGPL-2.1-or-later |
| box64 0.4.3 (aarch64 only) | Debian package, via snapshot.debian.org | MIT |
| libgcc_s 14.2.0 x86_64 (aarch64 only) | Debian package, via snapshot.debian.org | GPL-3.0-or-later with GCC Runtime Library Exception |

Their availability and behaviour are outside this project's control. box64 in
particular emulates a whole x86_64 Wine, so aarch64 runs are slower and less
predictable than x86_64 ones.

## Setup

rules_wine is not on the Bazel Central Registry yet. Depend on a commit:

```starlark
bazel_dep(name = "rules_wine", version = "0.0.0")
git_override(
    module_name = "rules_wine",
    commit = "1e307b77f0c657cc4729c4de90da6b51c1d497f0",
    remote = "https://github.com/JSGette/rules_wine.git",
)
```

## Usage

`wine_run <path/to/windows-exe> [args...]` runs the executable in the caller's
working directory and returns its Windows exit code. The executable must be a
path, not a name looked up in Wine's `PATH`.

### Generate a file with a Windows binary

Cross-compile the generator for Windows and run it as a build action with
`windows_run_binary`:

```starlark
load("@rules_go//go:def.bzl", "go_cross_binary")
load("@rules_wine//wine:defs.bzl", "windows_run_binary")

go_cross_binary(
    name = "gen_windows",
    platform = "@rules_go//go/toolchain:windows_amd64",
    target = ":gen",
)

windows_run_binary(
    name = "schema_windows",
    outs = ["schema_windows.gen.json"],
    args = ["-output=$(execpath schema_windows.gen.json)"],
    tool = ":gen_windows",
)
```

How the tool runs is decided by the `@rules_wine//wine:toolchain_type`
toolchain, which resolves for the platform the action executes on, whatever
the target platform:

| Exec platform | Toolchain |
| --- | --- |
| Linux x86_64, Linux aarch64 | Under `wine_run` |
| Windows x86_64 | Natively |
| Anything else | None, the build fails with "no matching toolchains" |

So the same target works on a Windows workstation, a Linux CI runner, and a
macOS client using Linux remote execution. To run Windows tools some other
way, register your own `windows_exec_toolchain` from
`@rules_wine//wine:defs.bzl` ahead of the bundled ones.

`wine_run` can also be the `tool` of a plain `run_binary` or `genrule`, with
the Windows executable as its first argument. That only works where the
action executes on Linux.

### Keep a checked-in file up to date

Combine it with `write_source_file` to regenerate a committed file from Linux.
It also creates a test that fails when the committed file is stale:

```starlark
load("@bazel_lib//lib:write_source_files.bzl", "write_source_file")

write_source_file(
    name = "update_schema_windows",
    in_file = ":schema_windows",
    out_file = "schema_windows.json",
)
```

```sh
bazel run //path/to:update_schema_windows
```

Wine prints nothing by default. Set `WINEDEBUG` to get diagnostics, e.g.
`--action_env=WINEDEBUG=err+all`.

## License

Apache-2.0. See [LICENSE](LICENSE).
