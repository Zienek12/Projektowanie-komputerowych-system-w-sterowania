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
% symulacja
[t] = sim(schemat, czas);

% Wybor sygnalu do wyznaczenia punktu przegiecia (aTwew_1)
y = aTwew_1;

% Numeryczne wyznaczenie pochodnej w celu znalezienia punktu przegiecia
dt = diff(t);
dy = diff(y) ./ dt;               % pierwsza pochodna
t_dy = t(1:end-1) + dt/2;         % punkty czasowe pochodnej

% Szukanie maksymalnego nachylenia po punkcie skoku (czas_skok)
idx_start = find(t_dy >= czas_skok, 1);
[max_dy, idx_max_rel] = max(dy(idx_start:end));
idx_pp = idx_start + idx_max_rel - 1;

t_pp = t_dy(idx_pp);              % czas w punkcie przegiecia
y_pp = y(idx_pp);                 % wartosc odpowiedzi w punkcie przegiecia

% Pojedynczy wykres odpowiedzi z punktem przegiecia
figure(1); hold on; grid on;
plot(t, y, 'b-', 'LineWidth', 1.5);
%plot(t_pp, y_pp, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

title('Odpowiedz skokowa obiektu');
xlabel('t [min]');
ylabel('Twew1 [oC]');
legend('Odpowiedz obiektu y(t)', 'Location', 'southeast');

% Wyswietlenie wynikow w oknie polecen
fprintf('--------------------------------------------------\n');
fprintf('Punkt przegiecia:\n');
fprintf('t_pp = %.2f min\n', t_pp);
fprintf('y_pp = %.4f oC\n', y_pp);
fprintf('--------------------------------------------------\n');