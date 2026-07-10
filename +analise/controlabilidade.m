function T = controlabilidade(P)
% CONTROLABILIDADE  (T1) Rank e condicionamento do par AUMENTADO na grade.
%   Teoria: com J0 regularizando, o rank e CHEIO (=3) para todo rho, INCLUSIVE
%   no zenite. A "degeneracao" a demonstrar e de CONDICIONAMENTO, nao de rank:
%   cond(ctrb) explode ~ com 1/J^2 enquanto o rank fica constante. Isso corrige
%   a narrativa -- o baseline fixo falha por ganho agressivo, nao por perder
%   controlabilidade.
%
%   Monta o par aumentado como o lqi (estado [phi; phidot; xi]):
%     A_aug = [A 0; -C 0],  B_aug = [B; 0]

  rho = P.rho_grid(:);
  n = numel(rho);
  theta_deg = acosd(sqrt(rho));
  rankc = zeros(n,1); condc = zeros(n,1); Jval = zeros(n,1);

  for k = 1:n
    [A,B,C,~,J] = modelo.matrizesPlanta(P, rho(k));
    A_aug = [A, zeros(2,1); -C, 0];
    B_aug = [B; 0];
    Wc = ctrb(A_aug, B_aug);
    rankc(k) = rank(Wc);
    condc(k) = cond(Wc);
    Jval(k)  = J;
  end

  T = table(theta_deg, rho, Jval, rankc, condc, ...
      'VariableNames', {'theta_deg','rho','J','rank_ctrb','cond_ctrb'});
  disp('T1 - Controlabilidade do par aumentado na grade:'); disp(T);

  figure('Color','w','Name','T1 controlabilidade');
  yyaxis left;  semilogy(theta_deg, condc,'-o'); ylabel('cond(ctrb)');
  yyaxis right; plot(theta_deg, rankc,'-s'); ylabel('rank'); ylim([0 4]);
  xlabel('elevacao (deg)'); grid on;
  title('Rank constante (=3), condicionamento explode no zenite');
end
