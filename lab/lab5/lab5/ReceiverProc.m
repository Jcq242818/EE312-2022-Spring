function [rxBit,offsetLLTF,pktOffset,packetSeq]=ReceiverProc(MPDU_Param,nonHTcfg,hcd,chanBW,osf,burstCaptures)

% ��1����ȡPSDU����Ҫ����Ϣ
    indLSTF = wlanFieldIndices(nonHTcfg,'L-STF'); 
    indLLTF = wlanFieldIndices(nonHTcfg,'L-LTF'); 
    indLSIG = wlanFieldIndices(nonHTcfg,'L-SIG');

% ��2���²��������ź�
    fs = helperSampleRate(chanBW);
    rxWaveform = resample(burstCaptures,fs,fs*osf);
    rxWaveformLen = size(rxWaveform,1);
    searchOffset = 0; % Offset from start of the waveform in samples
  
% ��3����С��������10��OFDM����
    lstfLen = double(indLSTF(2)); % Number of samples in L-STF
    minPktLen = lstfLen*5;
    pktInd = 1;
    sr = helperSampleRate(chanBW); % Sampling rate
    offsetLLTF = [];
    packetSeq = [];
    displayFlag = 1; % Flag to display the decoded information

%��4��ΪMPDU����FCS
    fcsDet = comm.CRCDetector(MPDU_Param.generatorPolynomial);
    fcsDet.InitialConditions = 1;
    fcsDet.DirectMethod = true;
    fcsDet.FinalXOR = 1;

%��5������EVM
    hEVM = comm.EVM('AveragingDimensions',[1 2 3]);
    hEVM.MaximumEVMOutputPort = true;
    pktOffsetInx = 1; %�������STF��ʼλ

%��6������ѭ������
while (searchOffset + minPktLen) <= rxWaveformLen    
    
% ���ݰ���� Packet detect ��ⷽ��Ϊ����أ����ҵ�STF����ʼֵ 
    pktOffset = helperPacketDetect(rxWaveform(1+searchOffset:end,:),chanBW,0.8)-1;
 
% �������ݰ�ƫ�� Adjust packet offset
    pktOffset = searchOffset+pktOffset;
    if pktOffsetInx <=3 
        figure(5)
        subplot(4,1,pktOffsetInx); plot(real(rxWaveform)); hold on; plot([0 length(rxWaveform)], [0 0], 'r');
        stem(pktOffset,0.4); axis([10000 30000 -0.3 0.5]); xlabel('Time unit'); ylabel('Amplitude');
        pktOffsetInx =  pktOffsetInx+1;
    end
%   ���ݰ������ж�
    if isempty(pktOffset) || (pktOffset+indLSIG(2)>rxWaveformLen)
        if pktInd==1
            disp('** No packet detected **');
        end
        break;
    end
 
% ��ȡSTF/LTF/SIG�򣬴�Ƶƫ����
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    coarseFreqOffset = wlanCoarseCFOEstimate(nonHT,chanBW); 
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

%LTFͬ��
    offsetLLTF = helperSymbolTiming(nonHT,chanBW);
    
    if isempty(offsetLLTF)
        searchOffset = pktOffset+lstfLen;
        continue;
    end
    % Adjust packet offset
    pktOffset = pktOffset+offsetLLTF-double(indLLTF(1));%�ҵ�STF����ʼλ��
     if pktOffsetInx == 4
         figure(5)
         subplot(4,1,pktOffsetInx); plot(real(rxWaveform)); hold on; plot([0 length(rxWaveform)], [0 0], 'r');
         stem(pktOffset,0.4); axis([10000 30000 -0.3 0.5]); xlabel('Time unit'); ylabel('Amplitude');
         pktOffsetInx =  pktOffsetInx+1;
     end
%�ٴ��ж����ݰ��Ƿ������
    if (pktOffset<0) || ((pktOffset+minPktLen)>rxWaveformLen) 
        searchOffset = pktOffset+lstfLen; 
        continue; 
    end
    % �ٴγ�ȡSTF/LTF/SIG����Ƶƫ����
    fprintf('\nPacket-%d detected at index %d\n',pktInd,pktOffset+1);
  
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

% ��ȡLTF����Ƶƫ����
    lltf = nonHT(indLLTF(1):indLLTF(2),:);           % Extract L-LTF
    fineFreqOffset = wlanFineCFOEstimate(lltf,chanBW);
    nonHT = helperFrequencyOffset(nonHT,fs,-fineFreqOffset);
    cfoCorrection = coarseFreqOffset+fineFreqOffset; % Total CFO
 
% ����L-LTF���ŵ�����
    lltf = nonHT(indLLTF(1):indLLTF(2),:);
    demodLLTF = wlanLLTFDemodulate(lltf,chanBW);
    chanEstLLTF = wlanLLTFChannelEstimate(demodLLTF,chanBW);

% ��������
    noiseVarNonHT = helperNoiseEstimate(demodLLTF);

% �ָ���L-SIG��
    [recLSIGBits,failCheck] = wlanLSIGRecover( ...
           nonHT(indLSIG(1):indLSIG(2),:), ...
           chanEstLLTF, noiseVarNonHT,chanBW);
 
    if failCheck	
        fprintf('  L-SIG check fail \n');
        searchOffset = pktOffset+lstfLen; 
        continue; 
    else
        fprintf('  L-SIG check pass \n');
    end
 
% �ָ����ݰ�����������LSIG�ֶ�
    [lsigMCS,lsigLen,rxSamples] = helperInterpretLSIG(recLSIGBits,sr);
 
    if (rxSamples+pktOffset)>length(rxWaveform)
        disp('** Not enough samples to decode packet **');
        break;
    end

% Ӧ��CFO�����������ݰ��������ֶ�ƵƫУ��
    rxWaveform(pktOffset+(1:rxSamples),:) = helperFrequencyOffset(rxWaveform(pktOffset+(1:rxSamples),:),fs,-cfoCorrection);

% ��������Non-HT����
    rxNonHTcfg = wlanNonHTConfig;
    rxNonHTcfg.MCS = lsigMCS;
    rxNonHTcfg.PSDULength = lsigLen;

% ��ȡ������ָʾ
    indNonHTData = wlanFieldIndices(rxNonHTcfg,'NonHT-Data');


% �����ŵ����ƽ���ָ�PSDU���غ;���֮��ĵ��Ʒ���
    [rxPSDU,eqSym] = wlanNonHTDataRecover(rxWaveform(pktOffset+...
           (indNonHTData(1):indNonHTData(2)),:), ...
           chanEstLLTF,noiseVarNonHT,rxNonHTcfg);
 
% ��ʾ��ǰ����ͼ
    step(hcd,reshape(eqSym,[],1)); % Current constellation 
    release(hcd); % Release previous constellation plot
 
    refSym = helperClosestConstellationPoint(eqSym,rxNonHTcfg);
    [evm.RMS,evm.Peak] = step(hEVM,refSym,eqSym);

% ��MACͷ���Ƴ�FCS
    [rxBit{pktInd},crcCheck] = step(fcsDet,double(rxPSDU)); 
 
    if ~crcCheck
         disp('  MAC CRC check pass');
    else
         disp('  MAC CRC check fail');
    end
 
% ����MAC��Ϣ---��MACͷ�����н�������ȡ�����
    [mac,packetSeq(pktInd)] = helperNonHTMACHeaderDecode(rxBit{pktInd}); 

% ��ʾ������
    if displayFlag
        fprintf('  Estimated CFO: %5.1f Hz\n\n',cfoCorrection); 
 
        disp('  Decoded L-SIG contents: ');
        fprintf(' MCS: %d\n',lsigMCS);
        fprintf(' Length: %d\n',lsigLen);
        fprintf(' Number of samples in packet: %d\n\n',rxSamples);
 
        fprintf('  EVM:\n');
        fprintf('    EVM peak: %0.3f%%  EVM RMS: %0.3f%%\n\n', ...
        evm.Peak,evm.RMS);
 
        fprintf('  Decoded MAC Sequence Control field contents:\n');
        fprintf('    Sequence number:%d\n',packetSeq(pktInd));
    end

% �����������
    % Update search index
    searchOffset = pktOffset+double(indNonHTData(2));
 
    pktInd = pktInd+1;

% ���ظ��İ���⵽ʱ����������
    if length(unique(packetSeq))<length(packetSeq)
        break
    end  
end
packetSeq
