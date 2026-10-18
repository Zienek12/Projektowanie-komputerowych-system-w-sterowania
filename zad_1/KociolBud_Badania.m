clear all; close all;

skala = 60;                         % skala czasu (czasy w minutach)
schemat = 'KociolBud3CvwCvg';
IlePom = 3;
czas = 3000;
czas_skok = 500;                    % chwila podania skoku

kolor = 'rgbm';
linia = ['- '; '--'; ': '; '-.'];

KociolBud_skryptWN;                 % parametry nominalne modelu

% Model (wartosci parametrow z identyfikacji).
T = 1000; T0 = 100; k = 4 / (0.1*QkN);

% ========================================================================
% A. Porownanie odpowiedzi w czterech punktach pracy
%
% P1: warunki nominalne
% P2: wyzsza temperatura zewnetrzna
% P3: mniejsza moc kotla i mniejszy przeplyw
% P4: wyzsza temperatura zewnetrzna, mniejsza moc kotla i mniejszy przeplyw
% ========================================================================
TzewP = [TzewN,       TzewN+10, TzewN,       TzewN+10];
QkP   = [QkN,         QkN,       0.8*QkN,    0.8*QkN];
FgP   = [1,            1,        0.8,        0.8];
opisP = {'P1: nominalny', 'P2: Tzew+10', ...
         'P3: Qk,Fg 80%', 'P4: Tzew+10, Qk,Fg 80%'};

% Skok Tzew i skok Qk sa podawane pojedynczo. Skok Qk ma amplitude 10%.
dTzew = 1;
dQkProc = 0.10;
dFg = [0, 0, 0];
dQd = [0, 0, 0];

% Reakcje wzgledne (odjete wartosci przed skokiem).
TwewTzew = [];
TkpTzew = [];
TwewQk = [];
TkpQk = [];

for p = 1:4
    Tzew0 = TzewP(p);
    Qk0 = QkP(p);
    Fg0 = [1, 1, 1] .* FgP(p) .* FgN;
    Qd0 = [0, 0, 0];
    tau_siec = 240 / skala;

    % Warunki poczatkowe dla danego punktu pracy.
    KociolBud_skryptP0;

    % Skok temperatury zewnetrznej.
    dTzew = 1;
    dQk = 0;
    [t] = sim(schemat, czas);
    if p == 1
        TwewTzew = zeros(numel(aTwew_1), 4);
        TkpTzew = zeros(numel(aTkp), 4);
        TwewQk = zeros(numel(aTwew_1), 4);
        TkpQk = zeros(numel(aTkp), 4);
    end
    TwewTzew(:, p) = aTwew_1(:) - aTwew_1(1);
    TkpTzew(:, p) = aTkp(:) - aTkp(1);

    % Skok mocy kotla, przy niezmienionym Tzew.
    dTzew = 0;
    dQk = dQkProc * Qk0;
    [tQk] = sim(schemat, czas);
    TwewQk(:, p) = aTwew_1(:) - aTwew_1(1);
    TkpQk(:, p) = aTkp(:) - aTkp(1);
end

figure(1); clf; hold on; grid on;
for p = 1:4
    plot(t, TwewTzew(:,p), [kolor(p), linia(p,:)], 'LineWidth', 1.1);
end
title('Skok T_{zew}: T_{wew} w czterech punktach pracy');
xlabel('t [min]'); ylabel('\Delta T_{wew} [^oC]');
legend(opisP, 'Location', 'best');

figure(2); clf; hold on; grid on;
for p = 1:4
    plot(t, TkpTzew(:,p), [kolor(p), linia(p,:)], 'LineWidth', 1.1);
end
title('Skok T_{zew}: T_{kp} w czterech punktach pracy');
xlabel('t [min]'); ylabel('\Delta T_{kp} [^oC]');
legend(opisP, 'Location', 'best');

figure(3); clf; hold on; grid on;
for p = 1:4
    plot(tQk, TwewQk(:,p), [kolor(p), linia(p,:)], 'LineWidth', 1.1);
end
title('Skok Q_k (10%): T_{wew} w czterech punktach pracy');
xlabel('t [min]'); ylabel('\Delta T_{wew} [^oC]');
legend(opisP, 'Location', 'best');

figure(4); clf; hold on; grid on;
for p = 1:4
    plot(tQk, TkpQk(:,p), [kolor(p), linia(p,:)], 'LineWidth', 1.1);
end
title('Skok Q_k (10%): T_{kp} w czterech punktach pracy');
xlabel('t [min]'); ylabel('\Delta T_{kp} [^oC]');
legend(opisP, 'Location', 'best');

% Bezposrednie porownanie przyrostow temperatur dla obu wymuszen.
figure(5); clf;
subplot(2,1,1); hold on; grid on;
for p = 1:4
    plot(t, TwewTzew(:,p), [kolor(p), linia(p,:)]);
end
title('\Delta T_{wew} - porownanie reakcji');
xlabel('t [min]'); ylabel('\Delta T_{wew} [^oC]');
legend(opisP, 'Location', 'best');
subplot(2,1,2); hold on; grid on;
for p = 1:4
    plot(tQk, TwewQk(:,p), [kolor(p), linia(p,:)]);
end
xlabel('t [min]'); ylabel('\Delta T_{wew} [^oC]');
legend(opisP, 'Location', 'best');

figure(6); clf;
subplot(2,1,1); hold on; grid on;
for p = 1:4
    plot(t, TkpTzew(:,p), [kolor(p), linia(p,:)]);
end
title('\Delta T_{kp} - porownanie reakcji');
xlabel('t [min]'); ylabel('\Delta T_{kp} [^oC]');
legend(opisP, 'Location', 'best');
subplot(2,1,2); hold on; grid on;
for p = 1:4
    plot(tQk, TkpQk(:,p), [kolor(p), linia(p,:)]);
end
xlabel('t [min]'); ylabel('\Delta T_{kp} [^oC]');
legend(opisP, 'Location', 'best');

% ========================================================================
% B. Wplyw opoznienia transportowego
% ========================================================================
tauMale = 0.1;                      % praktycznie brak opoznienia
tauSpec = 24000 / skala;              % opoznienie, dla ktorego widac reakcje
tauBadanie = [tauMale, tauSpec];
opisTau = {'male opoznienie', 'opoznienie specyficzne'};
TwewTau = [];
TkpTau = [];

% Opoznienie badane jest w nominalnym punkcie pracy dla skoku Tzew.
Tzew0 = TzewN;
Qk0 = QkN;
Fg0 = [1, 1, 1] .* FgN;
Qd0 = [0, 0, 0];
dTzew = 1;
dQk = 0;
for j = 1:2
    tau_siec = tauBadanie(j);
    KociolBud_skryptP0;
    [tTau] = sim(schemat, czas);
    if j == 1
        TwewTau = zeros(numel(aTwew_1), 2);
        TkpTau = zeros(numel(aTkp), 2);
    end
    TwewTau(:,j) = aTwew_1(:) - aTwew_1(1);
    TkpTau(:,j) = aTkp(:) - aTkp(1);
end

figure(7); clf; hold on; grid on;
plot(tTau, TwewTau(:,1), 'b-', 'LineWidth', 1.2);
plot(tTau, TwewTau(:,2), 'r--', 'LineWidth', 1.2);
title('Wplyw opoznienia transportowego na T_{wew}');
xlabel('t [min]'); ylabel('\Delta T_{wew} [^oC]');
legend(opisTau, 'Location', 'best');

figure(8); clf; hold on; grid on;
plot(tTau, TkpTau(:,1), 'b-', 'LineWidth', 1.2);
plot(tTau, TkpTau(:,2), 'r--', 'LineWidth', 1.2);
title('Wplyw opoznienia transportowego na T_{kp}');
xlabel('t [min]'); ylabel('\Delta T_{kp} [^oC]');
legend(opisTau, 'Location', 'best');
