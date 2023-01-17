BER_ZF = zeros(1,41);
BER_ML = zeros(1,41);
for i = -20:1:20
    BER_ZF(i+21) = Force_Zero(i);
    BER_ML(i+21) = ML(i);
end
%task2.1
figure(1);
plot((-20:20), BER_ZF,'-o','lineWidth',2);
grid on;
title(' Detection Error VS Different SNR in STBC 4x2 by Force Zero');
set(gca, 'FontWeight','bold','LineWidth',2);
xlabel('SNR(dB)');
ylabel('Detection Error');


%task2.2
figure(2);
plot((-20:20),BER_ML,'-ro','lineWidth',2)
grid on;
title(' Detection Error VS Different SNR in STBC 4x2 by ML');
set(gca, 'FontWeight','bold','LineWidth',2);
xlabel('SNR(dB)');
ylabel('Detection Error');

%combiner
figure(3)
plot((-20:20), BER_ZF,'-o','lineWidth',2);
hold on
plot((-20:20),BER_ML,'-ro','lineWidth',2);
grid on
title(' Detection Error VS Different SNR in STBC 4x2');
set(gca, 'FontWeight','bold','LineWidth',2);
xlabel('SNR(dB)');
ylabel('Detection Error');
legend('Force Zero','ML')



    