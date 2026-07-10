function m = avaliaBateria(P, G, cenarios)
% AVALIABATERIA  Roda uma bateria de cenarios e retorna as PIORES metricas
%   (mais o esforco medio de controle).
%
%   cenarios : cell array de structs de cenario (ex.: {degrau, zenite})
%   Sempre avalia no modo 'continuo' (o metodo principal).
%
%   m.ess, m.Mp, m.tr, m.td, m.ts : piores valores da bateria
%   m.esforco : media de trapz(u^2 dt) sobre os cenarios

  n = numel(cenarios);
  ESS = zeros(n,1); MP = ESS; TR = ESS; TD = ESS; TS = ESS; EFF = ESS;

  for k = 1:n
    out = sim.simulaCenario(P, G, 'continuo', cenarios{k});
    mk  = analise.metricasDesempenho(out.t, out.phi, out.cen.rfinal, out.phi(1));
    ESS(k)=mk.ess; MP(k)=mk.Mp; TR(k)=mk.tr; TD(k)=mk.td; TS(k)=mk.ts;
    EFF(k)=trapz(out.t, out.u.^2);
  end

  m.ess = max(ESS);      % pior erro em regime (rad)
  m.Mp  = max(MP);       % pior sobressinal (%)
  m.tr  = max(TR);       % pior tempo de subida (s)
  m.td  = max(TD);       % pior tempo de atraso (s)
  m.ts  = max(TS);       % pior tempo de acomodacao (s)
  m.esforco = mean(EFF); % esforco medio (N^2*m^2*s)
end
