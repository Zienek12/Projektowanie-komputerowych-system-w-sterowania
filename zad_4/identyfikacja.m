clear all; close all;
skala = 60;             %skala czasu (wszystkie czasy w minutach) 
%gdy n=60, to Max step size dac 0.1 
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
dSp = 0;
Kp = 0;
Ki = 0;
dQk = 0.1*QkN;
dFg = [0, 0, 0] .* FgN;     %procent przeplywu nominalnego danego grzejnika
dQd = [0, 0, 0] .* QgN;      %procent zapotrzebowania nominalnego danego pomieszczenia
%-------------------------------------------------------
%symulacja                                                     % wersja po 2019
[t] = sim(schemat, czas);                                     %[out] = sim(schemat, czas);

% ===========================================================
%            IDENTYFIKACJA METODA M2P (Metoda Dwoch Punktow)
% ===========================================================
% Wyznaczenie przyrostu odpowiedzi skokowej
idx_skok = find(t >= czas_skok, 1);
y_skok = aTkz - aTkz(idx_skok); 
[Ymax, ~] = max(y_skok);

% Wyznaczenie czasow dla charakterystycznych progow (28.3% oraz 63.2%)
prog1 = 0.283 * Ymax;
prog2 = 0.632 * Ymax;

idx_t1 = find(y_skok >= prog1, 1);
idx_t2 = find(y_skok >= prog2, 1);

t1 = t(idx_t1) - czas_skok;
t2 = t(idx_t2) - czas_skok;

% Obliczenie parametrow modelu inercyjnego I rzedu z opoznieniem
T_m2p = 1.5 * (t2 - t1);
T0_m2p = t2 - 1.5 * t1;

% Wyznaczenie rzeczywistego wzmocnienia na podstawie Ymax i wymuszenia dQk
k_m2p = Ymax / dQk;

% Symulacja / wyznaczenie odpowiedzi zidentyfikowanego modelu m2p
t_model = t - czas_skok;
t_model(t_model < 0) = 0;
y_m2p = zeros(size(t));

for i = 1:length(t)
    if t_model(i) >= T0_m2p
        y_m2p(i) = aTkz(idx_skok) + (k_m2p * dQk) * (1 - exp(-(t_model(i) - T0_m2p) / T_m2p));
    else
        y_m2p(i) = aTkz(idx_skok);
    end
end

% Rysowanie wynikow
figure(1); hold on; grid on;
plot(t, aTkz, strcat(kolor(1), linia(1,:)), 'LineWidth', 1.5);     
plot(t, y_m2p, strcat(kolor(2), linia(2,:)), 'LineWidth', 1.5);
legend('Obiekt rzeczywisty / symulacja', 'Model zidentyfikowany m2p');
xlabel('Czas [min]');
ylabel('Temperatura');
title('Porownanie odpowiedzi obiektu i modelu m2p');
% ===========================================================
%        OBLICZANIE NASTAW METODA ZIEGLERA-NICHOLSA
% ===========================================================
K = Ymax / dQk;          % wzmocnienie statyczne obiektu

%  Regulator PI:
Kp_PI = 0.9 * T_m2p / (K * T0_m2p);
Ti_PI = 3.33 * T0_m2p;
Td_PI = 0;


disp('--------------------------------------------------');
disp('PARAMETRY MODELU:');
disp(['K  = ', num2str(K)]);
disp(['T  = ', num2str(T_m2p)]);
disp(['T0 = ', num2str(T0_m2p)]);
disp('--------------------------------------------------');
disp('NASTAWY REGULATORA METODA ZIEGLERA-NICHOLSA:');
disp(['PI  -> Kp = ', num2str(Kp_PI), ' | Ti = ', num2str(Ti_PI)]);
disp('--------------------------------------------------');

% ===========================================================
%        OBLICZANIE NASTAW ZA POMOCA FUNKCJI PIDTUNE
% ===========================================================
s = tf('s');
G_M2p = tf(K, [T_m2p 1], 'InputDelay', T0_m2p);

% Wyznaczenie regulatorow
C_M2p = pidtune(G_M2p, 'PI');

disp('NASTAWY REGULATORA METODA PIDTUNE:');
disp(['PI  -> Kp = ', num2str(C_M2p.Kp), ' | Ti = ', num2str(C_M2p.Ki)]);

