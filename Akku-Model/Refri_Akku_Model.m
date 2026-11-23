%% PARÁMETROS DE ENTRADA

Re0=2300; % primer valor del número de reynols
Ptot=800*11; % Potencia TOTAL disipada (800 W por megatab)
Tamb=25; % Temperatura ambiente (ºC)
N_vc=11; % numero de volumenes de control
h0=2300; % primer valor del coeficiente de convección(W/(m^2K)) para el bucle 
Tlim=60; % temperatura máxima(ºC) que puede alcanzar el último tab(el más caliente)
A_canal=(93*14-4*25+pi*25)*10^-6; % Área de una canalización (m^2)
P_mojado=(2*(93-10)+2*(14-10)+10*pi)*10^-3; % perímetro del canal (m)
D_h=4*A_canal/P_mojado; % diámetro hidráulico del canal (m)

% PROPIEDADES DEL AIRE (CONDICIONES DE ENTRADA)
Tref=Tamb; 
[rho_int, mu_int, k_int, cp_int]=consultar_tabla(Tref);

%% PRIMERA APROXIMACIÓN DEL CAUDAL
Q0s=2*2300*mu_int*A_canal/(rho_int*D_h); % caudal en m^3/s
Q0min=Q0s*60; % caudal en m^3/min


%% REPARTO DE POTENCIA ENTRE VOLÚMENES
% Primera aproximación: todos disipan la misma potencia
Pdis= (Ptot/N_vc)*ones(1,N_vc); % Perdidas en cada VC (N_vc potencias)
 
% GEOMETRIA EQUIVALENTE
A_mega=0.01632; % m^2. Area del megatab expuesta al flujo de aire
A_conv=A_mega*ones(1,N_vc); % vector con el area de cada megatab (de momento iguales)% RESISTENCIA TERMICA DE CONVECCION
R_conv=1./(h0.*A_conv); %K/W

%% CALCULO DEL CAUDAL MASICO PARA h0

% Comprobamos que hemos introducido un area valida (finita y positiva)
if ~isfinite(A_mega) || A_mega <= 0
    error('Introduce en A_mega el area expuesta del megatab, en m^2.');
end

% Potencia del ultimo subnivel y de los anteriores
P_ultimo = Pdis(N_vc);
P_antes = sum(Pdis(1:N_vc-1));

% Salto de temperatura entre el ultimo megatab y su aire medio
DeltaT_conv = P_ultimo * R_conv(N_vc);

% Margen disponible para el calentamiento medio del aire
DeltaT_disponible = Tlim - Tamb - DeltaT_conv;

if DeltaT_disponible <= 0
    error('Con esta area y este h, ningun caudal finito cumple T_lim.');
end

% Caudal masico necesario
m_dot = (P_antes + P_ultimo/2) / (cp_int * DeltaT_disponible);  % kg/s

% CONVERSION A CAUDAL VOLUMETRICO
Q_m3s = m_dot / rho_int;  % m^3/s, a la temperatura de referencia
Q_m3min = 60 * Q_m3s;    % m^3/min
%% TEMPERATURAS EN LOS VOLUMENES DE CONTROL

% Un valor por subnivel
Tin  = zeros(1, N_vc);
Tout = zeros(1, N_vc);
Tair = zeros(1, N_vc);
Ttab = zeros(1, N_vc);

% Entrada al primer volumen
Tin(1) = Tamb;

for k = 1:N_vc

    % Balance energetico del aire
    Tout(k) = Tin(k) + Pdis(k)/(m_dot * cp_int);

    % Temperatura media del aire
    Tair(k) = (Tin(k) + Tout(k))/2;

    % Temperatura del megatab
    Ttab(k) = Tair(k) + Pdis(k)*R_conv(k);

    % La salida de este volumen alimenta el siguiente
    if k < N_vc
        Tin(k+1) = Tout(k);
    end

end
