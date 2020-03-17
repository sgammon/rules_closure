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

"""Utilities for compiling Closure Templates to Python.
"""

load("@rules_python//python:defs.bzl", _py_library = "py_library")
load("//closure/private:defs.bzl", "SOY_FILE_TYPE", "unfurl")
load("//closure/private:providers.bzl", "SoyInfo")
load("//closure/compiler:closure_js_aspect.bzl", "closure_js_aspect")

_SOY_PY_RUNTIME = "@com_google_template_soy_py_runtime//:runtime"
_SOY_COMPILER_BIN = "@com_google_template_soy//:SoyToPySrcCompiler"


def _impl(ctx):
    args = ctx.actions.args()
    inputs = []

    # add the runtime
    args.add("--runtimePath=.")
    for file in ctx.attr.soy_runtime.files.to_list():
      inputs.append(file)

    iout_prefix = _soy__dirname([s for s in ctx.files.srcs][0].path)
    args.add("--outputPathFormat=%s/{INPUT_DIRECTORY}/{INPUT_FILE_NAME_NO_EXT}.py" %
        (ctx.configuration.genfiles_dir.path))

    # force a link manifest to be written
    manifest_path = "%s/%s.manifest" % (
      ctx.configuration.genfiles_dir.path, str(ctx.label)
        .replace(':', '/')
        .replace('//', '')
        .replace('_soy_py', '')
    )
    args.add("--outputNamespaceManifest=%s" % manifest_path)

    for arg in ctx.attr.defs:
        if not arg.startswith("--") or (" " in arg and "=" not in arg):
            fail("Please use --flag=value syntax for defs")
        args += [arg]

    for f in ctx.files.srcs:
        args.add("--srcs=" + f.path)
        inputs.append(f)

    seen_protos = []
    protodeps = []
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

    for protodep in ctx.attr.proto_deps:
        if protodep not in protodeps:
            for descriptor in protodep[ProtoInfo].transitive_descriptor_sets.to_list():
                if descriptor not in protodeps:
                    protodeps.append(descriptor)
                    args.add("--protoFileDescriptors=%s" % descriptor.path)
                    inputs.append(descriptor)

    soydeps = []
    ## new style begins here
    for dep in unfurl(ctx.attr.deps):
        dep_templates = getattr(dep.actions[0], "outputs", None)
        if dep_templates:
            for f in dep_templates.to_list():
                if f.path not in soydeps:
                    soydeps.append(f.path)
                    inputs.append(f)
        else:
            fail("Failed to resolve output templates for SoyInfo dependency.")

    ## prep soy dependencies for the template, if we have any
    if len(soydeps) > 0:
        args.add("--depHeaders=%s" % ",".join(soydeps))

    ctx.actions.run(
        inputs = inputs,
        outputs = ctx.outputs.outputs,
        executable = ctx.executable.pycompiler,
        arguments = [args],
        mnemonic = "SoyPythonCompiler",
        progress_message = "Generating %d Soy Python file(s)" % len(ctx.outputs.outputs),
    )


_closure_py_template_library = rule(
    implementation = _impl,
    output_to_genfiles = True,
    attrs = {
        "srcs": attr.label_list(allow_files = SOY_FILE_TYPE),
        "deps": attr.label_list(
            mandatory = True,
            providers = [SoyInfo],
        ),
        "proto_deps": attr.label_list(
            mandatory = False,
            providers = [ProtoInfo],
        ),
        "outputs": attr.output_list(),
        "pycompiler": attr.label(cfg = "host", executable = True, mandatory = True),
        "soy_runtime": attr.label(),
        "defs": attr.string_list(),
    },
)


def _soy__dirname(file):
    return file[:file.rfind("/") + 1]

def _soy__filename(file):
    return file[file.rfind("/") + 1:]


# Generates a py_library with the generated Python code for each
# provided template source.
#
# For each Soy input called abc_def.soy, a Python class will be
# implemented.
#
# srcs: an explicit file list of soy files to scan.
# deps: Soy files that these templates depend on, in order for
#     templates to include the parameters of templates they call.
# py_deps: Python dependencies to inject into the `py_library`.
# proto_deps: Protobuf model dependencies to include.
# soycompilerbin: Optional Soy to Python compiler target.
def closure_py_template_library(
        name,
        srcs = [],
        deps = [],
        py_deps = [],
        proto_deps = [],
        soypyruntime = str(Label(_SOY_PY_RUNTIME)),
        soycompilerbin = str(Label(_SOY_COMPILER_BIN)),
        **kwargs):

    # Strip off the .soy suffix from the file name, preserving the
    # case of directory names, if any.
    py_outs = [
        (_soy__dirname(fn) + _soy__filename(fn)[:-4] +
          ".py").replace("-", "_")
        for fn in srcs
    ]

    extra_outs = [
      name + ".manifest",
    ]

    _closure_py_template_library(
      name = name + "_soy_py",
      srcs = srcs,
      deps = deps + py_deps,
      proto_deps = proto_deps,
      outputs = py_outs + extra_outs,
      pycompiler = soycompilerbin,
      soy_runtime = soypyruntime,
      **kwargs,
    )

    _py_library(
      name = name,
      srcs = py_outs,
    )
