clear all; close all;
skala = 60;             % skala czasu (wszystkie czasy w minutach) 
schemat = 'KociolBud3CvwCvg';        
IlePom = 3;             % ile pomieszczen
czas = 3000; 
czas_skok = 500;

% ----------------------------------------------------
kolor = 'rgbcm'; linia = ['- '; '--'; ': '];
KociolBud_skryptWN;     % obliczenia parametrow (warunki nominalne)

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
% symulacja
[t] = sim(schemat, czas);

% Wybor sygnalu do identyfikacji (aTwew_1)
y = aTwew_1;

% ===========================================================
%     METODA DWUPUNKTOWA M2p (dla 28.3% i 63.2%)
% ===========================================================

% 1. Wartosc poczatkowa i koncowa (stan ustalony)
idx_skok = find(t >= czas_skok, 1);
y0 = y(idx_skok);                 % wartosc przed skokiem
y_inf = y(end);                   % wartosc w stanie ustalonym
dy_tot = y_inf - y0;              % pelna zmiana wartosci

% 2. Wartosci dla 28.3% oraz 63.2% zmiany
y28 = y0 + 0.283 * dy_tot;
y63 = y0 + 0.632 * dy_tot;

% 3. Odnalezienie indeksow i czasow dla y28 oraz y63
idx28 = find(y >= y28, 1);
idx63 = find(y >= y63, 1);

t28 = t(idx28);
t63 = t(idx63);

% 4. Obliczenie czasow wzglednych (od momentu skoku)
t28_rel = t28 - czas_skok;
t63_rel = t63 - czas_skok;

% 5. Obliczenie parametrow modelu dla punktow 28.3% i 63.2%
T_M2p = 1.5 * (t63_rel - t28_rel);
T0_M2p = 1.5 * t28_rel - 0.5 * t63_rel;

% Wzmocnienie obiektu k_M2p (du_val to wielkosc skoku wejscia)
du_val = dQk;                     % skok mocy kociołka
k_M2p = dy_tot / du_val;

% ===========================================================
%            WYKRES ODPOWIEDZI OBIEKTU
% ===========================================================
figure(1); hold on; grid on;
plot(t, y, 'b-', 'LineWidth', 1.5);

% Zaznaczenie punktow 28.3% i 63.2% na odpowiedzi obiektu
plot(t28, y(idx28), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8);
plot(t63, y(idx63), 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 8);

% Linie pomocnicze (poziome i pionowe)
yline(y0, 'k--', 'y0');
yline(y_inf, 'k--', 'y_inf');
yline(y28, 'm--', 'y28.3%');
yline(y63, 'g--', 'y63.2%');

plot([t28 t28], [min(y) y28], 'm:');
plot([t63 t63], [min(y) y63], 'g:');

%title('Identyfikacja M2p (punkty 28.3% i 63.2%)');
xlabel('t [min]');
ylabel('Twew1 [oC]');
legend('Odpowiedz obiektu y(t)', 'Punkt 28.3%', 'Punkt 63.2%', 'Location', 'southeast');

% Wyswietlenie wynikow w oknie polecen
fprintf('--------------------------------------------------\n');
fprintf('Wyniki metody dwupunktowej (28.3%% i 63.2%%):\n');
fprintf('t28.3 = %.2f min | y28.3 = %.4f oC\n', t28, y28);
fprintf('t63.2 = %.2f min | y63.2 = %.4f oC\n', t63, y63);
fprintf('--------------------------------------------------\n');
fprintf('Wyznaczone parametry transmitancji M2p:\n');
fprintf('k  = %.6f\n', k_M2p);
fprintf('T  = %.2f min\n', T_M2p);
fprintf('T0 = %.2f min\n', T0_M2p);
fprintf('--------------------------------------------------\n');