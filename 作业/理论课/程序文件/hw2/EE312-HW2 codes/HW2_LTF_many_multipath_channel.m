clear; 
clc;
signal_power = zeros(1,21);% 我们假设信号的功率是0dB
count = 100; %定义重复实验的总次数
fail = 0; %定义在这些实验中失败的次数
ratio = zeros(1,21);
noise = 0:1:20;
SNR = signal_power - noise;
save_result = zeros(10,21);
for noise_power = 0:1:20 
for many = 1:1:10  %在每个噪声功率下进行10次测试，以便拟合数据
for repeat = 1: count
cfgHT = wlanHTConfig('ChannelBandwidth','CBW20');
LTF = wlanLLTF(cfgHT);
Channel = sqrt(noise_power/2) * (randn(1,1200) + 1j* randn(1,1200));
Channel(601:760) = Channel(601:760) + LTF.';
% Channel_1 = conv(Channel, [1 0 0 0 0.8]);
% Channel_1 = conv(Channel, [1 0 0 0 0 0 0.8]);
% Channel_1 = conv(Channel, [1 0 0 0 0 0 0 0 0.8]);
 Channel_1 = conv(Channel, [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.8]);
Time = zeros(1, 1000);
for i = 1:length(Time)
Time(i) = Channel_1(i:i+159) * conj(LTF);
end
% plot(abs(Time));
[~,index] = max(Time);
if index ~= 601
        fail = fail+1;
end
end
ratio(noise_power + 1) = fail/count;
save_result(many, noise_power+1)= ratio(noise_power + 1);
fail = 0;
many
end
noise_power
end
%对save_result的每一列求方差(使用var(save_result,0,1))
% average_result = mean(save_result,1);
% plot(SNR,average_result,'linewidth',2);
% title('Error Probability vs SNR Under Multipath Channel ')
% xlabel('SNR')
% ylabel('Error Probability')
% grid on
var_result = var(save_result,0,1);
plot(SNR,var_result,'linewidth',2);
title('Error Variance vs SNR Under Multipath Channel')
xlabel('SNR')
ylabel('Error Variance')
grid on