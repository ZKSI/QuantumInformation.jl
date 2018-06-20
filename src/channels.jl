
#### Relationship among representations of channels

"""
Checks if set of Kraus operators fulfill completness relation.
"""
function kraus_is_CPTP(kraus_list::Vector{<:AbstractMatrix{<:Number}}, atol=1e-08)
    complentess_relation = sum(k'*k for k in kraus_list)
    isapprox(complentess_relation, eye(complentess_relation), atol=atol)
end

"""
Transforms list of Kraus operators into super-operator matrix.
"""
function kraus_to_superoperator(kraus_list::Vector{<:AbstractMatrix{<:Number}})
    # TODO: chceck if all Kraus operators are the same shape
    sum(k⊗k' for k in kraus_list)
end

function kraus_to_stinespring(kraus_list::Vector{<:AbstractMatrix{<:Number}})
    dim = size(kraus_list, 1)
    sum(k⊗ket(i-1, dim) for (i, k) in enumerate(kraus_list))
end

function kraus_to_dynamical_matrix(kraus_list::Vector{<:AbstractMatrix{<:Number}})
    sum(res(k) * res(k)' for k in kraus_list)
end

function superoperator_to_kraus(m::AbstractMatrix{<:Number}, cols=0)
    F = eigfact(Hermitian(reshuffle(m)))
    # TODO: vcat ?
    [sqrt(val)*unres(F.vectors[:,i], cols) for (i,val) in enumerate(F.values)]
end

superoperator_to_dynamical_matrix(m::AbstractMatrix{<:Number}) = reshuffle(m)

function superoperator_to_stinespring(m::AbstractMatrix{<:Number})
    kraus_to_stinespring(superoperator_to_kraus(M))
end

function dynamical_matrix_to_kraus(R::AbstractMatrix{<:Number})
    F = eigfact(Hermitian(R))

    kraus = Any[] #TODO: make proper type
    for (val, vec) in zip(F.values, F.vectors)
        if val>=0.0
            push!(kraus, sqrt(val) * unres(vec))
        else
            push!(kraus, zero(unres(vec)))
        end
    end
    return kraus
end

function dynamical_matrix_to_stinespring(R::AbstractMatrix{<:Number})
    return kraus_to_stinespring(dynamical_matrix_to_kraus(R))
end

function dynamical_matrix_to_superoperator(R::AbstractMatrix{<:Number})
    return reshuffle(R)
end

#### Application of channels

function apply_channel_dynamical_matrix(R::AbstractMatrix{<:Number}, rho::AbstractMatrix{<:Number})
    unres(reshuffle(R) * res(rho))
end

function apply_channel_kraus(kraus_list::Vector{<:AbstractMatrix{<:Number}}, rho::AbstractMatrix{<:Number})
    return sum(k * rho * k' for k in kraus_list)
end

# TODO: Remove this function
apply_kraus(kraus_list::Vector{<:AbstractMatrix{<:Number}}, rho::AbstractMatrix{<:Number}) = apply_channel_kraus(kraus_list, rho)

function apply_channel_superoperator(M::AbstractMatrix{<:Number}, rho::AbstractMatrix{<:Number})
    return unres(M * res(rho))
end

function apply_channel_stinespring(A::AbstractMatrix{<:Number}, rho::AbstractMatrix{<:Number}, dims)
    return ptrace(A * rho * A', dims, [1,])
end

function channel_to_superoperator(channel::Function, dim::Int)
    dim > 0 ? () : error("Channel dimension has to be nonnegative")
    M = zeros(ComplexF64, dim*dim, dim*dim)
    for (i, e) in enumerate(base_matrices(dim))
        M[:, i] = res(channel(e))
    end
    M
end
