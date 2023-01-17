clear; clc;
numCBPSSI = 48;
cbw = 'CBW20';
numBPSCS = 1;
cfgHT = wlanHTConfig('ChannelBandwidth','CBW20');
[wave,L_SIG_field] = wlanLSIG(cfgHT);
L_SIG_field_BCC = wlanBCCEncode(L_SIG_field,0.5);
L_SIG_field_BCC_I = wlanBCCInterleave(L_SIG_field_BCC,'Non-HT',numCBPSSI);
L_SIG_field_BPSK = wlanConstellationMap(L_SIG_field_BCC_I,numBPSCS);
L_SIG_field_BPSK = L_SIG_field_BPSK';
%之后插入导频。插入的具体方法见IEEE 802.11 公式17.24. 最后根据M(k)和P来求解插入导频和DC子载波的位置。
%经过计算，在BPSK映射后插入导频序列的规则是：第6位插1，第20位插1，第27位插0(这是DC子载波)，第34位插1，第48位插-1。
L_SIG_field_OFDM_initial = [L_SIG_field_BPSK(1:5),1,L_SIG_field_BPSK(6:18),1, ...
    L_SIG_field_BPSK(19:24),0,L_SIG_field_BPSK(25:30),1,L_SIG_field_BPSK(31:43),-1,L_SIG_field_BPSK(44:48)];

L_SIG_field_OFDM_final =[0,0,0,0,0,0,L_SIG_field_OFDM_initial(1:53),0,0,0,0,0];

% L_SIG_final = [L_SIG_field_OFDM_final(49:64),L_SIG_field_OFDM_final(1:64)]; %添加循环前缀
% L_SIG_final = int8(L_SIG_final);

figure
wave = wave';
x = eps:4e-6/80:4e-6;
plot(x,abs(wave),'linewidth',2);
 title('L-SIG Waveform');
 xlabel('Time (seconds)');
 ylabel('Amplitude');
grid on

% %绘制我们产生的一个L_SIG
% waveform = wlanWaveformGenerator(L_SIG_final,cfgHT);
% figure;
% plot(abs(waveform));
% title('L-SIG Waveform');
% xlabel('Time (nanoseconds)');
% ylabel('Amplitude');

