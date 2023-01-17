signal_power = zeros(1,21);   % 我们假设信号的功率是0dB
count = 100; %定义重复实验的总次数
successful = 0; %定义在这些实验中成功的次数
ratio = zeros(1,21);
noise = 0:1:20;
SNR = signal_power - noise;
save_result = zeros(10,21);
for noise_power = 0:1:20 
for many = 1:1:10  %在每个噪声功率下进行10次测试，以便拟合数据
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
save_result(many, noise_power+1)= ratio(noise_power + 1);
successful = 0;
many
end
noise_power
end
%对save_result的每一列求平均--用mean(save_result,1)
average_result = mean(save_result,1);
plot(SNR,average_result,'linewidth',2);
title('Average Arrival Detection Probability vs SNR in 10 Experiment')
xlabel('SNR')
ylabel('Average Arrival Detection Probability')
grid on