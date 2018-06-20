sparsify_kraus(kraus_list) = [sparse(k) for k in kraus_list]


@testset "Channels" begin

include("test_channels.jl")

@testset "channel_to_superoperator" begin
    ρ = [0.25 0.25im; -0.25im 0.75]
    T = hcat([ComplexF64[0.25, 0.25im, -0.25im, 0.75] for i=1:4]...) #stack res ρ
    M = channel_to_superoperator(x -> ρ, 2)
    @test norm(T-M) ≈ 0. atol=1e-15
end


@testset "kraus" begin


    @testset "kraus_is_CPTP" begin
        for kraus_list in kraus_set
            @test kraus_is_CPTP(kraus_list) == true
        end
        for kraus_list in kraus_set
            @test kraus_is_CPTP(sparsify_kraus(kraus_list)) == true
        end
    end

    @testset "kraus_to_superoperator" begin
        ket0 = ket(0, 2)
        ket1 = ket(1, 2)
        @test kraus_to_superoperator(kraus_list_u)*vec(proj(ket1)) ≈ vec(proj(ket0))

        ket0 = ket(SparseVector{ComplexF64}, 0, 2)
        ket1 = ket(SparseVector{ComplexF64}, 1, 2)
        @test kraus_to_superoperator(sparsify_kraus(kraus_list_u))*vec(proj(ket0)) ≈ vec(proj(ket1))

        α = 0.25
        K₁ = ComplexF64[0 sqrt(α); 0 0]
        K₂ = ComplexF64[1 0; 0 sqrt(1 - α)]
        kl = Matrix{ComplexF64}[K₁, K₂]
        M = kraus_to_superoperator(kl)
        T = diagm(ComplexF64[1, sqrt(1 - α), sqrt(1 - α), 1 - α])
        T[2, 3] = α
        @test norm(T-M) ≈ 0 atol=1e-15
    end

    @testset "kraus_to_stinespring" begin
        for kraus_list in kraus_set
            u = kraus_to_stinespring(kraus_list)
            @test isidentity(u'*u)==true
        end
        for kraus_list in kraus_set
            u = kraus_to_stinespring(sparsify_kraus(kraus_list))
            @test isidentity(u'*u)==true
        end
    end

    @testset "kraus_to_dynamical_matrix" begin
        for kraus_list in kraus_set
            h = kraus_to_dynamical_matrix(kraus_list)
            r, c = size(kraus_list[1])
            @test isidentity(ptrace(h, [r, c], 1))==true
        end
        for kraus_list in kraus_set
            h = kraus_to_dynamical_matrix(sparsify_kraus(kraus_list))
            r, c = size(kraus_list[1])
            @test isidentity(ptrace(h, [r, c], 1))==true
        end
    end
end
    @testset "superoperator_to_kraus" begin
    end
    @testset "superoperator_to_dynamical_matrix" begin
    end
    @testset "superoperator_to_stinespring" begin
    end
    @testset "dynamical_matrix_to_kraus" begin
    end
    @testset "dynamical_matrix_to_stinespring" begin
    end
    @testset "apply_channel_dynamical_matrix" begin
    end

    @testset "apply_channel_kraus" begin
        α = 0.25
        K₁ = ComplexF64[0 sqrt(α); 0 0]
        K₂ = ComplexF64[1 0; 0 sqrt(1 - α)]
        kl = Matrix{ComplexF64}[K₁, K₂]
        ρ = [0.25 0.25im; -0.25im 0.75]
        σ = apply_channel_kraus(kl, ρ)
        ξ = ComplexF64[1/4 + 3/16 sqrt(3/4)*1im/4; -sqrt(3/4)*1im/4 9/16]
        @test trace(σ) ≈ 1. atol=1e-15
        @test ishermitian(σ)
        @test norm(σ - ξ) ≈ 0. atol=1e-15
    end

    @testset "apply_channel_superoperator" begin
    end
    @testset "apply_channel_stinespring" begin
    end


end
