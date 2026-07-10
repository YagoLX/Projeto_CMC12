function [u, dxi] = leiControle(X, r, K, P)
% LEICONTROLE  Lei LQI com saturacao e anti-windup por integracao condicional.
%   u = sat( -K*[phi; phidot; xi] )
%   dxi (derivada do estado integral) e CONGELADA quando o atuador esta saturado
%   E o erro so pioraria a saturacao (clamping). Fora disso, dxi = r - phi.
%
%   Nao introduz parametro novo (ao contrario do back-calculation), entao o
%   CMA-ES nao ganha dimensao. Fica inerte em rastreio suave (u nao satura) e
%   so age nos degraus grandes de azimute -> nao atrapalha onde o integral e o heroi.
%
%   Entradas:
%     X = [phi; phidot; xi],  r = referencia,  K = [K_phi K_phidot K_i]
%   Saidas:
%     u   : torque saturado
%     dxi : derivada do estado integral (0 se congelado)

  phi = X(1);  phidot = X(2);  xi = X(3);

  u_unsat = -( K(1)*phi + K(2)*phidot + K(3)*xi );
  u = max(min(u_unsat, P.umax), -P.umax);

  e = r - phi;
  saturado = (u ~= u_unsat);
  if saturado && (sign(e) == sign(u_unsat))
    dxi = 0;          % congela: integrar so empurraria mais contra a saturacao
  else
    dxi = e;          % integra normal
  end

  % Se o passo adaptativo do ode45 travar caçando a quina do 'if', trocar por:
  %   sat_frac = min(1, abs(u_unsat)/P.umax);  dxi = e*(1 - sat_frac);
  % ou usar ode15s. Comece pelo binario -- normalmente passa liso.
end
