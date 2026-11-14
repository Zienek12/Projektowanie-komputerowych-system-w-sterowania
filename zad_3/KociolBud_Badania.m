%%
clear all; close all;
skala = 60;             %skala czasu (wszystkie czasy w minutach)
%gdy n=60, to Max step size dac 0.1
schemat = 'KociolBud3CvwCvg_regulacja_ms';
IlePom = 3;                     %ile pomieszczen
czas = 3000; czas_skok = 500;
%----------------------------------------------------
kolor = 'rgbm';
linia  = {'-'; '--'; ':'; '-.'};
KociolBud_skryptWN;             %obliczenia parametrow (warunki nominalne)
%===========================================================
%            BADANIA
%===========================================================
%============= warunki poczatkowe nominalne  ===================
Tzew0 = TzewN+1;
Qk0 = QkN*1;
Fg0 = [1, 1, 1] .* FgN;
Qd0 = [0, 0, 0];
KociolBud_skryptP0;
Sp = Twew0(1);

%=================== zaklocenia (stale) ======================
dQk = 0*QkN;
dFg = [0, 0, 0] .* FgN;     %procent przeplywu nominalnego danego grzejnika
dQd = [0, 0, 0] .* QgN;     %procent zapotrzebowania nominalnego danego pomieszczenia
dSp = 0; dTzew = 0;         %wartosci ustawiane dla kazdej symulacji w funkcji symuluj

%=================== wielkosc skokow w badaniach =============
skok_SP = 1;                %skok wartosci zadanej [C]
skok_Tzew = -1;             %skok temperatury zewnetrznej [C]
pasmo = 0.05;               %pasmo czasu stabilizacji: 5% skoku SP, czyli +-0.05 C

%===========================================================
%   MODELE Z IDENTYFIKACJI (zad_2)  G(s) = K/(T*s+1)*exp(-T0*s)
%===========================================================
K = 0.002667;

T0_MS = 30.0;
T_MS  = 570.0;

T0_M2p = 63.0;
T_M2p  = 402.0;

G_MS  = tf(K, [T_MS 1],  'InputDelay', T0_MS);
G_M2p = tf(K, [T_M2p 1], 'InputDelay', T0_M2p);

%===========================================================
%   NASTAWY PI: a) ZN+MS, b) ZN+M2p, c) pidtune+MS, d) pidtune+M2p
%   ISA: u = Kp*(e + 1/Ti*calka(e))      IND: u = Kp*e + Ki*calka(e)
%   Regulator w schemacie ma postac IND, wiec Ki = Kp/Ti
%===========================================================
%Ziegler-Nichols (metoda odpowiedzi skokowej, PI)
Kp_a = 0.9*T_MS /(K*T0_MS);   Ti_a = 3.33*T0_MS;
Kp_b = 0.9*T_M2p/(K*T0_M2p);  Ti_b = 3.33*T0_M2p;

%pidtune zwraca postac rownolegla (IND)
C_MS  = pidtune(G_MS,  'PI');
C_M2p = pidtune(G_M2p, 'PI');

Kp_vect = [Kp_a, Kp_b, C_MS.Kp, C_M2p.Kp];
Ki_vect = [Kp_a/Ti_a, Kp_b/Ti_b, C_MS.Ki, C_M2p.Ki];
Ti_vect = Kp_vect ./ Ki_vect;

%parametry modelu w URM dla kazdego zestawu nastaw
T_vect  = [T_MS,  T_M2p,  T_MS,  T_M2p];
T0_vect = [T0_MS, T0_M2p, T0_MS, T0_M2p];

model_nazwa = {'MS'; 'M2p'; 'MS'; 'M2p'};
metoda = {'ZN'; 'ZN'; 'pidtune'; 'pidtune'};
etykiety = {'a) ZN, MS'; 'b) ZN, M2p'; 'c) pidtune, MS'; 'd) pidtune, M2p'};

%===========================================================
%   SYMULACJE
%===========================================================
for i = 1:4
    %skok SP (URM i URO liczone w jednej symulacji)
    wSP(i) = symuluj(schemat, czas, Kp_vect(i), Ki_vect(i), K, T_vect(i), T0_vect(i), skok_SP, 0); %#ok<SAGROW>
    ts_URM(i)  = czas_stabilizacji(wSP(i).t, wSP(i).PVm, Sp + skok_SP, pasmo, czas_skok); %#ok<SAGROW>
    ts_URO(i)  = czas_stabilizacji(wSP(i).t, wSP(i).PV,  Sp + skok_SP, pasmo, czas_skok); %#ok<SAGROW>

    %skok Tzew (tylko URO, SP bez zmian)
    wTz(i) = symuluj(schemat, czas, Kp_vect(i), Ki_vect(i), K, T_vect(i), T0_vect(i), 0, skok_Tzew); %#ok<SAGROW>
    ts_Tzew(i) = czas_stabilizacji(wTz(i).t, wTz(i).PV, Sp, pasmo, czas_skok); %#ok<SAGROW>
end

%===========================================================
%   1) SKOK SP: URM i URO dla nastaw a-d
%===========================================================
figure(1);
for i = 1:4
    subplot(2,4,i); hold on; grid on;
    plot(wSP(i).t, wSP(i).PV,  'b-',  'DisplayName', 'URO');
    plot(wSP(i).t, wSP(i).PVm, 'r--', 'DisplayName', 'URM');
    title(etykiety{i});
    xlabel('Czas [min]'); ylabel('PV: T_{wew1} [C]');
    legend('Location', 'southeast');

    subplot(2,4,i+4); hold on; grid on;
    plot(wSP(i).t, wSP(i).CV,  'b-',  'DisplayName', 'URO');
    plot(wSP(i).t, wSP(i).CVm, 'r--', 'DisplayName', 'URM');
    xlabel('Czas [min]'); ylabel('CV: Q_k [W]');
    legend('Location', 'northeast');
end
sgtitle('Skok SP: model (URM) i obiekt (URO)');

figure(2);
for i = 1:4
    subplot(2,2,1); hold on; grid on;
    plot(wSP(i).t, wSP(i).PVm, 'Color', kolor(i), 'LineStyle', linia{i}, 'DisplayName', etykiety{i});
    subplot(2,2,3); hold on; grid on;
    plot(wSP(i).t, wSP(i).CVm, 'Color', kolor(i), 'LineStyle', linia{i}, 'DisplayName', etykiety{i});
    subplot(2,2,2); hold on; grid on;
    plot(wSP(i).t, wSP(i).PV,  'Color', kolor(i), 'LineStyle', linia{i}, 'DisplayName', etykiety{i});
    subplot(2,2,4); hold on; grid on;
    plot(wSP(i).t, wSP(i).CV,  'Color', kolor(i), 'LineStyle', linia{i}, 'DisplayName', etykiety{i});
end
subplot(2,2,1); title('URM'); ylabel('PV: T_{wew1} [C]'); legend('Location', 'southeast');
subplot(2,2,2); title('URO'); ylabel('PV: T_{wew1} [C]'); legend('Location', 'southeast');
subplot(2,2,3); xlabel('Czas [min]'); ylabel('CV: Q_k [W]'); legend('Location', 'northeast');
subplot(2,2,4); xlabel('Czas [min]'); ylabel('CV: Q_k [W]'); legend('Location', 'northeast');
sgtitle('Skok SP: porownanie nastaw a-d');

%===========================================================
%   2) SKOK SP i SKOK Tzew na obiekcie (URO), wybrane nastawy
%===========================================================
wybrane = [2 4];            %najkrotszy ts na URO w ramach kazdej metody (ZN i pidtune)

figure(3);
for n = 1:numel(wybrane)
    i = wybrane(n);
    subplot(2,2,1); hold on; grid on;
    plot(wSP(i).t, wSP(i).PV, 'Color', kolor(i), 'LineStyle', linia{i}, 'DisplayName', etykiety{i});
    subplot(2,2,3); hold on; grid on;
    plot(wSP(i).t, wSP(i).CV, 'Color', kolor(i), 'LineStyle', linia{i}, 'DisplayName', etykiety{i});
    subplot(2,2,2); hold on; grid on;
    plot(wTz(i).t, wTz(i).PV, 'Color', kolor(i), 'LineStyle', linia{i}, 'DisplayName', etykiety{i});
    subplot(2,2,4); hold on; grid on;
    plot(wTz(i).t, wTz(i).CV, 'Color', kolor(i), 'LineStyle', linia{i}, 'DisplayName', etykiety{i});
end
subplot(2,2,1); title(sprintf('URO: skok SP = %g C', skok_SP)); ylabel('PV: T_{wew1} [C]'); legend('Location', 'southeast');
subplot(2,2,2); title(sprintf('URO: skok T_{zew} = %g C', skok_Tzew)); ylabel('PV: T_{wew1} [C]'); legend('Location', 'southeast');
subplot(2,2,3); xlabel('Czas [min]'); ylabel('CV: Q_k [W]'); legend('Location', 'northeast');
subplot(2,2,4); xlabel('Czas [min]'); ylabel('CV: Q_k [W]'); legend('Location', 'southeast');

%===========================================================
%   3) TABELA
%===========================================================
Tabela = table(metoda, model_nazwa, round(Kp_vect',2), round(Ti_vect',2), round(Kp_vect',2), round(Ki_vect',3), ...
    round(ts_URM',1), round(ts_URO',1), round(ts_Tzew',1), ...
    'VariableNames', {'Nastawy', 'Model', 'Kp_ISA', 'Ti_ISA', 'Kp_IND', 'Ki_IND', 'ts_URM_SP', 'ts_URO_SP', 'ts_URO_Tzew'}, ...
    'RowNames', {'a'; 'b'; 'c'; 'd'});
fprintf('\nCzas stabilizacji ts [min] od chwili skoku, pasmo +-%g C (NaN = brak stabilizacji do konca symulacji)\n', pasmo);
disp(Tabela);

%===========================================================
%   FUNKCJE
%===========================================================
function w = symuluj(schemat, czas, Kp, Ki, K, T_m, T0_m, dSp, dTzew)
    %Parametry podawane przez SimulationInput - plik modelu nie jest zmieniany.
    in = Simulink.SimulationInput(schemat);
    in = in.setModelParameter('StopTime', num2str(czas));
    in = in.setModelParameter('LimitDataPoints', 'off');    %inaczej tout ma tylko 1000 probek
    in = in.setVariable('Kp', Kp);
    in = in.setVariable('Ki', Ki);
    in = in.setVariable('dSp', dSp);
    in = in.setVariable('dTzew', dTzew);
    in = in.setBlockParameter([schemat '/Transfer Fcn'], 'Numerator', mat2str(K));
    in = in.setBlockParameter([schemat '/Transfer Fcn'], 'Denominator', mat2str([T_m 1]));
    in = in.setBlockParameter([schemat '/Transport' newline 'Delay'], 'DelayTime', mat2str(T0_m));
    out = sim(in);

    Qk0 = evalin('base', 'Qk0');
    w.t   = out.tout;
    w.PV  = out.aTwew_1;
    w.CV  = out.aCV;
    w.PVm = out.aTwewM;
    w.CVm = Qk0 + out.aCVM;     %PI w URM pracuje na odchylkach od punktu pracy
end

function ts = czas_stabilizacji(t, y, y_zad, pasmo, t_skok)
    %Czas od skoku do chwili, po ktorej PV pozostaje w pasmie wokol y_zad.
    idx = find(t >= t_skok & abs(y - y_zad) > pasmo, 1, 'last');
    if isempty(idx)
        ts = 0;                 %PV nie opuscilo pasma
    elseif idx == numel(t)
        ts = NaN;               %brak stabilizacji do konca symulacji
    else
        ts = t(idx+1) - t_skok;
    end
end
