clear; clc;
Noise_Power =0;
cfgHT = wlanHTConfig('ChannelBandwidth','CBW20');
LTF = wlanLLTF(cfgHT);
Channel = sqrt(Noise_Power/2) * (randn(1,1200) + 1j* randn(1,1200));
Channel(601:760) = Channel(601:760) + LTF.';
Time = zeros(1, 1000);
for i = 1:length(Time)
Time(i) = Channel(i:i+159) * conj(LTF);
end
plot(abs(Time));
grid;


