load("@depend_on_what_you_use//src/cc_info_mapping:cc_info_mapping.bzl", "DwyuCcInfoRemappingsInfo")
load(":dwyu.bzl", "dwyu_aspect_impl")

def dwyu_aspect_factory(
        config = None,
        recursive = False,
        skipped_tags = None,
        target_mapping = None,
        use_implementation_deps = False):
    """
    Create a "Depend on What You Use" (DWYU) aspect.

    An aspect can only have default values and cannot be configured on the command line. Use this factory to create
    an aspect with the desired behavior and then use it on the command line or in rules.

    Args:
        config: Configuration file for the tool comparing the include statements to the dependencies.
        recursive: If true, execute the aspect on all transitive dependencies.
                   If false, analyze only the target the aspect is being executed on.
        skipped_tags: Do not execute the aspect on targets with at least one of those tags. By default skips the
                      analysis for targets tagged with 'no-dwyu'.
        target_mapping: A target providing a map of target labels to alternative CcInfo provider objects for those
                        targets. Typically created with the dwyu_make_cc_info_mapping rule.
        use_implementation_deps: If true, ensure cc_library dependencies which are used only in private files are
                                 listed in implementation_deps. Only available if flag
                                 '--experimental_cc_implementation_deps' is provided.
    Returns:
        Configured DWYU aspect
    """
    attr_aspects = []
    if recursive:
        if use_implementation_deps:
            attr_aspects = ["implementation_deps", "deps"]
        else:
            attr_aspects = ["deps"]
    aspect_config = [config] if config else []
    aspect_skipped_tags = skipped_tags if skipped_tags else ["no-dwyu"]
    aspect_target_mapping = [target_mapping] if target_mapping else []
    return aspect(
        implementation = dwyu_aspect_impl,
        attr_aspects = attr_aspects,
        fragments = ["cpp"],
        # Uncomment when minimum Bazel version is 7.0.0, see https://github.com/bazelbuild/bazel/issues/19609
        # DWYU is only able to work on targets providing CcInfo. Other targets shall be skipped.
        # required_providers = [CcInfo],
        toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
        attrs = {
            "_cc_toolchain": attr.label(
                default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
            ),
            "_config": attr.label_list(
                default = aspect_config,
                allow_files = [".json"],
            ),
            "_dwyu_binary": attr.label(
                default = Label("@depend_on_what_you_use//src/analyze_includes:analyze_includes"),
                allow_files = True,
                executable = True,
                cfg = "exec",
                doc = "Tool Analyzing the include statement in the source code under inspection" +
                      " and comparing them to the available dependencies.",
            ),
            "_process_target": attr.label(
                default = Label("@depend_on_what_you_use//src/aspect:process_target"),
                executable = True,
                cfg = "exec",
                doc = "Tool for processing the target under inspection and its dependencies. We have to perform this" +
                      " as separate action, since otherwise we can't look into TreeArtifact sources.",
            ),
            "_recursive": attr.bool(
                default = recursive,
            ),
            "_skipped_tags": attr.string_list(
                default = aspect_skipped_tags,
            ),
            "_target_mapping": attr.label_list(
                providers = [DwyuCcInfoRemappingsInfo],
                default = aspect_target_mapping,
            ),
            "_use_implementation_deps": attr.bool(
                default = use_implementation_deps,
            ),
        },
    )
