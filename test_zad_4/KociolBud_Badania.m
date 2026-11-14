clear all; close all;
skala = 60;             %skala czasu (wszystkie czasy w minutach) 
%gdy n=60, to Max step size daæ 0.1 
schemat = 'KociolBud3CvwCvg';        
IlePom = 3;                     %ile pomieszczen
czas = 3000; czas_skok = 500;
%----------------------------------------------------
kolor = 'rgbcm'; linia = ['- '; '--'; ': '];
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
[t] = sim(schemat, czas);                                     %[out] = sim(schemat, czas);
figure(1); hold on;grid on;
plot(t, aTwew_1, strcat(kolor(1), linia(1,:)));     %plot(out,tout, out.aTwew_1, strcat(kolor(1), linia(1,:)));
plot(t, aTwew_2, strcat(kolor(2), linia(2,:)));  
plot(t, aTwew_3, strcat(kolor(3), linia(3,:)));
%plot(t,aPV,'k');
title('T_w_e_w [^oC]'); xlabel('t[min]'); ylabel('Twew');
legend('T_w_e_w_1', 'T_w_e_w_2', 'T_w_e_w_3');

figure(2); hold on;grid on; 
plot(t,aTkp,'b');
%plot(t,aTkp,'b','LineWidth',2);
title('T_k_p [^oC]'); xlabel('t[min]'); ylabel('Tkp');



