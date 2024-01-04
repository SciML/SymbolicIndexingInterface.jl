# Interface Functions

## Mandatory methods

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
is_time_dependent
constant_structure
all_variable_symbols
all_symbols
solvedvariables
allvariables
```

## Optional Methods

### Observed equation handling

```@docs
observed
```

### Parameter indexing

```@docs
parameter_values
set_parameter!
getp
setp
ParameterIndexingProxy
```

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

# Symbolic Trait

```@docs
ScalarSymbolic
ArraySymbolic
NotSymbolic
symbolic_type
hasname
getname
```

# Types

```@docs
SymbolCache
```
