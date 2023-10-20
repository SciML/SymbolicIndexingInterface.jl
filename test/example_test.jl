struct SymbolCache
    vars::Vector{Symbol}
    params::Vector{Symbol}
    indepvar::Union{Symbol, Nothing}
end

SymbolicIndexingInterface.isvariable(sys::SymbolCache, sym) = sym in sys.vars
function SymbolicIndexingInterface.variableindex(sys::SymbolCache, sym)
    findfirst(isequal(sym), sys.vars)
end
SymbolicIndexingInterface.isparameter(sys::SymbolCache, sym) = sym in sys.params
function SymbolicIndexingInterface.parameterindex(sys::SymbolCache, sym)
    findfirst(isequal(sym), sys.params)
end
function SymbolicIndexingInterface.isindependent_variable(sys::SymbolCache, sym)
    sys.indepvar !== nothing && isequal(sym, sys.indepvar)
end
function SymbolicIndexingInterface.isobserved(sys::SymbolCache, sym)
    isvariable(sys, sym) || isparameter(sys, sym) || isindependent_variable(sys, sym)
end
function SymbolicIndexingInterface.observed(sys::SymbolCache, sym)
    idx = variableindex(sys, sym)
    if idx !== nothing
        return istimedependent(sys) ? (t) -> [idx * i for i in t] :
               () -> [idx * i for i in 1:5]
    end
    idx = parameterindex(sys, sym)
    if idx !== nothing
        return istimedependent(sys) ? (t) -> idx : () -> idx
    end
    if isindependent_variable(sys, sym)
        return istimedependent(sys) ? (t) -> t : () -> 1:5
    end
end
SymbolicIndexingInterface.istimedependent(sys::SymbolCache) = isequal(sys.indepvar, :t)
SymbolicIndexingInterface.constant_structure(sys::SymbolCache) = true

sys = SymbolCache([:x, :y, :z], [:a, :b, :c], :t)

@test all(isvariable.((sys,), [:x, :y, :z]))
@test all(.!isvariable.((sys,), [:a, :b, :c, :t, :p, :q, :r]))
@test all(variableindex.((sys,), [:x, :z, :y]) .== [1, 3, 2])
@test all(variableindex.((sys,), [:a, :b, :c, :t, :p, :q, :r]) .=== nothing)
@test all(isparameter.((sys,), [:a, :b, :c]))
@test all(.!isparameter.((sys,), [:x, :y, :z, :t, :p, :q, :r]))
@test all(parameterindex.((sys,), [:c, :a, :b]) .== [3, 1, 2])
@test all(parameterindex.((sys,), [:x, :y, :z, :t, :p, :q, :r]) .=== nothing)
@test isindependent_variable(sys, :t)
@test all(.!isindependent_variable.((sys,), [:x, :y, :z, :a, :b, :c, :p, :q, :r]))
@test all(isobserved.((sys,), [:x, :y, :z, :a, :b, :c, :t]))
@test all(observed(sys, :x)(1:4) .== [1, 2, 3, 4])
@test all(observed(sys, :y)(1:4) .== [2, 4, 6, 8])
@test all(observed(sys, :z)(1:4) .== [3, 6, 9, 12])
@test observed(sys, :a)(1:4) == 1
@test observed(sys, :b)(1:4) == 2
@test observed(sys, :c)(1:4) == 3
@test observed(sys, :t)(1:4) == 1:4
@test istimedependent(sys)
@test constant_structure(sys)

sys = SymbolCache([:x, :y, :z], [:a, :b, :c], nothing)

@test !istimedependent(sys)
@test all(observed(sys, :x)() .== [1, 2, 3, 4, 5])
@test all(observed(sys, :y)() .== [2, 4, 6, 8, 10])
@test all(observed(sys, :z)() .== [3, 6, 9, 12, 15])
@test observed(sys, :a)() == 1
@test observed(sys, :b)() == 2
@test observed(sys, :c)() == 3
@test constant_structure(sys)
