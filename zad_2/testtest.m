clear all; close all;
skala = 60;             % skala czasu (wszystkie czasy w minutach) 
schemat = 'KociolBud3CvwCvg';        
IlePom = 3;             % ile pomieszczen
czas = 3000; 
czas_skok = 500;

% ----------------------------------------------------
kolor = 'rgbcm'; linia = ['- '; '--'; ': '];
KociolBud_skryptWN;     % obliczenia parametrow (warunki nominalne)

% model (wartosci parametrow z identyfikacji)
T = 1000; T0 = 100; k = 4 / (0.1*QkN);

% ===========================================================
%            BADANIA 
% ===========================================================
% ============= warunki poczatkowe nominalne  ===================
Tzew0 = TzewN+1;                  
Qk0 = QkN*1;
Fg0 = [1, 1, 1] .* FgN;
Qd0 = [0, 0, 0];                   % zawsze
KociolBud_skryptP0;

% =================== zaklocenie ======================
dTzew = 0;
dQk = 0.1 * QkN;                  % skok mocy o 10 procent w czasie czas_skok
dFg = [0, 0, 0] .* FgN;
dQd = [0, 0, 0] .* QgN;

% -------------------------------------------------------
% symulacja obiektu
[t] = sim(schemat, czas);

% Wybor sygnalu do wyznaczenia punktow identyfikacji (aTwew_1)
y = aTwew_1;

% Parametry ogolne wymuszenia i odpowiedzi
idx_skok = find(t >= czas_skok, 1);
y0 = y(idx_skok);                 % wartosc poczatkowa
y_inf = y(end);                   % wartosc w stanie ustalonym
dy_tot = y_inf - y0;              % przyrost odpowiedzi
du_val = dQk;                     % przyrost wymuszenia

% Wzmocnienie statyczne (wspolne dla obu metod)
k_id = dy_tot / du_val;

% ===========================================================
%            1. IDENTYFIKACJA - METODA STYCZNEJ (MS)
% ===========================================================
dt = diff(t);
dy = diff(y) ./ dt;               % pierwsza pochodna
t_dy = t(1:end-1) + dt/2;         % punkty czasowe dla pochodnej

% Szukanie maksymalnego nachylenia po punkcie skoku (czas_skok)
idx_start = find(t_dy >= czas_skok, 1);
[max_dy, idx_max_rel] = max(dy(idx_start:end));
idx_pp = idx_start + idx_max_rel - 1;

t_pp = t_dy(idx_pp);              % czas punktu przegiecia
y_pp = y(idx_pp);                 % wartosc w punkcie przegiecia
a_pp = dy(idx_pp);                % nachylenie stycznej

% Punkty przeciecia stycznej z poziomami y0 i y_inf
tA = t_pp - (y_pp - y0) / a_pp;
tB = t_pp + (y_inf - y_pp) / a_pp;

% Parametry MS
T0_MS = tA - czas_skok;
T_MS = tB - tA;

% Utworzenie transmitancji MS
G_MS = tf(k_id, [T_MS 1], 'InputDelay', T0_MS);

% ===========================================================
%     2. IDENTYFIKACJA - METODA DWUPUNKTOWA (M2p: 28.3% i 63.2%)
% ===========================================================
y28 = y0 + 0.283 * dy_tot;
y63 = y0 + 0.632 * dy_tot;

idx28 = find(y >= y28, 1);
idx63 = find(y >= y63, 1);

t28_rel = t(idx28) - czas_skok;
t63_rel = t(idx63) - czas_skok;

% Parametry M2p
T_M2p = 1.5 * (t63_rel - t28_rel);
T0_M2p = 1.5 * t28_rel - 0.5 * t63_rel;

% Utworzenie transmitancji M2p
G_M2p = tf(k_id, [T_M2p 1], 'InputDelay', T0_M2p);

% ===========================================================
%            WERYFIKACJA MODELI (WYKRES)
% ===========================================================
% Czas symulacji modeli od momentu skoku (czas_skok)
t_sim_model = 0 : 1 : (czas - czas_skok);

% Odpowiedzi skokowe modeli (dla wymuszenia du_val)
[y_step_MS, t_out_MS] = step(G_MS * du_val, t_sim_model);
[y_step_M2p, t_out_M2p] = step(G_M2p * du_val, t_sim_model);

% Przesuniecie odpowiedzi modeli o czas_skok i poziom y0
t_model = t_out_MS + czas_skok;
y_MS = y_step_MS + y0;
y_M2p = y_step_M2p + y0;

% Wykres weryfikacyjny
figure(1); hold on; grid on;
plot(t, y, 'b-', 'LineWidth', 2.0);
plot(t_model, y_MS, 'r--', 'LineWidth', 1.5);
plot(t_model, y_M2p, 'g:', 'LineWidth', 1.8);

title('Weryfikacja modeli: Obiekt vs MS vs M2p');
xlabel('t [min]');
ylabel('Twew1 [oC]');
legend('Odpowiedz obiektu y(t)', 'Model MS', 'Model M2p', 'Location', 'southeast');

% ===========================================================
%            WYSWIETLENIE WYNIKOW W COMMAND WINDOW
% ===========================================================
fprintf('==================================================\n');
fprintf('WYNIKI IDENTYFIKACJI TRANSMITANCJI\n');
fprintf('==================================================\n');
fprintf('Wspolne wzmocnienie statyczne k = %.6f\n\n', k_id);

fprintf('--- METODA STYCZNEJ (MS) ---\n');
fprintf('T0_MS = %.2f min\n', T0_MS);
fprintf('T_MS  = %.2f min\n', T_MS);
fprintf('G_MS(s) = (%.6f / (%.2f*s + 1)) * exp(-%.2f*s)\n\n', k_id, T_MS, T0_MS);

fprintf('--- METODA DWUPUNKTOWA (M2p: 28.3%% i 63.2%%) ---\n');
fprintf('T0_M2p = %.2f min\n', T0_M2p);
fprintf('T_M2p  = %.2f min\n', T_M2p);
fprintf('G_M2p(s) = (%.6f / (%.2f*s + 1)) * exp(-%.2f*s)\n', k_id, T_M2p, T0_M2p);
fprintf('==================================================\n');