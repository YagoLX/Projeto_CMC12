function fig = plotComparacoes(P, G, cen, modos)
% PLOTCOMPARACOES  Sobrepoe phi(t) (e u(t)) dos metodos no mesmo cenario.
%   modos : cell array, default {'fixo','chaveado','continuo'}

  if nargin < 4 || isempty(modos), modos = {'fixo','chaveado','continuo'}; end

  fig = figure('Name', cen.nome, 'Color','w');
  ax1 = subplot(2,1,1); hold(ax1,'on'); grid(ax1,'on');
  ax2 = subplot(2,1,2); hold(ax2,'on'); grid(ax2,'on');

  for i = 1:numel(modos)
    out = sim.simulaCenario(P, G, modos{i}, cen);
    plot(ax1, out.t, rad2deg(out.phi), 'LineWidth',1.4, 'DisplayName',modos{i});
    plot(ax2, out.t, out.u,            'LineWidth',1.2, 'DisplayName',modos{i});
  end

  % Referencia e banda de erro em regime.
  tt = linspace(cen.tspan(1), cen.tspan(2), 300);
  rr = arrayfun(cen.ref.pos, tt);
  plot(ax1, tt, rad2deg(rr), 'k--', 'DisplayName','ref');
  yline(ax1, rad2deg(cen.rfinal)+1.5, ':', '+1.5deg');
  yline(ax1, rad2deg(cen.rfinal)-1.5, ':', '-1.5deg');

  ylabel(ax1,'azimute \phi (deg)'); legend(ax1,'Location','best');
  title(ax1, cen.nome, 'Interpreter','none');
  ylabel(ax2,'torque u (N\cdotm)'); xlabel(ax2,'t (s)');
  yline(ax2,  P.umax, 'r:', 'u_{max}');
  yline(ax2, -P.umax, 'r:');
end
