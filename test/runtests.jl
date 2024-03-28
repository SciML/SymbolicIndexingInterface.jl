using SymbolicIndexingInterface
using SafeTestsets
using Test

@safetestset "Quality Assurance" begin
    @time include("qa.jl")
end
@safetestset "Interface test" begin
    @time include("example_test.jl")
end
@safetestset "Trait test" begin
    @time include("trait_test.jl")
end
@safetestset "SymbolCache test" begin
    @time include("symbol_cache_test.jl")
end
@safetestset "Fallback test" begin
    @time include("fallback_test.jl")
end
@safetestset "Parameter indexing test" begin
    @time include("parameter_indexing_test.jl")
end
@safetestset "State indexing test" begin
    @time include("state_indexing_test.jl")
end
@safetestset "Remake test" begin
    @time include("remake_test.jl")
end
@safetestset "ProblemState test" begin
    @time include("problem_state_test.jl")
end
