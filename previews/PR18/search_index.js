var documenterSearchIndex = {"docs":
[{"location":"api/#Interface-Functions","page":"API","title":"Interface Functions","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"symbolic_container\nis_variable\nvariable_index\nvariable_symbols\nis_parameter\nparameter_index\nparameter_symbols\nis_independent_variable\nindependent_variable_symbols\nis_observed\nobserved\nis_time_dependent\nconstant_structure\nall_solvable_symbols\nall_symbols\nparameter_values\ngetp\nsetp","category":"page"},{"location":"api/#SymbolicIndexingInterface.symbolic_container","page":"API","title":"SymbolicIndexingInterface.symbolic_container","text":"symbolic_container(p)\n\nUsing p, return an object that implements the symbolic indexing interface. In case p itself implements the interface, p can be returned as-is. All symbolic indexing interface methods fall back to calling the same method on symbolic_container(p), so this may be used for trivial implementations of the interface that forward all calls to another object.\n\nThis is also used by ParameterIndexingProxy\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.is_variable","page":"API","title":"SymbolicIndexingInterface.is_variable","text":"is_variable(sys, sym)\n\nCheck whether the given sym is a variable in sys.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.variable_index","page":"API","title":"SymbolicIndexingInterface.variable_index","text":"variable_index(sys, sym, [i])\n\nReturn the index of the given variable sym in sys, or nothing otherwise. If constant_structure is false, this accepts the current time index as an additional parameter i.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.variable_symbols","page":"API","title":"SymbolicIndexingInterface.variable_symbols","text":"variable_symbols(sys, [i])\n\nReturn a vector of the symbolic variables being solved for in the system sys. If constant_structure(sys) == false this accepts an additional parameter indicating the current time index. The returned vector should not be mutated.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.is_parameter","page":"API","title":"SymbolicIndexingInterface.is_parameter","text":"is_parameter(sys, sym)\n\nCheck whether the given sym is a parameter in sys.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.parameter_index","page":"API","title":"SymbolicIndexingInterface.parameter_index","text":"parameter_index(sys, sym)\n\nReturn the index of the given parameter sym in sys, or nothing otherwise.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.parameter_symbols","page":"API","title":"SymbolicIndexingInterface.parameter_symbols","text":"parameter_symbols(sys)\n\nReturn a vector of the symbolic parameters of the given system sys. The returned vector should not be mutated.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.is_independent_variable","page":"API","title":"SymbolicIndexingInterface.is_independent_variable","text":"is_independent_variable(sys, sym)\n\nCheck whether the given sym is an independent variable in sys. The returned vector should not be mutated.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.independent_variable_symbols","page":"API","title":"SymbolicIndexingInterface.independent_variable_symbols","text":"independent_variable_symbols(sys)\n\nReturn a vector of the symbolic independent variables of the given system sys.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.is_observed","page":"API","title":"SymbolicIndexingInterface.is_observed","text":"is_observed(sys, sym)\n\nCheck whether the given sym is an observed value in sys.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.observed","page":"API","title":"SymbolicIndexingInterface.observed","text":"observed(sys, sym, [states])\n\nReturn the observed function of the given sym in sys. The returned function should have the signature (u, p) -> [values...] where u and p is the current state and parameter vector. If istimedependent(sys) == true, the function should accept the current time t as its third parameter. If constant_structure(sys) == false, accept a third parameter which can either be a vector of symbols indicating the order of states or a time index which identifies the order of states.\n\nSee also: is_time_dependent, constant_structure\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.is_time_dependent","page":"API","title":"SymbolicIndexingInterface.is_time_dependent","text":"is_time_dependent(sys)\n\nCheck if sys has time as (one of) its independent variables.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.constant_structure","page":"API","title":"SymbolicIndexingInterface.constant_structure","text":"constant_structure(sys)\n\nCheck if sys has a constant structure. Constant structure systems do not change the number of variables or parameters over time.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.all_solvable_symbols","page":"API","title":"SymbolicIndexingInterface.all_solvable_symbols","text":"all_solvable_symbols(sys)\n\nReturn an array of all symbols in the system that can be solved for. This includes observed variables, but not parameters or independent variables.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.all_symbols","page":"API","title":"SymbolicIndexingInterface.all_symbols","text":"all_symbols(sys)\n\nReturn an array of all symbols in the system. This includes parameters and independent variables.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.parameter_values","page":"API","title":"SymbolicIndexingInterface.parameter_values","text":"parameter_values(p)\n\nReturn an indexable collection containing the value of each parameter in p.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.getp","page":"API","title":"SymbolicIndexingInterface.getp","text":"getp(sys, p)\n\nReturn a function that takes an integrator or solution of sys, and returns the value of the parameter p. Note that p can be a direct numerical index or a symbolic value. Requires that the integrator or solution implement parameter_values. This function typically does not need to be implemented, and has a default implementation relying on parameter_values.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.setp","page":"API","title":"SymbolicIndexingInterface.setp","text":"setp(sys, p)\n\nReturn a function that takes an integrator of sys and a value, and sets the the parameter p to that value. Note that p can be a direct numerical index or a symbolic value. Requires that the integrator implement parameter_values and the returned collection be a mutable reference to the parameter vector in the integrator. In case parameter_values cannot return such a mutable reference, setp needs to be implemented manually.\n\n\n\n\n\n","category":"function"},{"location":"api/#Traits","page":"API","title":"Traits","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"ScalarSymbolic\nArraySymbolic\nNotSymbolic\nsymbolic_type\nhasname\ngetname","category":"page"},{"location":"api/#SymbolicIndexingInterface.ScalarSymbolic","page":"API","title":"SymbolicIndexingInterface.ScalarSymbolic","text":"struct ScalarSymbolic <: SymbolicTypeTrait end\n\nTrait indicating a type is a scalar symbolic variable.\n\nSee also: ArraySymbolic, NotSymbolic, symbolic_type\n\n\n\n\n\n","category":"type"},{"location":"api/#SymbolicIndexingInterface.ArraySymbolic","page":"API","title":"SymbolicIndexingInterface.ArraySymbolic","text":"struct ArraySymbolic <: SymbolicTypeTrait end\n\nTrait indicating type is a symbolic array. Calling collect on a symbolic array must return an AbstractArray containing ScalarSymbolic variables for each element in the array, in the same shape as the represented array. For example, if a is a symbolic array representing a 2x2 matrix, collect(a) must return a 2x2 array of scalar symbolic variables.\n\nSee also: ScalarSymbolic, NotSymbolic, symbolic_type\n\n\n\n\n\n","category":"type"},{"location":"api/#SymbolicIndexingInterface.NotSymbolic","page":"API","title":"SymbolicIndexingInterface.NotSymbolic","text":"struct NotSymbolic <: SymbolicTypeTrait end\n\nTrait indicating a type is not symbolic.\n\nSee also: ScalarSymbolic, ArraySymbolic, symbolic_type\n\n\n\n\n\n","category":"type"},{"location":"api/#SymbolicIndexingInterface.symbolic_type","page":"API","title":"SymbolicIndexingInterface.symbolic_type","text":"symbolic_type(x) = symbolic_type(typeof(x))\nsymbolic_type(::Type)\n\nGet the symbolic type trait of a type. Default to NotSymbolic for all types except Symbol.\n\nSee also: ScalarSymbolic, ArraySymbolic, NotSymbolic\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.hasname","page":"API","title":"SymbolicIndexingInterface.hasname","text":"hasname(x)\n\nCheck whether the given symbolic variable (for which symbolic_type(x) != NotSymbolic()) has a valid name as per getname.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.getname","page":"API","title":"SymbolicIndexingInterface.getname","text":"getname(x)::Symbol\n\nGet the name of a symbolic variable as a Symbol\n\n\n\n\n\n","category":"function"},{"location":"api/#Types","page":"API","title":"Types","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"SymbolCache","category":"page"},{"location":"api/#SymbolicIndexingInterface.SymbolCache","page":"API","title":"SymbolicIndexingInterface.SymbolCache","text":"struct SymbolCache{V,P,I}\nfunction SymbolCache(vars, [params, [indepvars]])\n\nA struct implementing the symbolic indexing interface for the trivial case of having a vector of variables, parameters and independent variables. This struct does not implement observed, and is_observed returns false for all input symbols. It is considered to be time dependent if it contains at least one independent variable.\n\nThe independent variable may be specified as a single symbolic variable instead of an array containing a single variable if the system has only one independent variable.\n\n\n\n\n\n","category":"type"},{"location":"#SymbolicIndexingInterface.jl:-Arrays-of-Arrays-and-Even-Deeper","page":"Home","title":"SymbolicIndexingInterface.jl: Arrays of Arrays and Even Deeper","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SymbolicIndexingInterface.jl is a set of interface functions for handling containers of symbolic variables.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"To install SymbolicIndexingInterface.jl, use the Julia package manager:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg\nPkg.add(\"SymbolicIndexingInterface\")","category":"page"},{"location":"#Contributing","page":"Home","title":"Contributing","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Please refer to the SciML ColPrac: Contributor's Guide on Collaborative Practices for Community Packages for guidance on PRs, issues, and other matters relating to contributing to SciML.\nThere are a few community forums:\nthe #diffeq-bridged channel in the Julia Slack\nJuliaDiffEq on Gitter\non the Julia Discourse forums\nsee also SciML Community page","category":"page"},{"location":"#Reproducibility","page":"Home","title":"Reproducibility","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"<details><summary>The documentation of this SciML package was built using these direct dependencies,</summary>","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg # hide\nPkg.status() # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"</details>","category":"page"},{"location":"","page":"Home","title":"Home","text":"<details><summary>and using this machine and Julia version.</summary>","category":"page"},{"location":"","page":"Home","title":"Home","text":"using InteractiveUtils # hide\nversioninfo() # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"</details>","category":"page"},{"location":"","page":"Home","title":"Home","text":"<details><summary>A more complete overview of all dependencies and their versions is also provided.</summary>","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg # hide\nPkg.status(;mode = PKGMODE_MANIFEST) # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"</details>","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can also download the \n<a href=\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"using TOML\nversion = TOML.parse(read(\"../../Project.toml\",String))[\"version\"]\nname = TOML.parse(read(\"../../Project.toml\",String))[\"name\"]\nlink = \"https://github.com/SciML/\"*name*\".jl/tree/gh-pages/v\"*version*\"/assets/Manifest.toml\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"\">manifest</a> file and the\n<a href=\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"using TOML\nversion = TOML.parse(read(\"../../Project.toml\",String))[\"version\"]\nname = TOML.parse(read(\"../../Project.toml\",String))[\"name\"]\nlink = \"https://github.com/SciML/\"*name*\".jl/tree/gh-pages/v\"*version*\"/assets/Project.toml\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"\">project</a> file.","category":"page"},{"location":"tutorial/#Implementing-SymbolicIndexingInterface-for-a-type","page":"Tutorial","title":"Implementing SymbolicIndexingInterface for a type","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Implementing the interface for a type allows it to be used by existing symbolic indexing infrastructure. There are multiple ways to implement it, and the entire interface is not always necessary.","category":"page"},{"location":"tutorial/#Defining-a-fallback","page":"Tutorial","title":"Defining a fallback","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The simplest case is when the type contains an object that already implements the interface. All its methods can simply be forwarded to that object. To do so, SymbolicIndexingInterface.jl provides the symbolic_container method. For example,","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"struct MySolutionWrapper{T<:SciMLBase.AbstractTimeseriesSolution}\n  sol::T\n  # other properties...\nend\n\nsymbolic_container(sys::MySolutionWrapper) = sys.sol","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"MySolutionWrapper wraps an AbstractTimeseriesSolution which already implements the interface. Since symbolic_container will return the wrapped solution, all method calls such as is_parameter(sys::MySolutionWrapper, sym) will be forwarded to is_parameter(sys.sol, sym).","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"In case some methods need to function differently than those of the wrapped type, they can selectively be defined. For example, suppose MySolutionWrapper does not support observed quantities. The following method can be defined (in addition to the one above):","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"is_observed(sys::MySolutionWrapper, sym) = false","category":"page"},{"location":"tutorial/#Defining-the-interface-in-its-entirety","page":"Tutorial","title":"Defining the interface in its entirety","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Not all of the methods in the interface are required. Some only need to be implemented if a type supports specific functionality. Consider the following struct which needs to implement the interface:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"struct ExampleSolution\n  state_index::Dict{Symbol,Int}\n  parameter_index::Dict{Symbol,Int}\n  independent_variable::Union{Symbol,Nothing}\n  # mapping from observed variable to Expr to calculate its value\n  observed::Dict{Symbol,Expr}\n  u::Vector{Vector{Float64}}\n  p::Vector{Float64}\n  t::Vector{Float64}\nend","category":"page"},{"location":"tutorial/#Mandatory-methods","page":"Tutorial","title":"Mandatory methods","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"function SymbolicIndexingInterface.is_variable(sys::ExampleSolution, sym)\n  haskey(sys.state_index, sym)\nend\n\nfunction SymbolicIndexingInterface.variable_index(sys::ExampleSolution, sym)\n  get(sys.state_index, sym, nothing)\nend\n\nfunction SymbolicIndexingInterface.variable_symbols(sys::ExampleSolution)\n  collect(keys(sys.state_index))\nend\n\nfunction SymbolicIndexingInterface.is_parameter(sys::ExampleSolution, sym)\n  haskey(sys.parameter_index, sym)\nend\n\nfunction SymbolicIndexingInterface.parameter_index(sys::ExampleSolution, sym)\n  get(sys.parameter_index, sym, nothing)\nend\n\nfunction SymbolicIndexingInterface.parameter_symbols(sys::ExampleSolution)\n  collect(keys(sys.parameter_index))\nend\n\nfunction SymbolicIndexingInterface.is_independent_variable(sys::ExampleSolution, sym)\n  # note we have to check separately for `nothing`, otherwise\n  # `is_independent_variable(p, nothing)` would return `true`.\n  sys.independent_variable !== nothing && sym === sys.independent_variable\nend\n\nfunction SymbolicIndexingInterface.independent_variable_symbols(sys::ExampleSolution)\n  sys.independent_variable === nothing ? [] : [sys.independent_variable]\nend\n\n# this type accepts `Expr` for observed expressions involving state/parameter/observed\n# variables\nSymbolicIndexingInterface.is_observed(sys::ExampleSolution, sym) = sym isa Expr || sym isa Symbol && haskey(sys.observed, sym)\n\nfunction SymbolicIndexingInterface.observed(sys::ExampleSolution, sym::Expr)\n  if is_time_dependent(sys)\n    return function (u, p, t)\n      # compute value from `sym`, leveraging `variable_index` and\n      # `parameter_index` to turn symbols into indices\n    end\n  else\n    return function (u, p)\n      # compute value from `sym`, leveraging `variable_index` and\n      # `parameter_index` to turn symbols into indices\n    end\n  end\nend\n\nfunction SymbolicIndexingInterface.is_time_dependent(sys::ExampleSolution)\n  sys.independent_variable !== nothing\nend\n\nSymbolicIndexingInterface.constant_structure(::ExampleSolution) = true\n\nfunction SymbolicIndexingInterface.all_solvable_symbols(sys::ExampleSolution)\n  return vcat(\n    collect(keys(sys.state_index)),\n    collect(keys(sys.observed)),\n  )\nend\n\nfunction SymbolicIndexingInterface.all_symbols(sys::ExampleSolution)\n  return vcat(\n    all_solvable_symbols(sys),\n    collect(keys(sys.parameter_index)),\n    sys.independent_variable === nothing ? Symbol[] : sys.independent_variable\n  )\nend","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Note that the method definitions are all assuming constant_structure(p) == true.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"In case constant_structure(p) == false, the following methods would change:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"constant_structure(::ExampleSolution) = false\nvariable_index(sys::ExampleSolution, sym) would become variable_index(sys::ExampleSolution, sym i) where i is the time index at which the index of sym is required.\nvariable_symbols(sys::ExampleSolution) would become variable_symbols(sys::ExampleSolution, i) where i is the time index at which the variable symbols are required.\nobserved(sys::ExampleSolution, sym) would become observed(sys::ExampleSolution, sym, i) where i is either the time index at which the index of sym is required or a Vector of state symbols at the current time index.","category":"page"},{"location":"tutorial/#Optional-methods","page":"Tutorial","title":"Optional methods","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Note that observed is optional if is_observed is always false, or the type is only responsible for identifying observed values and observed will always be called on a type that wraps this type. An example is ModelingToolkit.AbstractSystem, which can identify whether a value is observed, but cannot implement observed itself.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Other optional methods relate to parameter indexing. If a type contains the values of parameter variables, it must implement parameter_values. This will allow the default definitions of getp and setp to work. While setp is not typically useful for solution objects, it may be useful for integrators. Typically the default implementations for getp and setp will suffice and manually defining them is not necessary.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"function SymbolicIndexingInterface.parameter_values(sys::ExampleSolution)\n  sys.p\nend","category":"page"},{"location":"tutorial/#Implementing-the-SymbolicTypeTrait-for-a-type","page":"Tutorial","title":"Implementing the SymbolicTypeTrait for a type","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The SymbolicTypeTrait is used to identify values that can act as symbolic variables. It has three variants:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"NotSymbolic for quantities that are not symbolic. This is the default for all types.\nScalarSymbolic for quantities that are symbolic, and represent a single logical value.\nArraySymbolic for quantities that are symbolic, and represent an array of values. Types implementing this trait must return an array of ScalarSymbolic variables of the appropriate size and dimensions when collected.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The trait is implemented through the symbolic_type function. Consider the following example types:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"struct MySym\n  name::Symbol\nend\n\nstruct MySymArr{N}\n  name::Symbol\n  size::NTuple{N,Int}\nend","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"They must implement the following functions:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"SymbolicIndexingInterface.symbolic_type(::Type{MySym}) = ScalarSymbolic()\nSymbolicIndexingInterface.hasname(::MySym) = true\nSymbolicIndexingInterface.getname(sym::MySym) = sym.name\n\nSymbolicIndexingInterface.symbolic_type(::Type{<:MySymArr}) = ArraySymbolic()\nSymbolicIndexingInterface.hasname(::MySymArr) = true\nSymbolicIndexingInterface.getname(sym::MySymArr) = sym.name\nfunction Base.collect(sym::MySymArr)\n  [\n    MySym(Symbol(sym.name, :_, join(idxs, \"_\")))\n    for idxs in Iterators.product(Base.OneTo.(sym.size)...)\n  ]\nend","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"hasname is not required to always be true for symbolic types. For example, Symbolics.Num returns false whenever the wrapped value is a number, or an expression.","category":"page"}]
}
