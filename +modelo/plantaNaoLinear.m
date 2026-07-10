function dx = plantaNaoLinear(x2, u, theta, thetad, P)
% PLANTANAOLINEAR  Planta NAO-LINEAR COMPLETA do azimute (codigo do grupo).
%   E o que a simulacao integra de verdade (nao o modelo congelado).
%
%   [J0 + JL*cos^2(theta)]*phiddot ...
%       - 2*JL*cos(theta)*sin(theta)*thetad*phidot ...   (Coriolis/reacao)
%       + b*phidot = u
%
%   Entradas:
%     x2     : [phi; phidot]  estado mecanico
%     u      : torque de controle (ja saturado) N*m
%     theta  : elevacao (rad)      -- parametro exogeno
%     thetad : taxa de elevacao (rad/s) -- SO ela ativa o Coriolis
%     P      : struct de parametros
%   Saida:
%     dx = [phidot; phiddot]

  phidot = x2(2);

  Jvar   = P.J0 + P.JL*cos(theta)^2;                         % inercia variavel
  coriol = -2*P.JL*cos(theta)*sin(theta)*thetad*phidot;      % termo de Coriolis
  phiddot = (u - coriol - P.b*phidot) / Jvar;

  dx = [phidot; phiddot];
end
