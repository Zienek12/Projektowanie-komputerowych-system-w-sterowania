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
%            BADANIA OBIEKTU (SYMULACJA)
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

% Symulacja obiektu
[t] = sim(schemat, czas);
y_obiekt = aTwew_1;

% ===========================================================
%   DEFINICJA TRANSMITANCJI Z IDENTYFIKACJI (MS oraz M2p)
% ===========================================================
% Przyjecie parametrow (podstaw swoje zidentyfikowane wartosci)
du_val = dQk;
y0 = y_obiekt(find(t >= czas_skok, 1));
y_inf = y_obiekt(end);
k_id = (y_inf - y0) / du_val;

% Parametry z Metody Stycznej (MS)
T0_MS = 30.0;           % przykladowe opoznienie MS [min]
T_MS  = 570.0;          % przykladowa stala czasowa MS [min]

% Parametry z Metody Dwupunktowej (M2p)
T0_M2p = 63.0;          % przykladowe opoznienie M2p [min]
T_M2p  = 402.0;         % przykladowa stala czasowa M2p [min]

% Utworzenie obiektow LTI z opoznieniem
G_MS  = tf(k_id, [T_MS 1],  'InputDelay', T0_MS);
G_M2p = tf(k_id, [T_M2p 1], 'InputDelay', T0_M2p);

% ===========================================================
%          OBLICZENIE ODPOWIEDZI SKOKOWYCH MODELI
% ===========================================================
% Dziedzina czasu dla modeli (od momentu skoku do konca symulacji)
t_model_rel = 0 : 1 : (czas - czas_skok);

[y_step_MS]  = step(G_MS * du_val, t_model_rel);
[y_step_M2p] = step(G_M2p * du_val, t_model_rel);

% Przesuniecie odpowiedzi modeli do bezwzglednej osi czasu i poziomu y0
t_model = t_model_rel + czas_skok;
y_MS  = y_step_MS + y0;
y_M2p = y_step_M2p + y0;

% Interpolacja odpowiedzi obiektu do punktow czasowych modelu (do MSE)
y_obiekt_interp = interp1(t, y_obiekt, t_model);

% ===========================================================
%          WSKAZNIKI JAKOSCI DOPASOWANIA (MSE i MAX ERR)
% ===========================================================
err_MS  = y_obiekt_interp - y_MS;
err_M2p = y_obiekt_interp - y_M2p;

mse_MS  = mean(err_MS.^2);
mse_M2p = mean(err_M2p.^2);

max_err_MS  = max(abs(err_MS));
max_err_M2p = max(abs(err_M2p));

% ===========================================================
%                    WYKRES POROWNAWCZY
% ===========================================================
figure(1);

hold on; grid on;
plot(t, y_obiekt, 'b-', 'LineWidth', 2.0);
plot(t_model, y_MS, 'r--', 'LineWidth', 1.5);
plot(t_model, y_M2p, 'g-.', 'LineWidth', 1.5);
title('Porownanie odpowiedzi obiektu i zidentyfikowanych modeli');
xlabel('t [min]');
ylabel('Twew1 [oC]');
legend('Obiekt rzeczywisty', 'Model MS', 'Model M2p', 'Location', 'southeast');


