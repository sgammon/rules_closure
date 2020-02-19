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

"""Build rule for running a PhantomJS test."""

# XXX: Loading a nontrivial number of external resources into PhantomJS will
#      cause it to freeze: https://github.com/ariya/phantomjs/issues/14028

load(
    "//closure/private:defs.bzl",
    "HTML_FILE_TYPE",
    "collect_runfiles",
    "long_path",
    "unfurl",
)

def _impl(ctx):
    if not ctx.attr.deps:
        fail("phantomjs_rule needs at least one dep")
    files = [ctx.outputs.executable]
    srcs = []
    direct_srcs = []
    deps = unfurl(ctx.attr.deps, provider = "closure_js_library")
    deps.append(ctx.attr.runner)
    for dep in deps:
        if hasattr(dep, "closure_js_binary"):
            direct_srcs += [dep.closure_js_binary.bin]
        else:
            srcs += [dep.closure_js_library.srcs]
    srcs = depset(direct_srcs, transitive = srcs)

    defs = [arg for arg in ctx.attr.defs if "--define" in arg]
    defcount = len(defs)
    if defcount > 0:
        serialized_defs = ""
        i = 0
        for flag in defs:
            stripped = flag.replace("--define=", "")
            split = stripped.split("=")
            key = split[0]
            if "=" in stripped:
                # there is a value
                value = split[1].replace("'", "\'")
            else:
                # it's a flipped flag
                value = "true"

            # `"some_property": value`
            serialized_defs += ("\"%s\":%s" % (key, value))
            if i < (defcount - 1):
                serialized_defs += ","
            i = i + 1

        def_arg = "'%s'" % serialized_defs
    else:
        def_arg = "no_def_overrides"

    args = [
        "#!/bin/sh\nexec " + ctx.executable._phantomjs.short_path,
        ctx.attr.harness.closure_js_binary.bin.short_path,
        ctx.file.html.short_path,
        def_arg,
    ]
    args += [long_path(ctx, src) for src in srcs.to_list()]
    ctx.actions.write(
        is_executable = True,
        output = ctx.outputs.executable,
        content = " \\\n  ".join(args),
    )
    return struct(
        files = depset(files),
        runfiles = ctx.runfiles(
            files = files + ctx.attr.data + [ctx.file.html],
            transitive_files = depset(transitive = [
                collect_runfiles(deps),
                collect_runfiles(ctx.attr.data),
                collect_runfiles([
                    ctx.attr._phantomjs,
                    ctx.attr.runner,
                    ctx.attr.harness,
                ]),
            ]),
        ),
    )

phantomjs_test = rule(
    test = True,
    implementation = _impl,
    attrs = {
        "deps": attr.label_list(providers = ["closure_js_library"]),
        "defs": attr.string_list(mandatory = False),
        "runner": attr.label(providers = ["closure_js_library"]),
        "harness": attr.label(
            providers = ["closure_js_binary"],
            default = Label("//closure/testing:phantomjs_harness_bin"),
        ),
        "html": attr.label(
            allow_single_file = HTML_FILE_TYPE,
            default = Label("//closure/testing:empty.html"),
        ),
        "data": attr.label_list(allow_files = True),
        "_phantomjs": attr.label(
            default = Label("//third_party/phantomjs"),
            executable = True,
            cfg = "host",
        ),
    },
)
