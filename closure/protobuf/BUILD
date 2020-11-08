# Copyright 2016 The Closure Rules Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

load("//closure/compiler:closure_js_library.bzl", "closure_js_library")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")


bzl_library(
    name = "protobuf-bzl",
    srcs = [
        "closure_js_proto_library.bzl",
        "closure_proto_library.bzl",
    ],
)

closure_js_library(
    name = "jspb",
    srcs = ["@com_google_protobuf_js//:proto_js_library_files"],
    suppress = [
        "analyzerChecks",
        "lintChecks",
        "reportUnknownTypes",
        "strictCheckTypes",
        "deprecated",
        "stricterMissingRequire",
        "stricterMissingRequireTypeInProvidesFile",
    ],
    deps = [
        "//closure/library/array",
        "//closure/library/asserts",
        "//closure/library/crypt",
        "//closure/library/crypt:base64",
        "//closure/library/object",
        "//closure/library/string",
    ],
)
