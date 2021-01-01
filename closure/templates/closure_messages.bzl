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

"""Utilities for extracting messages from Closure Templates.
"""

load("//closure/private:defs.bzl", "SOY_FILE_TYPE", "unfurl")
load("//closure/private:providers.bzl", "SoyInfo")
load("//closure/compiler:closure_js_aspect.bzl", "closure_js_aspect")

_SOY_EXTRACTOR_BIN = "@com_google_template_soy//:SoyMsgExtractor"


def _soy__dirname(file):
    return file[:file.rfind("/") + 1]


def _impl(ctx):
    args = ctx.actions.args()
    inputs = []
    targetLocale = ctx.attr.targetLocale
    sourceLocale = ctx.attr.sourceLocale

    for arg in ctx.attr.defs:
        if not arg.startswith("--") or (" " in arg and "=" not in arg):
            fail("Please use --flag=value syntax for defs")
        args += [arg]

    seen_protos = []
    protodeps = []
    soysrc = []

    for src in ctx.attr.deps:
        src_templates = getattr(src.actions[0], "inputs", None)
        if src_templates:
            for f in src_templates.to_list():
                if f.path not in soysrc and f.path.endswith("soy"):
                    soysrc.append(f.path)
                    inputs.append(f)

    for dep in unfurl(ctx.attr.deps, provider = "closure_js_library"):
        dep_descriptors = getattr(dep.closure_js_library, "descriptors", None)
        if dep_descriptors:
            for f in dep_descriptors.to_list():
                if f not in protodeps:
                    if f.path not in seen_protos:
                        seen_protos.append(f.path)
                        protodeps.append(f)
                        args += ["--protoFileDescriptors=%s" % f.path]
                        inputs.append(f)

    for f in soysrc:
        args.add("--srcs=" + f)

    args.add("--sourceLocaleString=%s" % sourceLocale)
    args.add("--targetLocaleString=%s" % targetLocale)
    args.add("--outputFile=%s" % ctx.outputs.outputs[0].path)

    ctx.actions.run(
        inputs = inputs,
        outputs = ctx.outputs.outputs,
        executable = ctx.executable.msgextractor,
        arguments = [args],
        mnemonic = "SoyMessageExtractor",
        progress_message = "Generating %d Soy message file(s)" % len(ctx.outputs.outputs),
    )


_closure_messages = rule(
    implementation = _impl,
    output_to_genfiles = True,
    attrs = {
        "deps": attr.label_list(
            mandatory = True,
            providers = [SoyInfo],
        ),
        "targetLocale": attr.string(
            mandatory = True,
        ),
        "sourceLocale": attr.string(
            mandatory = True,
        ),
        "outputs": attr.output_list(),
        "msgextractor": attr.label(cfg = "host", executable = True, mandatory = True),
        "defs": attr.string_list(),
    },
)


# Generates a file with extracted messages from the specified
# bundle of Soy files referenced during invocation.
#
# name: Target name.
# deps: Templates to generate messages from.
# targetLocale: Locale string for target language.
# sourceLocale: Locale string for source language.
def closure_messages(
        name,
        targetLocale,
        sourceLocale = "en",
        deps = [],
        soyextractorbin = str(Label(_SOY_EXTRACTOR_BIN)),
        **kwargs):
    _closure_messages(
      name = "%s_%s_soy_msg" % (name, targetLocale),
      deps = deps,
      outputs = ["%s.%s.xliff" % (name, targetLocale)],
      targetLocale = targetLocale,
      sourceLocale = sourceLocale,
      msgextractor = soyextractorbin,
      **kwargs,
    )

    native.filegroup(
      name = name,
      srcs = ["%s.%s.xliff" % (name, targetLocale)],
    )

