clc
clear

% -------------------------------------------------------------------------------------------------> 设置频谱分析工具
hsa = dsp.SpectrumAnalyzer( ...
    'SpectrumType',    'Power density', ...
    'SpectralAverages', 10, ...
    'YLimits',         [-150 -60], ...
    'Title',           'Received Baseband LTE Signal Spectrum', ...
    'YLabel',          'Power spectral density');

% -------------------------------------------------------------------------------------------------> 设置星座图
hcd = comm.ConstellationDiagram('Title','Equalized PDSCH Symbols',...
                                'ShowReferenceConstellation',false);

%% 2.发射机设计
% 1. 导入图像，生成二进制码流
% 2. 设置DL-SCH下行链路参数
% 3. 配置RMC参数
% 4. 产生LTE复基带波形

%% 2.1 导入图像，生成二进制码流            
fileTx = 'tree.png';    % -------------------------------------------------------------------------> 定义图像文件名

scale = 0.4;      %--------------------------------------------------------------------------------> 缩放因子
[fData_Resize] = ResizeImage(fileTx,scale);   %----------------------------------------------------> 图像缩放

imsize = size(fData_Resize);     % ----------------------------------------------------------------> 新图像的尺寸

binData = dec2bin(fData_Resize(:),8); %------------------------------------------------------------> 转换二进制数

trData = reshape((binData-'0').',1,[]).'; %--------------------------------------------------------> 创建二进制比特流

figure(1);  %--------------------------------------------------------------------------------------> 显示需要传输的图像
subplot(211); 
    imshow(fData_Resize);
    title('Transmitted Image');
subplot(212);
    title('Received image will appear here...');
    set(gca,'Visible','off');
    set(findall(gca, 'type', 'text'), 'visible', 'on');


%% 2.2 设置DL-SCH下行链路参数
txsim.RC = 'R.7';       % RMC：Reference Measurement Channel---------------------------------------> 参考测量信道
txsim.NCellID = 88;     % -------------------------------------------------------------------------> 小区标识
txsim.NFrame = 700;     % -------------------------------------------------------------------------> 系统帧号
txsim.TotFrames = 1;    % -------------------------------------------------------------------------> 初始化系统帧数
txsim.DesiredCenterFrequency = 2.45e9; % ----------------------------------------------------------> 中心频率
txsim.NTxAnts = 1;      % -------------------------------------------------------------------------> 发射天线数量

rmc = lteRMCDL(txsim.RC);  %-----------------------------------------------------------------------> 创建RMC对象

trBlkSize = rmc.PDSCH.TrBlkSizes;
txsim.TotFrames = ceil(numel(trData)/sum(trBlkSize(:)));  %----------------------------------------> 计算所需要的LTE帧数（3个）

%% 2.3 产生LTE复基带波形
[eNodeBOutput,txGrid,rmc] = LTEWaveformGenerator(rmc,txsim,trData);

figure(2)
subplot(2,1,1)
plot(real(eNodeBOutput)); axis([0 10000 -0.05 0.05]); xlabel('n') ;ylabel('eNodeBOutput')   
subplot(2,1,2)
plot(imag(eNodeBOutput)); axis([0 10000 -0.05 0.05]); xlabel('n') ;ylabel('eNodeBOutput')         

%% 3.接收机设计
% 1、捕获基带信号
% 2、接收信号频偏校正
% 3、信号同步：找到LTE帧起始位置
% 4、OFDM解调，获取LTE资源网格
% 5、信道估计
% 6、解码PD-SCH和DL-SCH，获得发射的数据
% 7、图像恢复

%% 3.1 定义接收机对象结构体参数
rxsim = struct;   % -------------------------------------------------------------------------------> 定义接收机对象结构体参数
rxsim.RadioFrontEndSampleRate = rmc.SamplingRate; % -----------------------------------------------> 设置采样率
rxsim.RadioCenterFrequency = txsim.DesiredCenterFrequency;  % -------------------------------------> 设置接收机中心频率
rxsim.NRxAnts = txsim.NTxAnts;   % ----------------------------------------------------------------> 设置天线数量
rxsim.FramesPerBurst = txsim.TotFrames+1;    %-----------------------------------------------------> 设置系统帧数
rxsim.numBurstCaptures = 1; 
samplesPerFrame = 10e-3*rxsim.RadioFrontEndSampleRate; % %-----------------------------------------> 单个系统帧的采样点数

rx.BasebandSampleRate = rxsim.RadioFrontEndSampleRate;
rx.CenterFrequency = rxsim.RadioCenterFrequency;
rx.SamplesPerFrame = samplesPerFrame;
rx.OutputDataType = 'double';
rx.EnableBurstMode = true;
rx.NumFramesInBurst = rxsim.FramesPerBurst;
rx.ChannelMapping = 1;

burstCaptures = zeros(samplesPerFrame,rxsim.NRxAnts,rxsim.FramesPerBurst);

%% 3.2. 初始化ENodeB
enb.PDSCH = rmc.PDSCH;     % ----------------------------------------------------------------------> 初始化eNodeB           
enb.DuplexMode = 'FDD';    % ----------------------------------------------------------------------> 设置复用方式
enb.CyclicPrefix = 'Normal';    % -----------------------------------------------------------------> 判断循环前缀方式
enb.CellRefP = 4; 

% Bandwidth: {1.4 MHz, 3 MHz, 5 MHz, 10 MHz, 20 MHz}   % ------------------------------------------> 判断小区带宽
SampleRateLUT = [1.92 3.84 7.68 15.36 30.72]*1e6;
NDLRBLUT = [6 15 25 50 100];
enb.NDLRB = NDLRBLUT(SampleRateLUT==rxsim.RadioFrontEndSampleRate);
if isempty(enb.NDLRB)
    error('Sampling rate not supported. Supported rates are %s.',...
            '1.92 MHz, 3.84 MHz, 7.68 MHz, 15.36 MHz, 30.72 MHz');
end
fprintf('\nSDR hardware sampling rate configured to capture %d LTE RBs.\n',enb.NDLRB);

% 3.2. 信道估计结构体配置
cec.PilotAverage = 'UserDefined';  % --------------------------------------------------------------> Type of pilot symbol averaging
cec.FreqWindow = 9;                % --------------------------------------------------------------> Frequency window size in REs
cec.TimeWindow = 9;                % --------------------------------------------------------------> Time window size in REs
cec.InterpType = 'Cubic';          % --------------------------------------------------------------> 2D interpolation type
cec.InterpWindow = 'Centered';     % --------------------------------------------------------------> Interpolation window type
cec.InterpWinSize = 3;             % --------------------------------------------------------------> Interpolation window size

%% 3.3 信号捕获和处理
enbDefault = enb;

while rxsim.numBurstCaptures
    enb = enbDefault;
    rxWaveform  = eNodeBOutput;    % --------------------------------------------------------------> 信号捕获
    
    hsa.SampleRate = rxsim.RadioFrontEndSampleRate;   
    step(hsa,rxWaveform);          % --------------------------------------------------------------> 显示频谱
    
    %----------------------------------------------------------------------------------------------> 进行频偏纠正
    frequencyOffset = lteFrequencyOffset(enb,rxWaveform);
    rxWaveform = lteFrequencyCorrect(enb,rxWaveform,frequencyOffset);
    fprintf('\nCorrected a frequency offset of %i Hz.\n',frequencyOffset)
    
    %----------------------------------------------------------------------------------------------> 小区搜索PCI
    cellSearch.SSSDetection = 'PostFFT'; cellSearch.MaxCellCount = 1;
    [NCellID,frameOffset] = lteCellSearch(enb,rxWaveform,cellSearch);
    fprintf('Detected a cell identity of %i.\n', NCellID);
    enb.NCellID = NCellID; 
    
    %----------------------------------------------------------------------------------------------> 同步
    rxWaveform = rxWaveform(frameOffset+1:end,:);
    tailSamples = mod(length(rxWaveform),samplesPerFrame);
    rxWaveform = rxWaveform(1:end-tailSamples,:);
    enb.NSubframe = 0;
    fprintf('Corrected a timing offset of %i samples.\n',frameOffset)
    
    rxGrid = lteOFDMDemodulate(enb,rxWaveform);     %----------------------------------------------> OFDM 解调

    [hest,nest] = lteDLChannelEstimate(enb,cec,rxGrid);   %----------------------------------------> 信道估计
    sfDims = lteResourceGridSize(enb);    %--------------------------------------------------------> 资源网格
    
    Lsf = sfDims(2); % ----------------------------------------------------------------------------> 单个子帧的OFDM符号
    LFrame = 10*Lsf; % ----------------------------------------------------------------------------> 单个系统帧的OFDM符号
    
    numFullFrames = length(rxWaveform)/samplesPerFrame;   
    rxDataFrame = zeros(sum(enb.PDSCH.TrBlkSizes(:)),numFullFrames);
    recFrames = zeros(numFullFrames,1);
    rxSymbols = []; txSymbols = [];
    
    %---------------------------------------------------------------------------------------------> MIB解码, PDSCH and DL-SCH
    for frame = 0:(numFullFrames-1)
        fprintf('\nPerforming DL-SCH Decode for frame %i of %i in burst:\n', ...
            frame+1,numFullFrames)
        
        %-----------------------------------------------------------------------------------------> 抽取0号子帧和信道估计结果
        enb.NSubframe = 0;
        rxsf = rxGrid(:,frame*LFrame+(1:Lsf),:);
        hestsf = hest(:,frame*LFrame+(1:Lsf),:,:);
               
        %-----------------------------------------------------------------------------------------> PBCH解调
        enb.CellRefP = 4;
        pbchIndices = ltePBCHIndices(enb); 
        [pbchRx,pbchHest] = lteExtractResources(pbchIndices,rxsf,hestsf);
        [~,~,nfmod4,mib,CellRefP] = ltePBCHDecode(enb,pbchRx,pbchHest,nest);
        
        if ~CellRefP
            fprintf('  No PBCH detected for frame.\n');
            continue;
        end
        enb.CellRefP = CellRefP; 
        
        %----------------------------------------------------------------------------------------> 获得enb值,进行MIB解码
        enb = lteMIB(mib,enb);
        enb.NFrame = enb.NFrame+nfmod4;
        fprintf('  Successful MIB Decode.\n')
        fprintf('  Frame number: %d.\n',enb.NFrame);
        
        enb.NDLRB = min(enbDefault.NDLRB,enb.NDLRB);   %-----------------------------------------> 限制下行带宽
              
        recFrames(frame+1) = enb.NFrame;  % -----------------------------------------------------> 存储帧号
               
        %----------------------------------------------------------------------------------------> 处理子帧
        for sf = 0:9
            if sf~=5   % ------------------------------------------------------------------------> 忽视5号子帧

                enb.NSubframe = sf;
                rxsf = rxGrid(:,frame*LFrame+sf*Lsf+(1:Lsf),:);

                [hestsf,nestsf] = lteDLChannelEstimate(enb,cec,rxsf); % -------------------------> 信道估计

                %--------------------------------------------------------------------------------> PCFICH解调
                pcfichIndices = ltePCFICHIndices(enb);
                [pcfichRx,pcfichHest] = lteExtractResources(pcfichIndices,rxsf,hestsf);
                [cfiBits,recsym] = ltePCFICHDecode(enb,pcfichRx,pcfichHest,nestsf);

                %--------------------------------------------------------------------------------> CFI 解码
                enb.CFI = lteCFIDecode(cfiBits);
                
                %--------------------------------------------------------------------------------> 获得PDSCH索引
                [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enb, enb.PDSCH, enb.PDSCH.PRBSet); 
                [pdschRx, pdschHest] = lteExtractResources(pdschIndices, rxsf, hestsf);

                %--------------------------------------------------------------------------------> PDSCH解码
                [rxEncodedBits, rxEncodedSymb] = ltePDSCHDecode(enb,enb.PDSCH,pdschRx,...
                                               pdschHest,nestsf);

                %--------------------------------------------------------------------------------> 重构符号流
                rxSymbols = [rxSymbols; rxEncodedSymb{:}]; %#ok<AGROW>
                
                %--------------------------------------------------------------------------------> DL-SCH解码
                outLen = enb.PDSCH.TrBlkSizes(enb.NSubframe+1);  
                
                [decbits{sf+1}, blkcrc(sf+1)] = lteDLSCHDecode(enb,enb.PDSCH,...  
                                                outLen, rxEncodedBits); 
                       
                txRecode = lteDLSCH(enb,enb.PDSCH,pdschIndicesInfo.G,decbits{sf+1});

                txRemod = ltePDSCH(enb, enb.PDSCH, txRecode);    %-------------------------------> PD-SCH解码
                [~,refSymbols] = ltePDSCHDecode(enb, enb.PDSCH, txRemod);

                txSymbols = [txSymbols; refSymbols{:}]; %#ok<AGROW>

                release(hcd); % 
                step(hcd,rxEncodedSymb{:}); % %---------------------------------------------------> 绘制星座点
            end
        end
        

        fprintf('  Retrieving decoded transport block data.\n');
        rxdata = [];
        for i = 1:length(decbits)
            if i~=6 
                rxdata = [rxdata; decbits{i}{:}]; %#ok<AGROW>
            end
        end
        
        rxDataFrame(:,frame+1) = rxdata;

        focalFrameIdx = frame*LFrame+(1:LFrame);            
    end
    rxsim.numBurstCaptures = rxsim.numBurstCaptures-1;
end


%% 3.4 图像恢复

[~,frameIdx] = min(recFrames);   % --------------------------------------------------------------> 获得系统帧号
fprintf('\nRecombining received data blocks:\n');
decodedRxDataStream = zeros(length(rxDataFrame(:)),1);
frameLen = size(rxDataFrame,1);

%------------------------------------------------------------------------------------------------> 重构比特流
for n=1:numFullFrames
    currFrame = mod(frameIdx-1,numFullFrames)+1;
    decodedRxDataStream((n-1)*frameLen+1:n*frameLen) = rxDataFrame(:,currFrame);
    frameIdx = frameIdx+1; 
end

%------------------------------------------------------------------------------------------------> EVM
if ~isempty(rxSymbols)
    hEVM = comm.EVM();
    hEVM.MaximumEVMOutputPort = true;
    [evm.RMS,evm.Peak] = step(hEVM,txSymbols, rxSymbols);
    fprintf('  EVM peak = %0.3f%%\n',evm.Peak);
    fprintf('  EVM RMS  = %0.3f%%\n',evm.RMS);
else
    fprintf('  No transport blocks decoded.\n');
end

%------------------------------------------------------------------------------------------------> BER计算
hBER = comm.ErrorRate;
err = step(hBER, decodedRxDataStream(1:length(trData)), trData);
fprintf('  Bit Error Rate (BER) = %0.5f.\n', err(1));
fprintf('  Number of bit errors = %d.\n', err(2));
fprintf('  Number of transmitted bits = %d.\n',length(trData));

%------------------------------------------------------------------------------------------------> 图像重构
fprintf('\nConstructing image from received data.\n');
str = reshape(sprintf('%d',decodedRxDataStream(1:length(trData))), 8, []).';
decdata = uint8(bin2dec(str));
receivedImage = reshape(decdata,imsize);

figure(1);
subplot(212); 
imshow(receivedImage);
title(sprintf('Received Image: %dx%d Antenna Configuration',txsim.NTxAnts, rxsim.NRxAnts));
