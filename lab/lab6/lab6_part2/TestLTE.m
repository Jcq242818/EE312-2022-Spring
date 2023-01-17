%% 接收机信号处理过程
clc;clear;

%% 导入IQ数据
load eNodeBOutput.mat           %----------------------------------------------------------------------------------> 加载IQ信号
eNodeBOutput = double(eNodeBOutput)/32768; %-----------------------------------------------------------------------> 加载IQ信号
sr = 15.36e6;                   %----------------------------------------------------------------------------------> 采样率

%% 1. 显示接收信号频谱（eNodeBOutput一共107520个数据,持续时间为0.007s，7ms）
spectrumAnalyzer = dsp.SpectrumAnalyzer();
spectrumAnalyzer.Name = 'Received signal spectrum';
fprintf('\nPlotting received signal spectrum...\n');
step(spectrumAnalyzer, eNodeBOutput);

%% 2. 显示PSS/SSS相关波形
synchCorrPlot = dsp.ArrayPlot();
synchCorrPlot.Name = 'PSS/SSS correlation';  %---------------------------------------------------------------------> PSS/SSS

%% 3. 显示PDCCH信道OFDM解调后符号的星座图
pdcchConstDiagram = comm.ConstellationDiagram();
pdcchConstDiagram.Name = 'PDCCH constellation';  %-----------------------------------------------------------------> 星座图

%% 4. 统计EVM
pdschEVM = comm.EVM();   %-----------------------------------------------------------------------------------------> 计算EVM

%% 6. eNodeB对象初始化，设置资源块（RB）6个，也就意味着72个子载波
% 设采用普通循环前缀，1个RB包含12个子载波（子载波间隔为15KHz）和1个时隙（0.5ms，7个OFDM符号）
enb = struct;                   %----------------------------------------------------------------------------------> eNodeB结构体
enb.NDLRB = 6;                  %----------------------------------------------------------------------------------> 资源块
ofdmInfo = lteOFDMInfo(setfield(enb,'CyclicPrefix','Normal')); %#ok<SFLD>

%% 7. 下采样信号，使用resample函数，将信号从15.36MS/s->1.92Ms，采样后信号长度为13440。
%由于小区信息分布在距离DC最近的6个RB上，占用带宽15KHz*12*6=1.08MHz，所以采用基本1.92MS/s可以恢复
nSamples = ceil(ofdmInfo.SamplingRate/round(sr)*size(eNodeBOutput,1));
nRxAnts = 1;
downsampled = zeros(nSamples, nRxAnts);
downsampled(:,1) = resample(eNodeBOutput(:,1), ofdmInfo.SamplingRate, round(sr));  %------------------------------> 下采样

%% 8. 小区搜索：盲检，FDD和TDD；Normal和Extended
%PSS和SSS盲检可以得出小区PCI（enb.NCellID）
[enbMax,offsetMax]=NCellDetection(enb,downsampled);

enb = enbMax;
offset = offsetMax;
corr = cell(1,3);
idGroup = floor(enbMax.NCellID/3);
for i = 0:2
    enb.NCellID = idGroup*3 + mod(enbMax.NCellID + i,3);    %-----------------------------------------------------> NID等15,16,17，比较
    [~,corr{i+1}] = lteDLFrameOffset(enb, downsampled);
    corr{i+1} = sum(corr{i+1},2);
end
threshold = 1.3 * max([corr{2}; corr{3}]);    %-----------------------------------------------------> 如果NID等于17时，小于15或16时1.3倍
if (max(corr{1})<threshold)    
    warning('Synchronization signal correlation was weak; detected cell identity may be incorrect.');
end

enb.NCellID = enbMax.NCellID;  %---------------------------------------------------------------------------------> 否则，返回CellID

synchCorrPlot.YLimits = [0 max([corr{1}; threshold])*1.1];
step(synchCorrPlot, [corr{1}]);  %-------------------------------------------------------------------------------> PSS/SSS相关

%% 9 符号同步
fprintf('Timing offset to frame start: %d samples\n',offset);
downsampled = downsampled(1+offset:end,:); 
enb.NSubframe = 0;
fprintf('Cell-wide settings after cell search:\n');
disp(enb);
%% 10 系统信息频偏纠正
fprintf('\nPerforming frequency offset estimation...\n');
delta_f = lteFrequencyOffset(enb, downsampled);
fprintf('Frequency offset: %0.3fHz\n',delta_f);
downsampled = lteFrequencyCorrect(enb, downsampled, delta_f);    
%% 11. 信道估计
%--------------------------------------------------------------------------------------------------------------> 信道估计参数配置
cec.PilotAverage = 'UserDefined';     % Type of pilot averaging
cec.FreqWindow = 9;                   % Frequency window size    
cec.TimeWindow = 9;                   % Time window size    
cec.InterpType = 'cubic';             % 2D interpolation type
cec.InterpWindow = 'Centered';        % Interpolation window type
cec.InterpWinSize = 1;                % Interpolation window size  
enb.CellRefP = 4;   
%-------------------------------------------------------------------------------------------------------------> OFDM解调                                                               OFDM解调
fprintf('Performing OFDM demodulation...\n\n');
griddims = lteResourceGridSize(enb); 
%-------------------------------------------------------------------------> OFDM解调 一个子帧中有14个OFDM符号；假设6个子帧
L = griddims(2);                     
%-------------------------------------------------------------------------> rxgrid的每一列表示一个OFDM解调结果
rxgrid = lteOFDMDemodulate(enb, downsampled);    
%-------------------------------------------------------------------------> 取第一个子帧做信道估计
[hest, nest] = lteDLChannelEstimate(enb, cec, rxgrid(:,1:L,:));
%% 12 PBCH信道解码
fprintf('Performing MIB decoding...\n');
pbchIndices = ltePBCHIndices(enb);
[pbchRx, pbchHest] = lteExtractResources(pbchIndices, rxgrid(:,1:L,:), hest(:,1:L,:,:));

[bchBits, pbchSymbols, nfmod4, mib, enb.CellRefP] = ltePBCHDecode(enb, pbchRx, pbchHest, nest); 

enb = lteMIB(mib, enb);  %------------------------------------------------------------------------------------> MIB解码

enb.NFrame = enb.NFrame+nfmod4;

fprintf('Cell-wide settings after MIB decoding:\n');  
disp(enb);  %-------------------------------------------------------------------------------------------------> MIB解码结果


%% 13. SIB1解码
fprintf('Restarting reception now that bandwidth (NDLRB=%d) is known...\n',enb.NDLRB);

%% （1） 重采样
ofdmInfo = lteOFDMInfo(enb);

fprintf('\nResampling not required; received signal is at desired sampling rate for NDLRB=%d (%0.3fMs/s).\n',enb.NDLRB,sr/1e6);

nSamples = ceil(ofdmInfo.SamplingRate/round(sr)*size(eNodeBOutput,1));
resampled = zeros(nSamples, nRxAnts);

resampled(:,1) = resample(eNodeBOutput(:,1), ofdmInfo.SamplingRate, round(sr));

%% （2） 频偏估计和纠正
fprintf('\nPerforming frequency offset estimation...\n');
delta_f = lteFrequencyOffset(enb, resampled);

fprintf('Frequency offset: %0.3fHz\n',delta_f);
resampled = lteFrequencyCorrect(enb, resampled, delta_f);

%% （3） 找到帧的起始位置
fprintf('\nPerforming timing offset estimation...\n');
offset = lteDLFrameOffset(enb, resampled); 
fprintf('Timing offset to frame start: %d samples\n',offset);
% Aligning signal with the start of the frame
resampled = resampled(1+offset:end,:);   

%% （4） OFDM 解调
fprintf('\nPerforming OFDM demodulation...\n\n');
rxgrid = lteOFDMDemodulate(enb, resampled);   

%% （5） SIB1 解码
if (mod(enb.NFrame,2)~=0)                    
    if (size(rxgrid,2)>=(L*10))
        rxgrid(:,1:(L*10),:) = [];   
        fprintf('Skipping frame %d (odd frame number does not contain SIB1).\n\n',enb.NFrame);
    else        
        rxgrid = [];
    end
    enb.NFrame = enb.NFrame + 1;
end

%% （6）少于5个子帧终止
if (size(rxgrid,2)>=(L*5))
    rxgrid(:,1:(L*5),:) = [];    
else    
    rxgrid = [];
end
enb.NSubframe = 5;

if (isempty(rxgrid))
    fprintf('Received signal does not contain a subframe carrying SIB1.\n\n');
end

%% 数据足够，进行SIB解码
decState = [];   %------------------------------------------------------------------------------------------> 设置重传参数

while (size(rxgrid,2) > 0)  %-------------------------------------------------------------------------------> SIB解码

    fprintf('SIB1 decoding for frame %d\n',mod(enb.NFrame,1024));

    if (mod(enb.NFrame,8)==0)
        fprintf('Resetting HARQ buffers.\n\n'); %-----------------------------------------------------------> 重新设置HARQ缓存
        decState = [];
    end

    rxsubframe = rxgrid(:,1:L,:);  %------------------------------------------------------------------------> 抽取当前子帧
    
    [hest,nest] = lteDLChannelEstimate(enb, cec, rxsubframe);   %-------------------------------------------> 信道估计 
    
    % PCFICH 和 CFI 解调 
    fprintf('Decoding CFI...\n\n');
    pcfichIndices = ltePCFICHIndices(enb);  %---------------------------------------------------------------> 获取CFI索引
    [pcfichRx, pcfichHest] = lteExtractResources(pcfichIndices, rxsubframe, hest);

    % PCFICH 解调
    cfiBits = ltePCFICHDecode(enb, pcfichRx, pcfichHest, nest);
    cfi = lteCFIDecode(cfiBits); %  %-----------------------------------------------------------------------> 获取CFI
    if (isfield(enb,'CFI') && cfi~=enb.CFI)
        release(pdcchConstDiagram);
    end
    enb.CFI = cfi;
    fprintf('Decoded CFI value: %d\n\n', enb.CFI);   
    
    tddConfigs = 0; % not used for FDD, only used to control while loop

    dci = {};
    
    while (isempty(dci) && ~isempty(tddConfigs))

        tddConfigs(1) = [];        

        % PDCCH 解调  
        pdcchIndices = ltePDCCHIndices(enb); %-----------------------------------------------------------------------> PDCCH索引
        [pdcchRx, pdcchHest] = lteExtractResources(pdcchIndices, rxsubframe, hest);

        % PDCCH解码，星座图
        [dciBits, pdcchSymbols] = ltePDCCHDecode(enb, pdcchRx, pdcchHest, nest);  %----------------------------------> PDCCH解码
        step(pdcchConstDiagram, pdcchSymbols);

        fprintf('PDCCH search for SI-RNTI...\n\n');
        pdcch = struct('RNTI', 65535);  
        pdcch.ControlChannelType = 'PDCCH';
        pdcch.EnableCarrierIndication = 'Off';
        pdcch.SearchSpace = 'Common';
        pdcch.EnableMultipleCSIRequest = 'Off';
        pdcch.EnableSRSRequest = 'Off';
        pdcch.NTxAnts = 1;
        dci = ltePDCCHSearch(enb, pdcch, dciBits); %-----------------------------------------------------------------> DCI解码             
    end
    

    if ~isempty(dci)  %-----------------------------------------------------------------> 如果DCI解码成功，进一步PDSCH解码
        
        dci = dci{1};
        fprintf('DCI message with SI-RNTI:\n');
        disp(dci);
        
        [pdsch, trblklen] = hPDSCHConfiguration(enb, dci, pdcch.RNTI);  %----------------------------------> 从DCI中获取PDSCH配置
        pdsch.NTurboDecIts = 5;
        fprintf('PDSCH settings after DCI decoding:\n');
        disp(pdsch);

        fprintf('Decoding SIB1...\n\n');        

        [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enb, pdsch, pdsch.PRBSet);  %-------------------> 获取PDSCH索引
        [pdschRx, pdschHest] = lteExtractResources(pdschIndices, rxsubframe, hest);
 
        [dlschBits,pdschSymbols] = ltePDSCHDecode(enb, pdsch, pdschRx, pdschHest, nest); %----------------> PDSCH解码

        if ~isempty(decState)
            fprintf('Recombining with previous transmission.\n\n');
        end        
        [sib1, crc, decState] = lteDLSCHDecode(enb, pdsch, trblklen, dlschBits, decState);
        
        recoded = lteDLSCH(enb, pdsch, pdschIndicesInfo.G, sib1);
        remod = ltePDSCH(enb, pdsch, recoded);
        [~,refSymbols] = ltePDSCHDecode(enb, pdsch, remod);
        
        fprintf('SIB1 CRC: %d\n',crc);
        if crc == 0
            fprintf('Successful SIB1 recovery.\n\n');
        else
            fprintf('SIB1 decoding failed.\n\n');
        end
        
    else

        fprintf('DCI decoding failed.\n\n');   %------------------------------------------------------------------> 解码失败提示
    end
    
    surf(abs(hest(:,:,1,1)));   %---------------------------------------------------------------------------------> 画出信道图像
    if (size(rxgrid,2)>=(L*20))
        rxgrid(:,1:(L*20),:) = [];  
    else
        rxgrid = [];
    end
    enb.NFrame = enb.NFrame+2;
        
end

