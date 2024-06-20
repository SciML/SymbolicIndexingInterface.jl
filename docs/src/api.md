# Interface Functions

## Index provider interface

### Mandatory methods

```@docs
symbolic_container
is_variable
variable_index
variable_symbols
is_parameter
parameter_index
parameter_symbols
is_independent_variable
independent_variable_symbols
is_observed
default_values
is_time_dependent
constant_structure
all_variable_symbols
all_symbols
solvedvariables
allvariables
```

### Optional Methods

#### Observed equation handling

```@docs
observed
parameter_observed
```

#### Parameter timeseries

If the index provider contains parameters that change during the course of the simulation
at discrete time points, it must implement the following methods to ensure correct
functioning of [`getu`](@ref) and [`getp`](@ref) for value providers that save the parameter
timeseries. Note that there can be multiple parameter timeseries, in case different parameters
may change at different times.

```@docs
is_timeseries_parameter
timeseries_parameter_index
ParameterTimeseriesIndex
get_all_timeseries_indexes
ContinuousTimeseries
```

## Value provider interface

### State indexing

```@docs
Timeseries
NotTimeseries
is_timeseries
state_values
set_state!
current_time
getu
setu
```

### Parameter indexing

```@docs
parameter_values
set_parameter!
finalize_parameters_hook!
getp
setp
ParameterIndexingProxy
```

#### Parameter timeseries

If a solution object saves a timeseries of parameter values that are updated during the
simulation (such as by callbacks), it must implement the following methods to ensure
correct functioning of [`getu`](@ref) and [`getp`](@ref).

Parameter timeseries support requires that the value provider store the different
timeseries in a [`ParameterTimeseriesCollection`](@ref).

```@docs
is_parameter_timeseries
get_parameter_timeseries_collection
ParameterTimeseriesCollection
with_updated_parameter_timeseries_values
```

### Batched Queries and Updates

```@docs
BatchedInterface
associated_systems
```

## Container objects

```@docs
remake_buffer
```

# Symbolic Trait

```@docs
ScalarSymbolic
ArraySymbolic
NotSymbolic
symbolic_type
hasname
getname
symbolic_evaluate
```

# Types

```@docs
SymbolCache
ProblemState
```
