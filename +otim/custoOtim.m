function J = custoOtim(p, P, tune, stress)
% p = [log10(q_phidot); log10(q_i)]   (R e q_phi FIXOS)
  g = P.otim;
  if any(p < g.guardLo) || any(p > g.guardHi), J = 1e6; return; end

  Q = diag([g.qphi, 10^p(1), 10^p(2)]);   R = g.Rfix;
  try
    G  = controle.projetaGradeLQI(P, Q, R);
    mt = sim.avaliaBateria(P, G, tune);     % pior caso na sintonia
    ms = sim.avaliaBateria(P, G, stress);   % pior caso no estresse
  catch
    J = 1e6; return;
  end

  Jreq = pen(mt.ess,P.req.ess) + pen(mt.Mp,P.req.Mp) + pen(mt.tr,P.req.tr) ...
       + pen(mt.td,P.req.td)   + pen(mt.ts,P.req.ts);

  rel  = g.stress_relax;
  Jstr = g.wstr * ( pen(ms.Mp, rel*P.req.Mp) + pen(ms.ts, rel*P.req.ts) );
  if ms.Mp > 200 || ms.ess > 10*P.req.ess, Jstr = Jstr + 1e3; end

  if Jreq < 1e-6, Jeff = g.lambda * mt.esforco; else, Jeff = 0; end
  J = Jreq + Jstr + Jeff;
end

function c = pen(v, lim)
  c = max(0, (v - lim)/lim)^2;
end