clear all; close all;
skala = 60;             %skala czasu (wszystkie czasy w minutach)
%gdy n=60, to Max step size dac 0.1
schemat = 'KociolBud3CvwCvg';
IlePom = 3;                     %ile pomieszczen
czas = 5000; czas_skok = 500;
%----------------------------------------------------
kolor = 'rgbcm'; linia = ['- '; '--'; ': '];
KociolBud_skryptWN;                             %obliczenia parametrow (warunki nominalne), nazwa schematu
%===========================================================
%   Sp.4  Regulacja centralna pogodowa (RP) i bezposrednia (RB)
%   Uklad regulacji PI: PV = Tkz, CV = Qk
%   RB: Sp = const (= Tkz nominalne)
%   RP: Sp = Tkz0 - a_pog*(Tzew - Tzew0)  (krzywa grzewcza)
%   Parametry schematu: reg (0 - otwarty, 1 - regulator PI),
%   rp (0 - RB, 1 - RP), Sp0, dSp, Kp, Ki, a_pog
%===========================================================
%============= warunki poczatkowe nominalne  ===================
Tzew0 = TzewN+1;
Qk0 = QkN*1;
Fg0 = [1, 1, 1] .* FgN;
Qd0 = [0, 0, 0];                                   %zawsze
KociolBud_skryptP0;
Sp0 = Tkz0;                                        %punkt pracy: Sp = Tkz w stanie ustalonym

%--- nachylenie krzywej grzewczej (Twew1 = const przy zmianie Tzew, Fg stale) ---
xa = -A \ (B * [Tzew0+1; Qk0]);
xb = -A \ (B * [Tzew0+1; Qk0+1]);
Qk_pog = Qk0 + (Twew0(1) - xa(1)) / (xb(1) - xa(1));
x_pog  = xa + (Qk_pog - Qk0) * (xb - xa);
a_pog  = Tkz0 - x_pog(2*IlePom+1);                 %[oC Tkz / oC Tzew]

%=================== zaklocenia (domyslnie zerowe) ======================
dTzew = 0; dSp = 0; dQk = 0;
dFg = [0, 0, 0] .* FgN;     %procent przeplywu nominalnego danego grzejnika
dQd = [0, 0, 0] .* QgN;     %procent zapotrzebowania nominalnego danego pomieszczenia
Kp = 0; Ki = 0; reg = 0; rp = 0;

%===========================================================
%   IDENTYFIKACJA (metoda dwoch punktow M2P) - uklad otwarty (reg = 0)
%   (ta sama metoda co w zad_4/identyfikacja.m)
%===========================================================
czas_id = 3000;
dQk = 0.1*QkN;
[t] = sim(schemat, czas_id);
idx_skok = find(t >= czas_skok, 1);
y_skok = aTkz - aTkz(idx_skok);
Ymax = max(y_skok);
idx_t1 = find(y_skok >= 0.283*Ymax, 1);
idx_t2 = find(y_skok >= 0.632*Ymax, 1);
t1 = t(idx_t1) - czas_skok;
t2 = t(idx_t2) - czas_skok;
T_m2p  = 1.5*(t2 - t1);
T0_m2p = t2 - 1.5*t1;
K_m2p  = Ymax / dQk;                               %wzmocnienie statyczne [oC/W]
if T0_m2p <= 0
    warning('T0 z M2P <= 0, ustawiono T0 = 1 min'); T0_m2p = 1;
end
dQk = 0;

figure(10); hold on; grid on;
plot(t, aTkz, 'b-', 'LineWidth', 1.5);
t_m = max(t - czas_skok, 0);
y_m = aTkz(idx_skok) + (t_m >= T0_m2p) .* (K_m2p*0.1*QkN) .* (1 - exp(-(t_m - T0_m2p)/T_m2p));
plot(t, y_m, 'r--', 'LineWidth', 1.5);
legend('obiekt (symulacja)', 'model M2P'); xlabel('t [min]'); ylabel('T_{kz} [^oC]');
title('Identyfikacja M2P w punkcie nominalnym');

%===========================================================
%   NASTAWY: Ziegler-Nichols (PI) oraz pidtune
%===========================================================
Kp_ZN = 0.9 * T_m2p / (K_m2p * T0_m2p);
Ti_ZN = 3.33 * T0_m2p;
Ki_ZN = Kp_ZN / Ti_ZN;
G_M2p = tf(K_m2p, [T_m2p 1], 'InputDelay', T0_m2p);
C_pt  = pidtune(G_M2p, 'PI');
Kp_pt = C_pt.Kp; Ki_pt = C_pt.Ki; Ti_pt = Kp_pt / Ki_pt;

Kp_t = [Kp_ZN, Kp_pt];
Ki_t = [Ki_ZN, Ki_pt];
Ti_t = [Ti_ZN, Ti_pt];
nazwy_nast  = {'ZN', 'pidtune'};
nazwy_ukl   = {'RB', 'RP'};
nazwy_skok  = {'skok SP', 'skok Tzew'};

%===========================================================
%   BADANIA: RB i RP, nastawy ZN i pidtune, skok SP oraz skok Tzew
%===========================================================
dSp_skok = 5;           %skok wartosci zadanej Tkz [oC]
dTzew_skok = 5;         %skok temperatury zewnetrznej [oC]
reg = 1;
ts = nan(2,2,2,2);      %czas stabilizacji (d, m, n, [Tkz Twew1])
ymx = nan(2,2,2,2);     %maksymalne odchylenie od stanu poczatkowego
for d = 1:2
    figure(d);
    leg = {};
    for m = 1:2
        for n = 1:2
            rp = m-1; Kp = Kp_t(n); Ki = Ki_t(n);
            dSp = (d==1)*dSp_skok; dTzew = (d==2)*dTzew_skok;
            [t] = sim(schemat, czas);
            sty = strcat(kolor(m), linia(n,:));
            subplot(3,1,1); hold on; grid on; plot(t, aTwew_1, sty, 'LineWidth', 1.2);
            subplot(3,1,2); hold on; grid on; plot(t, aTkz, sty, 'LineWidth', 1.2);
            subplot(3,1,3); hold on; grid on; plot(t, aQk/1000, sty, 'LineWidth', 1.2);
            leg{end+1} = [nazwy_ukl{m} ' - ' nazwy_nast{n}];
            %--- wskazniki jakosci (pasmo 5% maksymalnego odchylenia) ---
            Y = [aTkz(:), aTwew_1(:)];
            for j = 1:2
                y = Y(:,j);
                y0 = y(find(t >= czas_skok, 1));
                yk = y(end);
                dev = max(abs(y(t >= czas_skok) - y0));
                band = max(0.05*max(dev, abs(yk-y0)), 0.01);
                ii = find(abs(y - yk) > band & t >= czas_skok, 1, 'last');
                if isempty(ii), ts(d,m,n,j) = 0;
                elseif ii >= numel(t), ts(d,m,n,j) = NaN;
                else, ts(d,m,n,j) = t(ii+1) - czas_skok; end
                ymx(d,m,n,j) = dev;
            end
        end
    end
    subplot(3,1,1); title(['T_{wew1} [^oC] - ' nazwy_skok{d}]); ylabel('T_{wew1}'); legend(leg, 'Location', 'best');
    subplot(3,1,2); title('T_{kz} (PV) [^oC]'); ylabel('T_{kz}');
    subplot(3,1,3); title('Q_k (CV) [kW]'); ylabel('Q_k'); xlabel('t [min]');
end

%===========================================================
%   TABELA WYNIKOW
%===========================================================
fprintf('\nModel M2P: K = %.5g [oC/W], T = %.4g min, T0 = %.4g min, a_pog = %.4g\n', K_m2p, T_m2p, T0_m2p, a_pog);
fprintf('Czas stabilizacji: pasmo 5%% max odchylenia (min od momentu skoku)\n');
fprintf('%-10s %-8s %-8s %-9s %-10s %-9s %-10s %-10s %-10s\n', 'skok', 'uklad', 'metoda', 'Kp', 'Ki', 'Ti', 'ts Tkz', 'ts Twew1', 'max dTwew1');
for d = 1:2
    for m = 1:2
        for n = 1:2
            fprintf('%-10s %-8s %-8s %-9.4g %-10.4g %-9.4g %-10.1f %-10.1f %-10.3f\n', nazwy_skok{d}, nazwy_ukl{m}, nazwy_nast{n}, ...
                Kp_t(n), Ki_t(n), Ti_t(n), ts(d,m,n,1), ts(d,m,n,2), ymx(d,m,n,2));
        end
    end
end
