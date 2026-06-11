using Test
using NoLimits
using DataFrames
using Distributions
using ComponentArrays
using Random
using SciMLBase
using OrdinaryDiffEq

# NewtonInner is an OPT-IN inner-EBE optimizer: the default (LBFGS via
# Optimization.jl) is unchanged. These tests check that (1) the option produces
# the same fits as the default within inner-solver tolerance, (2) the
# `max_dim` fallback reproduces the default path exactly, and (3) the inner
# solutions themselves agree at matching gradient tolerances.

function _newton_test_dm()
    model = @Model begin
        @fixedEffects begin
            a = RealNumber(0.8)
            b = RealNumber(0.3)
            ω = RealNumber(0.5, scale=:log)
            σ = RealNumber(0.4, scale=:log)
        end
        @covariates begin
            t = Covariate()
            x = ConstantCovariateVector([:Age])
        end
        @randomEffects begin
            η = RandomEffect(Normal(0.0, ω); column=:ID)
        end
        @formulas begin
            lin = a + b * x.Age + η
            y ~ Normal(lin, σ)
        end
    end
    rng = Xoshiro(11)
    rows = NamedTuple[]
    for i in 1:40
        age = 0.5 + 0.05 * (i % 20)
        ηi = 0.4 * randn(rng)
        for j in 1:6
            t = (j - 1) * 0.5
            y = 0.8 + 0.3 * age + ηi + 0.4 * randn(rng)
            push!(rows, (ID=i, t=t, Age=age, y=y))
        end
    end
    return DataModel(model, DataFrame(rows); primary_id=:ID, time_col=:t)
end

@testset "NewtonInner inner solver (opt-in)" begin
    dm = _newton_test_dm()

    @testset "inner solve agrees with the default optimizer" begin
        llc = NoLimits.build_ll_cache(dm; force_saveat=true)
        _, binfos, ccache = NoLimits._build_laplace_batch_infos(dm, NamedTuple())
        θ = NoLimits.get_θ0_untransformed(get_model(dm).fixed.fixed)
        adc = NoLimits._init_laplace_ad_cache(length(binfos))
        for bi in (1, 5, 17)
            info = binfos[bi]
            b0 = zeros(info.n_b)
            sol_def = NoLimits._laplace_solve_batch!(dm, info, θ, ccache, llc, adc, bi, b0)
            sol_new = NoLimits._laplace_solve_batch!(dm, info, θ, ccache, llc, adc, bi, b0;
                                                     optimizer=NewtonInner())
            @test sol_new isa NoLimits._NewtonSol
            @test sol_new.converged
            @test NoLimits._laplace_sol_grad_norm(sol_new) <= 1e-8
            @test collect(sol_new.u) ≈ collect(sol_def.u) atol=1e-6
            @test NoLimits._laplace_sol_logf(sol_new) ≈ NoLimits._laplace_sol_logf(sol_def) atol=1e-8
        end
    end

    @testset "Laplace fit matches default within tolerance" begin
        res_def = fit_model(dm, NoLimits.Laplace(optim_kwargs=(maxiters=40,));
                            serialization=EnsembleSerial(), rng=Xoshiro(3))
        res_new = fit_model(dm, NoLimits.Laplace(optim_kwargs=(maxiters=40,),
                                                 inner_optimizer=NewtonInner());
                            serialization=EnsembleSerial(), rng=Xoshiro(3))
        @test isfinite(get_objective(res_new))
        @test get_objective(res_new) ≈ get_objective(res_def) rtol=1e-6 atol=1e-6
        @test collect(get_params(res_new; scale=:transformed)) ≈
              collect(get_params(res_def; scale=:transformed)) rtol=1e-3 atol=1e-3
        eta_def = get_random_effects(dm, res_def, :η)
        eta_new = get_random_effects(dm, res_new, :η)
        @test eta_new ≈ eta_def atol=1e-4
    end

    @testset "FOCEI fit matches default within tolerance" begin
        res_def = fit_model(dm, NoLimits.FOCEI(optim_kwargs=(maxiters=40,));
                            serialization=EnsembleSerial(), rng=Xoshiro(3))
        res_new = fit_model(dm, NoLimits.FOCEI(optim_kwargs=(maxiters=40,),
                                               inner_optimizer=NewtonInner());
                            serialization=EnsembleSerial(), rng=Xoshiro(3))
        @test isfinite(get_objective(res_new))
        @test get_objective(res_new) ≈ get_objective(res_def) rtol=1e-6 atol=1e-6
    end

    @testset "max_dim fallback reproduces the default path" begin
        res_def = fit_model(dm, NoLimits.Laplace(optim_kwargs=(maxiters=15,));
                            serialization=EnsembleSerial(), rng=Xoshiro(3))
        res_fb = fit_model(dm, NoLimits.Laplace(optim_kwargs=(maxiters=15,),
                                                inner_optimizer=NewtonInner(max_dim=0));
                           serialization=EnsembleSerial(), rng=Xoshiro(3))
        @test get_objective(res_fb) ≈ get_objective(res_def) rtol=1e-10 atol=1e-10
    end
end
