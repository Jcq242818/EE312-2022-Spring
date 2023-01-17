%% 1. 题目：基于802.11a的图像传输系统仿真
% 1、发射机首先将图像进行数据包划分、产生MPDU（每个MPDU包含一个MAC头和一个帧体）。
% 2、然后按照802.11a标准进行封装，产生802.11a波形。
% 3、接收机捕获的信号，然后解调到基带，接着利用MAC头部中的序列号排序，最后拼接恢复图像。

clc;clear;
%% 2. 初始化频谱图和星座图
% 2.1 ------------------------------------------------------------------------------------> 配置频谱显示工具
hsa = dsp.SpectrumAnalyzer( 'SpectrumType','Power density', ...
                            'SpectralAverages', 10, ...
                            'YLimits',         [-60 0], ...
                            'Title',           'Received Baseband WLAN Signal Spectrum', ...
                            'YLabel',          'Power spectral density');
                        
% 2.2 ------------------------------------------------------------------------------------> 配置星座图工具
hcd = comm.ConstellationDiagram('Title','Equalized WLAN Symbols',...
                                'ShowReferenceConstellation',false);
                            

%% 3.802.11a波形生成
% （1）导入图像，生成二进制码流
% （2）将二进制码流封装成802.11a格式的波形
% 3.1 导入图像，生成二进制码流            
fileTx = 'peppers.png';    % ------------------------------------------------------> 定义图像文件名
scale = 0.3;      %-----------------------------------------------------------------------> 缩放因子
[fData_Resize] = ResizeImage(fileTx,scale);   %-------------------------------------------> 图像缩放
imsize = size(fData_Resize);     % -------------------------------------------------------> 新图像的尺寸

binData = dec2bin(fData_Resize(:),8); %---------------------------------------------------> 转换二进制数

txImage = reshape((binData-'0').',1,[]).'; %----------------------------------------------> 创建二进制比特流
figure(1);  %-----------------------------------------------------------------------------> 显示需要传输的图像
subplot(211); 
    imshow(fData_Resize);
    title('Transmitted Image');
subplot(212);
    title('Received image will appear here...');
    set(gca,'Visible','off');
    set(findall(gca, 'type', 'text'), 'visible', 'on');
 

% 3.2 将二进制码流封装成PSDU数据包
MPDU_Param.lengthMACheader = 256; %-------------------------------------------------------> MPDU头部所需的比特数
MPDU_Param.lengthFCS = 32;        %-------------------------------------------------------> FCS所需的比特数
MPDU_Param.generatorPolynomial = [32 26 23 22 16 12 11 10 8 7 5 4 2 1 0];  %--------------> CRC-32校验多项式（除数）

% MPDU：| MAC头部（256 bits）|+|MSDU比特（4048*8 bits）|+|校验位（32 bits）|
[txData,psduData,numMSDUs,lengthMPDU] = createPSDU(txImage,MPDU_Param);  %----------------> 创建psdu数据包
lengthMPDU
% 3.3 将PSDU数据包封装成为Non-HT格式的波形
[txWaveform,nonHTcfg,chanBW,overSampleFactor] = createTxWaveform(psduData,numMSDUs,lengthMPDU); 
fs = helperSampleRate(chanBW);  %--------------------------------------------------------> 计算信号（5M）采样率

figure(2)
subplot(2,1,1)
plot((1:length(txWaveform))/(fs*overSampleFactor),real(txWaveform))
xlabel('t(sec)')
ylabel('Amplitude')
axis([0 0.01 -1 1])
hold on
subplot(2,1,2)
plot((1:length(txWaveform))/(fs*overSampleFactor),real(txWaveform))
xlabel('t(sec)')
ylabel('Amplitude')
axis([0 8e-5 -0.5 0.5])


%% 4.经过高斯噪声信道
SNR_i=inf;   %----------------------------------------------------------------------------> 设置信噪比
[txWaveformAWGN] = createAWGNChannel(nonHTcfg,txWaveform,SNR_i);   %---------------------> 添加加性高斯白噪声


%% 5.接收机信号处理过程
%5.1. 捕获WLAN数据包
load('rxWaveform.mat')
burstCaptures = [rxWaveform;rxWaveform];
% burstCaptures = [txWaveformAWGN;txWaveformAWGN];   %-------------------------------------> 波形复制，为信号解码准备
step(hsa,burstCaptures);    %------------------------------------------------------------> 显示信号的频谱

%5.2. 接收参数设置
% samplesPerFrame = length(txWaveform);  %-------------------------------------------------> 单帧采样点数
% rxSamplesPerFrame = samplesPerFrame*2; %-------------------------------------------------> 波形复制后，单帧采样点数

%5.3. 数据包处理
% overSampleFactor = 1.5;
[rxBit,offsetLLTF,pktOffset,packetSeq]=ReceiverProc(MPDU_Param,nonHTcfg,hcd,chanBW,overSampleFactor,burstCaptures);
 
%5.4. 图像重构和误码率计算
lengthTxImage = length(txImage);       %-------------------------------------------------> 计算图像的尺寸
reBuildImage(rxBit,offsetLLTF,pktOffset,packetSeq,numMSDUs,MPDU_Param,txData,lengthTxImage,imsize)




