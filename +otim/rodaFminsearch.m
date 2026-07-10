function [Qopt, Ropt, popt, Jopt] = rodaFminsearch(P, tune, stress)
  g = P.otim;
  p0 = log10(g.q0(:));                     % [log10 q_phidot; log10 q_i]
  opts = optimset('Display','final','MaxFunEvals',g.MaxFunEvals, ...
                  'MaxIter',g.MaxFunEvals,'TolFun',1e-4,'TolX',1e-3);
  fun = @(p) otim.custoOtim(p, P, tune, stress);

  [popt, Jopt] = fminsearch(fun, p0, opts);
  rng(0);
  for s = 1:g.nStart
    ps = p0 + (rand(2,1)-0.5)*2;           % +-1 decada
    [pc, Jc] = fminsearch(fun, ps, opts);
    if Jc < Jopt, popt = pc; Jopt = Jc; end
  end
  popt = popt(:);
  Qopt = diag([g.qphi, 10^popt(1), 10^popt(2)]);
  Ropt = g.Rfix;
end