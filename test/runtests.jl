using SymbolicIndexingInterface
using SafeTestsets
using Test
using Pkg

const GROUP = get(ENV, "GROUP", "All")

function activate_downstream_env()
    Pkg.activate("downstream")
    Pkg.develop(PackageSpec(path = dirname(@__DIR__)))
    Pkg.instantiate()
end

mutable struct CheckboundsCountedArray{T, N, A <: AbstractArray{T, N}} <:
               AbstractArray{T, N}
    array::A
    count::Int
end

CheckboundsCountedArray(arr) = CheckboundsCountedArray(arr, 0)
Base.@propagate_inbounds Base.getindex(arr::CheckboundsCountedArray, args...) = getindex(
    arr.array, args...)
Base.@propagate_inbounds Base.setindex!(arr::CheckboundsCountedArray, args...) = setindex!(
    arr.array, args...)
Base.size(arr::CheckboundsCountedArray) = size(arr.array)
Base.length(arr::CheckboundsCountedArray) = length(arr.array)
function Base.checkbounds(arr::CheckboundsCountedArray, args...)
    arr.count += 1
    checkbounds(arr.array, args...)
end
function Base.checkbounds(::Type{Bool}, arr::CheckboundsCountedArray, args...)
    arr.count += 1
    checkbounds(arr.array, args...)
end

function Base.copy(arr::CheckboundsCountedArray)
    return CheckboundsCountedArray(copy(arr.array), arr.count)
end

function test_no_boundschecks(arr::CheckboundsCountedArray)
    @test arr.count == 0
end
function test_no_boundschecks(p::ProblemState)
    test_no_boundschecks(p.u)
    test_no_boundschecks(p.p)
end
function test_no_boundschecks(ptc::ParameterTimeseriesCollection)
    test_no_boundschecks(ptc.collection)
    arr = ptc.collection isa CheckboundsCountedArray ? ptc.collection.array : ptc.collection
    for buf in ptc.collection
        test_no_boundschecks(buf)
    end
    test_no_boundschecks(ptc.paramcache)
end
test_no_boundschecks(_) = nothing

maybe_CheckboundsCountedArray(arr, inbounds) = inbounds ? CheckboundsCountedArray(arr) : arr

if GROUP == "All" || GROUP == "Core"
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
    @safetestset "ParameterTimeseriesCollection test" begin
        @time include("parameter_timeseries_collection_test.jl")
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
    @safetestset "BatchedInterface test" begin
        @time include("batched_interface_test.jl")
    end
    @safetestset "Simple Adjoints test" begin
        @time include("simple_adjoints_test.jl")
    end
end

if GROUP == "All" || GROUP == "Downstream"
    activate_downstream_env()
    @safetestset "BatchedInterface with array symbolics test" begin
        @time include("downstream/batchedinterface_arrayvars.jl")
    end
    @safetestset "remake_buffer with array symbolics test" begin
        @time include("downstream/remake_arrayvars.jl")
    end
    @safetestset "array indexing" begin
        @time include("downstream/array_indexing.jl")
    end
end
