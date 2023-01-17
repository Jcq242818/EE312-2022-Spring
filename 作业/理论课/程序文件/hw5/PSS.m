% 对三种不同情况的u值产生Zadoff序列
d25_n = du_n(25);
figure(1);
plot(d25_n, 'ro');
xlabel('Real part'); ylabel('Imaginary Part'); 
title('PSS in Frequency domain u=25');


d29_n = du_n(29);
figure(2);
plot(d29_n, 'ro');
xlabel('Real part'); ylabel('Imaginary Part');
title('PSS in Frequency domain u=29');
 
d34_n = du_n(34);
figure(3);
plot(d34_n, 'ro');
xlabel('Real part'); ylabel('Imaginary Part'); 
title('PSS in Frequency domain u=34');

