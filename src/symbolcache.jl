"""
    SymbolCache(syms, indepsym, paramsyms)

A container that simply stores a vector of all syms, indepsym and paramsyms.
"""
struct SymbolCache{S, T, U}
    syms::S
    indepsym::T
    paramsyms::U
end

independent_variables(sc::SymbolCache) = sc.indepsym
independent_variables(::SymbolCache{S, Nothing}) where {S} = []
is_indep_sym(::SymbolCache{S, Nothing}, _) where {S} = false
states(sc::SymbolCache) = sc.syms
states(::SymbolCache{Nothing}) = []
state_sym_to_index(::SymbolCache{Nothing}, _) = nothing
parameters(sc::SymbolCache) = sc.paramsyms
parameters(::SymbolCache{S, T, Nothing}) where {S, T} = []
param_sym_to_index(::SymbolCache{S, T, Nothing}, _) where {S, T} = nothing

function Base.copy(VA::SymbolCache)
    typeof(VA)((VA.syms === nothing) ? nothing : copy(VA.syms),
               (VA.indepsym === nothing) ? nothing : copy(VA.indepsym),
               (VA.paramsyms === nothing) ? nothing : copy(VA.paramsyms))
end
