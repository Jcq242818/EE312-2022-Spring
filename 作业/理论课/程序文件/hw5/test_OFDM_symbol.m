%由PSS原始序列(u=29)产生为一个OFDMsymbol的过程
%先对u=29进行拆分，拆成两半。因为插入的原则是0号不插，因此整个序列要想在低频插入的话要先切成一半。之后再插入
d29_n= du_n(29);
[d29_n_part1,d29_n_part2] = resize_sequence(d29_n);
x_128 = OFDM_symbol(128, [zeros(1,32) d29_n_part1 0 d29_n_part2 zeros(1,33)]);
x_256 = OFDM_symbol(256, [zeros(1,96) d29_n_part1 0 d29_n_part2 zeros(1,97)]);
x_512 = OFDM_symbol(512, [zeros(1,224) d29_n_part1 0 d29_n_part2 zeros(1,225)]);
x_1024 = OFDM_symbol(1024, [zeros(1,480) d29_n_part1 0 d29_n_part2 zeros(1,481)]);
x_1536 = OFDM_symbol(1536, [zeros(1,736) d29_n_part1 0 d29_n_part2 zeros(1,737)]);
x_2048 = OFDM_symbol(2048, [zeros(1,992) d29_n_part1 0 d29_n_part2 zeros(1,993)]);
% figure(1)
% subplot(2,1,1);
% plot(real(x_128));
% xlabel('n'); ylabel('Real part');
% title('OFDM symbol with sample rate 1.92MHz');
% subplot(2,1,2);
% plot(imag(x_128));
% xlabel('n'); ylabel('Imaginary part');
% figure(2)
% subplot(2,1,1);
% plot(real(x_256));
% xlabel('n'); ylabel('Real part');
% title('OFDM symbol with sample rate 3.84MHz');
% subplot(2,1,2);
% plot(imag(x_256));
% xlabel('n'); ylabel('Imaginary part');
% figure(3)
% subplot(2,1,1);
% plot(real(x_512));
% xlabel('n'); ylabel('Real part');
% title('OFDM symbol with sample rate 7.68MHz');
% subplot(2,1,2);
% plot(imag(x_512));
% xlabel('n'); ylabel('Imaginary part');
% figure(4)
% subplot(2,1,1);
% plot(real(x_1024));
% xlabel('n'); ylabel('Real part');
% title('OFDM symbol with sample rate 15.36MHz');
% subplot(2,1,2);
% plot(imag(x_1024));
% xlabel('n'); ylabel('Imaginary part');
% figure(5)
% subplot(2,1,1);
% plot(real(x_1536));
% xlabel('n'); ylabel('Real part');
% title('OFDM symbol with sample rate 23.04MHz');
% subplot(2,1,2);
% plot(imag(x_1536));
% xlabel('n'); ylabel('Imaginary part');
% figure(6)
% subplot(2,1,1);
% plot(real(x_2048));
% xlabel('n'); ylabel('Real part');
% title('OFDM symbol with sample rate 30.72MHz');
% subplot(2,1,2);
% plot(imag(x_2048));
% xlabel('n'); ylabel('Imaginary part');
% 利用1.92 MHz的采样率进行采样
x_128_sample = x_128;
x_256_sample = x_256(1:2:256);
x_512_sample = x_512(1:4:512);
x_1024_sample = x_1024(1:8:1024);
x_1536_sample = x_1536(1:12:1536);
x_2048_sample = x_2048(1:16:2048);
figure(7)
subplot(2,1,1);
plot(real(x_128_sample));
xlabel('n'); ylabel('Real part');
title('OFDM symbol(sampling rate = 1.92MHz) after sample at 1.92MHz');
subplot(2,1,2);
plot(imag(x_128_sample));
xlabel('n'); ylabel('Imaginary part');
figure(8)
subplot(2,1,1);
plot(real(x_256_sample));
xlabel('n'); ylabel('Real part');
title('OFDM symbol(sampling rate = 3.84MHz) after sample at 1.92MHz');
subplot(2,1,2);
plot(imag(x_256_sample));
xlabel('n'); ylabel('Imaginary part');
figure(9)
subplot(2,1,1);
plot(real(x_512_sample));
xlabel('n'); ylabel('Real part');
title('OFDM symbol(sampling rate = 7.68MHz) after sample at 1.92MHz');
subplot(2,1,2);
plot(imag(x_512_sample));
xlabel('n'); ylabel('Imaginary part');
figure(10)
subplot(2,1,1);
plot(real(x_1024_sample));
xlabel('n'); ylabel('Real part');
title('OFDM symbol(sampling rate = 15.36MHz) after sample at 1.92MHz');
subplot(2,1,2);
plot(imag(x_1024_sample));
xlabel('n'); ylabel('Imaginary part');
figure(11)
subplot(2,1,1);
plot(real(x_1536_sample));
xlabel('n'); ylabel('Real part');
title('OFDM symbol(sampling rate = 23.04MHz) after sample at 1.92MHz');
subplot(2,1,2);
plot(imag(x_1536_sample));
xlabel('n'); ylabel('Imaginary part');
figure(12)
subplot(2,1,1);
plot(real(x_2048_sample));
xlabel('n'); ylabel('Real part');
title('OFDM symbol(sampling rate = 30.72MHz) after sample at 1.92MHz');
subplot(2,1,2);
plot(imag(x_2048_sample));
xlabel('n'); ylabel('Imaginary part');











