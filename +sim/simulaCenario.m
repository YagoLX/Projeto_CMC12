function out = simulaCenario(P, G, mode, cen)
% SIMULACENARIO  Integra a malha fechada NAO-LINEAR (com Coriolis) via ode45.
%   Estado da ODE: X = [phi; phidot; xi].
%
%   Entradas:
%     P    : parametros
%     G    : grade de ganhos (de projetaGradeLQI)
%     mode : 'fixo' | 'chaveado' | 'continuo'
%     cen  : struct de cenario com campos
%              .tspan   [t0 tf]
%              .X0      [phi0; phidot0; xi0]
%              .ref.pos  @(t) referencia de azimute
%              .elev.pos @(t) elevacao theta(t)
%              .elev.rate@(t) taxa thetad(t)  (ativa o Coriolis)
%              .rfinal   referencia final (p/ metricas)
%              .maxstep  passo maximo do ode (opcional)
%   Saida:
%     out.t, out.phi, out.phidot, out.xi, out.u, out.cen, out.mode

  if ~isfield(cen,'maxstep') || isempty(cen.maxstep), cen.maxstep = Inf; end
  opt = odeset('RelTol',1e-6,'AbsTol',1e-8,'MaxStep',cen.maxstep);

  [t,X] = ode45(@(t,X) malhaFechada(t,X,P,G,mode,cen), cen.tspan, cen.X0, opt);

  % Reconstroi u(t) para o custo de controle e diagnostico.
  u = zeros(size(t));
  for i = 1:numel(t)
    rho  = cos(cen.elev.pos(t(i)))^2;
    Ki   = controle.interpolaGanho(G, rho, mode);
    u(i) = controle.leiControle(X(i,:).', cen.ref.pos(t(i)), Ki, P);
  end

  out.t = t;  out.phi = X(:,1);  out.phidot = X(:,2);  out.xi = X(:,3);
  out.u = u;  out.cen = cen;      out.mode = mode;
end

% ---------------- subfuncao: lado direito da ODE ----------------
function dX = malhaFechada(t, X, P, G, mode, cen)
  r      = cen.ref.pos(t);
  theta  = cen.elev.pos(t);
  thetad = cen.elev.rate(t);
  rho    = cos(theta)^2;

  K = controle.interpolaGanho(G, rho, mode);        % scheduling pelo encoder
  [u, dxi] = controle.leiControle(X, r, K, P);       % LQI + clamping
  dx2 = modelo.plantaNaoLinear(X(1:2), u, theta, thetad, P);  % planta completa

  dX = [dx2; dxi];
end
