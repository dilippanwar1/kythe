load("//tools:build_rules/shims.bzl", "go_test")
load("@io_bazel_rules_go//go:def.bzl", "go_library")

package(default_visibility = ["//kythe:default_visibility"])

go_library(
    name = "cache",
    srcs = ["cache.go"],
    deps = ["//kythe/go/platform/analysis"],
)

go_test(
    name = "cache_test",
    size = "small",
    srcs = ["cache_test.go"],
    library = "cache",
    visibility = ["//visibility:private"],
)
