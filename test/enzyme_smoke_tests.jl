using Test

# ─────────────────────────────────────────────────────────────────────────────
# Opt-in Enzyme smoke tests: REAL Enzyme gradients on the cheapest validated
# configuration (non-ODE joint logf w.r.t. the RE vector, forward + reverse),
# checked against ForwardDiff (which is finite-difference-certified for these
# objectives). Costs a few minutes of Enzyme JIT, so they only run when all of:
#
#   * ENV["NOLIMITS_TEST_ENZYME"] == "true"   (explicit opt-in)
#   * VERSION >= v"1.12.5"                    (earlier 1.12.x has a compiler bug
#                                              that breaks Enzyme reverse mode)
#   * Enzyme is available in the active environment (it is NOT a NoLimits dep)
#
# Otherwise this file records a single passing skip marker. Note: the smoke run
# sets the PROCESS-GLOBAL `Enzyme.API.strictAliasing!(false)` (required for
# NoLimits paths), so keep it last in a shard or run it standalone:
#   NOLIMITS_TEST_ENZYME=true julia +1.12.6 --project=<env-with-enzyme> test/enzyme_smoke_tests.jl
# ─────────────────────────────────────────────────────────────────────────────

const _ENZ_REQUESTED = get(ENV, "NOLIMITS_TEST_ENZYME", "false") == "true"
const _ENZ_JULIA_OK = VERSION >= v"1.12.5"
const _ENZ_AVAILABLE = Base.find_package("Enzyme") !== nothing

if _ENZ_REQUESTED && _ENZ_JULIA_OK && _ENZ_AVAILABLE
    include("enzyme_smoke_impl.jl")
else
    @info "Skipping Enzyme smoke tests (set NOLIMITS_TEST_ENZYME=true on Julia ≥ 1.12.5 with Enzyme installed to enable)" _ENZ_REQUESTED _ENZ_JULIA_OK _ENZ_AVAILABLE
    @testset "Enzyme smoke tests (skipped)" begin
        @test true
    end
end
