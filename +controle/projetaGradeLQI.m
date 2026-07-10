function G = projetaGradeLQI(P, Q, R)
% PROJETAGRADELQI  Resolve o LQI em cada no da grade de rho e guarda K(rho).
%   Coracao do gain scheduling.
%
%   ATENCAO A CONVENCAO DO MATLAB: lqi(sys,Q,R) monta o estado aumentado como
%   [x; xi] (originais primeiro, integrador POR ULTIMO) e devolve
%       K = [K_phi, K_phidot, K_i]
%   A lei de controle e u = -K*[phi; phidot; xi], com xi = integral de (r - y).
%
%   Q deve ser 3x3 (estado aumentado), R escalar.
%
%   G.rho_grid : coluna de rho
%   G.K_grid   : (nRho x 3) ganhos por no
%   G.K_fixo   : ganho no horizonte (rho=1), usado no baseline fixo
%   G.Q, G.R   : guardados para rastreabilidade

  if nargin < 2 || isempty(Q), Q = diag([P.qphi, P.qphidot, P.qi]); end
  if nargin < 3 || isempty(R), R = P.R; end

  rho_grid = P.rho_grid(:);
  n = numel(rho_grid);
  K_grid = zeros(n,3);

  for k = 1:n
    [A,B,C,D] = modelo.matrizesPlanta(P, rho_grid(k));
    sys = ss(A,B,C,D);
    K_grid(k,:) = lqi(sys, Q, R);      % [K_phi K_phidot K_i]
  end

  G.rho_grid = rho_grid;
  G.K_grid   = K_grid;
  G.K_fixo   = K_grid(end,:);          % rho_grid termina em 1 (horizonte)
  G.Q = Q;  G.R = R;
end
