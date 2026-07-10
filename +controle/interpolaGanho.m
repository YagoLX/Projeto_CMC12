function K = interpolaGanho(G, rho, mode)
% INTERPOLAGANHO  Retorna o ganho K = [K_phi K_phidot K_i] para um rho online.
%   As tres variantes do roadmap (passo 4), para comparacao no mesmo grafico:
%
%     'fixo'     : um K so (horizonte, rho=1). Baseline que FALHA no zenite.
%     'chaveado' : no mais proximo da grade (escalonado por chaveamento).
%     'continuo' : interpolacao linear componente-a-componente (escalonado continuo).
%
%   rho vem do encoder de elevacao a cada passo: rho = cos^2(theta).

  switch lower(mode)
    case 'continuo'
      K = interp1(G.rho_grid, G.K_grid, rho, 'linear', 'extrap');
    case 'chaveado'
      [~, i] = min(abs(G.rho_grid - rho));
      K = G.K_grid(i, :);
    case 'fixo'
      K = G.K_fixo;
    otherwise
      error('interpolaGanho:mode', 'mode invalido: %s', mode);
  end
end
