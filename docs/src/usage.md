# Using the SciML Symbolic Indexing Interface

This tutorial will cover ways to use the symbolic indexing interface for types that
implement it. SciML's core types (problems, solutions, and iterator (integrator) types)
all support this symbolic indexing interface which allows for domain-specific interfaces
(such as ModelingToolkit, Catalyst, etc.) to seamlessly blend their symbolic languages with
the types obtained from SciML. Other tutorials will focus on how users can make use of the
interface for their own DSL, this tutorial will simply focus on what the user experience
looks like for DSL which have set it up.

We recommend any DSL implementing the symbolic indexing interface to link to this tutorial
as a full description of the functionality.

!!! note
    While this tutorial focuses on demonstrating the symbolic indexing interface for ODEs,
    note that the same functionality works across all of the other problem types, such as
    optimization problems, nonlinear problems, nonlinear solutions, etc.

## Symbolic Indexing of Differential Equation Solutions

Consider the following example:

```@example Usage
using ModelingToolkit, OrdinaryDiffEq, SymbolicIndexingInterface, Plots

@parameters σ ρ β
@variables t x(t) y(t) z(t) w(t)
D = Differential(t)

eqs = [D(D(x)) ~ σ * (y - x),
    D(y) ~ x * (ρ - z) - y,
    D(z) ~ x * y - β * z,
    w ~ x + y + z]

@mtkbuild sys = ODESystem(eqs, t)
```

The system has 4 state variables, 3 parameters, and one observed variable:

```@example Usage
ModelingToolkit.observed(sys)
```

Solving the system,

```@example Usage
u0 = [D(x) => 2.0,
    x => 1.0,
    y => 0.0,
    z => 0.0]

p = [σ => 28.0,
    ρ => 10.0,
    β => 8 / 3]

tspan = (0.0, 100.0)
prob = ODEProblem(sys, u0, tspan, p, jac = true)
sol = solve(prob, Tsit5())
```

We can obtain the timeseries of any time-dependent variable using `getindex`

```@example Usage
sol[x]
```

This also works for arrays or tuples of variables, including observed quantities and
independent variables, for interpolating solutions, and plotting:

```@example Usage
sol[[x, y]]
```

```@example Usage
sol[(t, w)]
```

```@example Usage
sol(1.3, idxs=x)
```

```@example Usage
sol(1.3, idxs=[x, w])
```

```@example Usage
sol(1.3, idxs=[:y, :z])
```

```@example Usage
plot(sol, idxs=x)
```

If necessary, `Symbol`s can be used to refer to variables. This is only valid for
symbolic variables for which [`hasname`](@ref) returns `true`. The `Symbol` used must
match the one returned by [`getname`](@ref) for the variable.

```@example Usage
hasname(x)
```

```@example Usage
getname(x)
```

```@example Usage
sol[(:x, :w)]
```

Note how when indexing with an array, the returned type is a `Vector{Array{Float64}}`,
and when using a `Tuple`, the returned type is `Vector{Tuple{Float64, Float64}}`.
To obtain the value of all state variables, we can use the shorthand:

```@example Usage
sol[solvedvariables] # equivalent to sol[variable_symbols(sol)]
```

This does not include the observed variable `w`. To include observed variables in the
output, the following shorthand is used:
```@example Usage
sol[allvariables] # equivalent to sol[all_variable_symbols(sol)]
```

## Parameter Indexing: Getting and Setting Parameter Values

Parameters cannot be obtained using this syntax, and instead require using [`getp`](@ref) and [`setp`](@ref).

!!! note
    The reason why parameters use a separate syntax is to be able to ensure type stability
    of the `sol[x]` indexing. Without separating the parameter indexing, the return type of
    symbolic indexing could be anything a parameter can be, which is general is not the same
    type as state variables!

```@example Usage
σ_getter = getp(sys, σ)
σ_getter(sol) # can also pass `prob`
```

Note that this also supports arrays/tuples of parameter symbols:

```@example Usage
σ_ρ_getter = getp(sys, (σ, ρ))
σ_ρ_getter(sol)
```

Now suppose the system has to be solved with a different value of the parameter `β`.

```@example Usage
β_setter = setp(sys, β)
β_setter(prob, 3)
```

The updated parameter values can be checked using [`parameter_values`](@ref).

```@example Usage
parameter_values(prob)
```

When solving the new system, note that the parameter getter functions still work on the new
solution object.

```@example Usage
sol2 = solve(prob, Tsit5())
σ_getter(sol)
```

```@example Usage
σ_ρ_getter(sol)
```

To set the entire parameter vector at once, [`setp`](@ref) can be used
(note that the order of symbols passed to `setp` must match the order of values in the array).

```@example Usage
setp(prob, parameter_symbols(prob))(prob, [29.0, 11.0, 2.5])
parameter_values(prob)
```

!!! note
    These getters and setters generate high-performance functions for the specific chosen
    symbols or collection of symbols. Caching the getter/setter function and reusing it
    on other problem/solution instances can be the key to achieving good performance. Note
    that this caching is allowed only when the symbolic system is unchanged (it's fine for
    the numerical values to have changed, but not the underlying equations).