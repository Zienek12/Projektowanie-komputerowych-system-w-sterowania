clear all; close all;
skala = 60;             %skala czasu (wszystkie czasy w minutach) 
%gdy n=60, to Max step size daæ 0.1 
schemat = 'KociolBud3CvwCvg_regulacja_ms';        
IlePom = 3;                     %ile pomieszczen
czas = 3000; czas_skok = 500;
%----------------------------------------------------
kolor = 'rgbc';
linia  = {'- '; '--'; ': '; '-.'};
KociolBud_skryptWN;                             %obliczenia parametrow (warunki nominalne), nazwa schematu
%model (wartosci parametrow z identyfikacji)
T = 1000; T0 = 100; k = 4 / (0.1*QkN);      %4 / 3000 = 0.0013
%===========================================================
%            BADANIA 
%===========================================================
%============= warunki poczatkowe nominalne  ===================
Tzew0 = TzewN+1;                  
Qk0 = QkN*1;
Fg0 = [1, 1, 1] .* FgN;
Qd0 = [0, 0, 0];                                   %zawsze
KociolBud_skryptP0;
%=================== zaklocenie ======================
dTzew = 1;
dQk = 0*QkN;
dFg = [0, 0, 0] .* FgN;     %procent przeplywu nominalnego danego grzejnika
dQd = [0, 0, 0] .* QgN;      %procent zapotrzebowania nominalnego danego pomieszczenia
%-------------------------------------------------------
%symulacja                                                     % wersja po 2019
K = 0.002667;

T0_MS = 30.0;           
T_MS  = 570.0;   

T0_M2p = 63.0;          
T_M2p  = 402.0; 

G_MS  = tf(K, [T_MS 1],  'InputDelay', T0_MS);
G_M2P = tf(K, [T_M2p 1], 'InputDelay', T0_M2p);



Kp_MS = 6411.69;
Ti_MS = 99.9;
Ti_MS = 1/Ti_MS;

Kp_M2P = 2153.30;
Ti_M2P = 209.79;
Ti_M2P = 1/Ti_M2P;

C_MS = pidtune(G_MS, 'PI');
Kp_ms_tune = C_MS.Kp;
Ki_ms_tune = C_MS.Ki;

C_M2P = pidtune(G_M2P, 'PI');
Kp_M2P_tune = C_M2P.Kp;
Ki_M2P_tune = C_M2P.Ki;

Kp_vect = [Kp_MS, Kp_M2P, Kp_ms_tune, Kp_M2P_tune];
Ti_Vect = [Ti_MS, Ti_M2P, Ki_ms_tune, Ki_M2P_tune];

for i = 1:4
    Kp = Kp_vect(i);
    Ki = Ti_Vect(i);
    [t] = sim(schemat, czas);                                     %[out] = sim(schemat, czas);
    figure(1); hold on; grid on;
    plot(t, aTwew_1, 'Color', kolor(i), 'LineStyle', linia(i, :));
    xlabel('Czas [min]');
    ylabel('Temperatura');
    legend('Wynik symulacji', 'Location', 'best');
end



