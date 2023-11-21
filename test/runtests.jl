using SymbolicIndexingInterface
using Test

@testset "Interface test" begin
    @time include("example_test.jl")
end
@testset "Trait test" begin
    @time include("trait_test.jl")
end
@testset "SymbolCache test" begin
    @time include("symbol_cache_test.jl")
end