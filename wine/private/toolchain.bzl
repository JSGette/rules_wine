"""Toolchain for running Windows x86_64 executables as build actions."""

def _windows_exec_toolchain_impl(ctx):
    launcher = ctx.attr.launcher[DefaultInfo].files_to_run if ctx.attr.launcher else None
    return [platform_common.ToolchainInfo(launcher = launcher)]

windows_exec_toolchain = rule(
    implementation = _windows_exec_toolchain_impl,
    doc = """Runs Windows x86_64 executables on the execution platform.

    A None launcher means the execution platform runs them natively.""",
    attrs = {
        "launcher": attr.label(
            doc = "Executable invoked as `<launcher> <windows-exe> [args...]`.",
            cfg = "exec",
            executable = True,
        ),
    },
)
