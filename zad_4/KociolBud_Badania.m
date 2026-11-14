clear all; close all;
skala = 60;             %skala czasu (wszystkie czasy w minutach) 
%gdy n=60, to Max step size daæ 0.1 
schemat = 'KociolBud3CvwCvg_regulacja_pog';        
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
Sp = 0;
dSp = 0;    %ZN     PIDTUNE
Kp_vect = [189.5981, 132.1198];
Ki_vect = [523.9755, 0.43713];
dQk = 0*QkN;
dFg = [0, 0, 0] .* FgN;     %procent przeplywu nominalnego danego grzejnika
dQd = [0, 0, 0] .* QgN;      %procent zapotrzebowania nominalnego danego pomieszczenia
%-------------------------------------------------------
Kp = Kp_vect(1);
Ki = Ki_vect(1);

Az = (TgzN - TzewN) / (TwewN- TzewN);
Bz = (TgzN - TwewN) / (TwewN - TzewN);

[t] = sim(schemat, czas);                                     %[out] = sim(schemat, czas);

for i = 1:2
    Kp = Kp_vect(i);
    Ki = Ki_vect(i);
    for j = 0:1
        set_param(gcb,'sw',j);
        figure(); hold on; grid on;
        subplot();
        plot(t,aTwew_1);
        subplot();
        plot(t, aCV);
        

    end

end