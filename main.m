%% MAIN  Orquestrador do projeto (LQI gain-scheduled + fminsearch).
%  Ordem segue o roadmap: params -> T1 -> T2 -> T3(falha) -> grade+T4 -> otim -> T5/T6/T7.
clear; clc; close all;

% Pacotes (+pasta) no path. (fminsearch e nativo do MATLAB: sem lib externa.)
here = fileparts(mfilename('fullpath'));
addpath(here);

P = params();                       % struct unico de parametros
RODAR_OTIM = true;                  % true roda o fminsearch (lento; nativo, sem lib)

%% T1 - Controlabilidade / condicionamento na grade
analise.controlabilidade(P);

%% Projeta a grade LQI com os pesos-semente
G = controle.projetaGradeLQI(P);    % usa P.qphi/qphidot/qi/R como semente
fprintf('Ganho horizonte (rho=1): [%.3g %.3g %.3g]\n', G.K_fixo);
fprintf('Ganho ~zenite  (rho min): [%.3g %.3g %.3g]\n', G.K_grid(1,:));

%% T2 - Resposta ao degrau no MODELO CONGELADO, por rho (valida ganhos)
figure('Color','w','Name','T2 degrau congelado por rho'); hold on; grid on;
for k = round(linspace(1, numel(P.rho_grid), 5))
  [A,B,C,D] = modelo.matrizesPlanta(P, P.rho_grid(k));
  Aa = [A zeros(2,1); -C 0];  Ba = [B;0];
  Kk = G.K_grid(k,:);
  sysCL = ss(Aa - Ba*Kk, [0;0;1], [C 0], 0);   % entrada = ref no integrador
  step(sysCL, 8);
end
title('T2: degrau no modelo congelado (deve cumprir os 5 requisitos)');

%% Cenarios
cenDeg  = sim.cenarioDegrau(P, 0, 90);     % 7a  degrau, elevacao fixa 0deg
cenDeg2 = sim.cenarioDegrau(P, 45, 90);    %     degrau em outra elevacao (exercita a grade)
cenZen  = sim.cenarioZenite(P);            % 7b  cruzamento do zenite (estresse)
cenGPS  = sim.cenarioGPS(P);               % 7c  trajetoria lenta (rampa)

%% T3 - Baseline LQI FIXO na planta nao-linear (demonstra a falha no zenite)
viz.plotComparacoes(P, G, cenZen, {'fixo'});   % ganho do horizonte perto do zenite

%% T4 - Gain-scheduled: fixo vs chaveado vs continuo (mesmo grafico + tabela)
viz.plotComparacoes(P, G, cenZen);
analise.comparaMetodos(P, G, cenZen);

%% Otimizacao (opcional; lento) - fminsearch sintoniza q_phidot, q_i (R fixo)
if RODAR_OTIM
  % SEPARA sintonia de estresse:
  %   tune   = degraus viaveis onde os 5 requisitos sao bem-postos (custo pleno)
  %   stress = zenite, entra so como GUARDA relaxada (nao briga com o tune)
  tune   = {cenDeg, cenDeg2};
  stress = {cenZen};

  [Qopt, Ropt] = otim.rodaFminsearch(P, tune, stress);
  G = controle.projetaGradeLQI(P, Qopt, Ropt);      % regrade com pesos otimos
  fprintf('Regrade com pesos do fminsearch concluida.\n');
end

%% T5 - Os tres cenarios do roadmap (tabela por cenario; GPS usa metrica de rampa)
for cen = {cenDeg, cenZen, cenGPS}
  analise.comparaMetodos(P, G, cen{1});
end

%% T6 - Robustez a erro de modelo (J_L +-20%) no metodo continuo
%  Ganhos vem do JL NOMINAL (design corrente G); a planta e simulada com JL errado.
figure('Color','w','Name','T6 erro de modelo'); hold on; grid on;
for f = [0.8 1.0 1.2]
  Perr = P; Perr.JL = P.JL*f;                        % planta com JL errado...
  out  = sim.simulaCenario(Perr, G, 'continuo', cenZen);   % ...ganhos nominais (G)
  plot(out.t, rad2deg(out.phi), 'DisplayName', sprintf('J_L x%.1f', f));
end
yline(rad2deg(cenZen.rfinal),'k--'); legend('Location','best');
title('T6: LQI mantem ess->0 mesmo com J_L errado (adaptar vs cancelar)');

%% T7 - Custo de controle por metodo (ja sai na tabela de comparaMetodos)
%  A coluna 'custo' = int u^2 dt. Compare fixo/chaveado/continuo na mesma trajetoria.

%% Entregavel - animacao
outAnim = sim.simulaCenario(P, G, 'continuo', cenGPS);
viz.animaAntena(outAnim, fullfile(here,'resultados','antena.mp4'));

disp('Pipeline concluido.');