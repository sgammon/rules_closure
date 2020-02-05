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

licenses(["notice"])  # Apache 2.0

package(default_visibility = ["//visibility:public"])

load("//closure/private:lines_sorted_test.bzl", "lines_sorted_test")

exports_files([
    "defs.bzl",
    "filegroup_external.bzl",
    "protobuf_drop_java_7_compatibility.patch",
    "repositories.bzl",
])

lines_sorted_test(
    name = "repositories_defs_sorted_test",
    cmd = "sed '1,/BEGIN_DECLARATIONS/ d' $< | grep ^def >$@",
    error_message = "The functions in repositories.bzl must be sorted",
    file = "repositories.bzl",
)

lines_sorted_test(
    name = "repositories_params_sorted_test",
    cmd = "grep -e '^ *omit' $< | grep -o 'omit_[_0-9a-z]*' >$@",
    error_message = "The parameter list in repositories.bzl must be sorted",
    file = "repositories.bzl",
)

lines_sorted_test(
    name = "repositories_calls_sorted_test",
    cmd = "grep -e '^ *if not omit' $< | grep -o 'omit_[_0-9a-z]*' >$@",
    error_message = "The param call list in repositories.bzl must be sorted",
    file = "repositories.bzl",
)

lines_sorted_test(
    name = "defs_loads_sorted_test",
    cmd = "grep -e '^load' $< >$@",
    error_message = "The load list in defs.bzl must be sorted",
    file = "defs.bzl",
)
