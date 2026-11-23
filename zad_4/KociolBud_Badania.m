clear all; close all;
skala = 60;             %skala czasu (wszystkie czasy w minutach)
%gdy n=60, to Max step size daæ 0.1
schemat = 'KociolBud3CvwCvg_regulacja_pog';
IlePom = 3;                     %ile pomieszczen
czas = 5000; czas_skok = 500;
%----------------------------------------------------
kolor = 'rgbcm'; linia = ['- '; '--'; ': '];
KociolBud_skryptWN;                             %obliczenia parametrow (warunki nominalne), nazwa schematu
%===========================================================
%            BADANIA - regulacja centralna: RB vs RP
%  PV = Tkz, CV = Qk, regulator PI (blok PI_MS w schemacie)
%  RB (regulacja bezposrednia): zadana Tkz = Sp (stala)
%  RP (regulacja pogodowa)    : zadana Tkz = Az*Sp - Bz*Tzew,
%                               gdzie Sp = zadana temp. wewnetrzna
%  przelacznik 'Manual Switch1' w schemacie: sw=0 -> RB, sw=1 -> RP
%===========================================================
%============= warunki poczatkowe nominalne  ===================
Tzew0 = TzewN+1;
Qk0 = QkN*1;
Fg0 = [1, 1, 1] .* FgN;
Qd0 = [0, 0, 0];                                   %zawsze
KociolBud_skryptP0;                                %m.in. Tkz0, Twew0
Az = (TgzN - TzewN) / (TwewN - TzewN);
Bz = (TgzN - TwewN) / (TwewN - TzewN);

%=================== model (identyfikacja.m, metoda M2P) ======================
% G(s) = K*exp(-T0*s)/(T*s+1), wejscie Qk, wyjscie Tkz
K_m = 0.0079914; T_m = 264.9; T0_m = 157.35;       %wartosci z identyfikacja.m

%=================== nastawy ======================
% 1 - Ziegler-Nichols (PI), 2 - pidtune; Ki = Kp/Ti
Kp_ZN = 189.5981;  Ti_ZN = 523.9755;  Ki_ZN = Kp_ZN / Ti_ZN;
Kp_PT = 132.1198;  Ki_PT = 0.43713;   Ti_PT = Kp_PT / Ki_PT;
Kp_vect = [Kp_ZN, Kp_PT];
Ki_vect = [Ki_ZN, Ki_PT];
Ti_vect = [Ti_ZN, Ti_PT];
nazwa_nastaw = {'ZN', 'pidtune'};
nazwa_ukl    = {'RB', 'RP'};                       %indeks = sw+1
styl = {'-', '--'};                                %RB / RP
% kolory: wiersz = uklad (RB / RP), kolumna = nastawy (ZN / pidtune)
kol  = {[0 0 1], [0 0.7 0];      %RB: niebieski, pomaranczowy
        [1 0.5 0], [1 0 0]};      %RP: zielony, czerwony

%=================== scenariusze zaklocen ======================
% skok SP: rownowazny skok zadanej Tkz o +1 st.C w obu ukladach
%   RB: Sp = Tkz0,                dSp = 1
%   RP: Sp = (Tkz0 + Bz*Tzew0)/Az, dSp = 1/Az  (-> Tkz_zad = Tkz0 + 1)
% skok Tzew: Tzew0 -> Tzew0 + 1 (Sp bez zmian)
dTkz = 1;
scen_nazwa = {'skok SP (zadana Tkz +1 st.C)', 'skok Tzew (+1 st.C)'};
dTzew_s = [0, 1];
dQk = 0*QkN;
dFg = [0, 0, 0] .* FgN;     %procent przeplywu nominalnego danego grzejnika
dQd = [0, 0, 0] .* QgN;      %procent zapotrzebowania nominalnego danego pomieszczenia

tol = 0.02;                  %pasmo czasu stabilizacji: 2% maks. odchylenia
load_system(schemat);
wyniki = {};                 %tabela wskaznikow
for s = 1:2                  %scenariusz
    dTzew = dTzew_s(s);
    fig = figure('Name', scen_nazwa{s});
    ax1 = subplot(2,1,1); hold on; grid on;
    ax2 = subplot(2,1,2); hold on; grid on;
    for i = 1:2              %nastawy
        Kp = Kp_vect(i);
        Ki = Ki_vect(i);
        for sw = 0:1         %0 - RB, 1 - RP
            set_param([schemat '/Manual Switch1'], 'sw', num2str(sw));
            if sw == 0       %RB
                Sp = Tkz0;            dSp = (s == 1) * dTkz;
            else             %RP
                Sp = (Tkz0 + Bz*Tzew0) / Az;  dSp = (s == 1) * dTkz / Az;
            end
            [t] = sim(schemat, czas);
            t = t(:);
            twew = aTwew_1(:); cv = aCV(:); tkz = aTkz(:);
            etykieta = [nazwa_ukl{sw+1} ', ' nazwa_nastaw{i}];
            plot(ax1, t, twew, 'Color', kol{sw+1,i}, 'LineStyle', styl{sw+1}, 'LineWidth', 1.4, 'DisplayName', etykieta);
            plot(ax2, t, cv,   'Color', kol{sw+1,i}, 'LineStyle', styl{sw+1}, 'LineWidth', 1.4, 'DisplayName', etykieta);
            [ts_w, dm_w] = czas_stab(t, twew, czas_skok, tol);
            [ts_k, dm_k] = czas_stab(t, tkz,  czas_skok, tol);
            [ts_c, dm_c] = czas_stab(t, cv,   czas_skok, tol);
            wyniki(end+1,:) = {scen_nazwa{s}, nazwa_ukl{sw+1}, nazwa_nastaw{i}, ...
                Kp, Ti_vect(i), ts_w, dm_w, ts_k, ts_c}; %#ok<SAGROW>
        end
    end
    xlim(ax1, [czas_skok-50 czas]); xlim(ax2, [czas_skok-50 czas]);
    ylabel(ax1, 'T_{wew1} [^oC]'); title(ax1, ['Temperatura wewnatrz - ' scen_nazwa{s}]);
    ylabel(ax2, 'CV = Q_k'); xlabel(ax2, 'Czas [min]'); title(ax2, 'Zmienna sterujaca (moc kotla)');
    legend(ax1, 'Location', 'best'); legend(ax2, 'Location', 'best');
end

%=================== tabela wynikow ======================
T = cell2table(wyniki, 'VariableNames', {'Skok','Uklad','Nastawy','Kp','Ti','ts_Twew','dmax_Twew','ts_Tkz','ts_CV'});
model = sprintf('M2P: K=%.5g, T=%.4g, T0=%.4g (inercja I rzedu + opoznienie)', K_m, T_m, T0_m);
fprintf('\nModel obiektu (Qk -> Tkz): %s\n', model);
fprintf('Nastawy: ZN: Kp=%.4f, Ti=%.2f (Ki=%.5f); pidtune: Kp=%.4f, Ti=%.2f (Ki=%.5f)\n', ...
    Kp_ZN, Ti_ZN, Ki_ZN, Kp_PT, Ti_PT, Ki_PT);
fprintf('ts = czas stabilizacji (pasmo %.0f%% maks. odchylenia) liczony od chwili skoku [min]\n', tol*100);
disp(T);

%================ funkcja pomocnicza ================
function [ts, dmax] = czas_stab(t, y, t_skok, tol)
% czas stabilizacji (pasmo tol*dmax wokol wartosci ustalonej) i maks. odchylenie
    i0 = find(t < t_skok, 1, 'last');
    y0 = y(i0);
    idx = t >= t_skok;
    tt = t(idx) - t_skok;  yy = y(idx);
    yend = yy(end);
    dmax = max(abs(yy - y0));
    pasmo = max(tol * dmax, 1e-6);
    k = find(abs(yy - yend) > pasmo, 1, 'last');
    if isempty(k)
        ts = 0;
    elseif k == numel(tt)
        ts = NaN;
    else
        ts = tt(k+1);
    end
end
