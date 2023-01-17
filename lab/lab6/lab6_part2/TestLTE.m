%% ���ջ��źŴ������
clc;clear;

%% ����IQ����
load eNodeBOutput.mat           %----------------------------------------------------------------------------------> ����IQ�ź�
eNodeBOutput = double(eNodeBOutput)/32768; %-----------------------------------------------------------------------> ����IQ�ź�
sr = 15.36e6;                   %----------------------------------------------------------------------------------> ������

%% 1. ��ʾ�����ź�Ƶ�ף�eNodeBOutputһ��107520������,����ʱ��Ϊ0.007s��7ms��
spectrumAnalyzer = dsp.SpectrumAnalyzer();
spectrumAnalyzer.Name = 'Received signal spectrum';
fprintf('\nPlotting received signal spectrum...\n');
step(spectrumAnalyzer, eNodeBOutput);

%% 2. ��ʾPSS/SSS��ز���
synchCorrPlot = dsp.ArrayPlot();
synchCorrPlot.Name = 'PSS/SSS correlation';  %---------------------------------------------------------------------> PSS/SSS

%% 3. ��ʾPDCCH�ŵ�OFDM�������ŵ�����ͼ
pdcchConstDiagram = comm.ConstellationDiagram();
pdcchConstDiagram.Name = 'PDCCH constellation';  %-----------------------------------------------------------------> ����ͼ

%% 4. ͳ��EVM
pdschEVM = comm.EVM();   %-----------------------------------------------------------------------------------------> ����EVM

%% 6. eNodeB�����ʼ����������Դ�飨RB��6����Ҳ����ζ��72�����ز�
% �������ͨѭ��ǰ׺��1��RB����12�����ز������ز����Ϊ15KHz����1��ʱ϶��0.5ms��7��OFDM���ţ�
enb = struct;                   %----------------------------------------------------------------------------------> eNodeB�ṹ��
enb.NDLRB = 6;                  %----------------------------------------------------------------------------------> ��Դ��
ofdmInfo = lteOFDMInfo(setfield(enb,'CyclicPrefix','Normal')); %#ok<SFLD>

%% 7. �²����źţ�ʹ��resample���������źŴ�15.36MS/s->1.92Ms���������źų���Ϊ13440��
%����С����Ϣ�ֲ��ھ���DC�����6��RB�ϣ�ռ�ô���15KHz*12*6=1.08MHz�����Բ��û���1.92MS/s���Իָ�
nSamples = ceil(ofdmInfo.SamplingRate/round(sr)*size(eNodeBOutput,1));
nRxAnts = 1;
downsampled = zeros(nSamples, nRxAnts);
downsampled(:,1) = resample(eNodeBOutput(:,1), ofdmInfo.SamplingRate, round(sr));  %------------------------------> �²���

%% 8. С��������ä�죬FDD��TDD��Normal��Extended
%PSS��SSSä����Եó�С��PCI��enb.NCellID��
[enbMax,offsetMax]=NCellDetection(enb,downsampled);

enb = enbMax;
offset = offsetMax;
corr = cell(1,3);
idGroup = floor(enbMax.NCellID/3);
for i = 0:2
    enb.NCellID = idGroup*3 + mod(enbMax.NCellID + i,3);    %-----------------------------------------------------> NID��15,16,17���Ƚ�
    [~,corr{i+1}] = lteDLFrameOffset(enb, downsampled);
    corr{i+1} = sum(corr{i+1},2);
end
threshold = 1.3 * max([corr{2}; corr{3}]);    %-----------------------------------------------------> ���NID����17ʱ��С��15��16ʱ1.3��
if (max(corr{1})<threshold)    
    warning('Synchronization signal correlation was weak; detected cell identity may be incorrect.');
end

enb.NCellID = enbMax.NCellID;  %---------------------------------------------------------------------------------> ���򣬷���CellID

synchCorrPlot.YLimits = [0 max([corr{1}; threshold])*1.1];
step(synchCorrPlot, [corr{1}]);  %-------------------------------------------------------------------------------> PSS/SSS���

%% 9 ����ͬ��
fprintf('Timing offset to frame start: %d samples\n',offset);
downsampled = downsampled(1+offset:end,:); 
enb.NSubframe = 0;
fprintf('Cell-wide settings after cell search:\n');
disp(enb);
%% 10 ϵͳ��ϢƵƫ����
fprintf('\nPerforming frequency offset estimation...\n');
delta_f = lteFrequencyOffset(enb, downsampled);
fprintf('Frequency offset: %0.3fHz\n',delta_f);
downsampled = lteFrequencyCorrect(enb, downsampled, delta_f);    
%% 11. �ŵ�����
%--------------------------------------------------------------------------------------------------------------> �ŵ����Ʋ�������
cec.PilotAverage = 'UserDefined';     % Type of pilot averaging
cec.FreqWindow = 9;                   % Frequency window size    
cec.TimeWindow = 9;                   % Time window size    
cec.InterpType = 'cubic';             % 2D interpolation type
cec.InterpWindow = 'Centered';        % Interpolation window type
cec.InterpWinSize = 1;                % Interpolation window size  
enb.CellRefP = 4;   
%-------------------------------------------------------------------------------------------------------------> OFDM���                                                               OFDM���
fprintf('Performing OFDM demodulation...\n\n');
griddims = lteResourceGridSize(enb); 
%-------------------------------------------------------------------------> OFDM��� һ����֡����14��OFDM���ţ�����6����֡
L = griddims(2);                     
%-------------------------------------------------------------------------> rxgrid��ÿһ�б�ʾһ��OFDM������
rxgrid = lteOFDMDemodulate(enb, downsampled);    
%-------------------------------------------------------------------------> ȡ��һ����֡���ŵ�����
[hest, nest] = lteDLChannelEstimate(enb, cec, rxgrid(:,1:L,:));
%% 12 PBCH�ŵ�����
fprintf('Performing MIB decoding...\n');
pbchIndices = ltePBCHIndices(enb);
[pbchRx, pbchHest] = lteExtractResources(pbchIndices, rxgrid(:,1:L,:), hest(:,1:L,:,:));

[bchBits, pbchSymbols, nfmod4, mib, enb.CellRefP] = ltePBCHDecode(enb, pbchRx, pbchHest, nest); 

enb = lteMIB(mib, enb);  %------------------------------------------------------------------------------------> MIB����

enb.NFrame = enb.NFrame+nfmod4;

fprintf('Cell-wide settings after MIB decoding:\n');  
disp(enb);  %-------------------------------------------------------------------------------------------------> MIB������


%% 13. SIB1����
fprintf('Restarting reception now that bandwidth (NDLRB=%d) is known...\n',enb.NDLRB);

%% ��1�� �ز���
ofdmInfo = lteOFDMInfo(enb);

fprintf('\nResampling not required; received signal is at desired sampling rate for NDLRB=%d (%0.3fMs/s).\n',enb.NDLRB,sr/1e6);

nSamples = ceil(ofdmInfo.SamplingRate/round(sr)*size(eNodeBOutput,1));
resampled = zeros(nSamples, nRxAnts);

resampled(:,1) = resample(eNodeBOutput(:,1), ofdmInfo.SamplingRate, round(sr));

%% ��2�� Ƶƫ���ƺ;���
fprintf('\nPerforming frequency offset estimation...\n');
delta_f = lteFrequencyOffset(enb, resampled);

fprintf('Frequency offset: %0.3fHz\n',delta_f);
resampled = lteFrequencyCorrect(enb, resampled, delta_f);

%% ��3�� �ҵ�֡����ʼλ��
fprintf('\nPerforming timing offset estimation...\n');
offset = lteDLFrameOffset(enb, resampled); 
fprintf('Timing offset to frame start: %d samples\n',offset);
% Aligning signal with the start of the frame
resampled = resampled(1+offset:end,:);   

%% ��4�� OFDM ���
fprintf('\nPerforming OFDM demodulation...\n\n');
rxgrid = lteOFDMDemodulate(enb, resampled);   

%% ��5�� SIB1 ����
if (mod(enb.NFrame,2)~=0)                    
    if (size(rxgrid,2)>=(L*10))
        rxgrid(:,1:(L*10),:) = [];   
        fprintf('Skipping frame %d (odd frame number does not contain SIB1).\n\n',enb.NFrame);
    else        
        rxgrid = [];
    end
    enb.NFrame = enb.NFrame + 1;
end

%% ��6������5����֡��ֹ
if (size(rxgrid,2)>=(L*5))
    rxgrid(:,1:(L*5),:) = [];    
else    
    rxgrid = [];
end
enb.NSubframe = 5;

if (isempty(rxgrid))
    fprintf('Received signal does not contain a subframe carrying SIB1.\n\n');
end

%% �����㹻������SIB����
decState = [];   %------------------------------------------------------------------------------------------> �����ش�����

while (size(rxgrid,2) > 0)  %-------------------------------------------------------------------------------> SIB����

    fprintf('SIB1 decoding for frame %d\n',mod(enb.NFrame,1024));

    if (mod(enb.NFrame,8)==0)
        fprintf('Resetting HARQ buffers.\n\n'); %-----------------------------------------------------------> ��������HARQ����
        decState = [];
    end

    rxsubframe = rxgrid(:,1:L,:);  %------------------------------------------------------------------------> ��ȡ��ǰ��֡
    
    [hest,nest] = lteDLChannelEstimate(enb, cec, rxsubframe);   %-------------------------------------------> �ŵ����� 
    
    % PCFICH �� CFI ��� 
    fprintf('Decoding CFI...\n\n');
    pcfichIndices = ltePCFICHIndices(enb);  %---------------------------------------------------------------> ��ȡCFI����
    [pcfichRx, pcfichHest] = lteExtractResources(pcfichIndices, rxsubframe, hest);

    % PCFICH ���
    cfiBits = ltePCFICHDecode(enb, pcfichRx, pcfichHest, nest);
    cfi = lteCFIDecode(cfiBits); %  %-----------------------------------------------------------------------> ��ȡCFI
    if (isfield(enb,'CFI') && cfi~=enb.CFI)
        release(pdcchConstDiagram);
    end
    enb.CFI = cfi;
    fprintf('Decoded CFI value: %d\n\n', enb.CFI);   
    
    tddConfigs = 0; % not used for FDD, only used to control while loop

    dci = {};
    
    while (isempty(dci) && ~isempty(tddConfigs))

        tddConfigs(1) = [];        

        % PDCCH ���  
        pdcchIndices = ltePDCCHIndices(enb); %-----------------------------------------------------------------------> PDCCH����
        [pdcchRx, pdcchHest] = lteExtractResources(pdcchIndices, rxsubframe, hest);

        % PDCCH���룬����ͼ
        [dciBits, pdcchSymbols] = ltePDCCHDecode(enb, pdcchRx, pdcchHest, nest);  %----------------------------------> PDCCH����
        step(pdcchConstDiagram, pdcchSymbols);

        fprintf('PDCCH search for SI-RNTI...\n\n');
        pdcch = struct('RNTI', 65535);  
        pdcch.ControlChannelType = 'PDCCH';
        pdcch.EnableCarrierIndication = 'Off';
        pdcch.SearchSpace = 'Common';
        pdcch.EnableMultipleCSIRequest = 'Off';
        pdcch.EnableSRSRequest = 'Off';
        pdcch.NTxAnts = 1;
        dci = ltePDCCHSearch(enb, pdcch, dciBits); %-----------------------------------------------------------------> DCI����             
    end
    

    if ~isempty(dci)  %-----------------------------------------------------------------> ���DCI����ɹ�����һ��PDSCH����
        
        dci = dci{1};
        fprintf('DCI message with SI-RNTI:\n');
        disp(dci);
        
        [pdsch, trblklen] = hPDSCHConfiguration(enb, dci, pdcch.RNTI);  %----------------------------------> ��DCI�л�ȡPDSCH����
        pdsch.NTurboDecIts = 5;
        fprintf('PDSCH settings after DCI decoding:\n');
        disp(pdsch);

        fprintf('Decoding SIB1...\n\n');        

        [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enb, pdsch, pdsch.PRBSet);  %-------------------> ��ȡPDSCH����
        [pdschRx, pdschHest] = lteExtractResources(pdschIndices, rxsubframe, hest);
 
        [dlschBits,pdschSymbols] = ltePDSCHDecode(enb, pdsch, pdschRx, pdschHest, nest); %----------------> PDSCH����

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

        fprintf('DCI decoding failed.\n\n');   %------------------------------------------------------------------> ����ʧ����ʾ
    end
    
    surf(abs(hest(:,:,1,1)));   %---------------------------------------------------------------------------------> �����ŵ�ͼ��
    if (size(rxgrid,2)>=(L*20))
        rxgrid(:,1:(L*20),:) = [];  
    else
        rxgrid = [];
    end
    enb.NFrame = enb.NFrame+2;
        
end

