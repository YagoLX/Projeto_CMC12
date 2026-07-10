function cen = cenarioDegrau(P, thetaDeg, stepDeg, tf)
% CENARIODEGRAU  (7a) Degrau de azimute com elevacao FIXA (thetad=0).
%   Coriolis desligado -> testa rastreio puro. O integrador zera ess aqui.
%   E o cenario de SINTONIA: os 5 requisitos sao bem-postos e viaveis.
%
%   thetaDeg : elevacao fixa (graus)   -- define rho = cos^2
%   stepDeg  : amplitude do degrau de azimute (graus)
%   tf       : tempo final (s), default 10

  if nargin < 2 || isempty(thetaDeg), thetaDeg = 0;  end
  if nargin < 3 || isempty(stepDeg),  stepDeg  = 90; end
  if nargin < 4 || isempty(tf),       tf       = 10; end

  th  = deg2rad(thetaDeg);
  amp = deg2rad(stepDeg);

  cen.tipo    = 'degrau';                  % metricas de step (stepinfo)
  cen.tspan   = [0 tf];
  cen.X0      = [0; 0; 0];                 % parte do repouso na origem
  cen.ref.pos = @(t) amp;                  % degrau em t=0
  cen.elev.pos  = @(t) th;                 % elevacao constante
  cen.elev.rate = @(t) 0;                  % thetad = 0 -> sem Coriolis
  cen.rfinal  = amp;
  cen.maxstep = 0.02;
  cen.nome    = sprintf('Degrau %gdeg @ elev %gdeg', stepDeg, thetaDeg);
end