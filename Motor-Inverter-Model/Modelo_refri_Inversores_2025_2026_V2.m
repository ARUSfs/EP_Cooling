clear; clc; close all;

%% CARGA DATOS
ruta = fullfile(pwd, 'Matrices de datos');
addpath(ruta);
S = load('Inv_modrefriART26.mat');

time = S.tiempo(:);

P_inv_FL = S.P_FL(:);
P_inv_FR = S.P_FR(:);
P_inv_RL = S.P_RL(:);
P_inv_RR = S.P_RR(:);

[time, idxu] = unique(time, 'stable');
P_inv_FL = P_inv_FL(idxu)/1.5;
P_inv_FR = P_inv_FR(idxu)/1.5;
P_inv_RL = P_inv_RL(idxu)/1.5;
P_inv_RR = P_inv_RR(idxu)/1.5;

%% PARAMETROS AGUA / AMBIENTE 
rho   = 1000;   % kg/m3
Cp_w  = 4180;   % J/kgK
T_amb = 25;     % C

%% CAUDAL AGUA
Q_Lpm = 3.18;
Q_m3s = Q_Lpm/1000/60;
mdot  = rho*Q_m3s;

%% GEOMETRIA / TRANSFERENCIA
A_cp  = 0.672;      % [m^2] agua<->coldplate 

% Radiador (aire)
A_rad = 0.03776;          % [m^2] area efectiva radiador
h_cp  = 2500;          % [W/m2K] agua<->coldplate 
h_rad = 1243;        % [W/m2K] aire<->radiador 

UA_rad = h_rad*A_rad;  % [W/K]

%% INVERSOR -> COLDPLATE
e_pad = 0.5e-3;   % m
k_pad = 6;        % W/mK
h_pad = k_pad/e_pad;

A_pad = 0.009217; % [m2] area contacto de cada inversor con coldplate
fprintf('h_pad = %.0f W/m2K\n', h_pad);

%%  MASAS TERMICAS
m_cp   = 1.156;     % kg
c_cp   = 500;     % J/kgK
Cth_cp = m_cp*c_cp;

% Inversores 
m_inv   = 1.1;    % kg 
c_inv   = 900;    % J/kgK
Cth_inv = m_inv*c_inv;

% Agua en el coldplate 
V_w_cp = 0.00012238;     % [m3]
m_w_cp = rho*V_w_cp;     % [kg]

% Agua en el radiador 
V_w_rad = 0.000152;    % [m3] 
m_w_rad = rho*V_w_rad;   % [kg]

fprintf('m_w_cp  = %.3f kg (V_cp  = %.3f L)\n', m_w_cp,  V_w_cp*1000);
fprintf('m_w_rad = %.3f kg (V_rad = %.3f L)\n', m_w_rad, V_w_rad*1000);

%% ====== FUNCIONES DE POTENCIA ======
P_inv_FL_fun = @(t) interp1(time, P_inv_FL, t, 'linear', 'extrap');
P_inv_FR_fun = @(t) interp1(time, P_inv_FR, t, 'linear', 'extrap');
P_inv_RL_fun = @(t) interp1(time, P_inv_RL, t, 'linear', 'extrap');
P_inv_RR_fun = @(t) interp1(time, P_inv_RR, t, 'linear', 'extrap');

%% ODE
% x(1)=T_w_cp
% x(2)=T_w_rad
% x(3)=T_cp
% x(4)=T_inv_FL
% x(5)=T_inv_FR
% x(6)=T_inv_RL
% x(7)=T_inv_RR

x0    = 25*ones(7,1);
tspan = [time(1) time(end)];

odefun = @(t,x) ode_inv_4pads_wheels( ...
    t,x, mdot,Cp_w,T_amb,UA_rad, ...
    h_cp,A_cp, h_pad,A_pad, ...
    Cth_cp,Cth_inv, m_w_cp,m_w_rad, ...
    P_inv_FL_fun,P_inv_FR_fun,P_inv_RL_fun,P_inv_RR_fun);

opts = odeset('RelTol',1e-6,'AbsTol',1e-6);
[t_sol,x_sol] = ode45(odefun,tspan,x0,opts);

T_w_cp   = x_sol(:,1);
T_w_rad  = x_sol(:,2);
T_cp     = x_sol(:,3);
T_inv_FL = x_sol(:,4);
T_inv_FR = x_sol(:,5);
T_inv_RL = x_sol(:,6);
T_inv_RR = x_sol(:,7);

P_rad = UA_rad.*max(T_w_rad - T_amb, 0);
%% AIRE EN RADIADOR
mdot_air = 0.0768;    % [kg/s]  (76.8 g/s)
Cp_air   = 1005;      % [J/kgK]
T_air_in = T_amb;     % [C] 
T_air_out = T_air_in + P_rad./(mdot_air*Cp_air);   % [C]


%% ====== RESULTADOS ======
fprintf('\n=== RESULTADOS (FL/FR/RL/RR) + PAD + CP ===\n');
fprintf('Caudal: %.2f L/min\n', Q_Lpm);
fprintf('T final agua salida coldplate: %.2f C\n', T_w_cp(end));
fprintf('T final agua salida radiador:  %.2f C\n', T_w_rad(end));
fprintf('T final coldplate:             %.2f C\n', T_cp(end));
fprintf('T final inv FL: %.2f | FR: %.2f | RL: %.2f | RR: %.2f C\n', ...
    T_inv_FL(end), T_inv_FR(end), T_inv_RL(end), T_inv_RR(end));
fprintf('P media radiador: %.1f W\n', mean(P_rad));
fprintf('P max radiador:   %.1f W\n', max(P_rad));
fprintf('==========================================\n');

%% ====== GRAFICAS ======
figure('Color','w');
plot(t_sol,T_cp,'k','LineWidth',1.8); hold on;
plot(t_sol,T_w_cp,'r--','LineWidth',1.5);
plot(t_sol,T_w_rad,'b--','LineWidth',1.5);
plot(t_sol,T_inv_FL,'LineWidth',1.2);
plot(t_sol,T_inv_FR,'LineWidth',1.2);
plot(t_sol,T_inv_RL,'LineWidth',1.2);
plot(t_sol,T_inv_RR,'LineWidth',1.2);
grid on; xlabel('t [s]'); ylabel('T [C]');
legend('T_{cp}','T_{w,cp}','T_{w,rad}', ...
       'T_{inv,FL}','T_{inv,FR}','T_{inv,RL}','T_{inv,RR}', ...
       'Location','best');
title('Evolucion termica inversores');

figure('Color','w');
plot(t_sol, P_rad/1000,'LineWidth',1.8);
grid on; xlabel('t [s]'); ylabel('P_{rad} [kW]');
title('Potencia disipada por el radiador');

%% ====== FUNCION AUXILIAR ======
function dx = ode_inv_4pads_wheels(t,x,mdot,Cp_w,T_amb,UA_rad, h_cp,A_cp, h_pad,A_pad, Cth_cp,Cth_inv, m_w_cp,m_w_rad, ...
                                  PFL,PFR,PRL,PRR)

T_w_cp  = x(1);
T_w_rad = x(2);
T_cp    = x(3);
TFL     = x(4);
TFR     = x(5);
TRL     = x(6);
TRR     = x(7);

P_inv_FL = PFL(t);
P_inv_FR = PFR(t);
P_inv_RL = PRL(t);
P_inv_RR = PRR(t);

Q_FL = h_pad*A_pad*(TFL - T_cp);
Q_FR = h_pad*A_pad*(TFR - T_cp);
Q_RL = h_pad*A_pad*(TRL - T_cp);
Q_RR = h_pad*A_pad*(TRR - T_cp);

Q_cp_to_w = h_cp*A_cp*(T_cp - T_w_cp);
Q_rad     = UA_rad*max(T_w_rad - T_amb, 0);

dT_w_cp  = (mdot*Cp_w*(T_w_rad - T_w_cp) + Q_cp_to_w) / (m_w_cp*Cp_w);
dT_w_rad = (mdot*Cp_w*(T_w_cp - T_w_rad) - Q_rad)     / (m_w_rad*Cp_w);

dT_cp = (Q_FL + Q_FR + Q_RL + Q_RR - Q_cp_to_w) / Cth_cp;

dTFL = (P_inv_FL - Q_FL) / Cth_inv;
dTFR = (P_inv_FR - Q_FR) / Cth_inv;
dTRL = (P_inv_RL - Q_RL) / Cth_inv;
dTRR = (P_inv_RR - Q_RR) / Cth_inv;

dx = [dT_w_cp; dT_w_rad; dT_cp; dTFL; dTFR; dTRL; dTRR];
end
