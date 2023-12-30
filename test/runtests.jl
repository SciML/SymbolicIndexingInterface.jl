using SymbolicIndexingInterface
using Test
@testset "Quality Assurance" begin
    @time include("qa.jl")
end
@testset "Interface test" begin
    @time include("example_test.jl")
end
@testset "Trait test" begin
    @time include("trait_test.jl")
end
@testset "SymbolCache test" begin
    @time include("symbol_cache_test.jl")
end
@testset "Fallback test" begin
    @time include("fallback_test.jl")
end
@testset "Parameter indexing test" begin
    @time include("parameter_indexing_test.jl")
end
