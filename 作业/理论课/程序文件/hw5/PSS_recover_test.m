d25_n = du_n(25);
d29_n = du_n(29);
d34_n = du_n(34);
[d29_n_part1,d29_n_part2] = resize_sequence(d29_n);
%利用离散反傅里叶变换---假如我们发射的PSS序列为d29_n
x_128 = OFDM_symbol(128, [zeros(1,32) d29_n_part1 0 d29_n_part2 zeros(1,33)]);
%对接收到的信号进行低通滤波
%利用离散傅里叶变换得到发射的PSS序列信息
x_128_received = OFDM_reverse_symbol(x_128);
figure(1);
subplot(2,1,1);
plot(d29_n,'ro');
subplot(2,1,2);
plot(x_128_received,'ro');
