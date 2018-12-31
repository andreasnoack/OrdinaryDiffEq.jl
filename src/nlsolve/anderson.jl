function (S::NLAnderson{false,<:NLSolverCache})(integrator)
  nlcache = S.cache
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack z,tmp,W,κ,tol,c,γ,max_iter,min_iter = nlcache
  if typeof(integrator.f) <: SplitFunction
    f = integrator.f.f1
  else
    f = integrator.f
  end
  # precalculations
  κtol = κ*tol

  zs = zeros(S.n+1)
  gs = zeros(S.n+1)
  residuals = zeros(S.n+1)
  # initial step of NLAnderson iteration
  zs[1] = z
  iter = 1
  tstep = t + c*dt
  u = tmp + γ*z
  z₊ = dt*f(u, p, tstep)
  gs[1] = z₊
  dz = z₊ - z
  ndz = integrator.opts.internalnorm(dz)
  xs = circshift(xs, 1)
  gs = circshift(gs, 1)
  z = z₊
  zs[1] = z
  η = nlcache.ηold
  do_anderson = true

  # anderson acceleration for fixed point iteration
  fail_convergence = false
  while (do_anderson || iter < min_iter) && iter < max_iter
    iter += 1
    u = tmp + γ*z
    z₊ = dt*f(u, p, tstep)
    gs[1] = z₊
    
    mk = min(S.n, iter)
    residuals[1:mk] = (gs[2:mk+1] .- zs[2:mk+1]) .- (gs[1] - zs[1])
    alphas[1:mk] .= residuals[1:mk] \ (zs[1] - gs[1])
    for i = 1:mk
        z₊ += alphas[i]*(gs[i+1] - gs[1])
    end
    xs = circshift(xs, 1)
    gs = circshift(gs, 1)
    zs[1] = z₊
    ndzprev = ndz
    dz = z₊ - z
    ndz = integrator.opts.internalnorm(dz)
    if θ > 1 || ndz*(θ^(max_iter - iter)/(1-θ)) > κtol
      fail_convergence = true
      break
    end
    η = θ/(1-θ)
    do_functional = (η*ndz > κtol)
    z = z₊
  end
end