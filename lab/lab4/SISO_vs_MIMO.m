load .\EE312-Ji-lab4-MIMO\MIMO.mat
load .\EE312-lab4-Ji-SISO\SISO.mat

%task1
figure(1);
plot((-20:20), MIMO,'-o','lineWidth',2);
grid on;
title(' BER VS Different Eb/No in 4 QAM Alamouti 2x2');
set(gca, 'FontWeight','bold','LineWidth',2);
xlabel('Eb/No (dB)');
ylabel('BER');
legend('Alamouti');

%task2
figure(2);
plot((-20:20),SISO,'-ro','lineWidth',2)
grid on;
title(' BER VS Different Eb/No in 4 QAM SISO');
set(gca, 'FontWeight','bold','LineWidth',2);
xlabel('Eb/No (dB)');
ylabel('BER');
legend('SISO');

%task2
figure(3);
plot((-20:20), MIMO,'-ob','lineWidth',2);
hold on;
plot((-20:20),SISO,'-ro','lineWidth',2)
grid on;
title(' BER VS Different Eb/No in 4 QAM');
set(gca, 'FontWeight','bold','LineWidth',2);
xlabel('Eb/No (dB)');
ylabel('BER');
legend('Alamouti','SISO');


