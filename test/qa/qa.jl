using SymbolicIndexingInterface
using SciMLTesting
using Test

# ExplicitImports only sees an extension module once its trigger package is loaded, so
# load every weakdep here to bring the extensions into the QA scan.
using PrettyTables

# ExplicitImports silently skips an extension that fails to load, so assert the
# extension modules actually exist rather than trusting a green run_qa.
@testset "Extensions loaded" begin
    @test Base.get_extension(SymbolicIndexingInterface, :SymbolicIndexingInterfacePrettyTablesExt) !== nothing
end

run_qa(
    SymbolicIndexingInterface;
    ei_kwargs = (;
        all_explicit_imports_are_public = (; ignore = (:similar_type,)),
    ),
)
