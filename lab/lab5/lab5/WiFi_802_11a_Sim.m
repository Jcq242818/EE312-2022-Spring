%% 1. ��Ŀ������802.11a��ͼ����ϵͳ����
% 1����������Ƚ�ͼ��������ݰ����֡�����MPDU��ÿ��MPDU����һ��MACͷ��һ��֡�壩��
% 2��Ȼ����802.11a��׼���з�װ������802.11a���Ρ�
% 3�����ջ�������źţ�Ȼ��������������������MACͷ���е����к��������ƴ�ӻָ�ͼ��

clc;clear;
%% 2. ��ʼ��Ƶ��ͼ������ͼ
% 2.1 ------------------------------------------------------------------------------------> ����Ƶ����ʾ����
hsa = dsp.SpectrumAnalyzer( 'SpectrumType','Power density', ...
                            'SpectralAverages', 10, ...
                            'YLimits',         [-60 0], ...
                            'Title',           'Received Baseband WLAN Signal Spectrum', ...
                            'YLabel',          'Power spectral density');
                        
% 2.2 ------------------------------------------------------------------------------------> ��������ͼ����
hcd = comm.ConstellationDiagram('Title','Equalized WLAN Symbols',...
                                'ShowReferenceConstellation',false);
                            

%% 3.802.11a��������
% ��1������ͼ�����ɶ���������
% ��2����������������װ��802.11a��ʽ�Ĳ���
% 3.1 ����ͼ�����ɶ���������            
fileTx = 'peppers.png';    % ------------------------------------------------------> ����ͼ���ļ���
scale = 0.3;      %-----------------------------------------------------------------------> ��������
[fData_Resize] = ResizeImage(fileTx,scale);   %-------------------------------------------> ͼ������
imsize = size(fData_Resize);     % -------------------------------------------------------> ��ͼ��ĳߴ�

binData = dec2bin(fData_Resize(:),8); %---------------------------------------------------> ת����������

txImage = reshape((binData-'0').',1,[]).'; %----------------------------------------------> ���������Ʊ�����
figure(1);  %-----------------------------------------------------------------------------> ��ʾ��Ҫ�����ͼ��
subplot(211); 
    imshow(fData_Resize);
    title('Transmitted Image');
subplot(212);
    title('Received image will appear here...');
    set(gca,'Visible','off');
    set(findall(gca, 'type', 'text'), 'visible', 'on');
 

% 3.2 ��������������װ��PSDU���ݰ�
MPDU_Param.lengthMACheader = 256; %-------------------------------------------------------> MPDUͷ������ı�����
MPDU_Param.lengthFCS = 32;        %-------------------------------------------------------> FCS����ı�����
MPDU_Param.generatorPolynomial = [32 26 23 22 16 12 11 10 8 7 5 4 2 1 0];  %--------------> CRC-32У�����ʽ��������

% MPDU��| MACͷ����256 bits��|+|MSDU���أ�4048*8 bits��|+|У��λ��32 bits��|
[txData,psduData,numMSDUs,lengthMPDU] = createPSDU(txImage,MPDU_Param);  %----------------> ����psdu���ݰ�
lengthMPDU
% 3.3 ��PSDU���ݰ���װ��ΪNon-HT��ʽ�Ĳ���
[txWaveform,nonHTcfg,chanBW,overSampleFactor] = createTxWaveform(psduData,numMSDUs,lengthMPDU); 
fs = helperSampleRate(chanBW);  %--------------------------------------------------------> �����źţ�5M��������

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


%% 4.������˹�����ŵ�
SNR_i=inf;   %----------------------------------------------------------------------------> ���������
[txWaveformAWGN] = createAWGNChannel(nonHTcfg,txWaveform,SNR_i);   %---------------------> ��Ӽ��Ը�˹������


%% 5.���ջ��źŴ������
%5.1. ����WLAN���ݰ�
load('rxWaveform.mat')
burstCaptures = [rxWaveform;rxWaveform];
% burstCaptures = [txWaveformAWGN;txWaveformAWGN];   %-------------------------------------> ���θ��ƣ�Ϊ�źŽ���׼��
step(hsa,burstCaptures);    %------------------------------------------------------------> ��ʾ�źŵ�Ƶ��

%5.2. ���ղ�������
% samplesPerFrame = length(txWaveform);  %-------------------------------------------------> ��֡��������
% rxSamplesPerFrame = samplesPerFrame*2; %-------------------------------------------------> ���θ��ƺ󣬵�֡��������

%5.3. ���ݰ�����
% overSampleFactor = 1.5;
[rxBit,offsetLLTF,pktOffset,packetSeq]=ReceiverProc(MPDU_Param,nonHTcfg,hcd,chanBW,overSampleFactor,burstCaptures);
 
%5.4. ͼ���ع��������ʼ���
lengthTxImage = length(txImage);       %-------------------------------------------------> ����ͼ��ĳߴ�
reBuildImage(rxBit,offsetLLTF,pktOffset,packetSeq,numMSDUs,MPDU_Param,txData,lengthTxImage,imsize)




