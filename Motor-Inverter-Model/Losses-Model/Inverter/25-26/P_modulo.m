function Pmodulo = P_modulo(Ia,Ib,Ic,Uact)

Uref = 600;
Iref = 200;


%%
%Corriente por cada transistor

IS1_p = max(Ia,0);
IS1_n = min(Ia,0);

IS2_p = max(Ib,0);
IS2_n = min(Ib,0);

IS3_p = max(Ic,0);
IS3_n = min(Ic,0);



%% 
%Tensión umbral de cada transistor

Vce_S1_p = Vce_Ic(IS1_p,Tunion);
Vce_S1_n = -Vce_Ic(abs(IS1_n),Tunion);

Vce_S2_p = Vce_Ic(IS2_p,Tunion);
Vce_S2_n = -Vce_Ic(abs(IS2_n),Tunion);

Vce_S3_p = Vce_Ic(IS3_p,Tunion);
Vce_S3_n = -Vce_Ic(abs(IS3_n),Tunion);


%Pérdidas de conducción de IGBT

PcondS1_p = Vce_S1_p.*IS1_p;
PcondS1_n = Vce_S1_n.*IS1_n;

PcondS2_p = Vce_S2_p.*IS2_p;
PcondS2_n = Vce_S2_n.*IS2_n;

PcondS3_p = Vce_S3_p.*IS3_p;
PcondS3_n = Vce_S3_n.*IS3_n;

%%
%Energía commutación de cada transistor

EonS1_p = Eon_Ic(IS1_p,Tunion);
EonS1_n = Eon_Ic(abs(IS1_p),Tunion);

EonS2_p = Eon_Ic(IS2_p,Tunion);
EonS2_n = Eon_Ic(abs(IS2_n),Tunion);

EonS3_p = Eon_Ic(IS3_p,Tunion);
EonS3_n = Eon_Ic(abs(IS3_n),Tunion);

EoffS1_p = Eoff_Ic(IS1_p,Tunion);
EoffS1_n = Eoff_Ic(abs(IS1_n),Tunion);

EoffS2_p = Eoff_Ic(IS2_p,Tunion);
EoffS2_n = Eoff_Ic(abs(IS2_n),Tunion);

EoffS3_p = Eoff_Ic(IS3_p,Tunion);
EoffS3_n = Eoff_Ic(abs(IS3_n),Tunion);

%Pérdidas de conmutación de cada IGBT

PcommS1_p = (EonS1_p + EoffS1_p) * fcom .* (Uact/Uref) .* (IS1_p/Iref);
PcommS1_n = (EonS1_n + EoffS1_n) * fcom .* (Uact/Uref) .* (abs(IS1_n)/Iref);

PcommS2_p = (EonS2_p + EoffS2_p) * fcom .* (Uact/Uref) .* (IS1_p/Iref);
PcommS2_n = (EonS2_n + EoffS2_n) * fcom .* (Uact/Uref) .* (abs(IS2_n)/Iref);

PcommS3_p = (EonS3_p + EoffS3_p) * fcom .* (Uact/Uref) .* (IS1_p/Iref);
PcommS3_n = (EonS3_n + EoffS3_n) * fcom .* (Uact/Uref) .* (abs(IS2_n)/Iref);

%%
%Energía de recuperación de diodo

ErecS1_p = Erec_Id(IS1_p,Tunion);
ErecS1_n = Erec_Id(abs(IS1_n),Tunion);

ErecS2_p = Erec_Id(IS2_p,Tunion);
ErecS2_n = Erec_Id(abs(IS2_n),Tunion);

ErecS3_p = Erec_Id(IS3_p,Tunion);
ErecS3_n = Erec_Id(abs(IS3_n),Tunion);

%Perdidas de recuperación del diodo

PrecS1_p = ErecS1_p * fcom .* (Uact/Uref);
PrecS1_n = ErecS1_n * fcom .* (Uact/Uref);

PrecS2_p = ErecS2_p * fcom .* (Uact/Uref);
PrecS2_n = ErecS2_n * fcom .* (Uact/Uref);

PrecS3_p = ErecS3_p * fcom .* (Uact/Uref);
PrecS3_n = ErecS3_n * fcom .* (Uact/Uref);

%%
%Tensión directa de cada diodo

Vf_S1_p = Vf_Id(IS1_p,Tunion);
Vf_S1_n = -Vf_Id(abs(IS1_n),Tunion);

Vf_S2_p = Vf_Id(IS2_p,Tunion);
Vf_S2_n = -Vf_Id(abs(IS2_n),Tunion);

Vf_S3_p = Vf_Id(IS3_p,Tunion);
Vf_S3_n = -Vf_Id(abs(IS3_n),Tunion);

Vf_p_0 = Rf_cero(Tunion);
Vf_n_0 = -Rf_cero(Tunion);

%Resistencia directa de cada diodo

Rf_S1_p = (Vf_S1_p-Vf_p_0)./IS1_p;
Rf_S1_n = (Vf_S1_n-Vf_n_0)./IS1_n;

Rf_S2_p = (Vf_S2_p-Vf_p_0)./IS2_p;
Rf_S2_n = (Vf_S2_n-Vf_n_0)./IS2_n;

Rf_S3_p = (Vf_S3_p-Vf_p_0)./IS3_p;
Rf_S3_n = (Vf_S3_n-Vf_n_0)./IS3_n;


Rf_S1_p(isnan(Rf_S1_p)) = 0;
Rf_S1_p(isinf(Rf_S1_p)) = 0;

Rf_S1_n(isnan(Rf_S1_n)) = 0;
Rf_S1_n(isinf(Rf_S1_n)) = 0;

Rf_S2_p(isnan(Rf_S2_p)) = 0;
Rf_S2_p(isinf(Rf_S2_p)) = 0;

Rf_S2_n(isnan(Rf_S2_n)) = 0;
Rf_S2_n(isinf(Rf_S2_n)) = 0;

Rf_S3_p(isnan(Rf_S3_p)) = 0;
Rf_S3_p(isinf(Rf_S3_p)) = 0;

Rf_S3_n(isnan(Rf_S3_n)) = 0;
Rf_S3_n(isinf(Rf_S3_n)) = 0;

%Perdidas por conducción de cada diodo

Pconddio_S1_p = IS1_p.*Vf_S1_p + Rf_S1_p.*(IS1_p.^2);
Pconddio_S1_n = Vf_S1_n.*IS1_n + Rf_S1_n.*(IS1_n.^2);

Pconddio_S2_p = IS2_p.*Vf_S2_p + Rf_S2_p.*(IS2_p.^2);
Pconddio_S2_n = IS2_n.*Vf_S2_n + Rf_S2_n.*(IS2_n.^2);

Pconddio_S3_p = IS3_p.*Vf_S3_p + Rf_S3_p.*(IS3_p.^2);
Pconddio_S3_n = IS3_n.*Vf_S3_n + Rf_S3_n.*(IS3_n.^2);


%%
%Suma de perdidas(Las finales)

Ptran_S1_p = PcondS1_p + PcommS1_p;
Ptran_S1_n = PcondS1_n + PcommS1_n;

Ptran_S2_p = PcondS2_p + PcommS2_p;
Ptran_S2_n = PcondS2_n + PcommS2_n;

Ptran_S3_p = PcondS3_p + PcommS3_p;
Ptran_S3_n = PcondS3_n + PcommS3_n;

Pdio_S1_p = Pconddio_S1_p + PrecS1_p;
Pdio_S1_n = Pconddio_S1_n + PrecS1_n;

Pdio_S2_p = Pconddio_S2_p + PrecS2_p;
Pdio_S2_n = Pconddio_S2_n + PrecS2_n;

Pdio_S3_p = Pconddio_S3_p + PrecS3_p;
Pdio_S3_n = Pconddio_S3_n + PrecS3_n;

Pmodulo = Ptran_S1_p + Ptran_S1_n + Ptran_S2_p + Ptran_S2_n + Ptran_S3_p + Ptran_S3_n + Pdio_S1_p + Pdio_S1_n + Pdio_S2_p + Pdio_S2_n + Pdio_S3_p + Pdio_S3_n;


  function Vce_Ic_Tunion = Vce_Ic(Ientrada,Tunion)

Itab = [0,10,20,30,40,80,120,160,200,240,280,320,360,400];

Vce_0 = [0,0.8,0.9,1,1.044,1.246,1.422,1.583,1.737,1.891,2.045,2.193,2.348,2.50];
Vce_25 = [0,0.8,0.9,1,1.044,1.246,1.422,1.583,1.737,1.891,2.045,2.193,2.348,2.50];
Vce_125 = [0,0.698,0.843,0.96,1.044,1.328,1.595,1.822,2.052,2.269,2.495,2.72,2.96,3.204];
Vce_inf = [0,0.698,0.843,0.96,1.044,1.328,1.595,1.822,2.052,2.269,2.495,2.72,2.96,3.204];


Matriz_Vce = [Vce_0;Vce_25;Vce_125;Vce_inf];
Matriz_T = [0, 298.15 , 398.15 , 1000];

Vce_Ic_Tunion = interp2(Itab,Matriz_T,Matriz_Vce,Ientrada,Tunion,"linear");

end

  function Eon_Ic_relation = Eon_Ic(Ientrada,Tunion)


Itab = [0,50,100,150,200,250,300,350,400];

Eon_0 = [0.0027,0.00573,0.00948,0.105,0.105,0.105,0.105,0.105,0.105];
Eon_25 = [0.0027,0.00573,0.00948,0.105,0.105,0.105,0.105,0.105,0.105];
Eon_125 = [0.0027,0.00573,0.00956,0.014,0.0186,0.0247,0.0326,0.04221,0.0528];
Eon_150 = [0.0034,0.00635,0.0105,0.0155,0.0206,0.0272,0.0359,0.0466,0.0573];
Eon_inf = [0.0034,0.00635,0.0105,0.0155,0.0206,0.0272,0.0359,0.0466,0.0573];

Matriz_Eon = [Eon_0;Eon_25;Eon_125;Eon_150;Eon_inf];
Matriz_T = [0,298.15,398.15,423.15,1000];

Eon_Ic_relation = interp2(Itab,Matriz_T,Matriz_Eon,Ientrada,Tunion,"linear");

  end

  function Eoff_Ic_relation = Eoff_Ic(Ientrada,Tunion)

Itab = [0,50,100,150,200,250,300,350,400];

Eoff_0 =  [0.00121,0.00457,0.00859,0.011,0.011,0.011,0.011,0.011,0.011];
Eoff_25 = [0.00121,0.00457,0.00859,0.011,0.011,0.011,0.011,0.011,0.011];
Eoff_125 = [0.00121,0.00457,0.00859,0.0125,0.0167,0.0203,0.0243,0.0280,0.0318];
Eoff_150 = [0.00125,0.00507,0.00952,0.0140,0.0185,0.0226,0.0265,0.0306,0.0346];
Eoff_inf = [0.00125,0.00507,0.00952,0.0140,0.0185,0.0226,0.0265,0.0306,0.0346];

Matriz_Eoff = [Eoff_0;Eoff_25;Eoff_125;Eoff_150;Eoff_inf];
Matriz_T = [0,298.15,398.15,423.15,1000];

Eoff_Ic_relation = interp2(Itab,Matriz_T,Matriz_Eoff,Ientrada,Tunion,"linear");

  end

  function Erec_Id_relation = Erec_Id(Ientrada,Tunion)

Id = [0,50,100,150,200,250,300,350,400];

Erec_0 = [0.00331,0.00681,0.00810,0.00810,0.00810,0.00810,0.00810,0.00810,0.00810];
Erec_25 = [0.00331,0.00681,0.00810,0.00810,0.00810,0.00810,0.00810,0.00810,0.00810];
Erec_125 = [0.00331,0.00681,0.0101,0.0124,0.0147,0.0164,0.0177,0.0185,0.0191];
Erec_150 = [0.00423,0.00865,0.0119,0.0143,0.0167,0.0185,0.0199,0.0210,0.0219];
Erec_inf = [0.00423,0.00865,0.0119,0.0143,0.0167,0.0185,0.0199,0.0210,0.0219];

Matriz_Erec = [Erec_0;Erec_25;Erec_125;Erec_150;Erec_inf];
Matriz_T = [0,298.15,398.15,423.15,1000];

Erec_Id_relation = interp2(Id,Matriz_T,Matriz_Erec,Ientrada,Tunion,"linear");

   end

  function Vf_Id_relation = Vf_Id(Ientrada,Tunion)

Id = [0,40,80,120,160,200,240,280,320,360,400];

Vf_0 = [0.8,1.09,1.273,1.423,1.547,1.667,1.774,1.875,1.980,2.07,2.172];
Vf_25 = [0.8,1.09,1.273,1.423,1.547,1.667,1.774,1.875,1.980,2.07,2.172];
Vf_125 = [0.6,0.945,1.166,1.351,1.507,1.649,1.788,1.921,2.035,2.149,2.261];
Vf_150 = [0.5,0.9,1.141,1.331,1.495,1.644,1.786,1.92,2.045,2.169,2.284];
Vf_inf = [0.5,0.9,1.141,1.331,1.495,1.644,1.786,1.92,2.045,2.169,2.284];

Matriz_Vf = [Vf_0;Vf_25;Vf_125;Vf_150;Vf_inf];
Matriz_T = [0,298.15,398.15,423.15,1000];

Vf_Id_relation = interp2(Id,Matriz_T,Matriz_Vf,Ientrada,Tunion,"linear");

  end

  function Rf_0A = Rf_cero(Tunion)

T = [0,298.15,398.15,423.15,1000];
Vce = [0.8,0.8,0.6,0.5,0.5];

Rf_0A = interp1(T,Vce,Tunion,"linear");

  end

end
