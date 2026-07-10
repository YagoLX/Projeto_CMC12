function animaAntena(out, arquivoMP4)
% ANIMAANTENA  Anima a antena seguindo a referencia (entregavel do passo 9).
%   Vista de topo: seta de azimute real (phi) vs referencia; painel de elevacao.
%   Se arquivoMP4 for dado, grava via VideoWriter; senao, so mostra na tela.
%
%   out : saida de simulaCenario (t, phi, cen)

  if nargin < 2, arquivoMP4 = ''; end

  t = out.t; phi = out.phi;
  ref = arrayfun(out.cen.ref.pos, t);
  el  = arrayfun(out.cen.elev.pos, t);

 fig = figure('Color','w','Name','Antena seguindo a sonda', ...
             'Position',[100 100 900 450]);

  % --- painel azimute (vista de topo) ---
  ax1 = subplot(1,2,1); axis(ax1,'equal'); hold(ax1,'on'); grid(ax1,'on');
  th = linspace(0,2*pi,100); plot(ax1, cos(th), sin(th), 'Color',[.8 .8 .8]);
  hRef = plot(ax1,[0 cos(ref(1))],[0 sin(ref(1))],'k--','LineWidth',1.5);
  hAnt = plot(ax1,[0 cos(phi(1))],[0 sin(phi(1))],'b-','LineWidth',3);
  xlim(ax1,[-1.2 1.2]); ylim(ax1,[-1.2 1.2]);
  title(ax1,'Azimute (topo)'); legend(ax1,{'','ref','antena'},'Location','southoutside');

  % --- painel elevacao (perfil) ---
  ax2 = subplot(1,2,2); hold(ax2,'on'); grid(ax2,'on');
  hEl = plot(ax2,[0 cos(el(1))],[0 sin(el(1))],'r-','LineWidth',3);
  plot(ax2,[0 1],[0 0],'Color',[.8 .8 .8]);      % horizonte
  axis(ax2,'equal'); xlim(ax2,[0 1.2]); ylim(ax2,[-0.1 1.2]);
  title(ax2,'Elevacao (perfil)');

  gravando = ~isempty(arquivoMP4);
  if gravando
    vw = VideoWriter(arquivoMP4,'MPEG-4'); vw.FrameRate = 30; open(vw);
  end

  passo = max(1, round(numel(t)/300));           % ~300 quadros
  
  ht = sgtitle(fig, sprintf('t = %.1f s', t(1)));   % antes do for

  passo = max(1, round(numel(t)/300));
  for k = 1:passo:numel(t)
    set(hRef,'XData',[0 cos(ref(k))],'YData',[0 sin(ref(k))]);
    set(hAnt,'XData',[0 cos(phi(k))],'YData',[0 sin(phi(k))]);
    set(hEl ,'XData',[0 cos(el(k))], 'YData',[0 sin(el(k))]);
    set(ht,'String',sprintf('t = %.1f s', t(k)));    % atualiza, nao recria
    drawnow;
    if gravando, writeVideo(vw, getframe(fig)); end
  end
  if gravando, close(vw); fprintf('Animacao salva em %s\n', arquivoMP4); end
end
