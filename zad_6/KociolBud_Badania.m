clear all; close all;
skala = 60;             %skala czasu (wszystkie czasy w minutach) 
%gdy n=60, to Max step size daæ 0.1 
schemat = 'KociolBud3CvwCvg_ograniczenia';        
IlePom = 3;                     %ile pomieszczen
czas = 3000; czas_skok = 500; czas_koniec = 2500;
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
Sp = 20;
dSp = 1;
Kp = 3375;
Ki = Kp/333;
Ka = 0.3*Kp;

max = 20;
min = 0;
%--------------------
%symulacja                                                     
[out] = sim(schemat, czas);

figure(1);
sublot(2,1,1);
plot(t, aTwew1 );
plot(t, aCv);