function T = comparaMetodos(P, G, cen)
% COMPARAMETODOS  Roda os 3 metodos no mesmo cenario e tabula as metricas
%   mais o custo de controle. Retorna uma table pronta para o relatorio.
%
%   Linhas: fixo, chaveado, continuo.
%   Escolhe as metricas pelo TIPO do cenario:
%     cen.tipo == 'degrau' (default) -> metricas de step (stepinfo): ess,Mp,tr,td,ts
%     cen.tipo == 'rampa'            -> metricas de rastreio: lag, erro pico, erro rms
%   (aplicar stepinfo a uma rampa como o GPS produz numeros sem sentido).

  if ~isfield(cen,'tipo') || isempty(cen.tipo), cen.tipo = 'degrau'; end
  modos = {'fixo','chaveado','continuo'};

  % ================= cenario de RAMPA (ex.: GPS) =================
  if strcmpi(cen.tipo, 'rampa')
    nome = strings(3,1);
    ess=zeros(3,1); epk=ess; erms=ess; custo=ess; OK=false(3,1);
    for i = 1:3
      out = sim.simulaCenario(P, G, modos{i}, cen);
      r   = arrayfun(@(tt) cen.ref.pos(tt), out.t);       % referencia amostrada
      m   = analise.metricasRastreio(out.t, out.phi, r);
      nome(i)  = modos{i};
      ess(i)   = rad2deg(m.ess);
      epk(i)   = rad2deg(m.epk);
      erms(i)  = rad2deg(m.erms);
      custo(i) = trapz(out.t, out.u.^2);
      OK(i)    = (m.ess <= P.req.ess);                    % lag em regime <= 1.5 deg
    end
    T = table(nome, ess, epk, erms, custo, OK, ...
        'VariableNames', {'metodo','lag_ess_deg','erro_pico_deg','erro_rms_deg','custo','passa'});
    disp([char(cen.nome) '   [metricas de RASTREIO -- rampa]']);  disp(T);
    return;
  end

  % ================= cenario de DEGRAU =================
  nome = strings(3,1);
  ess=zeros(3,1); Mp=ess; tr=ess; td=ess; ts=ess; custo=ess; OK=false(3,1);
  for i = 1:3
    out = sim.simulaCenario(P, G, modos{i}, cen);
    m   = analise.metricasDesempenho(out.t, out.phi, out.cen.rfinal, out.phi(1));
    nome(i)  = modos{i};
    ess(i)   = rad2deg(m.ess);
    Mp(i)    = m.Mp;   tr(i) = m.tr;  td(i) = m.td;  ts(i) = m.ts;
    custo(i) = trapz(out.t, out.u.^2);
  end
  T = table(nome, ess, Mp, tr, td, ts, custo,  ...
      'VariableNames', {'metodo','ess_deg','Mp_pct','tr_s','td_s','ts_s','custo',});
  disp(cen.nome);  disp(T);
end