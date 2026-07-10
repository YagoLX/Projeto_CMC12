function m = metricasRastreio(t, phi, r)
% METRICASRASTREIO  Metricas de RASTREIO para cenarios de trajetoria (rampa).
%   stepinfo NAO se aplica a uma referencia que nao e degrau: sobressinal,
%   tempo de subida e acomodacao medidos contra 'rfinal' de uma rampa sao lixo.
%   Aqui medimos o que importa numa trajetoria: o erro de rastreio e(t)=r-phi.
%
%   Entradas:
%     t   : vetor de tempo
%     phi : azimute medido (rad)
%     r   : referencia de azimute AMOSTRADA em t (rad) -- mesmo tamanho de phi
%
%   Saidas (rad):
%     m.ess  : lag de velocidade em regime = |media de e(t) na cauda|
%              (para o LQI tipo-1, e o erro finito de seguimento a rampa)
%     m.epk  : pico do |erro de rastreio| (inclui o transiente inicial)
%     m.erms : rms do erro de rastreio ao longo do voo

  e = r(:) - phi(:);

  ncauda = max(1, round(0.2*numel(e)));      % ultimos 20% = "regime"
  m.ess  = abs(mean(e(end-ncauda+1:end)));   % lag de velocidade
  m.epk  = max(abs(e));                      % pior erro instantaneo
  m.erms = sqrt(mean(e.^2));                 % erro rms
end