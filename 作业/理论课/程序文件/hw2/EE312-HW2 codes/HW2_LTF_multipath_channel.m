clear; clc;
Noise_Power =0;
cfgHT = wlanHTConfig('ChannelBandwidth','CBW20');
LTF = wlanLLTF(cfgHT);
Channel = sqrt(Noise_Power/2) * (randn(1,1200) + 1j* randn(1,1200));
Channel(601:760) = Channel(601:760) + LTF.';
Channel_1 = conv(Channel, [1 0 0 0 0 0 0 0 0 0 0.8]);
Time = zeros(1, 1000);
for i = 1:length(Time)
Time(i) = Channel_1(i:i+159) * conj(LTF);
end
plot(abs(Time));
grid;









