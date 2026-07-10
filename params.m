function P = params()
% PARAMS  Retorna o struct P com TODOS os parametros do projeto CMC-12.
%   Um unico ponto de verdade. Todo arquivo recebe P e le daqui.
%
% Unidades SI (rad, rad/s, kg*m^2, N*m, s) salvo indicacao.

% ---------- Parametros fisicos da planta (azimute) ----------
P.JL   = 0.95;      % inercia da carga (antena Yagi CF-17), kg*m^2  [J=mL^2/3]
P.J0   = 0.02;      % PLACEHOLDER inercia constante (yoke + rotor refletido por N^2)
                    %   regulariza a singularidade do zenite; valor real vem do CAD SatNOGS
P.b    = 1;         % atrito viscoso de azimute, N*m*s/rad
                    %   chute por eficiencia do worm ~50%; REAVALIAR no teste de erro de modelo
P.N    = 30;        % reducao das engrenagens (1:30)

% ---------- Atuador (TPHSM refletido pelo eixo de saida) ----------
P.umax = 30.0;      % PLACEHOLDER saturacao de torque no eixo de azimute, N*m
                    %   ~torque de parada do motor * N * eficiencia; ajustar ao datasheet

% ---------- Grade de gain scheduling ----------
% Satura ANTES de 90 graus para o ganho da ultima fatia nao ficar impraticavel.
theta_max_deg = 85;                       % elevacao maxima da grade
rho_min = cosd(theta_max_deg)^2;          % ~0.0076
P.rho_grid = linspace(rho_min, 1, 20).';  % coluna, 20 nos de rho = cos^2(theta)

% ---------- Pesos LQI (ponto-semente / design point) ----------
% Q e 3x3 no estado aumentado [phi; phidot; xi] (ordem do lqi do MATLAB).
% q_phi pequeno de proposito: o lqi penaliza phi ABSOLUTO; o rastreio vem de q_i.
P.qphi    = 1e-3;   % peso de phi   (so molda transiente; mantem detectabilidade)
P.qphidot = 50;     % peso de phidot
P.qi      = 1;      % peso de xi = integral do erro (e o que zera ess)
P.R       = 0.1;    % peso do esforco de controle

% ---------- Requisitos de desempenho (alvos do custo) ----------
P.req.ess = deg2rad(1.5);   % erro em regime <= 1.5 deg
P.req.Mp  = 10;             % sobressinal <= 10 %
P.req.tr  = 3.0;            % tempo de subida <= 3 s
P.req.td  = 2.4;            % tempo de atraso <= 2.4 s
P.req.ts  = 6.0;            % tempo de acomodacao <= 6 s

% ---------- Otimizacao (fminsearch / Nelder-Mead) ----------
% MUDANCA-CHAVE: R fica FIXO durante a sintonia. Como no LQR/LQI so a razao
% Q/R fixa o ganho K, deixar Q e R livres cria uma direcao EXATAMENTE plana
% no custo (escalar Q e R juntos nao muda K, nem a trajetoria, nem o esforco).
% Fixando R matamos esse vale plano: sobram 2 variaveis efetivas (q_phidot, q_i).
P.otim.Rfix = 1.0;                          % R fixo na sintonia

% Reescala o ponto-semente para R=Rfix preservando EXATAMENTE o K do design point
% (so a razao importa: q/Rfix == q_antigo/P.R  =>  q = q_antigo*(Rfix/P.R)).
s = P.otim.Rfix / P.R;                       % = 10 com os valores acima
P.otim.qphi = P.qphi * s;                    % q_phi fixo, equivalente ao seed (1e-2)
P.otim.q0   = [P.qphidot; P.qi] * s;         % semente [q_phidot; q_i] em escala de Rfix ([500;10])

P.otim.lambda   = 1e-3;   % regularizacao de esforco -- SO aplicada DENTRO da viabilidade
P.otim.guardLo  = -8;     % guarda de faixa em log10 (fminsearch e irrestrito)
P.otim.guardHi  =  8;
P.otim.MaxFunEvals = 400; % orcamento por partida (tambem MaxIter)
P.otim.nStart   = 4;      % multi-start: partidas extras p/ fugir de minimo local
P.otim.verbose  = false;  % true imprime a decomposicao do custo por avaliacao

% Guarda de estresse (zenite): NAO exige os requisitos plenos la (a varredura
% do keyhole e dura). So penaliza, com limites relaxados e peso baixo, para o
% otimizador nao ESCOLHER um design que exploda no zenite -- sem deixar o
% zenite BRIGAR com os requisitos do cenario de sintonia.
P.otim.stress_relax = 2.0;   % limites relaxados = 2x o requisito nominal
P.otim.wstr         = 0.3;   % peso da guarda de estresse no custo

end