# Implementing the Complete Symbolic Indexing Interface

This tutorial will show how to define the entire Symbolic Indexing Interface on an
`ExampleSystem`:

```julia
struct ExampleSystem
  state_index::Dict{Symbol,Int}
  parameter_index::Dict{Symbol,Int}
  independent_variable::Union{Symbol,Nothing}
  # mapping from observed variable to Expr to calculate its value
  observed::Dict{Symbol,Expr}
end
```

Not all the methods in the interface are required. Some only need to be implemented if a type
supports specific functionality. Consider the following struct, which needs to implement the interface:

## Mandatory methods

### Simple Indexing Functions

These are the simple functions which describe how to turn symbols into indices.

```julia
function SymbolicIndexingInterface.is_variable(sys::ExampleSystem, sym)
  haskey(sys.state_index, sym)
end

function SymbolicIndexingInterface.variable_index(sys::ExampleSystem, sym)
  get(sys.state_index, sym, nothing)
end

function SymbolicIndexingInterface.variable_symbols(sys::ExampleSystem)
  collect(keys(sys.state_index))
end

function SymbolicIndexingInterface.is_parameter(sys::ExampleSystem, sym)
  haskey(sys.parameter_index, sym)
end

function SymbolicIndexingInterface.parameter_index(sys::ExampleSystem, sym)
  get(sys.parameter_index, sym, nothing)
end

function SymbolicIndexingInterface.parameter_symbols(sys::ExampleSystem)
  collect(keys(sys.parameter_index))
end

function SymbolicIndexingInterface.is_independent_variable(sys::ExampleSystem, sym)
  # note we have to check separately for `nothing`, otherwise
  # `is_independent_variable(p, nothing)` would return `true`.
  sys.independent_variable !== nothing && sym === sys.independent_variable
end

function SymbolicIndexingInterface.independent_variable_symbols(sys::ExampleSystem)
  sys.independent_variable === nothing ? [] : [sys.independent_variable]
end

function SymbolicIndexingInterface.is_time_dependent(sys::ExampleSystem)
  sys.independent_variable !== nothing
end

SymbolicIndexingInterface.constant_structure(::ExampleSystem) = true

function SymbolicIndexingInterface.all_solvable_symbols(sys::ExampleSystem)
  return vcat(
    collect(keys(sys.state_index)),
    collect(keys(sys.observed)),
  )
end

function SymbolicIndexingInterface.all_symbols(sys::ExampleSystem)
  return vcat(
    all_solvable_symbols(sys),
    collect(keys(sys.parameter_index)),
    sys.independent_variable === nothing ? Symbol[] : sys.independent_variable
  )
end
```

### Observed Equation Handling

These are for handling symbolic expressions and generating equations which are not directly
in the solution vector.

```julia
# this type accepts `Expr` for observed expressions involving state/parameter/observed
# variables
SymbolicIndexingInterface.is_observed(sys::ExampleSystem, sym) = sym isa Expr || sym isa Symbol && haskey(sys.observed, sym)

function SymbolicIndexingInterface.observed(sys::ExampleSystem, sym::Expr)
  if is_time_dependent(sys)
    return function (u, p, t)
      # compute value from `sym`, leveraging `variable_index` and
      # `parameter_index` to turn symbols into indices
    end
  else
    return function (u, p)
      # compute value from `sym`, leveraging `variable_index` and
      # `parameter_index` to turn symbols into indices
    end
  end
end
```

### Note about constant structure

Note that the method definitions are all assuming `constant_structure(p) == true`.

In case `constant_structure(p) == false`, the following methods would change:
- `constant_structure(::ExampleSystem) = false`
- `variable_index(sys::ExampleSystem, sym)` would become
  `variable_index(sys::ExampleSystem, sym i)` where `i` is the time index at which
  the index of `sym` is required.
- `variable_symbols(sys::ExampleSystem)` would become
  `variable_symbols(sys::ExampleSystem, i)` where `i` is the time index at which
  the variable symbols are required.
- `observed(sys::ExampleSystem, sym)` would become
  `observed(sys::ExampleSystem, sym, i)` where `i` is either the time index at which
  the index of `sym` is required or a `Vector` of state symbols at the current time index.

## Optional methods

Note that `observed` is optional if `is_observed` is always `false`, or the type is
only responsible for identifying observed values and `observed` will always be called
on a type that wraps this type. An example is `ModelingToolkit.AbstractSystem`, which
can identify whether a value is observed, but cannot implement `observed` itself.

Other optional methods relate to parameter indexing. If a type contains the values of
parameter variables, it must implement [`parameter_values`](@ref). This allows the
default definitions of [`getp`](@ref) and [`setp`](@ref) to work. While `setp` is
not typically useful for solution objects, it may be useful for integrators. Typically,
the default implementations for `getp` and `setp` will suffice, and manually defining
them is not necessary.

```julia
function SymbolicIndexingInterface.parameter_values(sys::ExampleSystem)
  sys.p
end
```

## Implementing the `SymbolicTypeTrait` for a type

The `SymbolicTypeTrait` is used to identify values that can act as symbolic variables. It
has three variants:

- [`NotSymbolic`](@ref) for quantities that are not symbolic. This is the default for all
  types.
- [`ScalarSymbolic`](@ref) for quantities that are symbolic, and represent a single
  logical value.
- [`ArraySymbolic`](@ref) for quantities that are symbolic, and represent an array of
  values. Types implementing this trait must return an array of `ScalarSymbolic` variables
  of the appropriate size and dimensions when `collect`ed.

The trait is implemented through the [`symbolic_type`](@ref) function. Consider the following
example types:

```julia
struct MySym
  name::Symbol
end

struct MySymArr{N}
  name::Symbol
  size::NTuple{N,Int}
end
```

They must implement the following functions:

```julia
SymbolicIndexingInterface.symbolic_type(::Type{MySym}) = ScalarSymbolic()
SymbolicIndexingInterface.hasname(::MySym) = true
SymbolicIndexingInterface.getname(sym::MySym) = sym.name

SymbolicIndexingInterface.symbolic_type(::Type{<:MySymArr}) = ArraySymbolic()
SymbolicIndexingInterface.hasname(::MySymArr) = true
SymbolicIndexingInterface.getname(sym::MySymArr) = sym.name
function Base.collect(sym::MySymArr)
  [
    MySym(Symbol(sym.name, :_, join(idxs, "_")))
    for idxs in Iterators.product(Base.OneTo.(sym.size)...)
  ]
end
```

[`hasname`](@ref) is not required to always be `true` for symbolic types. For example,
`Symbolics.Num` returns `false` whenever the wrapped value is a number, or an expression.
