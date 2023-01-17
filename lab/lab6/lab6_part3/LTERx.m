%% LTE接收机设计：基于LTE工具箱函数恢复预录数据

% # 1. 首先捕获信号；
% # 2. 信号频偏纠正
% # 3. 信号同步
% # 4. OFDM解调
% # 5. 信道估计
% # 6. 解码PDSCH and DL-SCH 
% # 7. 图像重构

clc
clear
%% 1. 捕获USRP信号
%(1) 设置USRP参数-----------------------------------------------------------------------------------> 设置频率、增益等参数
% prmQPSKReceiver.USRPCenterFrequency = 900e6;
% prmQPSKReceiver.USRPGain = 25;
% prmQPSKReceiver.RxBufferedFrames=1;
% prmQPSKReceiver.Fs = 5e6; 
% prmQPSKReceiver.USRPDecimationFactor = 100e6/prmQPSKReceiver.Fs; 
% prmQPSKReceiver.FrameSize=307200;
% prmQPSKReceiver.USRPFrameLength = prmQPSKReceiver.FrameSize*prmQPSKReceiver.RxBufferedFrames;

% (2) 构造接收机对象---------------------------------------------------------------------------------> 使用COMM函数构造
% radio = comm.SDRuReceiver(...
%         'IPAddress',            '192.168.10.2', ...
%         'CenterFrequency',      prmQPSKReceiver.USRPCenterFrequency, ...
%         'Gain',                 prmQPSKReceiver.USRPGain, ...
%         'DecimationFactor',     prmQPSKReceiver.USRPDecimationFactor, ...
%         'FrameLength',          prmQPSKReceiver.USRPFrameLength, ...
%         'OutputDataType',       'double');

%(3) 循环捕获，直到成功捕获数据包-------------------------------------------------------------------> 使用USRP循环捕获数据包   
% while (true)
% 
%          [corruptSignal, len] = step(radio);    %-----------------------------------> 使用USRP捕获数据包  
% 
%       if len < prmQPSKReceiver.USRPFrameLength  %-----------------------------------> 如果未能成功读取我们希望的长度，报错
%          errorIndex = errorIndex+1;
%          disp ( 'Not enough samples returned!' ) ;
%          disp(errorIndex)
%       else          
%          rxWaveform1 = corruptSignal;           %-----------------------------------> 成功捕获后跳出循环 
%          break; 
%       end
% end

%% 2、接收的基带信号处理
%% (1) 基本参数设置
rxsim = struct;
rxsim.RadioFrontEndSampleRate = 15.36e6; %-------------------------------------------------------> 设置采样率  
rxsim.RadioCenterFrequency = 900e6; %------------------------------------------------------------> 设置中心频率
rxsim.NRxAnts = 1;      %------------------------------------------------------------------------> 设置天线
rxsim.FramesPerBurst = 3;  %---------------------------------------------------------------------> 捕获的波形中包含系统帧数
rxsim.numBurstCaptures = 1;  %-------------------------------------------------------------------> 捕获的波形数

samplesPerFrame = 10e-3*rxsim.RadioFrontEndSampleRate;  %---------------------------------> LTE系统帧采样点数，持续时间为10ms
rx.BasebandSampleRate = rxsim.RadioFrontEndSampleRate;
rx.CenterFrequency = rxsim.RadioCenterFrequency;
rx.SamplesPerFrame = samplesPerFrame;
rx.OutputDataType = 'double';
rx.EnableBurstMode = true;
rx.NumFramesInBurst = rxsim.FramesPerBurst;
rx.ChannelMapping = 1;

burstCaptures = zeros(samplesPerFrame,rxsim.NRxAnts,rxsim.FramesPerBurst);  %--------------------> LTE系统帧采样点初始化

%% (2) 系统参数设置
txsim.RC = 'R.7';   %----------------------------------------------------------------------------> 版本R7
rmc = lteRMCDL(txsim.RC);
enb.PDSCH = rmc.PDSCH;
enb.DuplexMode = 'FDD';   %----------------------------------------------------------------------> FDD
enb.CyclicPrefix = 'Normal';  %------------------------------------------------------------------> 普通循环前缀
enb.CellRefP = 4; 

SampleRateLUT = [1.92 3.84 7.68 15.36 30.72]*1e6;  %-----------------------> 带宽: {1.4 MHz, 3 MHz, 5 MHz, 10 MHz, 20 MHz}
NDLRBLUT = [6 15 25 50 100];
enb.NDLRB = NDLRBLUT(SampleRateLUT==rxsim.RadioFrontEndSampleRate);

if isempty(enb.NDLRB)  %---------------------------------------------------> 无法获取小区带宽信息，报错
    error('Sampling rate not supported. Supported rates are %s.',...
            '1.92 MHz, 3.84 MHz, 7.68 MHz, 15.36 MHz, 30.72 MHz');
end
fprintf('\nSDR hardware sampling rate configured to capture %d LTE RBs.\n',enb.NDLRB);

%% （3）信道估计参数配置
cec.PilotAverage = 'UserDefined';  % -----------------------------------------------------> Type of pilot symbol averaging
cec.FreqWindow = 9;                % ----------------------------------------------------->  Frequency window size in REs
cec.TimeWindow = 9;                % ----------------------------------------------------->  Time window size in REs
cec.InterpType = 'Cubic';          % ----------------------------------------------------->  2D interpolation type
cec.InterpWindow = 'Centered';     % ----------------------------------------------------->  Interpolation window type
cec.InterpWinSize = 3;             % ----------------------------------------------------->  Interpolation window size

enbDefault = enb;

%% （4）基带波形处理：频偏校正 -> 小区搜索
load('rxWaveform5.mat');
rxWaveform  = [rxWaveform1;rxWaveform1];

%（1） 频偏校正
frequencyOffset = lteFrequencyOffset(enb,rxWaveform);
rxWaveform = lteFrequencyCorrect(enb,rxWaveform,frequencyOffset);     %---------------------------> 频偏校正
fprintf('\nCorrected a frequency offset of %i Hz.\n',frequencyOffset)
    
%（2）小区搜索获得小区PCI
cellSearch.SSSDetection = 'PostFFT'; cellSearch.MaxCellCount = 1;
[NCellID,frameOffset] = lteCellSearch(enb,rxWaveform,cellSearch);
fprintf('Detected a cell identity of %i.\n', NCellID);
enb.NCellID = NCellID; 
    
%（3）同步：找到LTE系统帧起始位置，删除不完整的帧
rxWaveform = rxWaveform(frameOffset+1:end,:);
tailSamples = mod(length(rxWaveform),samplesPerFrame);
rxWaveform = rxWaveform(1:end-tailSamples,:);
enb.NSubframe = 0;
fprintf('Corrected a timing offset of %i samples.\n',frameOffset)
    
%（4） OFDM解调
    rxGrid = lteOFDMDemodulate(enb,rxWaveform);
    
%（5）信道估计
    [hest,nest] = lteDLChannelEstimate(enb,cec,rxGrid);
    
    sfDims = lteResourceGridSize(enb);
    Lsf = sfDims(2); % OFDM symbols per subframe
    LFrame = 10*Lsf; % OFDM symbols per frame
    numFullFrames = length(rxWaveform)/samplesPerFrame;
    
    rxDataFrame = zeros(sum(enb.PDSCH.TrBlkSizes(:)),numFullFrames);
    recFrames = zeros(numFullFrames,1);
    rxSymbols = []; 
    
%（6）每个帧解码MIB, PDSCH and DL-SCH
    for frame = 0:(numFullFrames-1)
        fprintf('\nPerforming DL-SCH Decode for frame %i of %i in burst:\n', ...
            frame+1,numFullFrames)
        
        % 1、抽取0号子帧
        enb.NSubframe = 0;
        rxsf = rxGrid(:,frame*LFrame+(1:Lsf),:);
        hestsf = hest(:,frame*LFrame+(1:Lsf),:,:);
               
        % 2、PBCH解码
        enb.CellRefP = 4;
        pbchIndices = ltePBCHIndices(enb); 
        [pbchRx,pbchHest] = lteExtractResources(pbchIndices,rxsf,hestsf);
        [~,~,nfmod4,mib,CellRefP] = ltePBCHDecode(enb,pbchRx,pbchHest,nest);
        
        % 3、判断PBCH成功解码 
        if ~CellRefP
            fprintf('  No PBCH detected for frame.\n');
            continue;
        end
        enb.CellRefP = CellRefP; % From ltePBCHDecode
        
        % 4、解码MIB获取系统帧号
        enb = lteMIB(mib,enb);
        enb.NFrame = enb.NFrame + nfmod4;
        fprintf('  Successful MIB Decode.\n')
        fprintf('  Frame number: %d.\n',enb.NFrame);
        
        % 5、限制带宽
        enb.NDLRB = min(enbDefault.NDLRB,enb.NDLRB);
        
        % 6、保存系统帧号
        recFrames(frame+1) = enb.NFrame;
               
        % 7、处理子帧
        for sf = 0:9
            if sf~=5 
            
            % 课堂练习：完成子帧处理函数，实现实际数据恢复。
            [rxSymbols,rxEncodedBits,outLen]=subframeProc(enb,sf,rxGrid,frame,LFrame,Lsf,cec, rxSymbols);
            
            [decbits{sf+1}, blkcrc(sf+1)] = lteDLSCHDecode(enb,enb.PDSCH,outLen, rxEncodedBits);   %#ok<SAGROW>        
            end
        end
        
        % 8、重采样解码比特
        fprintf('Retrieving decoded transport block data.\n');
        rxdata = [];
        for i = 1:length(decbits)
            if i~=6 
                rxdata = [rxdata; decbits{i}{:}]; %#ok<AGROW>
            end
        end
        
        % 9、保存数据
        rxDataFrame(:,frame+1) = rxdata;

        % 10、信道估计
        focalFrameIdx = frame*LFrame+(1:LFrame);             
    end


%% （5）结果显示
[~,frameIdx] = min(recFrames);
fprintf('\nRecombining received data blocks:\n');

decodedRxDataStream = zeros(length(rxDataFrame(:)),1);
frameLen = size(rxDataFrame,1);

% 生成比特流
for n=1:numFullFrames
    currFrame = mod(frameIdx-1,numFullFrames)+1; % Get current frame index 
    decodedRxDataStream((n-1)*frameLen+1:n*frameLen) = rxDataFrame(:,currFrame);
    frameIdx = frameIdx+1; % Increment frame index
end

% 图像重构
fprintf('\nConstructing image from received data.\n');
decodedRxDataStream=decodedRxDataStream(1:2*frameLen);
str = reshape(sprintf('%d',decodedRxDataStream(1:422280)), 8, []).';
decdata = uint8(bin2dec(str));
imsize =[115 153 3];
receivedImage = reshape(decdata,imsize);

% 图像显示
figure(1);
imshow(receivedImage); title('Recovered Image')
