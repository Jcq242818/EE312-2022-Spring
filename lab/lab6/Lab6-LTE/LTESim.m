clc
clear

% -------------------------------------------------------------------------------------------------> ����Ƶ�׷�������
hsa = dsp.SpectrumAnalyzer( ...
    'SpectrumType',    'Power density', ...
    'SpectralAverages', 10, ...
    'YLimits',         [-150 -60], ...
    'Title',           'Received Baseband LTE Signal Spectrum', ...
    'YLabel',          'Power spectral density');

% -------------------------------------------------------------------------------------------------> ��������ͼ
hcd = comm.ConstellationDiagram('Title','Equalized PDSCH Symbols',...
                                'ShowReferenceConstellation',false);

%% 2.��������
% 1. ����ͼ�����ɶ���������
% 2. ����DL-SCH������·����
% 3. ����RMC����
% 4. ����LTE����������

%% 2.1 ����ͼ�����ɶ���������            
fileTx = 'tree.png';    % -------------------------------------------------------------------------> ����ͼ���ļ���

scale = 0.4;      %--------------------------------------------------------------------------------> ��������
[fData_Resize] = ResizeImage(fileTx,scale);   %----------------------------------------------------> ͼ������

imsize = size(fData_Resize);     % ----------------------------------------------------------------> ��ͼ��ĳߴ�

binData = dec2bin(fData_Resize(:),8); %------------------------------------------------------------> ת����������

trData = reshape((binData-'0').',1,[]).'; %--------------------------------------------------------> ���������Ʊ�����

figure(1);  %--------------------------------------------------------------------------------------> ��ʾ��Ҫ�����ͼ��
subplot(211); 
    imshow(fData_Resize);
    title('Transmitted Image');
subplot(212);
    title('Received image will appear here...');
    set(gca,'Visible','off');
    set(findall(gca, 'type', 'text'), 'visible', 'on');


%% 2.2 ����DL-SCH������·����
txsim.RC = 'R.7';       % RMC��Reference Measurement Channel---------------------------------------> �ο������ŵ�
txsim.NCellID = 88;     % -------------------------------------------------------------------------> С����ʶ
txsim.NFrame = 700;     % -------------------------------------------------------------------------> ϵͳ֡��
txsim.TotFrames = 1;    % -------------------------------------------------------------------------> ��ʼ��ϵͳ֡��
txsim.DesiredCenterFrequency = 2.45e9; % ----------------------------------------------------------> ����Ƶ��
txsim.NTxAnts = 1;      % -------------------------------------------------------------------------> ������������

rmc = lteRMCDL(txsim.RC);  %-----------------------------------------------------------------------> ����RMC����

trBlkSize = rmc.PDSCH.TrBlkSizes;
txsim.TotFrames = ceil(numel(trData)/sum(trBlkSize(:)));  %----------------------------------------> ��������Ҫ��LTE֡����3����

%% 2.3 ����LTE����������
[eNodeBOutput,txGrid,rmc] = LTEWaveformGenerator(rmc,txsim,trData);

figure(2)
subplot(2,1,1)
plot(real(eNodeBOutput)); axis([0 10000 -0.05 0.05]); xlabel('n') ;ylabel('eNodeBOutput')   
subplot(2,1,2)
plot(imag(eNodeBOutput)); axis([0 10000 -0.05 0.05]); xlabel('n') ;ylabel('eNodeBOutput')         

%% 3.���ջ����
% 1����������ź�
% 2�������ź�ƵƫУ��
% 3���ź�ͬ�����ҵ�LTE֡��ʼλ��
% 4��OFDM�������ȡLTE��Դ����
% 5���ŵ�����
% 6������PD-SCH��DL-SCH����÷��������
% 7��ͼ��ָ�

%% 3.1 ������ջ�����ṹ�����
rxsim = struct;   % -------------------------------------------------------------------------------> ������ջ�����ṹ�����
rxsim.RadioFrontEndSampleRate = rmc.SamplingRate; % -----------------------------------------------> ���ò�����
rxsim.RadioCenterFrequency = txsim.DesiredCenterFrequency;  % -------------------------------------> ���ý��ջ�����Ƶ��
rxsim.NRxAnts = txsim.NTxAnts;   % ----------------------------------------------------------------> ������������
rxsim.FramesPerBurst = txsim.TotFrames+1;    %-----------------------------------------------------> ����ϵͳ֡��
rxsim.numBurstCaptures = 1; 
samplesPerFrame = 10e-3*rxsim.RadioFrontEndSampleRate; % %-----------------------------------------> ����ϵͳ֡�Ĳ�������

rx.BasebandSampleRate = rxsim.RadioFrontEndSampleRate;
rx.CenterFrequency = rxsim.RadioCenterFrequency;
rx.SamplesPerFrame = samplesPerFrame;
rx.OutputDataType = 'double';
rx.EnableBurstMode = true;
rx.NumFramesInBurst = rxsim.FramesPerBurst;
rx.ChannelMapping = 1;

burstCaptures = zeros(samplesPerFrame,rxsim.NRxAnts,rxsim.FramesPerBurst);

%% 3.2. ��ʼ��ENodeB
enb.PDSCH = rmc.PDSCH;     % ----------------------------------------------------------------------> ��ʼ��eNodeB           
enb.DuplexMode = 'FDD';    % ----------------------------------------------------------------------> ���ø��÷�ʽ
enb.CyclicPrefix = 'Normal';    % -----------------------------------------------------------------> �ж�ѭ��ǰ׺��ʽ
enb.CellRefP = 4; 

% Bandwidth: {1.4 MHz, 3 MHz, 5 MHz, 10 MHz, 20 MHz}   % ------------------------------------------> �ж�С������
SampleRateLUT = [1.92 3.84 7.68 15.36 30.72]*1e6;
NDLRBLUT = [6 15 25 50 100];
enb.NDLRB = NDLRBLUT(SampleRateLUT==rxsim.RadioFrontEndSampleRate);
if isempty(enb.NDLRB)
    error('Sampling rate not supported. Supported rates are %s.',...
            '1.92 MHz, 3.84 MHz, 7.68 MHz, 15.36 MHz, 30.72 MHz');
end
fprintf('\nSDR hardware sampling rate configured to capture %d LTE RBs.\n',enb.NDLRB);

% 3.2. �ŵ����ƽṹ������
cec.PilotAverage = 'UserDefined';  % --------------------------------------------------------------> Type of pilot symbol averaging
cec.FreqWindow = 9;                % --------------------------------------------------------------> Frequency window size in REs
cec.TimeWindow = 9;                % --------------------------------------------------------------> Time window size in REs
cec.InterpType = 'Cubic';          % --------------------------------------------------------------> 2D interpolation type
cec.InterpWindow = 'Centered';     % --------------------------------------------------------------> Interpolation window type
cec.InterpWinSize = 3;             % --------------------------------------------------------------> Interpolation window size

%% 3.3 �źŲ���ʹ���
enbDefault = enb;

while rxsim.numBurstCaptures
    enb = enbDefault;
    rxWaveform  = eNodeBOutput;    % --------------------------------------------------------------> �źŲ���
    
    hsa.SampleRate = rxsim.RadioFrontEndSampleRate;   
    step(hsa,rxWaveform);          % --------------------------------------------------------------> ��ʾƵ��
    
    %----------------------------------------------------------------------------------------------> ����Ƶƫ����
    frequencyOffset = lteFrequencyOffset(enb,rxWaveform);
    rxWaveform = lteFrequencyCorrect(enb,rxWaveform,frequencyOffset);
    fprintf('\nCorrected a frequency offset of %i Hz.\n',frequencyOffset)
    
    %----------------------------------------------------------------------------------------------> С������PCI
    cellSearch.SSSDetection = 'PostFFT'; cellSearch.MaxCellCount = 1;
    [NCellID,frameOffset] = lteCellSearch(enb,rxWaveform,cellSearch);
    fprintf('Detected a cell identity of %i.\n', NCellID);
    enb.NCellID = NCellID; 
    
    %----------------------------------------------------------------------------------------------> ͬ��
    rxWaveform = rxWaveform(frameOffset+1:end,:);
    tailSamples = mod(length(rxWaveform),samplesPerFrame);
    rxWaveform = rxWaveform(1:end-tailSamples,:);
    enb.NSubframe = 0;
    fprintf('Corrected a timing offset of %i samples.\n',frameOffset)
    
    rxGrid = lteOFDMDemodulate(enb,rxWaveform);     %----------------------------------------------> OFDM ���

    [hest,nest] = lteDLChannelEstimate(enb,cec,rxGrid);   %----------------------------------------> �ŵ�����
    sfDims = lteResourceGridSize(enb);    %--------------------------------------------------------> ��Դ����
    
    Lsf = sfDims(2); % ----------------------------------------------------------------------------> ������֡��OFDM����
    LFrame = 10*Lsf; % ----------------------------------------------------------------------------> ����ϵͳ֡��OFDM����
    
    numFullFrames = length(rxWaveform)/samplesPerFrame;   
    rxDataFrame = zeros(sum(enb.PDSCH.TrBlkSizes(:)),numFullFrames);
    recFrames = zeros(numFullFrames,1);
    rxSymbols = []; txSymbols = [];
    
    %---------------------------------------------------------------------------------------------> MIB����, PDSCH and DL-SCH
    for frame = 0:(numFullFrames-1)
        fprintf('\nPerforming DL-SCH Decode for frame %i of %i in burst:\n', ...
            frame+1,numFullFrames)
        
        %-----------------------------------------------------------------------------------------> ��ȡ0����֡���ŵ����ƽ��
        enb.NSubframe = 0;
        rxsf = rxGrid(:,frame*LFrame+(1:Lsf),:);
        hestsf = hest(:,frame*LFrame+(1:Lsf),:,:);
               
        %-----------------------------------------------------------------------------------------> PBCH���
        enb.CellRefP = 4;
        pbchIndices = ltePBCHIndices(enb); 
        [pbchRx,pbchHest] = lteExtractResources(pbchIndices,rxsf,hestsf);
        [~,~,nfmod4,mib,CellRefP] = ltePBCHDecode(enb,pbchRx,pbchHest,nest);
        
        if ~CellRefP
            fprintf('  No PBCH detected for frame.\n');
            continue;
        end
        enb.CellRefP = CellRefP; 
        
        %----------------------------------------------------------------------------------------> ���enbֵ,����MIB����
        enb = lteMIB(mib,enb);
        enb.NFrame = enb.NFrame+nfmod4;
        fprintf('  Successful MIB Decode.\n')
        fprintf('  Frame number: %d.\n',enb.NFrame);
        
        enb.NDLRB = min(enbDefault.NDLRB,enb.NDLRB);   %-----------------------------------------> �������д���
              
        recFrames(frame+1) = enb.NFrame;  % -----------------------------------------------------> �洢֡��
               
        %----------------------------------------------------------------------------------------> ������֡
        for sf = 0:9
            if sf~=5   % ------------------------------------------------------------------------> ����5����֡

                enb.NSubframe = sf;
                rxsf = rxGrid(:,frame*LFrame+sf*Lsf+(1:Lsf),:);

                [hestsf,nestsf] = lteDLChannelEstimate(enb,cec,rxsf); % -------------------------> �ŵ�����

                %--------------------------------------------------------------------------------> PCFICH���
                pcfichIndices = ltePCFICHIndices(enb);
                [pcfichRx,pcfichHest] = lteExtractResources(pcfichIndices,rxsf,hestsf);
                [cfiBits,recsym] = ltePCFICHDecode(enb,pcfichRx,pcfichHest,nestsf);

                %--------------------------------------------------------------------------------> CFI ����
                enb.CFI = lteCFIDecode(cfiBits);
                
                %--------------------------------------------------------------------------------> ���PDSCH����
                [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enb, enb.PDSCH, enb.PDSCH.PRBSet); 
                [pdschRx, pdschHest] = lteExtractResources(pdschIndices, rxsf, hestsf);

                %--------------------------------------------------------------------------------> PDSCH����
                [rxEncodedBits, rxEncodedSymb] = ltePDSCHDecode(enb,enb.PDSCH,pdschRx,...
                                               pdschHest,nestsf);

                %--------------------------------------------------------------------------------> �ع�������
                rxSymbols = [rxSymbols; rxEncodedSymb{:}]; %#ok<AGROW>
                
                %--------------------------------------------------------------------------------> DL-SCH����
                outLen = enb.PDSCH.TrBlkSizes(enb.NSubframe+1);  
                
                [decbits{sf+1}, blkcrc(sf+1)] = lteDLSCHDecode(enb,enb.PDSCH,...  
                                                outLen, rxEncodedBits); 
                       
                txRecode = lteDLSCH(enb,enb.PDSCH,pdschIndicesInfo.G,decbits{sf+1});

                txRemod = ltePDSCH(enb, enb.PDSCH, txRecode);    %-------------------------------> PD-SCH����
                [~,refSymbols] = ltePDSCHDecode(enb, enb.PDSCH, txRemod);

                txSymbols = [txSymbols; refSymbols{:}]; %#ok<AGROW>

                release(hcd); % 
                step(hcd,rxEncodedSymb{:}); % %---------------------------------------------------> ����������
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


%% 3.4 ͼ��ָ�

[~,frameIdx] = min(recFrames);   % --------------------------------------------------------------> ���ϵͳ֡��
fprintf('\nRecombining received data blocks:\n');
decodedRxDataStream = zeros(length(rxDataFrame(:)),1);
frameLen = size(rxDataFrame,1);

%------------------------------------------------------------------------------------------------> �ع�������
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

%------------------------------------------------------------------------------------------------> BER����
hBER = comm.ErrorRate;
err = step(hBER, decodedRxDataStream(1:length(trData)), trData);
fprintf('  Bit Error Rate (BER) = %0.5f.\n', err(1));
fprintf('  Number of bit errors = %d.\n', err(2));
fprintf('  Number of transmitted bits = %d.\n',length(trData));

%------------------------------------------------------------------------------------------------> ͼ���ع�
fprintf('\nConstructing image from received data.\n');
str = reshape(sprintf('%d',decodedRxDataStream(1:length(trData))), 8, []).';
decdata = uint8(bin2dec(str));
receivedImage = reshape(decdata,imsize);

figure(1);
subplot(212); 
imshow(receivedImage);
title(sprintf('Received Image: %dx%d Antenna Configuration',txsim.NTxAnts, rxsim.NRxAnts));
