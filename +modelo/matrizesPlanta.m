function [A,B,C,D,J] = matrizesPlanta(P, rho)
% MATRIZESPLANTA  Modelo CONGELADO do azimute para projeto do LQR/LQI.
%   Elevacao parada (thetad=0 => Coriolis some). Duplo integrador amortecido.
%
%   Estado x = [phi; phidot], entrada u = tau_phi, saida y = phi.
%   J(rho) = J0 + JL*rho,  rho = cos^2(theta).
%
%   [A,B,C,D,J] = matrizesPlanta(P, rho)
%     A : 2x2 dinamica congelada
%     B : 2x1 ganho de entrada (~1/J, varia ~40x horizonte->zenite)
%     C : [1 0]  (mede phi)
%     D : 0
%     J : inercia efetiva nesse rho

  J = P.J0 + P.JL*rho;          % inercia efetiva; J0 impede J->0 no zenite
  A = [0        1;
       0   -P.b/J];
  B = [0;
       1/J];
  C = [1 0];
  D = 0;
end
