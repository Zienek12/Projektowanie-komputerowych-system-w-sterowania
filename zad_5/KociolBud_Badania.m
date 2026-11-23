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

Qk_max = 1.2*QkN;
Qk0 = QkN*1;
Fg0 = [1, 1, 1] .* FgN;
Qd0 = [0, 0, 0];                                   %zawsze
KociolBud_skryptP0;
Twew_zad = TwewN;

%=================== zaklocenie ======================
dTzew = 0;
dTwew = 1;
dQk = 0*QkN;
dFg = [0, 0, 0] .* FgN;     %procent przeplywu nominalnego danego grzejnika
dQd = [0, 0, 0] .* QgN;      %procent zapotrzebowania nominalnego danego pomieszczenia
%=============== dane pogodowe ===================
Az = (TgzN - TzewN) / (TwewN - TzewN);
Bz = (TgzN - TwewN) / (TwewN - TzewN);

%===================== Histereza ====================
h_rel = 14;


%-------------------------------------------------------
%symulacja                                                     % wersja po 2019
[t] = sim(schemat, czas);                                     %[out] = sim(schemat, czas);

figure(1);
hold on;
grid on;
subplot(3,1,1);
plot(t, aTwew_1, 'LineWidth', 1.2);
xlabel('Czas [min]');
ylabel('Temperatura');
legend('show', 'Location', 'best');
title('Temperatura w pomieszczeniu');

subplot(3,1,2);
plot(t, aQk, 'LineWidth', 1.2);
xlabel('Czas [min]');
ylabel('KW');
legend('show', 'Location', 'best');
title('Wartosc sterujaca');

subplot(3,1,3);
plot(t, aTkz, 'LineWidth', 1.2);
xlabel('Czas [min]');
ylabel('Temperatura');
legend('show', 'Location', 'best');
title('TKZ');

