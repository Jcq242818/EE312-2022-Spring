%% LTE���ջ���ƣ�����LTE�����亯���ָ�Ԥ¼����

% # 1. ���Ȳ����źţ�
% # 2. �ź�Ƶƫ����
% # 3. �ź�ͬ��
% # 4. OFDM���
% # 5. �ŵ�����
% # 6. ����PDSCH and DL-SCH 
% # 7. ͼ���ع�

clc
clear
%% 1. ����USRP�ź�
%(1) ����USRP����-----------------------------------------------------------------------------------> ����Ƶ�ʡ�����Ȳ���
% prmQPSKReceiver.USRPCenterFrequency = 900e6;
% prmQPSKReceiver.USRPGain = 25;
% prmQPSKReceiver.RxBufferedFrames=1;
% prmQPSKReceiver.Fs = 5e6; 
% prmQPSKReceiver.USRPDecimationFactor = 100e6/prmQPSKReceiver.Fs; 
% prmQPSKReceiver.FrameSize=307200;
% prmQPSKReceiver.USRPFrameLength = prmQPSKReceiver.FrameSize*prmQPSKReceiver.RxBufferedFrames;

% (2) ������ջ�����---------------------------------------------------------------------------------> ʹ��COMM��������
% radio = comm.SDRuReceiver(...
%         'IPAddress',            '192.168.10.2', ...
%         'CenterFrequency',      prmQPSKReceiver.USRPCenterFrequency, ...
%         'Gain',                 prmQPSKReceiver.USRPGain, ...
%         'DecimationFactor',     prmQPSKReceiver.USRPDecimationFactor, ...
%         'FrameLength',          prmQPSKReceiver.USRPFrameLength, ...
%         'OutputDataType',       'double');

%(3) ѭ������ֱ���ɹ��������ݰ�-------------------------------------------------------------------> ʹ��USRPѭ���������ݰ�   
% while (true)
% 
%          [corruptSignal, len] = step(radio);    %-----------------------------------> ʹ��USRP�������ݰ�  
% 
%       if len < prmQPSKReceiver.USRPFrameLength  %-----------------------------------> ���δ�ܳɹ���ȡ����ϣ���ĳ��ȣ�����
%          errorIndex = errorIndex+1;
%          disp ( 'Not enough samples returned!' ) ;
%          disp(errorIndex)
%       else          
%          rxWaveform1 = corruptSignal;           %-----------------------------------> �ɹ����������ѭ�� 
%          break; 
%       end
% end

%% 2�����յĻ����źŴ���
%% (1) ������������
rxsim = struct;
rxsim.RadioFrontEndSampleRate = 15.36e6; %-------------------------------------------------------> ���ò�����  
rxsim.RadioCenterFrequency = 900e6; %------------------------------------------------------------> ��������Ƶ��
rxsim.NRxAnts = 1;      %------------------------------------------------------------------------> ��������
rxsim.FramesPerBurst = 3;  %---------------------------------------------------------------------> ����Ĳ����а���ϵͳ֡��
rxsim.numBurstCaptures = 1;  %-------------------------------------------------------------------> ����Ĳ�����

samplesPerFrame = 10e-3*rxsim.RadioFrontEndSampleRate;  %---------------------------------> LTEϵͳ֡��������������ʱ��Ϊ10ms
rx.BasebandSampleRate = rxsim.RadioFrontEndSampleRate;
rx.CenterFrequency = rxsim.RadioCenterFrequency;
rx.SamplesPerFrame = samplesPerFrame;
rx.OutputDataType = 'double';
rx.EnableBurstMode = true;
rx.NumFramesInBurst = rxsim.FramesPerBurst;
rx.ChannelMapping = 1;

burstCaptures = zeros(samplesPerFrame,rxsim.NRxAnts,rxsim.FramesPerBurst);  %--------------------> LTEϵͳ֡�������ʼ��

%% (2) ϵͳ��������
txsim.RC = 'R.7';   %----------------------------------------------------------------------------> �汾R7
rmc = lteRMCDL(txsim.RC);
enb.PDSCH = rmc.PDSCH;
enb.DuplexMode = 'FDD';   %----------------------------------------------------------------------> FDD
enb.CyclicPrefix = 'Normal';  %------------------------------------------------------------------> ��ͨѭ��ǰ׺
enb.CellRefP = 4; 

SampleRateLUT = [1.92 3.84 7.68 15.36 30.72]*1e6;  %-----------------------> ����: {1.4 MHz, 3 MHz, 5 MHz, 10 MHz, 20 MHz}
NDLRBLUT = [6 15 25 50 100];
enb.NDLRB = NDLRBLUT(SampleRateLUT==rxsim.RadioFrontEndSampleRate);

if isempty(enb.NDLRB)  %---------------------------------------------------> �޷���ȡС��������Ϣ������
    error('Sampling rate not supported. Supported rates are %s.',...
            '1.92 MHz, 3.84 MHz, 7.68 MHz, 15.36 MHz, 30.72 MHz');
end
fprintf('\nSDR hardware sampling rate configured to capture %d LTE RBs.\n',enb.NDLRB);

%% ��3���ŵ����Ʋ�������
cec.PilotAverage = 'UserDefined';  % -----------------------------------------------------> Type of pilot symbol averaging
cec.FreqWindow = 9;                % ----------------------------------------------------->  Frequency window size in REs
cec.TimeWindow = 9;                % ----------------------------------------------------->  Time window size in REs
cec.InterpType = 'Cubic';          % ----------------------------------------------------->  2D interpolation type
cec.InterpWindow = 'Centered';     % ----------------------------------------------------->  Interpolation window type
cec.InterpWinSize = 3;             % ----------------------------------------------------->  Interpolation window size

enbDefault = enb;

%% ��4���������δ���ƵƫУ�� -> С������
load('rxWaveform5.mat');
rxWaveform  = [rxWaveform1;rxWaveform1];

%��1�� ƵƫУ��
frequencyOffset = lteFrequencyOffset(enb,rxWaveform);
rxWaveform = lteFrequencyCorrect(enb,rxWaveform,frequencyOffset);     %---------------------------> ƵƫУ��
fprintf('\nCorrected a frequency offset of %i Hz.\n',frequencyOffset)
    
%��2��С���������С��PCI
cellSearch.SSSDetection = 'PostFFT'; cellSearch.MaxCellCount = 1;
[NCellID,frameOffset] = lteCellSearch(enb,rxWaveform,cellSearch);
fprintf('Detected a cell identity of %i.\n', NCellID);
enb.NCellID = NCellID; 
    
%��3��ͬ�����ҵ�LTEϵͳ֡��ʼλ�ã�ɾ����������֡
rxWaveform = rxWaveform(frameOffset+1:end,:);
tailSamples = mod(length(rxWaveform),samplesPerFrame);
rxWaveform = rxWaveform(1:end-tailSamples,:);
enb.NSubframe = 0;
fprintf('Corrected a timing offset of %i samples.\n',frameOffset)
    
%��4�� OFDM���
    rxGrid = lteOFDMDemodulate(enb,rxWaveform);
    
%��5���ŵ�����
    [hest,nest] = lteDLChannelEstimate(enb,cec,rxGrid);
    
    sfDims = lteResourceGridSize(enb);
    Lsf = sfDims(2); % OFDM symbols per subframe
    LFrame = 10*Lsf; % OFDM symbols per frame
    numFullFrames = length(rxWaveform)/samplesPerFrame;
    
    rxDataFrame = zeros(sum(enb.PDSCH.TrBlkSizes(:)),numFullFrames);
    recFrames = zeros(numFullFrames,1);
    rxSymbols = []; 
    
%��6��ÿ��֡����MIB, PDSCH and DL-SCH
    for frame = 0:(numFullFrames-1)
        fprintf('\nPerforming DL-SCH Decode for frame %i of %i in burst:\n', ...
            frame+1,numFullFrames)
        
        % 1����ȡ0����֡
        enb.NSubframe = 0;
        rxsf = rxGrid(:,frame*LFrame+(1:Lsf),:);
        hestsf = hest(:,frame*LFrame+(1:Lsf),:,:);
               
        % 2��PBCH����
        enb.CellRefP = 4;
        pbchIndices = ltePBCHIndices(enb); 
        [pbchRx,pbchHest] = lteExtractResources(pbchIndices,rxsf,hestsf);
        [~,~,nfmod4,mib,CellRefP] = ltePBCHDecode(enb,pbchRx,pbchHest,nest);
        
        % 3���ж�PBCH�ɹ����� 
        if ~CellRefP
            fprintf('  No PBCH detected for frame.\n');
            continue;
        end
        enb.CellRefP = CellRefP; % From ltePBCHDecode
        
        % 4������MIB��ȡϵͳ֡��
        enb = lteMIB(mib,enb);
        enb.NFrame = enb.NFrame + nfmod4;
        fprintf('  Successful MIB Decode.\n')
        fprintf('  Frame number: %d.\n',enb.NFrame);
        
        % 5�����ƴ���
        enb.NDLRB = min(enbDefault.NDLRB,enb.NDLRB);
        
        % 6������ϵͳ֡��
        recFrames(frame+1) = enb.NFrame;
               
        % 7��������֡
        for sf = 0:9
            if sf~=5 
            
            % ������ϰ�������֡��������ʵ��ʵ�����ݻָ���
            [rxSymbols,rxEncodedBits,outLen]=subframeProc(enb,sf,rxGrid,frame,LFrame,Lsf,cec, rxSymbols);
            
            [decbits{sf+1}, blkcrc(sf+1)] = lteDLSCHDecode(enb,enb.PDSCH,outLen, rxEncodedBits);   %#ok<SAGROW>        
            end
        end
        
        % 8���ز����������
        fprintf('Retrieving decoded transport block data.\n');
        rxdata = [];
        for i = 1:length(decbits)
            if i~=6 
                rxdata = [rxdata; decbits{i}{:}]; %#ok<AGROW>
            end
        end
        
        % 9����������
        rxDataFrame(:,frame+1) = rxdata;

        % 10���ŵ�����
        focalFrameIdx = frame*LFrame+(1:LFrame);             
    end


%% ��5�������ʾ
[~,frameIdx] = min(recFrames);
fprintf('\nRecombining received data blocks:\n');

decodedRxDataStream = zeros(length(rxDataFrame(:)),1);
frameLen = size(rxDataFrame,1);

% ���ɱ�����
for n=1:numFullFrames
    currFrame = mod(frameIdx-1,numFullFrames)+1; % Get current frame index 
    decodedRxDataStream((n-1)*frameLen+1:n*frameLen) = rxDataFrame(:,currFrame);
    frameIdx = frameIdx+1; % Increment frame index
end

% ͼ���ع�
fprintf('\nConstructing image from received data.\n');
decodedRxDataStream=decodedRxDataStream(1:2*frameLen);
str = reshape(sprintf('%d',decodedRxDataStream(1:422280)), 8, []).';
decdata = uint8(bin2dec(str));
imsize =[115 153 3];
receivedImage = reshape(decdata,imsize);

% ͼ����ʾ
figure(1);
imshow(receivedImage); title('Recovered Image')
