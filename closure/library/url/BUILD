# DO NOT EDIT -- bazel run //closure/library:regenerate -- "$PWD"

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

load("@rules_python//python:defs.bzl", "py_binary")
load("//closure:defs.bzl", "closure_js_library")

closure_js_library(
    name = "all_js",
    exports = [":url"],
)

closure_js_library(
    name = "url",
    srcs = ["@com_google_javascript_closure_library//:closure/goog/url/url.js"],
    lenient = True,
    deps = [
        "//closure/library/asserts",
        "//closure/library/collections:iters",
        "//closure/library/dom",
        "//closure/library/dom:safe",
        "//closure/library/dom:tagname",
        "//closure/library/html:uncheckedconversions",
        "//closure/library/string:const",
    ],
)
