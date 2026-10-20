"""Runs a Windows x86_64 executable as a build action, natively or through a launcher."""

_TOOLCHAIN_TYPE = Label("//wine:toolchain_type")

def _windows_run_binary_impl(ctx):
    launcher = ctx.exec_groups["windows_exec"].toolchains[_TOOLCHAIN_TYPE].launcher
    tool = ctx.attr.tool[DefaultInfo].files_to_run

    args = ctx.actions.args()
    if launcher:
        args.add(tool.executable)
    args.add_all([ctx.expand_location(a, ctx.attr.srcs) for a in ctx.attr.args])

    ctx.actions.run(
        executable = launcher or tool,
        tools = [tool] if launcher else [],
        inputs = ctx.files.srcs,
        outputs = ctx.outputs.outs,
        arguments = [args],
        exec_group = "windows_exec",
        mnemonic = "WindowsRunBinary",
        progress_message = "Running Windows tool for %{label}",
    )
    return [DefaultInfo(files = depset(ctx.outputs.outs))]

windows_run_binary = rule(
    implementation = _windows_run_binary_impl,
    doc = """Like run_binary, for a Windows x86_64 tool.

    Runs on any execution platform with a @rules_wine//wine:toolchain_type
    toolchain, regardless of the target platform.""",
    attrs = {
        "tool": attr.label(
            doc = "A Windows x86_64 executable, e.g. a go_cross_binary for windows_amd64.",
            # Same exec group as the action, so the tool and the launcher are
            # resolved for the platform the action runs on.
            cfg = config.exec("windows_exec"),
            executable = True,
            allow_files = True,
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "Inputs of the action.",
            allow_files = True,
        ),
        "outs": attr.output_list(
            doc = "Files the tool writes.",
            mandatory = True,
        ),
        "args": attr.string_list(
            doc = "Arguments to the tool, subject to $(execpath) expansion of srcs and outs.",
        ),
    },
    exec_groups = {
        "windows_exec": exec_group(toolchains = [_TOOLCHAIN_TYPE]),
    },
)
