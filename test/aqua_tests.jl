using Test
using NoLimits
using Aqua

# Aqua.jl static quality assurance (https://juliatesting.github.io/Aqua.jl):
#   * method ambiguities (kept at zero — see the disambiguation blocks in
#     src/distributions/outcomes/*ObservedStatesMarkov*.jl)
#   * unbound type parameters, undefined exports
#   * project hygiene: stale deps, missing [compat] entries, test-project extras
#   * type piracy (all Distributions/Base extensions dispatch on owned types)
#   * persistent tasks blocking precompilation
# All checks run with defaults and no ignore lists; keep it that way.
@testset "Aqua quality assurance" begin
    Aqua.test_all(NoLimits)
end
