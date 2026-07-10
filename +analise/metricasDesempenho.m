function m = metricasDesempenho(t, y, r_final, y0)
% METRICASDESEMPENHO  Extrai as 5 metricas dos requisitos a partir de y(t).
%   Usa stepinfo (Control System Toolbox) e calcula o tempo de atraso a mao.
%
%   ATENCAO:
%    - stepinfo mede tempo de subida 10-90% por padrao. Se a banca esperar
%      0-100%, use 'RiseTimeLimits',[0 1] (ajuste abaixo).
%    - stepinfo NAO da o tempo de atraso (50%); calculamos separado.
%    - ess (erro em regime) em RADIANOS (compare com P.req.ess = deg2rad(1.5)).
%
%   m.ess : |r_final - media da cauda|  (rad)
%   m.Mp  : sobressinal (%)
%   m.tr  : tempo de subida (s)
%   m.td  : tempo de atraso 50% (s)
%   m.ts  : tempo de acomodacao, banda 2% (s)

  if nargin < 4 || isempty(y0), y0 = y(1); end

  S = stepinfo(y, t, r_final, 'SettlingTimeThreshold', 0.02);
  % Para subida 0-100%, descomente:
  % S = stepinfo(y, t, r_final, 'SettlingTimeThreshold',0.02, 'RiseTimeLimits',[0 1]);

  m.Mp = S.Overshoot;
  m.tr = S.RiseTime;
  m.ts = S.SettlingTime;

  % Erro em regime: media dos ultimos pontos (robusto a ripple numerico).
  ncauda = max(1, round(0.05*numel(y)));
  m.ess = abs(r_final - mean(y(end-ncauda+1:end)));

  % Tempo de atraso: primeiro cruzamento de 50% do salto total.
  yalvo = y0 + 0.5*(r_final - y0);
  if r_final >= y0, idx = find(y >= yalvo, 1);
  else,             idx = find(y <= yalvo, 1);
  end
  if isempty(idx), m.td = NaN; else, m.td = t(idx); end

  % Protege NaN de stepinfo (respostas que nao assentam) para o custo do CMA-ES.
  if isnan(m.ts), m.ts = t(end); end
  if isnan(m.tr), m.tr = t(end); end
end
