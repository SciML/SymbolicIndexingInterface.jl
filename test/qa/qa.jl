using SymbolicIndexingInterface
using SciMLTesting
using Test

# ExplicitImports per-check ignore-lists: each entry is a dependency name that is
# genuinely required but is neither exported nor declared `public` by its owner
# package, and has no public alternative to switch to.
#   * `init`         — RuntimeGeneratedFunctions.init(@__MODULE__): mandatory RGF setup
#                      boilerplate; RGF exposes no public spelling of it.
#   * `ismutable`    — ArrayInterface.ismutable: ArrayInterface exports/declares no
#                      public names at all, so every access is necessarily non-public.
#   * `Fix1`         — Base.Fix1: public in recent Julia but not on the v1.10 LTS, where
#                      ExplicitImports flags it; used for partial application.
#   * `similar_type` — StaticArraysCore.similar_type: StaticArraysCore exports only the
#                      array types (`MArray`, …), not `similar_type`.
run_qa(
    SymbolicIndexingInterface;
    explicit_imports = true,
    api_docs = true,
    ei_kwargs = (;
        all_qualified_accesses_are_public = (; ignore = (:init, :ismutable, :Fix1)),
        all_explicit_imports_are_public = (; ignore = (:similar_type,)),
    ),
    api_docs_kwargs = (; rendered = true),
)
