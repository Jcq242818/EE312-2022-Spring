function [txWaveform,nonHTcfg,chanBW,overSampleFactor] = createTxWaveform(psduData,numMSDUs,lengthMPDU)

%（1）创建WLAN数据包
nonHTcfg = wlanNonHTConfig;% Create packet configuration

%（2）调制方式：16/64QAM
nonHTcfg.MCS = 6;% Modulation: 64QAM Rate: 2/3
%（3）发射天线数目
nonHTcfg.NumTransmitAntennas = 1;% Number of transmit antenna
%（4）占用带宽
nonHTcfg.ChannelBandwidth='CBW5';
chanBW = nonHTcfg.ChannelBandwidth;

%（5）设置PSDU长度(字节)
bitsPerOctet = 8;
nonHTcfg.PSDULength = lengthMPDU/bitsPerOctet; % Set the PSDU length
%（6）初始化扰码
scramblerInitialization = randi([1 127],numMSDUs,1);
%（7）产生基带NonHT数据包
txWaveform = wlanWaveformGenerator(psduData,nonHTcfg, ...
'NumPackets',numMSDUs,'IdleTime',80e-6, ...
'ScramblerInitialization',scramblerInitialization);

%Short Training Field
L_k=sqrt(1/2)*[0,0,1+1j,0,0,0,-1-1j,0,0,0,1+1j,0,0,0,-1-1j,...
               0,0,0,-1-1j,0,0,0,1+1j,0,0,0,0,0,0,0,-1-1j,...
               0,0,0,-1-1j,0,0,0,1+1j,0,0,0,1+1j,0,0,0,1+1j,0,0,0,1+1j,0,0];
Short_preamble=createSTF(L_k);
figure(3)
subplot(2,1,1);plot(real(txWaveform(1:length(Short_preamble))));xlabel('n');ylabel('wlanLSTF');
subplot(2,1,2);plot(real(Short_preamble));xlabel('n');ylabel('S_k');
txWaveform(1:length(Short_preamble))=Short_preamble;


%Long Training Field
L_k=[1,1,-1,-1,1,1,-1,1,-1,1,1,1,1,1,1,-1,-1,1,1,-1,1,-1,1,...
    1,1,1,0,1,-1,-1,1,1,-1,1,-1,1,-1,-1,-1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,1,1,1];
Long_preamble=createLTF(L_k);
figure(4);
subplot(2,1,1);
plot(real(txWaveform(length(Short_preamble)+1:length(Short_preamble)+length(Long_preamble))));
xlabel('n');
ylabel('wlanLLTF');
subplot(2,1,2);
plot(real(Long_preamble));
xlabel('n');
ylabel('L_k');
txWaveform(length(Short_preamble)+1:length(Short_preamble)+length(Long_preamble))=Long_preamble;
 %（8）重采样波形
fs = helperSampleRate(chanBW);
overSampleFactor = 1;%定义过采样因子
txWaveform= resample(txWaveform,fs*overSampleFactor,fs);
fprintf('\nGenerating WLAN transmit waveform:\n')
%（9）归一化信号 
powerScaleFactor = 0.8;
txWaveform = txWaveform.*(1/max(abs(txWaveform))*powerScaleFactor);