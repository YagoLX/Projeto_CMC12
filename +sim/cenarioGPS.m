function cen = cenarioGPS(P, tf)
% CENARIOGPS  (7c) Trajetoria sintetica tipo sonda de balao (rampa lenta).
%   Aqui o LQI e TIPO 1: zera erro a degrau e rejeita disturbio constante,
%   mas deixa LAG DE VELOCIDADE finito a rampa. Como o alvo e lento, o lag e
%   pequeno -- mas VERIFIQUE-O contra o 1.5deg (nao assuma zero).
%
%   cen.tipo = 'rampa'  ->  comparaMetodos usa metricasRastreio (lag/erro
%   pico/rms), NAO stepinfo. Aplicar stepinfo a uma rampa da numeros sem sentido.
%
%   Trajetoria comprimida (tf s representando o voo de 4h) para simulacao viavel.
%   Azimute: rampa suave; Elevacao: sobe devagar e volta (Coriolis leve, continuo).
%
%   tf : horizonte de simulacao (s), default 60

  if nargin < 2 || isempty(tf), tf = 60; end

  % Azimute de referencia: rampa com aceleracao/desaceleracao suaves (perfil senoidal).
  az_rate = deg2rad(2);                         % ~2 deg/s de deriva media
  ref_pos = @(t) az_rate .* (t - (tf/(2*pi)).*sin(2*pi.*t./tf));

  % Elevacao: sobe a ~30deg no meio do voo e desce (arco suave) -> thetad != 0 continuo.
  el_amp  = deg2rad(30);
  el_pos  = @(t) el_amp .* sin(pi.*t./tf).^2;
  el_rate = @(t) el_amp .* (pi./tf) .* sin(2*pi.*t./tf);

  cen.tipo    = 'rampa';                         % metricas de rastreio
  cen.tspan   = [0 tf];
  cen.X0      = [0; 0; 0];
  cen.ref.pos = ref_pos;
  cen.elev.pos  = el_pos;
  cen.elev.rate = el_rate;
  cen.rfinal  = ref_pos(tf);
  cen.maxstep = 0.05;
  cen.nome    = 'Trajetoria GPS sintetica (rampa lenta)';
end