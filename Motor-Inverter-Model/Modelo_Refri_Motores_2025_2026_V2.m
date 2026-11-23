%% MODELO DE REFRIGERACIÓN MOTORES ART26 


clear;clc;close all;

%% Parámetros de entrada
ruta = fullfile(pwd, 'Matrices de datos');
addpath(ruta);
load('Inv_modrefriART26.mat','tiempo','loss_motor_FL','loss_motor_FR','loss_motor_RR','loss_motor_RL');
load('Bomb_curve.mat','Q_bomb','H_bomb');

[tiempo, idxu] = unique(tiempo, 'stable');
loss_motor_FL = loss_motor_FL(idxu);
loss_motor_FR = loss_motor_FR(idxu);
loss_motor_RL = loss_motor_RL(idxu);
loss_motor_RR = loss_motor_RR(idxu);

Q_LPM=4.47;
Q_m3s=Q_LPM*1e-3/60;

%% Parámetros del agua

rho=1000;
cp=4180;
T_amb=25;
mdot=rho*Q_m3s;

%% GEOMETRÍA DEL SERPENTÍN

Di=48.95e-3;
Do=58.95e-3;
Dm=0.5*(Di+Do);
L_serp=2.0;
Dh=Di;

As_serp=0.085;
V_serp=1.507e-4;
m_w_serp=0.151;

%% RADIADOR

A_rad=0.03776;
h_rad=1383;
V_rad=0.000287;
m_w_rad=rho*V_rad;

%% MOTORES

m_motor=3.65;
cp_motor=500;
C_th_motor=m_motor*cp_motor;

%% SERPENTÍN

m_serp_metal=0.50;          % [kg] 
cp_serp_metal=500;          % [J/kg/K] 
C_th_serp=m_serp_metal*cp_serp_metal;

%% PASTA TÉRMICA motor-serpentín

k_paste=2;                  % [W/m/K]
e_paste=135e-6;             % [m]
h_paste=k_paste/e_paste;    % [W/m^2/K] 

fprintf('h_pasta=k/e=%.2f/%.0fum=%.1f W/m2K\n',k_paste,e_paste*1e6,h_paste);

%% CONVECCIÓN serpentín-agua 

h_sw=1575;                  % [W/m^2/K] +

%% PÉRDIDAS DE LOS MOTORES

P_FL_fun=@(t)interp1(tiempo,loss_motor_FL,t,'linear','extrap');
P_FR_fun=@(t)interp1(tiempo,loss_motor_FR,t,'linear','extrap');
P_RR_fun=@(t)interp1(tiempo,loss_motor_RR,t,'linear','extrap');
P_RL_fun=@(t)interp1(tiempo,loss_motor_RL,t,'linear','extrap');

%% Curva de la bomba

H_atQ=interp1(Q_bomb,H_bomb,Q_LPM,'linear','extrap');
DeltaP_bomb=rho*9.81*H_atQ;
DeltaP_bomb_bar=DeltaP_bomb/1e5;

fprintf('Presión que debe aportar la bomba a Q=%.2f L/min: %.3f bar (H=%.2f m)\n',Q_LPM,DeltaP_bomb_bar,H_atQ);

%% SIMULACIÓN (ODE45)

T0=T_amb;

% Estados:
% [Tm_FL Tm_FR Tm_RR Tm_RL  Ts_FL Ts_FR Ts_RR Ts_RL  Tw_FL Tw_FR Tw_RR Tw_RL  T_rad]'
x0=T0*ones(13,1);
tspan=[tiempo(1) tiempo(end)];

params.mdot=mdot;
params.cp=cp;
params.As_serp=As_serp;
params.m_w_serp=m_w_serp;
params.m_w_rad=m_w_rad;
params.A_rad=A_rad;
params.h_rad=h_rad;
params.C_th_motor=C_th_motor;
params.C_th_serp=C_th_serp;
params.h_paste=h_paste;
params.h_sw=h_sw;
params.T_amb=T_amb;
params.P_FL_fun=P_FL_fun;
params.P_FR_fun=P_FR_fun;
params.P_RR_fun=P_RR_fun;
params.P_RL_fun=P_RL_fun;

odefun=@(t,x)refri_motores_serie_ode_v3(t,x,params);

opts=odeset('RelTol',1e-6,'AbsTol',1e-6,'OutputFcn',@ode_progress);
[t_sol,x_sol]=ode45(odefun,tspan,x0,opts);

Tm_FL=x_sol(:,1);
Tm_FR=x_sol(:,2);
Tm_RR=x_sol(:,3);
Tm_RL=x_sol(:,4);

Ts_FL=x_sol(:,5);
Ts_FR=x_sol(:,6);
Ts_RR=x_sol(:,7);
Ts_RL=x_sol(:,8);

Tw_FL=x_sol(:,9);
Tw_FR=x_sol(:,10);
Tw_RR=x_sol(:,11);
Tw_RL=x_sol(:,12);

T_rad=x_sol(:,13);

P_rad=h_rad*A_rad*(T_rad-T_amb);
%% ====== AIRE EN RADIADOR ======
mdot_air = 0.0768;    % [kg/s]  (76.8 g/s)
Cp_air   = 1005;      % [J/kgK]
T_air_in = T_amb;     % [C] 
T_air_out = T_air_in + P_rad./(mdot_air*Cp_air);   % [C]


%% RESULTADOS

fprintf('\n=== RESULTADOS ===\n');
fprintf('Tiempo simulado: %.1f s\n',t_sol(end)-t_sol(1));
fprintf('Temperaturas finales motores [°C]: FL=%.2f FR=%.2f RR=%.2f RL=%.2f\n',Tm_FL(end),Tm_FR(end),Tm_RR(end),Tm_RL(end));
fprintf('Temperaturas finales serpentín metal [°C]: FL=%.2f FR=%.2f RR=%.2f RL=%.2f\n',Ts_FL(end),Ts_FR(end),Ts_RR(end),Ts_RL(end));
fprintf('Temperaturas finales agua [°C]: FL=%.2f FR=%.2f RR=%.2f RL=%.2f Rad=%.2f\n',Tw_FL(end),Tw_FR(end),Tw_RR(end),Tw_RL(end),T_rad(end));
fprintf('Potencia media radiador: %.1f W\n',mean(P_rad));
fprintf('Potencia máxima radiador: %.1f W\n',max(P_rad));
fprintf('Presión bomba a Q=%.2f L/min: %.3f bar\n',Q_LPM,DeltaP_bomb_bar);
fprintf('============================\n');

%% GRÁFICAS

figure('Name','Temperaturas motores/serpentin/agua','Color','w');
plot(t_sol,Tm_FL,'r','LineWidth',1.3);hold on;
plot(t_sol,Tm_FR,'m','LineWidth',1.3);
plot(t_sol,Tm_RR,'c','LineWidth',1.3);
plot(t_sol,Tm_RL,'k','LineWidth',1.3);

plot(t_sol,Ts_FL,'--r','LineWidth',1.0);
plot(t_sol,Ts_FR,'--m','LineWidth',1.0);
plot(t_sol,Ts_RR,'--c','LineWidth',1.0);
plot(t_sol,Ts_RL,'--k','LineWidth',1.0);

plot(t_sol,Tw_FL,':r','LineWidth',1.2);
plot(t_sol,Tw_FR,':m','LineWidth',1.2);
plot(t_sol,Tw_RR,':c','LineWidth',1.2);
plot(t_sol,Tw_RL,':k','LineWidth',1.2);

plot(t_sol,T_rad,'g','LineWidth',1.5);

xlabel('t [s]');ylabel('Temperatura [°C]');
title('Evolución de temperaturas en el circuito de motores ');
grid on;
legend({'T_{m,FL}','T_{m,FR}','T_{m,RR}','T_{m,RL}',...
        'T_{s,FL}','T_{s,FR}','T_{s,RR}','T_{s,RL}',...
        'T_{w,FL}','T_{w,FR}','T_{w,RR}','T_{w,RL}',...
        'T_{rad}'},'Location','best');

figure('Name','Potencia radiador','Color','w');
plot(t_sol,P_rad/1000,'LineWidth',1.5);
xlabel('t [s]');ylabel('P_{rad} [kW]');
title('Potencia disipada en el radiador');
grid on;

%% FUNCIONES AUXILIARES
function dx=refri_motores_serie_ode_v3(t,x,p)
% x=[Tm_FL Tm_FR Tm_RR Tm_RL  Ts_FL Ts_FR Ts_RR Ts_RL  Tw_FL Tw_FR Tw_RR Tw_RL  T_rad]'

Tm_FL=x(1);Tm_FR=x(2);Tm_RR=x(3);Tm_RL=x(4);
Ts_FL=x(5);Ts_FR=x(6);Ts_RR=x(7);Ts_RL=x(8);
Tw_FL=x(9);Tw_FR=x(10);Tw_RR=x(11);Tw_RL=x(12);
T_rad=x(13);

mdot=p.mdot;cp=p.cp;As=p.As_serp;
m_w=p.m_w_serp;m_wrad=p.m_w_rad;
A_rad=p.A_rad;h_rad=p.h_rad;
C_m=p.C_th_motor;C_s=p.C_th_serp;
h_p=p.h_paste;h_sw=p.h_sw;
T_amb=p.T_amb;

P_FL=p.P_FL_fun(t);
P_FR=p.P_FR_fun(t);
P_RR=p.P_RR_fun(t);
P_RL=p.P_RL_fun(t);

T_in_FL=T_rad;
T_in_FR=Tw_FL;
T_in_RR=Tw_FR;
T_in_RL=Tw_RR;
T_in_rad=Tw_RL;

Qms_FL=h_p*As*(Tm_FL-Ts_FL);
Qms_FR=h_p*As*(Tm_FR-Ts_FR);
Qms_RR=h_p*As*(Tm_RR-Ts_RR);
Qms_RL=h_p*As*(Tm_RL-Ts_RL);

Qsw_FL=h_sw*As*(Ts_FL-Tw_FL);
Qsw_FR=h_sw*As*(Ts_FR-Tw_FR);
Qsw_RR=h_sw*As*(Ts_RR-Tw_RR);
Qsw_RL=h_sw*As*(Ts_RL-Tw_RL);

dTm_FL=(P_FL-Qms_FL)/C_m;
dTm_FR=(P_FR-Qms_FR)/C_m;
dTm_RR=(P_RR-Qms_RR)/C_m;
dTm_RL=(P_RL-Qms_RL)/C_m;

dTs_FL=(Qms_FL-Qsw_FL)/C_s;
dTs_FR=(Qms_FR-Qsw_FR)/C_s;
dTs_RR=(Qms_RR-Qsw_RR)/C_s;
dTs_RL=(Qms_RL-Qsw_RL)/C_s;

dTw_FL=(mdot*cp*(T_in_FL-Tw_FL)+Qsw_FL)/(m_w*cp);
dTw_FR=(mdot*cp*(T_in_FR-Tw_FR)+Qsw_FR)/(m_w*cp);
dTw_RR=(mdot*cp*(T_in_RR-Tw_RR)+Qsw_RR)/(m_w*cp);
dTw_RL=(mdot*cp*(T_in_RL-Tw_RL)+Qsw_RL)/(m_w*cp);

dT_rad=(mdot*cp*(T_in_rad-T_rad)-h_rad*A_rad*(T_rad-T_amb))/(m_wrad*cp);

dx=zeros(13,1);
dx(1)=dTm_FL;dx(2)=dTm_FR;dx(3)=dTm_RR;dx(4)=dTm_RL;
dx(5)=dTs_FL;dx(6)=dTs_FR;dx(7)=dTs_RR;dx(8)=dTs_RL;
dx(9)=dTw_FL;dx(10)=dTw_FR;dx(11)=dTw_RR;dx(12)=dTw_RL;
dx(13)=dT_rad;
end

function stop=ode_progress(t,~,flag)
stop=false;
persistent last_t
if strcmp(flag,'init')
last_t=0;
fprintf('Iniciando simulación...\n');
elseif isempty(flag)
if t(end)-last_t>=1
fprintf('Simulación en t=%.1f s\n',t(end));
last_t=t(end);
end
elseif strcmp(flag,'done')
fprintf('Simulación terminada.\n');
end
end

