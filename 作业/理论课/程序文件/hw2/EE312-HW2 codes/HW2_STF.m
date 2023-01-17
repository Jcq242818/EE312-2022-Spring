clear; clc;
% 我们假设信号的功率是0dB
signal_power = zeros(1,21);
count = 100; %定义重复实验的总次数
successful = 0; %定义在这些实验中成功的次数
ratio = zeros(1,21);
noise = 0:1:20;
SNR = signal_power - noise;
for noise_power = 0:1:20 %在每个噪声功率之下做100次实验
for repeat = 1: count
cfgHT = wlanHTConfig('ChannelBandwidth','CBW20');
STF = wlanLSTF(cfgHT);
Channel = sqrt(noise_power/2) * (randn(1,1200) + 1j* randn(1,1200));
Channel(601:760) = Channel(601:760) + STF.';
Time = zeros(1, 1000);
for i = 1:length(Time)
Time(i) = Channel(i:i+159) * conj(STF);
end
% plot(abs(Time));
[~,index] = max(Time);
if index == 601
        successful = successful+1;
end
end
ratio(noise_power + 1) = successful/count;
successful = 0;
noise_power
end
plot(SNR,ratio,'linewidth',2);
title('Arrival Detection Probability vs SNR in one Experiment')
xlabel('SNR')
ylabel('Arrival Detection Probability')
grid on


