abstract type SymbolicTypeTrait end

"""
    struct ScalarSymbolic <: SymbolicTypeTrait end

Trait indicating a type is a scalar symbolic variable.

See also: [`ArraySymbolic`](@ref), [`NotSymbolic`](@ref), [`symbolic_type`](@ref)
"""
struct ScalarSymbolic <: SymbolicTypeTrait end

"""
    struct ArraySymbolic <: SymbolicTypeTrait end

Trait indicating type is a symbolic array. Calling `collect` on a symbolic array must
return an `AbstractArray` containing `ScalarSymbolic` variables for each element in the
array, in the same shape as the represented array. For example, if `a` is a symbolic array
representing a 2x2 matrix, `collect(a)` must return a 2x2 array of scalar symbolic variables.

See also: [`ScalarSymbolic`](@ref), [`NotSymbolic`](@ref), [`symbolic_type`](@ref)
"""
struct ArraySymbolic <: SymbolicTypeTrait end

"""
    struct NotSymbolic <: SymbolicTypeTrait end

Trait indicating a type is not symbolic.

See also: [`ScalarSymbolic`](@ref), [`ArraySymbolic`](@ref), [`symbolic_type`](@ref)
"""
struct NotSymbolic <: SymbolicTypeTrait end

"""
    symbolic_type(x) = symbolic_type(typeof(x))
    symbolic_type(::Type)

Get the symbolic type trait of a type. Default to [`NotSymbolic`](@ref) for all types
except `Symbol`.

See also: [`ScalarSymbolic`](@ref), [`ArraySymbolic`](@ref), [`NotSymbolic`](@ref)
"""
symbolic_type(x) = symbolic_type(typeof(x))
symbolic_type(::Type) = NotSymbolic()
symbolic_type(::Type{Symbol}) = ScalarSymbolic()

"""
    hasname(x)

Check whether the given symbolic variable (for which `symbolic_type(x) != NotSymbolic()`) has a valid name as per `getname`.
"""
function hasname end

hasname(::Symbol) = true
hasname(::Any) = false

"""
    getname(x)::Symbol

Get the name of a symbolic variable as a `Symbol`
"""
function getname end