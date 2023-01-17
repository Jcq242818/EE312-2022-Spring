%% 802.11a Transmission and Reception Using Analog Devices AD9361/AD9364
% This example shows how to transmit and receive WLAN packets on a single
% SDR platform, using Xilinx(R) Zynq-Based Radio Support Package with
% MATLAB(R) and WLAN System Toolbox(TM). An image file is encoded and
% packed into WLAN packets for transmission, and subsequently decoded on
% reception.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting Started>
% documentation for details on configuring your host computer to work with
% the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2015-2016 The MathWorks, Inc.

%% Introduction
% You can use WLAN System Toolbox to generate standard-compliant waveforms.
% These baseband waveforms can be upconverted for RF transmission using SDR
% hardware such as Xilinx Zynq-Based Radio. The <matlab:sdrzdoc('sdrz_repeatedwaveformtx') Repeated Waveform Transmitter>
% functionality with the Zynq(R) radio hardware, allows a waveform to be
% transmitted over the air and is received using the same SDR hardware. The
% received waveform is captured and downsampled to baseband using a Xilinx
% Zynq-Based Radio and is decoded to recover the transmitted information as
% shown in the following figure.
%
% <<SDRWLAN80211aTransceiverZynq_published.png>>
%
% This example imports and segments an image file into multiple MPDUs,
% where each  MPDU includes a MAC header, a variable length frame body
% (MSDU) and a FCS (Frame Check Sequence), which contains a 32 bit CRC. The
% MPDUs are sequentially numbered using the sequence control field in the
% MAC header of each MPDU. The MPDUs are passed to the PHY layer as PSDUs.
% Each PSDU data is packed into a single NonHT, 802.11a(TM) [ <#24 1> ] WLAN
% packet using WLAN System Toolbox. This example creates a WLAN baseband
% waveform using the <matlab:doc('wlanWaveformGenerator') wlanWaveformGenerator> function. This function consumes multiple PSDUs
% and processes each to form a series of PPDUs. The multiple PPDUs are
% upconverted and the RF waveform is sent over the air using Xilinx
% Zynq-Based radio as shown in the following figure.
%
% <<ZynqRadioWLANTransmitReceiveAD9361AD9364MLTransmit.png>>
%
% This example then captures the transmitted waveform using the same Zynq
% radio hardware platform. The RF transmission is demodulated to baseband
% and the received MPDUs are ordered using the sequence control field in
% the MAC header. The information bits in multiple received MSDUs are
% combined to recover the transmitted image. The received processing is
% illustrated in the following diagram.
%
% <<ZynqRadioWLANTransmitReceiveAD9361AD9364MLReceive.png>>

%% Example Setup
% Before you run this example, perform the following steps:
%
% # Configure your host computer to work with the Support Package for
% Xilinx Zynq-Based Radio. See <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> for help. 
% # Make sure that WLAN System Toolbox is installed. You must have WLAN
% System Toolbox license to run this example.
%
% When you run this example, the first thing the script does is to check
% for WLAN System Toolbox.

% Check that WLAN System Toolbox is installed, and that there is a valid license
if isempty(ver('wlan')) % Check for WLAN System Toolbox install
    error('Please install WLAN System Toolbox to run this example.');
elseif ~license('test', 'WLAN_System_Toolbox') % Check that a valid license is present
    error( ...
        'A valid license for WLAN System Toolbox is required to run this example.');
end
 
%%
% The script then configures all of the scopes and figures that will be 
% displayed throughout the example. 

% Setup handle for image plot
if ~exist('imFig', 'var') || ~ishandle(imFig)
    imFig = figure;
    imFig.NumberTitle = 'off';
    imFig.Name = 'Image Plot';
    imFig.Visible = 'off';
else   
    clf(imFig); % Clear figure
    imFig.Visible = 'off';
end

% Setup Spectrum viewer
hsa = dsp.SpectrumAnalyzer( ...
    'SpectrumType',    'Power density', ...
    'SpectralAverages', 10, ...
    'YLimits',         [-150 -50], ...
    'Title',           'Received Baseband WLAN Signal Spectrum', ...
    'YLabel',          'Power spectral density');

% Setup the constellation diagram viewer for equalized WLAN symbols
hcd = comm.ConstellationDiagram('Title','Equalized WLAN Symbols',...
                                'ShowReferenceConstellation',false);
                            
%%
% An <matlab:sdrzdoc('commsdrtxzc706fmc23') SDR Transmitter>
% system object is used with the named radio |'ZC706 and FMCOMMS2/3/4'|
% to transmit baseband data to the SDR hardware.
%
% By default, the example is configured to run with ZC706 and ADI
% FMCOMMS2/3/4 hardware. You can replace the named hardware |'ZC706 and
% FMCOMMS2/3/4'| with |'ZedBoard and FMCOMMS2/3/4'| or |'PicoZed SDR'| in
% the |deviceNameSDR| variable to run with ZedBoard(TM) and ADI
% FMCOMMS2, FMCOMMS3, FMCOMMS4 hardware or PicoZed SDR.

%  Initialize SDR device
deviceNameSDR = 'ZC706 and FMCOMMS2/3/4'; % Set SDR Device
cfgdev = sdrdev(deviceNameSDR);           % Create SDR device object

%%
% The following sections explain the design and architecture of this
% example, and what you can expect to see as the code is executed.

%% Transmitter Design
% The general structure of the WLAN transmitter can be described as follows:
%
% # Import an image file and convert it to a binary stream.
% # Generate a baseband WLAN signal using WLAN System Toolbox, pack the
% binary data stream into multiple 802.11a packets.
% # Prepare the baseband signal for transmission using the SDR hardware.
% # Send the baseband data to the SDR hardware for upsampling and
% continuous transmission at the desired center frequency.

%%
% The transmitter gain parameter is used to impair the quality of the
% received waveform, you can change this parameter to reduce transmission
% quality, and impair the signal. These are suggested values, depending on
% your antenna configuration, you may have to tweak these values. The
% suggested values are:
%
% # Set to 0 for increased gain (0dB)
% # Set to -10 for default gain (-10dB)
% # Set to -20 for reduced gain (-20dB)

txGain = -10;

%%
% *Prepare Image File*
% 
% The example reads data from the image file, scales it for transmission,
% and converts it to a binary data stream. The scaling of the image reduces
% the quality of the image by decreasing the size of the binary data
% stream.
%
% The size of the transmitted image directly impacts the number of WLAN
% packets which are required for the transmission of the image data. A
% scaling factor is used to scale the original size of the image. The
% number of WLAN packets that are generated for transmission is dependent
% on the following:
%
% # The image scaling that you set when importing the image file.
% # The length of the data carried in a packet. This is specified by the
% |msduLength| variable. 
% # The MCS value of the transmitted packet.
%
% The combination of scaling factor |scale| of 0.2, and MSDU length
% |msduLength| of 4048 as shown below, requires the transmission of 6 WLAN
% radio packets. Increasing the scaling factor or decreasing the MSDU
% length will result in the transmission of more packets.

% Input an image file and convert to binary stream
fileTx = 'peppers.png';            % Image file name
fData = imread(fileTx);            % Read image data from file
scale = 0.2;                       % Image scaling factor
origSize = size(fData);            % Original input image size
scaledSize = max(floor(scale.*origSize(1:2)),1); % Calculate new image size
heightIx = min(round(((1:scaledSize(1))-0.5)./scale+0.5),origSize(1));
widthIx = min(round(((1:scaledSize(2))-0.5)./scale+0.5),origSize(2));
fData = fData(heightIx,widthIx,:); % Resize image
imsize = size(fData);              % Store new image size
binData = dec2bin(fData(:),8);     % Convert to 8 bit unsigned binary
txImage = reshape((binData-'0').',1,[]).'; % Create binary stream

%%
% The example displays the image file that is to be transmitted. When the
% image file is successfully received and decoded, the example displays the
% image.

% Plot transmit image
figure(imFig);
imFig.Visible = 'on';
subplot(211); 
    imshow(fData);
    title('Transmitted Image');
subplot(212);
    title('Received image will appear here...');
    set(gca,'Visible','off');
    set(findall(gca, 'type', 'text'), 'visible', 'on');

pause(1); % Pause to plot Tx image

%%
% *Fragment transmit data*
%
% The example uses the binary data stream that is created from the input
% image file |txImage|. The binary data stream is split into smaller
% transmit units of size |msduLength|. A MAC header and CRC field are added
% to each transmit unit to constitute an MPDU. The MPDUs are then
% sequentially passed to the physical layer for transmission.
%
% The length of the MPDU should be less than 4096 bytes. In this example
% the |msduLength| field is set to 4048 bytes. This is to ensure that after
% appending the MAC header and CRC field with |msduBits| the length of the
% MPDU should not exceed 4095 bytes. The data in the last MPDU is appended
% with zeros, this is to make all MPDUs the same size.

msduLength = 4048; % MSDU length in bytes
msduBits = msduLength*8;
numMSDUs = ceil(length(txImage)/msduBits);
padZeros = msduBits-mod(length(txImage),msduBits);
txData = [txImage; zeros(padZeros,1)];

% Generate FCS and from an MPDU. The FCS is calculated using the standard
% generator polynomial of degree 32 as defined in section 8.2.4.8 of
% 802.11n HT standard
generatorPolynomial = [32 26 23 22 16 12 11 10 8 7 5 4 2 1 0];
fcsGen = comm.CRCGenerator(generatorPolynomial);
fcsGen.InitialConditions = 1;
fcsGen.DirectMethod = true;
fcsGen.FinalXOR = 1;

% Divide input data stream into fragments
numFragment = 0;
bitsPerOctet = 8; 
lengthMACheader = 256; % MPDU header length in bits
lengthFCS = 32;        % FCS length in bits
lengthMPDU = lengthMACheader+msduBits+lengthFCS; % MPDU length in bits
data = zeros(lengthMPDU*numMSDUs,1);

for ind=0:numMSDUs-1
    
   % Extract bits for each MPDU
   frameBody = txData(ind*msduBits+1:msduBits*(ind+1),:);
   
   % Generate MPDU header bits
   mpduHeader = helperNonHTMACHeader(mod(numFragment, ...
                    16),mod(ind,4096));
    
   % Create MPDU with header, body and FCS             
   psdu = step(fcsGen,[mpduHeader;frameBody]);
   
   % Concatenate PSDUs for waveform generation
   data(lengthMPDU*ind+1:lengthMPDU*(ind+1)) = psdu;
   
end

%% 
% *Generate IEEE 802.11a Baseband WLAN Signal*
%
% The NonHT waveform is synthesized using <matlab:doc('wlanWaveformGenerator') wlanWaveformGenerator>
% with a non-HT format configuration object. The object is created using the
% <matlab:doc('wlanNonHTConfig') wlanNonHTConfig> function. The properties
% of the object contain the configuration. In this example an object is
% configured for a 20 MHz bandwidth, 1 transmit antenna and 64QAM rate 2/3
% (MCS 6).

nonHTcfg = wlanNonHTConfig;         % Create packet configuration
nonHTcfg.MCS = 6;                   % Modulation: 64QAM Rate: 2/3
nonHTcfg.NumTransmitAntennas = 1;   % Number of transmit antenna
chanBW = nonHTcfg.ChannelBandwidth;
nonHTcfg.PSDULength = lengthMPDU/bitsPerOctet; % Set the PSDU length

% The transmitter uses the |transmitRepeat| functionality to transmit the
% baseband WLAN waveform in a loop from the DDR memory on the Zynq-Based
% Radio platform. The transmitted RF signal is oversampled and transmitted
% at 30MHz. The 802.11a signal is transmitted on channel 5 which correspond
% to center frequency of 2.432GHz as defined in section 17.4.6.3 of [1]

tx = sdrtx(deviceNameSDR); % Transmitter properties

% Resample the transmit waveform at 30MHz
fs = helperSampleRate(chanBW); % Transmit sample rate in MHz
osf = 1.5;                     % OverSampling factor

tx.BasebandSampleRate = fs*osf; 
tx.CenterFrequency = 2.432e9;  % Channel 5
tx.ShowAdvancedProperties = true;
tx.BypassUserLogic = true;
tx.Gain = txGain;
tx.ChannelMapping = 1;         % Apply TX channel mapping

% Initialize the scrambler with a random integer for each packet
scramblerInitialization = randi([1 127],numMSDUs,1);

% Generate baseband NonHT packets separated by idle time 
txWaveform = wlanWaveformGenerator(data,nonHTcfg, ...
    'NumPackets',numMSDUs,'IdleTime',20e-6, ...
    'ScramblerInitialization',scramblerInitialization);

% Resample transmit waveform 
txWaveform  = resample(txWaveform,fs*osf,fs);

fprintf('\nGenerating WLAN transmit waveform:\n')

% Scale the normalized signal to avoid saturation of RF stages
powerScaleFactor = 0.8;
txWaveform = txWaveform.*(1/max(abs(txWaveform))*powerScaleFactor);
% Cast the transmit signal to int16, this is the native format for the SDR
% hardware
txWaveform = int16(txWaveform*2^15);

% Transmit RF waveform
tx.transmitRepeat(txWaveform);

%%
% *Repeated transmission using SDR Hardware*
%
% The |transmitRepeat| function transfers the baseband WLAN packets with
% idle time to the SDR platform, and stores the signal samples in hardware
% memory. The example then transmits the waveform continuously over the air
% until the release method of the transmit object is called. Messages are
% displayed in the command window to confirm that transmission has started
% successfully.

%% Receiver Design
%
% The general structure of the WLAN receiver can be described as follows:
%
% # Capture multiple packets of the transmitted WLAN signal using
% SDR hardware.
% # Detect a packet
% # Coarse carrier frequency offset is estimated and corrected
% # Fine timing synchronization is established. The L-STF, L-LTF and L-SIG
% samples are provided for fine timing to allow to adjust the packet
% detection at the start or end of the L-STF 
% # Fine carrier frequency offset is estimated and corrected
% # Perform a channel estimation for the received signal using the L-LTF
% # Decode the L-SIG field to recover the MCS value and the length of the
% data portion
% # Decode the data field to obtain the transmitted data within each
% packet
% # Perform cyclic redundancy code (CRC) check on the receive PSDUs
% # Order the received PSDU based on the information in the Sequence
% Control field of the MAC header
% # Combine decoded bit from all transmitted packet to form the received
% image
%
% This example plots the Power Spectral Density(PSD) of the captured
% waveform, and shows visualizations of the equalized data symbols, and
% the received image.
% 
%%
% *Receiver Setup*
% 
% The receiver is controlled using the properties defined in the |rx|
% object. The sample rate of the receiver is 30MHz, which is 1.5 times the
% baseband sample rate of 20MHz.

%%
% An <matlab:sdrzdoc('commsdrrxzc706fmc23') SDR Receiver> system object is
% used with the named radio |'ZC706 and FMCOMMS2/3/4'| to receive baseband
% data from the SDR hardware. 

rx = sdrrx(deviceNameSDR);
rx.BasebandSampleRate = tx.BasebandSampleRate;
rx.CenterFrequency = tx.CenterFrequency;
rx.OutputDataType = 'double';
rx.ChannelMapping = 1; % Configure Rx channel map
rx.EnableBurstMode = true;
rx.NumFramesInBurst = 1; % Capture all packets in a single burst 

% Configure receive samples equivalent to twice the length of the
% transmitted signal, this is to ensure that PSDUs are received in order.
% On reception the duplicate MAC fragments are removed.
samplesPerFrame = length(txWaveform);
rx.SamplesPerFrame = samplesPerFrame*2;
hsa.SampleRate = rx.BasebandSampleRate;

% Get the required field indices within a PSDU 
indLSTF = wlanFieldIndices(nonHTcfg,'L-STF'); 
indLLTF = wlanFieldIndices(nonHTcfg,'L-LTF'); 
indLSIG = wlanFieldIndices(nonHTcfg,'L-SIG');

%%
% *Capture Receive Packets* 
%%
% The transmitted waveform is captured using the Xilinx Zynq-Based Radio.
burstCaptures = zeros(rx.SamplesPerFrame,1);

% SDR Capture
fprintf('\nStarting a new RF capture.\n')
len = 0;
    
while len == 0
    % Store twice the length of WLAN transmitted packet worth of
    % samples, burstCaptures holds rx.PacketPerBurst number of
    % consecutive packet worth of baseband WLAN samples
    [burstCaptures,len,lostSamples] = step(rx);
end
if lostSamples
    warning('Dropped samples');
end

%%
% *Receiver Processing* 
%%
% The example uses a while loop to capture and decode packets. The WLAN
% waveform is continually transmitted over the air in a loop, the first
% packet that is captured by the receiver is not guaranteed to be the first
% packet that was transmitted. This means that the packets may be decoded
% out of sequence. To enable the received packets to be recombined in the
% correct order, their sequence number must be determined. The Sequence
% Control field in the MAC header contains information on the current
% packet order and therefore must be decoded. The decoded PSDU bits for
% each packet are passed to the MAC layer where the Sequence Control field
% in the MAC header is recovered to determine the packet order. The while
% loop finishes receive processing when a duplicate frame is detected,
% which is finally removed during receiver processing. In case of a missing
% frame the quality of the image is degraded.
%
% When the WLAN packet has successfully decoded, the detected sequence
% number is displayed in the command window for each received packet. The
% equalized data symbol constellation is shown for each receive packet.

% Show power spectral density of the received waveform
step(hsa,burstCaptures);

% Downsample the received signal
rxWaveform = resample(burstCaptures,fs,fs*osf);
rxWaveformLen = size(rxWaveform,1);
searchOffset = 0; % Offset from start of the waveform in samples

% Minimum packet length is 10 OFDM symbols
lstfLen = double(indLSTF(2)); % Number of samples in L-STF
minPktLen = lstfLen*5;
pktInd = 1;
sr = helperSampleRate(chanBW); % Sampling rate
offsetLLTF = [];
packetSeq = [];
displayFlag = 0; % Flag to display the decoded information

% Generate FCS for MPDU
fcsDet = comm.CRCDetector(generatorPolynomial);
fcsDet.InitialConditions = 1;
fcsDet.DirectMethod = true;
fcsDet.FinalXOR = 1;

% Perform EVM calculation
hEVM = comm.EVM('AveragingDimensions',[1 2 3]);
hEVM.MaximumEVMOutputPort = true;

% Receiver processing
while (searchOffset + minPktLen) <= rxWaveformLen    
    % Packet detect
    pktOffset = helperPacketDetect(rxWaveform(1+searchOffset:end,:), ...
        chanBW,0.8)-1;
 
    % Adjust packet offset
    pktOffset = searchOffset+pktOffset;
    if isempty(pktOffset) || (pktOffset+indLSIG(2)>rxWaveformLen)
        if pktInd==1
            disp('** No packet detected **');
        end
        break;
    end

    % Extract non-HT fields and perform coarse frequency offset correction
    % to allow for reliable symbol timing
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    coarseFreqOffset = wlanCoarseCFOEstimate(nonHT,chanBW); 
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

    % Symbol timing synchronization
    offsetLLTF = helperSymbolTiming(nonHT,chanBW);
    
    if isempty(offsetLLTF)
        searchOffset = pktOffset+lstfLen;
        continue;
    end
    % Adjust packet offset
    pktOffset = pktOffset+offsetLLTF-double(indLLTF(1));

    % Timing synchronization complete: Packet detected and synchronized
    % Extract the NonHT preamble field after synchronization and
    % perform frequency correction
    if (pktOffset<0) || ((pktOffset+minPktLen)>rxWaveformLen) 
        searchOffset = pktOffset+lstfLen; 
        continue; 
    end
    fprintf('\nPacket-%d detected at index %d\n',pktInd,pktOffset+1);
  
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

    % Perform fine frequency offset correction on the synchronized and
    % coarse corrected Non-HT preamble fields

    lltf = nonHT(indLLTF(1):indLLTF(2),:);           % Extract L-LTF
    fineFreqOffset = wlanFineCFOEstimate(lltf,chanBW);
    nonHT = helperFrequencyOffset(nonHT,fs,-fineFreqOffset);
    cfoCorrection = coarseFreqOffset+fineFreqOffset; % Total CFO


    % Channel estimation using L-LTF
    lltf = nonHT(indLLTF(1):indLLTF(2),:);
    demodLLTF = wlanLLTFDemodulate(lltf,chanBW);
    chanEstLLTF = wlanLLTFChannelEstimate(demodLLTF,chanBW);

    % Noise estimation
    noiseVarNonHT = helperNoiseEstimate(demodLLTF);

    % Recover L-SIG field bits
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

    % Retrieve packet parameters based on decoded L-SIG
    [lsigMCS,lsigLen,rxSamples] = helperInterpretLSIG(recLSIGBits,sr);

    if (rxSamples+pktOffset)>length(rxWaveform)
        disp('** Not enough samples to decode packet **');
        break;
    end
    
    % Apply CFO correction to the entire packet
    rxWaveform(pktOffset+(1:rxSamples),:) = helperFrequencyOffset(...
        rxWaveform(pktOffset+(1:rxSamples),:),fs,-cfoCorrection);

    % Create a receive Non-HT config object
    rxNonHTcfg = wlanNonHTConfig;
    rxNonHTcfg.MCS = lsigMCS;
    rxNonHTcfg.PSDULength = lsigLen;

    % Get the data field indices within a PPDU 
    indNonHTData = wlanFieldIndices(rxNonHTcfg,'NonHT-Data');

    % Recover PSDU bits using transmitted packet parameters and channel
    % estimates from L-LTF
    [rxPSDU,eqSym] = wlanNonHTDataRecover(rxWaveform(pktOffset+...
           (indNonHTData(1):indNonHTData(2)),:), ...
           chanEstLLTF,noiseVarNonHT,rxNonHTcfg);

    step(hcd,reshape(eqSym,[],1)); % Current constellation 
    release(hcd); % Release previous constellation plot

    refSym = helperClosestConstellationPoint(eqSym,rxNonHTcfg);
    [evm.RMS,evm.Peak] = step(hEVM,refSym,eqSym);

    % Remove FCS from MAC header and frame body
    [rxBit{pktInd},crcCheck] = step(fcsDet,double(rxPSDU)); %#ok<SAGROW>

    if ~crcCheck
         disp('  MAC CRC check pass');
    else
         disp('  MAC CRC check fail');
    end

    % Process receive MAC fragments, this is to retrieve the sequencing
    % information of the MAC fragments
    [mac,packetSeq(pktInd)] = ...
           helperNonHTMACHeaderDecode(rxBit{pktInd}); %#ok<SAGROW>

    % Display decoded information
    if displayFlag
        fprintf('  Estimated CFO: %5.1f Hz\n\n',cfoCorrection); %#ok<UNRCH>

        disp('  Decoded L-SIG contents: ');
        fprintf('                            MCS: %d\n',lsigMCS);
        fprintf('                         Length: %d\n',lsigLen);
        fprintf('    Number of samples in packet: %d\n\n',rxSamples);

        fprintf('  EVM:\n');
        fprintf('    EVM peak: %0.3f%%  EVM RMS: %0.3f%%\n\n', ...
        evm.Peak,evm.RMS);

        fprintf('  Decoded MAC Sequence Control field contents:\n');
        fprintf('    Sequence number:%d\n',packetSeq(pktInd));
    end

    % Update search index
    searchOffset = pktOffset+double(indNonHTData(2));

    
    pktInd = pktInd+1;
    % Finish processing when a duplicate packet is detected. The
    % recovered data includes bits from duplicate frame
    if length(unique(packetSeq))<length(packetSeq)
        break
    end  
end

% Release the state of transmit and receive object
release(tx); 
release(rx);

%%
% *Reconstruct Image*
%%
% The image is reconstructed from the received MAC frames.
if ~(isempty(offsetLLTF)||isempty(pktOffset))&& ...
        (numMSDUs==(numel(packetSeq)-1));
    % Remove the MAC header and duplicate captured MAC fragment
    rxBitMatrix = cell2mat(rxBit); 
    rxData = rxBitMatrix(lengthMACheader+1:end,1:numel(packetSeq)-1);

    startSeq = find(packetSeq==0);
    rxData = circshift(rxData,[0 -(startSeq(1)-1)]);% Order MAC fragments

    % Perform bit error rate (BER) calculation
    hBER = comm.ErrorRate;
    err = step(hBER,double(rxData(:)), ...
                    txData(1:length(reshape(rxData,[],1))));
    fprintf('  \nBit Error Rate (BER):\n');
    fprintf('          Bit Error Rate (BER) = %0.5f.\n',err(1));
    fprintf('          Number of bit errors = %d.\n', err(2));
    fprintf('    Number of transmitted bits = %d.\n\n',length(txData));

    % Recreate image from received data
    fprintf('\nConstructing image from received data.\n');
    
    str = reshape(sprintf('%d',rxData(1:length(txImage))),8,[]).';
    decdata = uint8(bin2dec(str));
  
    receivedImage = reshape(decdata,imsize);
    % Plot received image
    if exist('imFig', 'var') && ishandle(imFig) % If Tx figure is open
        figure(imFig); subplot(212); 
    else
        figure; subplot(212);
    end
    imshow(receivedImage);
    title(sprintf('Received Image'));
end

%% Things to Try
% You can modify the transmitter |txGain| gain to observe the difference in
% the EVM and BER after signal reception and processing. You should also be
% able to see any errors in the displayed, received image. Try changing the
% scaling factor |scale| to 0.5. This should improve the quality of the
% received image by generating more transmit bits. This should also
% increase the number of transmitted PPDUs.

%% Troubleshooting
%
% General tips for troubleshooting SDR hardware and the Communications
% System Toolbox Support Package for Xilinx Zynq-Based Radio can be found
% in <matlab:sdrzdoc('sdrz_troubleshoot') Common Problems and Fixes>.

%% Selected Bibliography
% # IEEE Std 802.11(TM)-2012 IEEE Standard for Information technology -
% Telecommunications and information exchange between systems - Local and
% metropolitan area networks - Specific requirements - Part 11: Wireless
% LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications.

displayEndOfDemoMessage(mfilename)