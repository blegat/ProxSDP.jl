
function compute_residual!(pair::PrimalDual, a::AuxiliaryData, primal_residual::CircularVector{Float64}, dual_residual::CircularVector{Float64}, comb_residual::CircularVector{Float64}, mat::Matrices, p::Params, aff)
    
    # Primal residual
    Px = pair.x .- p.primal_step * a.Mty
    Px_old = pair.x_old - p.primal_step * a.Mty_old
    primal_residual[p.iter] = sqrt(aff.n) * norm(Px - Px_old, Inf) / max(p.norm_rhs, norm(Px_old, Inf), 1e-4)

    # Dual residual
    Py = pair.y - p.dual_step * a.Mx
    Py_old = pair.y_old - p.dual_step * a.Mx_old
    dual_residual[p.iter] = sqrt(aff.m + aff.p) * norm(Py - Py_old, Inf) / max(p.norm_c, norm(Py_old, Inf), 1e-4)

    # Compute combined residual
    comb_residual[p.iter] = max(primal_residual[p.iter], dual_residual[p.iter])

    # Keep track of previous iterates
    copyto!(pair.x_old, pair.x)
    copyto!(pair.y_old, pair.y)
    copyto!(a.Mty_old, a.Mty)
    copyto!(a.Mx_old, a.Mx)

    return nothing
end

function soc_convergence(a::AuxiliaryData, cones::ConicSets, pair::PrimalDual, opt::Options, p::Params)
    for (idx, soc) in enumerate(cones.socone)
        if soc_gap(a.soc_v[idx], a.soc_s[idx]) >= opt.tol_soc
            return false
        end
    end
    return true
end

function soc_gap(v::ViewVector, s::ViewScalar)
    return norm(v) - s[]
end

function convergedrank(p::Params, cones::ConicSets, opt::Options)
    for (idx, sdp) in enumerate(cones.sdpcone)
        if !(p.min_eig[idx] < opt.tol_eig || p.target_rank[idx] > opt.max_target_rank_krylov_eigs || sdp.sq_side < opt.min_size_krylov_eigs)
            return false
        end
    end
    return true
end