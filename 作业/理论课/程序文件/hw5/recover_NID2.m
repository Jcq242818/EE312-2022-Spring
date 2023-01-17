%先产生本地的3个PSS原始序列
d25_n = du_n(25);d29_n = du_n(29);d34_n = du_n(34);
[d34_n_part1,d34_n_part2] = resize_sequence(d34_n);
%利用离散反傅里叶变换---假如我们发射的PSS序列为d29_n
x_128 = OFDM_symbol(128, [zeros(1,32) d34_n_part1 0 d34_n_part2 zeros(1,33)]);
%利用离散傅里叶变换得到发射的PSS序列信息
x_128_received = OFDM_reverse_symbol(x_128);
x_128_received = [x_128_received(33:63) x_128_received(65:95)];
%利用互相关进行检测
figure(1); 
subplot(3,1,1);
plot(abs(xcorr(d25_n, d25_n))); 
xlabel('n')
title('Cross correlation betweeen local PSS sequence(u=25)');

 
subplot(3,1,2);
plot(abs(xcorr(d29_n, d29_n))); 
xlabel('n')
title('Cross correlation betweeen local PSS sequence(u=29)');


subplot(3,1,3);
plot(abs(xcorr(d34_n, d34_n))); 
xlabel('n')
title('Cross correlation betweeen local PSS sequence(u=34)');

figure(2)
subplot(3,1,1);
plot(abs(xcorr(d25_n, d29_n))); 
xlabel('n')
title('Cross correlation betweeen local PSS sequence(u = 25 and u = 29)'); 

subplot(3,1,2); 
plot(abs(xcorr(d29_n, d34_n))); 
xlabel('n')
title('Cross correlation betweeen local PSS sequence(u = 29 and u = 34)'); 


subplot(3,1,3);
plot(abs(xcorr(d25_n, d34_n))); 
xlabel('n')
title('Cross correlation betweeen local PSS sequence(u = 25 and u = 34)'); 




