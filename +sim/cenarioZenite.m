function cen = cenarioZenite(P, thetadDeg, stepDeg, tf)
% CENARIOZENITE  (7b) Cruzamento do zenite com taxa de elevacao ALTA.
%   Teste de ESTRESSE: o Coriolis -2*JL*cos*sin*thetad*phidot vira disturbio
%   quase-constante na escala do laco; o integral do LQI deve REJEITA-lo.
%   Tambem exercita o ganho ~40x maior perto do zenite (motiva o scheduling).
%
%   O azimute e um DEGRAU, entao as metricas de step continuam validas -- mas
%   na otimizacao este cenario entra so como GUARDA relaxada (ver custoOtim),
%   nao com os requisitos plenos: a varredura do keyhole e dura de propria.
%
%   thetadDeg : |thetad| em graus/s (alto), default 20
%   stepDeg   : degrau de azimute simultaneo (graus), default 60
%   tf        : tempo final (s), default 12

  if nargin < 2 || isempty(thetadDeg), thetadDeg = 20; end
  if nargin < 3 || isempty(stepDeg),   stepDeg   = 60; end
  if nargin < 4 || isempty(tf),        tf        = 12; end

  amp    = deg2rad(stepDeg);
  thetad = deg2rad(thetadDeg);

  % Elevacao sobe de ~0 e cruza 90deg; saturada no topo para nao passar do zenite.
  th_of_t = @(t) min(deg2rad(89.5), thetad.*t);

  cen.tipo    = 'degrau';                                  % azimute e degrau
  cen.tspan   = [0 tf];
  cen.X0      = [0; 0; 0];
  cen.ref.pos = @(t) amp;                                  % degrau de azimute
  cen.elev.pos  = th_of_t;
  cen.elev.rate = @(t) thetad .* (th_of_t(t) < deg2rad(89.5));  % zera ao saturar
  cen.rfinal  = amp;
  cen.maxstep = 0.01;
  cen.nome    = sprintf('Zenite thetad=%gdeg/s, degrau %gdeg', thetadDeg, stepDeg);
end