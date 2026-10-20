"""Public API of rules_wine."""

load("//wine/private:toolchain.bzl", _windows_exec_toolchain = "windows_exec_toolchain")
load("//wine/private:windows_run_binary.bzl", _windows_run_binary = "windows_run_binary")

windows_exec_toolchain = _windows_exec_toolchain
windows_run_binary = _windows_run_binary
