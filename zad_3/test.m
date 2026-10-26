clear all; close all;
skala = 60;             % skala czasu (wszystkie czasy w minutach) 
% gdy n=60, to Max step size dac 0.1 
schemat = 'KociolBud3CvwCvg_regulacja_ms';        
IlePom = 3;             % ile pomieszczen
czas = 3000; czas_skok = 500;
%----------------------------------------------------
kolor = 'rgbm';         % zmieniono c na m dla lepszej widocznosci
linia  = {'-'; '--'; ':'; '-.'};
KociolBud_skryptWN;     % obliczenia parametrow (warunki nominalne)

% model (wartosci parametrow z identyfikacji)
T = 1000; T0 = 100; k = 4 / (0.1*QkN);      
%===========================================================
%            BADANIA 
%===========================================================
%============= warunki poczatkowe nominalne  ===================
Tzew0 = TzewN+1;                  
Qk0 = QkN*1;
Fg0 = [1, 1, 1] .* FgN;
Qd0 = [0, 0, 0];                                   
KociolBud_skryptP0;

%-------------------------------------------------------
% Parametry modeli
K = 0.002667;
T0_MS = 30.0;           
T_MS  = 570.0;   
T0_M2p = 63.0;          
T_M2p  = 402.0; 

G_MS  = tf(K, [T_MS 1],  'InputDelay', T0_MS);
G_M2P = tf(K, [T_M2p 1], 'InputDelay', T0_M2p);

% Nastawy reczne (Ziegler-Nichols)
Kp_MS = 6411.69;
Ti_MS_val = 99.9;
Ki_MS = 1/Ti_MS_val;

Kp_M2P = 2153.30;
Ti_M2P_val = 209.79;
Ki_M2P = 1/Ti_M2P_val;

% Nastawy z pidtune
C_MS = pidtune(G_MS, 'PI');
Kp_ms_tune = C_MS.Kp;
Ki_ms_tune = C_MS.Ki;

C_M2P = pidtune(G_M2P, 'PI');
Kp_M2P_tune = C_M2P.Kp;
Ki_M2P_tune = C_M2P.Ki;

Kp_vect = [Kp_MS, Kp_M2P, Kp_ms_tune, Kp_M2P_tune];
Ki_vect = [Ki_MS, Ki_M2P, Ki_ms_tune, Ki_M2P_tune];
etykiety = {'MS reczne', 'M2P reczne', 'MS pidtune', 'M2P pidtune'};

% ==========================================================
% ZADANIE 1: Porownanie 4 nastaw (Skok SP)
% ==========================================================
dTzew = 0;              % Brak zaklocenia Tzew
dQk = 0;
dFg = [0, 0, 0];     
dQd = [0, 0, 0];      

figure(1);
subplot(2,1,1); hold on; grid on;
title('Zmienna procesowa PV (Temperatura) - Skok SP');
xlabel('Czas [min]'); ylabel('Temp [C]');

subplot(2,1,2); hold on; grid on;
title('Zmienna sterujaca CV (Moc) - Skok SP');
xlabel('Czas [min]'); ylabel('Moc [W]');

disp('--- WSKAZNIKI JAKOSCI (Czas stabilizacji) - Skok SP ---');

for i = 1:4
    Kp = Kp_vect(i);
    Ki = Ki_vect(i);
    
    % Symulacja
    out = sim(schemat, czas); 
    
    % Zakladamy ze model zwraca zmienne t, PV (aTwew_1) i CV (Qk) do workspace 
    % lub uzywamy out.get('nazwa_zmiennej') zaleznie od wersji
    % Prawa do dostosowania w zaleznosci od budowy modelu Simulink:
    t_sim = t;
    PV_sim = out.aTwew_1; 
    CV_sim = out.Qk;      
    
    % Wykres PV
    subplot(2,1,1);
    plot(t_sim, PV_sim, 'Color', kolor(i), 'LineStyle', linia{i}, 'LineWidth', 1.5, 'DisplayName', etykiety{i});
    
    % Wykres CV
    subplot(2,1,2);
    plot(t_sim, CV_sim, 'Color', kolor(i), 'LineStyle', linia{i}, 'LineWidth', 1.5, 'DisplayName', etykiety{i});
    
    % Obliczanie wskaźnika jakosci (stepinfo)
    info = stepinfo(PV_sim, t_sim, PV_sim(end));
    fprintf('Nastawa: %s -> Czas stabilizacji: %.2f min\n', etykiety{i}, info.SettlingTime);
end

subplot(2,1,1); legend('Location', 'best');
subplot(2,1,2); legend('Location', 'best');

% ==========================================================
% ZADANIE 2: Reakcja na skok SP i Tzew (wybrane nastawy)
% ==========================================================
% Wybieramy najlepsza nastawe, np. MS pidtune (indeks 3)
wybrany_idx = 3;
Kp = Kp_vect(wybrany_idx);
Ki = Ki_vect(wybrany_idx);

% Skok zaklocenia w pewnym momencie (np. implementowane w modelu Simulink)
% Ustawiamy zmienna odpowiadajaca za skok Tzew
dTzew = -5;  % Spadek temp zew o 5 stopni
       
figure(2);
subplot(2,1,1); hold on; grid on;
title(['Reakcja na skok SP i Tzew - Nastawa: ' etykiety{wybrany_idx}]);
xlabel('Czas [min]'); ylabel('Temp [C]');

subplot(2,1,2); hold on; grid on;
xlabel('Czas [min]'); ylabel('Moc [W]');

out = sim(schemat, czas);
t_sim = out.tout;
PV_sim = out.aTwew_1;
CV_sim = out.Qk;

subplot(2,1,1);
plot(t_sim, PV_sim, 'b', 'LineWidth', 1.5, 'DisplayName', 'PV');
legend('Location', 'best');

subplot(2,1,2);
plot(t_sim, CV_sim, 'r', 'LineWidth', 1.5, 'DisplayName', 'CV');
legend('Location', 'best');

disp('--- WSKAZNIKI JAKOSCI ZAKLOCENIA ---');
info_zakl = stepinfo(PV_sim, t_sim, PV_sim(end));
fprintf('Czas stabilizacji po zakloceniach: %.2f min\n', info_zakl.SettlingTime);