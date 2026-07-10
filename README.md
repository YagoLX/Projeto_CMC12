# Controle de Azimute de Antenna Rotator com Inércia Variável


Controle do eixo de **azimute** de um *antenna rotator* cuja inércia efetiva depende do ângulo de elevação, tornando a planta não-linear. Estratégia principal: **LQI com *gain scheduling*** com controlador otimizado numericamente (`fminsearch`); comparador: **linearização por realimentação**.

---

## 1. O problema

Uma antena Yagi montada em um rotator de dois eixos precisa rastrear em azimute (`φ`) um alvo enquanto a elevação (`θ`) varia. A inércia que o eixo de azimute "enxerga" não é constante:

```
J(θ) = J0 + J_L·cos²(θ)
```

- No **horizonte** (`θ = 0°`): `J` é máximo (a antena está deitada, braço de alavanca total).
- No **zênite** (`θ → 90°`): `J_L·cos²θ → 0`; sobra apenas o termo residual `J0`. A planta quase degenera (fenômeno tipo *keyhole/gimbal*).

Um controlador de ganho fixo sintonizado no horizonte fica **agressivo demais** perto do zênite, porque o ganho de entrada `1/J` cresce cerca de 36×. Demonstrar essa falha e corrigi-la com escalonamento de ganho é o núcleo do trabalho.

### Requisitos de desempenho

| Métrica | Alvo |
|---|---|
| Erro em regime (`e_ss`) | ≤ 1,5° |
| Sobressinal (`M_p`) | ≤ 10 % |
| Tempo de subida (`t_r`) | ≤ 3 s |
| Tempo de atraso (`t_d`) | ≤ 2,4 s |
| Tempo de acomodação (`t_s`) | ≤ 6 s |

---

## 2. Teoria Resumida

### 2.1 Dinâmica do azimute

Derivando `d/dt(J(θ)·φ̇)` e somando atrito, chega-se à equação que a simulação integra de verdade:

```
[J0 + J_L·cos²θ]·φ̈  −  2·J_L·cosθ·sinθ·θ̇·φ̇  +  b·φ̇  =  u
        └── inércia variável ──┘   └──── Coriolis/reação ────┘   └ atrito ┘
```

O termo de **Coriolis** só existe quando a elevação se move (`θ̇ ≠ 0`) — ele acopla o movimento de elevação ao de azimute. Na escala do laço de azimute ele se comporta como um distúrbio, que o integrador do LQI rejeita.

Parâmetro de escalonamento: `ρ = cos²(θ) ∈ [0, 1]`. Como a elevação varia devagar frente ao laço de azimute, tratamos `ρ` como **parâmetro congelado** ao projetar os ganhos.

### 2.2 Modelo congelado (para projeto)

Com `θ̇ = 0`, o Coriolis some e sobra um duplo integrador amortecido. Estado `x = [φ; φ̇]`:

```
A(ρ) = [0      1   ]      B(ρ) = [ 0  ]      C = [1 0]
       [0   −b/J  ]             [1/J ]
```

com `J = J0 + J_L·ρ`. É sobre este modelo, avaliado em cada `ρ` da grade, que se resolve o LQI.

### 2.3 LQI (LQR com ação integral)

Aumenta-se o estado com o integrador do erro `ξ = ∫(r − φ)dt` para zerar o erro em regime (sistema tipo 1). O `lqi` do MATLAB monta o estado aumentado `[φ; φ̇; ξ]`, resolve o Riccati e devolve `K = [K_φ  K_φ̇  K_i]`; a lei é `u = −K·[φ; φ̇; ξ]`.

Os pesos `Q` (estado) e `R` (esforço) são os botões de projeto. Detalhe explorado no código: **só a razão `Q/R` fixa `K`** — escalar `Q` e `R` juntos não muda nada. Por isso a otimização **fixa `R`** e varia apenas `q_φ̇` e `q_i`, eliminando uma direção plana no custo.

### 2.4 Gain scheduling

Resolve-se o LQI numa grade de `ρ`, guarda-se `K(ρ)` e interpola-se online pela leitura do encoder de elevação. Três variantes são comparadas:

- **`fixo`** — um único `K` (horizonte). É o *baseline* que **falha** perto do zênite.
- **`chaveado`** — usa o ganho do nó mais próximo da grade.
- **`contínuo`** — interpola linearmente entre nós (método principal).

### 2.5 Comparador: linearização por realimentação

Em vez de adaptar o ganho, **cancela-se** a não-linearidade: `u = J(θ)·v + b·φ̇` deixa `φ̈ = v` (duplo integrador limpo), sobre o qual roda um LQR único. O contraste *adaptar vs. cancelar* é testado sob erro de modelo (`J_L` errado ±20 %).

### 2.6 Otimização dos pesos (`fminsearch`)

Um simplex de Nelder-Mead sintoniza `[log₁₀ q_φ̇, log₁₀ q_i]` (escala log garante positividade). A função-objetivo penaliza violação relativa de cada requisito, com uma **guarda relaxada** para o zênite (para o otimizador não escolher um design que exploda lá, sem deixar o zênite brigar com os requisitos do cenário de sintonia). É otimização local; um bloco *multi-start* reduz sensibilidade a mínimo local.

---

## 3. Arquitetura

Código MATLAB organizado em pacotes (pastas `+nome`). O fluxo de dados é:

```
params ──► projetaGradeLQI ──► K(ρ)
                                 │
   cenário ──► simulaCenario ────┤  (ode45 na planta NÃO-LINEAR completa)
                     │           │
                     ├─ interpolaGanho(ρ, modo) ── escolhe K online
                     ├─ leiControle ───────────── LQI + saturação + anti-windup
                     └─ plantaNaoLinear ───────── RHS com Coriolis
                                 │
        métricas / comparações / plots / animação
```

| Pacote | Papel |
|---|---|
| `+modelo` | Planta: `matrizesPlanta` (modelo congelado p/ projeto) e `plantaNaoLinear` (RHS real, com Coriolis). |
| `+controle` | `projetaGradeLQI` (resolve o LQI na grade), `interpolaGanho` (as 3 variantes), `leiControle` (lei + saturação + anti-windup por *clamping*). |
| `+otim` | `custoOtim` (função-objetivo) e `rodaFminsearch` (Nelder-Mead + multi-start). |
| `+sim` | `simulaCenario` (integra a malha fechada), `avaliaBateria` (piores métricas de um conjunto), e os cenários `cenarioDegrau`/`cenarioZenite`/`cenarioGPS`. |
| `+analise` | `controlabilidade`, `metricasDesempenho` (degrau), `metricasRastreio` (rampa), `comparaMetodos` (tabela comparativa). |
| `+viz` | `plotComparacoes` (φ e u sobrepostos) e `animaAntena` (vídeo do entregável). |
| `params.m` | Fonte única de verdade dos parâmetros. |
| `main.m` | Orquestrador — roda o pipeline inteiro na ordem do roadmap. |

---

## 4. Como rodar

Requisitos: **MATLAB** com **Control System Toolbox** (`lqi`, `ss`, `step`, `stepinfo`). O `fminsearch` é nativo — sem dependência externa.

```matlab
% a partir da raiz do projeto
main
```

`main.m` executa, em ordem:

1. **T1** — controlabilidade/condicionamento na grade.
2. Projeto da grade LQI com pesos-semente + resposta ao degrau congelado por `ρ` (**T2**).
3. **T3** — *baseline* fixo na planta não-linear: demonstra a falha no zênite.
4. **T4** — fixo vs. chaveado vs. contínuo no mesmo cenário + tabela.
5. **Otimização** (`RODAR_OTIM = true`; lento) — regride a grade com os pesos do `fminsearch`.
6. **T5** — os três cenários (degrau, zênite, GPS) com métricas por tipo.
7. **T6** — robustez a erro de modelo (`J_L` ±20 %).
8. **Entregável** — animação salva em `resultados/antena.mp4`.

Para uma passada rápida (sem sintonia), defina `RODAR_OTIM = false` no topo de `main.m`.

---

## 5. Parâmetros principais (`params.m`)

| Símbolo | Valor | Significado |
|---|---|---|
| `J_L` | 0,95 kg·m² | Inércia da carga (Yagi CF-17, `J = mL²/3`). |
| `J0` | 0,02 kg·m² | **Placeholder** — inércia residual que regulariza o zênite. |
| `b` | 1 N·m·s/rad | Atrito viscoso. **Reavaliar** no teste de erro de modelo. |
| `N` | 30 | Redução das engrenagens (1:30). |
| `u_max` | 30 N·m | **Placeholder** — saturação de torque no eixo de saída. |
| grade `ρ` | 20 nós, `θ ∈ [0°, 85°]` | Satura antes de 90° para o último ganho não ficar impraticável. |

> ⚠️ `J0`, `u_max` e `b` são **placeholders** marcados no código. Enquanto não vierem do CAD do SatNOGS / datasheet do motor / teste real, os números do relatório são provisórios, futuramente serão medidos empiricamente.

---

## 6. Limitações e pontos de atenção conhecidos

- **Extrapolação da grade no zênite.** A grade satura em 85° (`ρ_min ≈ 0,0076`), mas o cenário de zênite chega a 89,5° (`ρ ≈ 7,6e-5`). No modo `contínuo`, a interpolação **extrapola** além do último nó justamente ali. O modo `chaveado` clampa (mais seguro). Recomenda-se saturar `ρ ← max(ρ, ρ_min)` ou estender a grade antes de gerar os resultados finais.
- **Anti-windup depende de `K_i < 0`.** A regra de *clamping* em `leiControle` só é correta porque o LQI estável garante `K_i < 0` nesta convenção. Um `assert(K(3) < 0)` em `projetaGradeLQI` blindaria contra pesos patológicos.
- **RHS não-suave.** Saturação + `if` do *clamping* deixam o lado direito da ODE não-C¹; o `ode45` pode picar passo na chave. Há fallback comentado (versão suavizada / `ode15s`) — considerar torná-lo padrão no cenário de zênite.
- **Coriolis é pequeno aqui.** Nas condições do cenário (`θ̇ = 20°/s`), o Coriolis fica na casa de 0,1 N·m contra `u_max = 30`. O que realmente estressa o zênite é a queda de `J` (~36×), não o Coriolis.
- **GPS é rampa.** O LQI tipo 1 deixa *lag* de velocidade finito a uma rampa — verificar `metricasRastreio.ess` contra o limite de 1,5°, não assumir zero.

---

## 7. Referências

- Slotine & Li, *Applied Nonlinear Control* (1991) — linearização por realimentação.
- Khalil, *Nonlinear Systems* (3ª ed.), cap. 13.
- Ogata, *Modern Control Engineering* — LQR e espaço de estados.
- Rugh & Shamma (2000); Shamma & Athans, *Gain scheduling: potential hazards and possible remedies* — alerta sobre variação rápida do parâmetro (relevante ao zênite).
- Nelder & Mead (1965); Lagarias et al. (1998) — método por trás do `fminsearch`.
- TG de referência (parâmetros e requisitos): C. J. M. Campos, *Projeto de um Sistema de Controle de Antena para Rastreio de Sonda Estratosférica*, ITA, 2024.
