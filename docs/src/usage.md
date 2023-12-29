# Using the SymbolicIndexingInterface

This tutorial will cover ways to use the interface for types that implement it.
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

@named sys = ODESystem(eqs)
sys = structural_simplify(sys)
```

The system has 4 state variables, 3 parameters and one observed variable:
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

Parameters cannot be obtained using this syntax, and instead require using [`getp`](@ref) and [`setp`](@ref).

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

Solving the new system, note that the parameter getter functions still work on the new
solution object.

```@example Usage
sol2 = solve(prob, Tsit5())
σ_getter(sol)
```

```@example Usage
σ_ρ_getter(sol)
```

To set the entire parameter vector at once, [`parameter_values`](@ref) can be used
(note the usage of broadcasted assignment).

```@example Usage
parameter_values(prob) .= [29.0, 11.0, 2.5]
parameter_values(prob)
```
