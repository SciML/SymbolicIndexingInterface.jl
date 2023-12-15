# Implementing SymbolicIndexingInterface for a type

Implementing the interface for a type allows it to be used by existing symbolic indexing
infrastructure. There are multiple ways to implement it, and the entire interface is
not always necessary.

## Defining a fallback

The simplest case is when the type contains an object that already implements the interface.
All its methods can simply be forwarded to that object. To do so, SymbolicIndexingInterface.jl
provides the [`symbolic_container`](@ref) method. For example,

```julia
struct MySolutionWrapper{T<:SciMLBase.AbstractTimeseriesSolution}
  sol::T
  # other properties...
end

symbolic_container(sys::MySolutionWrapper) = sys.sol
```

`MySolutionWrapper` wraps an `AbstractTimeseriesSolution` which already implements the interface.
Since `symbolic_container` will return the wrapped solution, all method calls such as
`is_parameter(sys::MySolutionWrapper, sym)` will be forwarded to `is_parameter(sys.sol, sym)`.

In case some methods need to function differently than those of the wrapped type, they can selectively
be defined. For example, suppose `MySolutionWrapper` does not support observed quantities. The following
method can be defined (in addition to the one above):

```julia
is_observed(sys::MySolutionWrapper, sym) = false
```

## Defining the interface in its entirety

Not all of the methods in the interface are required. Some only need to be implemented if a type
supports specific functionality. Consider the following struct which needs to implement the interface:

```julia
struct ExampleSolution
  state_index::Dict{Symbol,Int}
  parameter_index::Dict{Symbol,Int}
  independent_variable::Union{Symbol,Nothing}
  u::Vector{Vector{Float64}}
  p::Vector{Float64}
  t::Vector{Float64}
end
```



### Mandatory methods

```julia
function SymbolicIndexingInterface.is_variable(sys::ExampleSolution, sym)
  haskey(sys.state_index, sym)
end

function SymbolicIndexingInterface.variable_index(sys::ExampleSolution, sym)
  get(sys.state_index, sym, nothing)
end

function SymbolicIndexingInterface.variable_symbols(sys::ExampleSolution)
  collect(keys(sys.state_index))
end

function SymbolicIndexingInterface.is_parameter(sys::ExampleSolution, sym)
  haskey(sys.parameter_index, sym)
end

function SymbolicIndexingInterface.parameter_index(sys::ExampleSolution, sym)
  get(sys.parameter_index, sym, nothing)
end

function SymbolicIndexingInterface.parameter_symbols(sys::ExampleSolution)
  collect(keys(sys.parameter_index))
end

function SymbolicIndexingInterface.is_independent_variable(sys::ExampleSolution, sym)
  # note we have to check separately for `nothing`, otherwise
  # `is_independent_variable(p, nothing)` would return `true`.
  sys.independent_variable !== nothing && sym === sys.independent_variable
end

function SymbolicIndexingInterface.independent_variable_symbols(sys::ExampleSolution)
  sys.independent_variable === nothing ? [] : [sys.independent_variable]
end

# this types accepts `Expr` for observed expressions involving state/parameter
# variables
SymbolicIndexingInterface.is_observed(sys::ExampleSolution, sym) = sym isa Expr

function SymbolicIndexingInterface.observed(sys::ExampleSolution, sym::Expr)
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

function SymbolicIndexingInterface.is_time_dependent(sys::ExampleSolution)
  sys.independent_variable !== nothing
end

SymbolicIndexingInterface.constant_structure(::ExampleSolution) = true
```

Note that the method definitions are all assuming `constant_structure(p) == true`.

In case `constant_structure(p) == false`, the following methods would change:
- `constant_structure(::ExampleSolution) = false`
- `variable_index(sys::ExampleSolution, sym)` would become
  `variable_index(sys::ExampleSolution, sym i)` where `i` is the time index at which
  the index of `sym` is required.
- `variable_symbols(sys::ExampleSolution)` would become
  `variable_symbols(sys::ExampleSolution, i)` where `i` is the time index at which
  the variable symbols are required.
- `observed(sys::ExampleSolution, sym)` would become
  `observed(sys::ExampleSolution, sym, i)` where `i` is either the time index at which
  the index of `sym` is required or a `Vector` of state symbols at the current time index.

## Optional methods

Note that `observed` is optional if `is_observed` is always `false`, or the type is
only responsible for identifying observed values and `observed` will always be called
on a type that wraps this type. An example is `ModelingToolkit.AbstractSystem`, which
can identify whether a value is observed, but cannot implement `observed` itself.

Other optional methods relate to parameter indexing. If a type contains the values of
parameter variables, it must implement [`parameter_values`](@ref). This will allow the
default definitions of [`getp`](@ref) and [`setp`](@ref) to work. While `setp` is
not typically useful for solution objects, it may be useful for integrators. Typically
the default implementations for `getp` and `setp` will suffice and manually defining
them is not necessary.

```julia
function SymbolicIndexingInterface.parameter_values(sys::ExampleSolution)
  sys.p
end
```

# Implementing the `SymbolicTypeTrait` for a type

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
