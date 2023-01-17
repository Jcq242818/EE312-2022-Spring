%% Transmit and Receive LTE MIMO Using a Single Analog Devices AD9361/AD9364
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package with MATLAB(R) and LTE System Toolbox(TM) to generate a multi-antenna 
% LTE transmission for simultaneous transmit and receive on a single 
% SDR platform. An image file is encoded and packed into a radio frame for
% transmission, and subsequently decoded on reception. The diagram below
% shows the setup used:
%
% <<sdr_2by2_transceiver_Zynq_diagram_published.png>>
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting Started>
% documentation for details on configuring your host computer to work with
% the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2016 The MathWorks, Inc.

%% Introduction
% You can use the LTE System Toolbox to generate standard-compliant baseband IQ
% downlink and uplink reference measurement channel (RMC) waveforms and
% downlink test model (E-TM) waveforms. These baseband waveforms can be
% modulated for RF transmission using SDR hardware such as Xilinx
% Zynq-Based Radio.
%
% This example imports an image file and packs it into multiple radio
% frames of a baseband RMC waveform that it generates using the LTE System
% Toolbox. The example creates a continuous RF LTE waveform by using the
% <matlab:sdrzdoc('sdrz_repeatedwaveformtx') Repeated Waveform Transmitter>
% functionality with the Zynq(R) radio hardware, whereby the baseband RMC
% waveform is transferred to the hardware memory on the Zynq radio, and
% transmitted continuously over the air without gaps. If you use an SDR
% device that is capable of two channel transmission and reception, such as
% the ZC706 and FMCOMMS3 or PicoZed SDR, the example can generate and
% transmit a multi-antenna LTE waveform using LTE Transmit Diversity.
%
% The script then captures the resultant waveform using the same Zynq radio
% hardware platform. If you have the appropriate hardware, the example can
% use 2-channel reception in the receiver.
%

%% Example Setup
% Before you run this example, perform the following steps:
%
% # Configure your host computer to work with the Support Package for
% Xilinx Zynq-Based Radio. See <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> for help. 
% # Make sure that LTE System Toolbox in installed. You must have an LTE
% System Toolbox license to run this example. If you do not have the LTE
% System Toolbox, install it now to continue with this example.
%
% When you run this example, the first thing the script does is check for
% the LTE System Toolbox.

% Check that LTE System Toolbox is installed, and that there is a valid license
if isempty(ver('lte')) % Check for LST install
    error('zynqRadioLTEMIMOTransmitReceive:NoLST', ...
        'Please install LTE System Toolbox to run this example.');
elseif ~license('test', 'LTE_Toolbox') % Check that a valid license is present
    error('zynqRadioLTEMIMOTransmitReceive:NoLST', ...
        'A valid license for LTE System Toolbox is required to run this example.');
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

% Setup handle for channel estimate plots
if ~exist('hhest', 'var') || ~ishandle(hhest)
    hhest = figure('Visible','Off');
    hhest.NumberTitle = 'off';
    hhest.Name = 'Channel Estimate';
else
    clf(hhest); % Clear figure
    hhest.Visible = 'off';
end

% Setup Spectrum viewer
hsa = dsp.SpectrumAnalyzer( ...
    'SpectrumType',    'Power density', ...
    'SpectralAverages', 10, ...
    'YLimits',         [-150 -60], ...
    'Title',           'Received Baseband LTE Signal Spectrum', ...
    'YLabel',          'Power spectral density');

% Setup the constellation diagram viewer for equalized PDSCH symbols
hcd = comm.ConstellationDiagram('Title','Equalized PDSCH Symbols',...
                                'ShowReferenceConstellation',false);

%%
% If you are using either an FMCOMMS2 or FMCOMMS3 RF card, or PicoZed(TM) SDR, the example
% defaults to 2-channel transmit and receive. If you are using an FMCOMMS4
% RF card, the example uses only one channel.
%
% An <matlab:sdrzdoc('commsdrtxzc706fmc23') SDR Transmitter>
% system object is used with the named radio |'ZC706 and FMCOMMS2/3/4'|
% to transmit baseband data to the SDR hardware.
%
% By default, the example is configured to run with ZC706 and ADI
% FMCOMMS2/3/4 hardware. You can replace the named hardware |'ZC706 and
% FMCOMMS2/3/4'| with |'ZedBoard and FMCOMMS2/3/4'| or |'PicoZed SDR'| in
% the |txsim| parameter structure to run with ZedBoard(TM) and ADI
% FMCOMMS2, FMCOMMS3, FMCOMMS4 hardware or PicoZed SDR.

%  Initialize SDR device
txsim = struct; % Create empty structure for transmitter
txsim.SDRDeviceName = 'ZC706 and FMCOMMS2/3/4'; % Set SDR Device
hdev = sdrdev(txsim.SDRDeviceName); % Create SDR device object

%%
% The script will then connect to the SDR device to verify the
% host/hardware connection, and to get information on the specific RF card
% version that is connected. An information message will be displayed in
% the command window while the connection to the hardware is established. 

% Connect to the SDR device, and get device info
devInfo = hdev.info;

%% Run Example
% You can run this example by executing
% <matlab:edit('zynqRadioLTEMIMOTransmitReceiveAD9361AD9364ML.m')
% zynqRadioLTEMIMOTransmitReceiveAD9361AD9364ML.m>. The following sections explain the
% design and architecture of this example, and what you can expect to see
% as the code is executed.

%% Transmitter Design: System Architecture
% The general structure of the LTE transmitter can be described as follows:
%
% # Import an image file and convert it to a binary stream.
% # Generate a baseband LTE signal using LTE System Toolbox, packing the
% binary data stream into the transport blocks of the downlink shared
% channel DL-SCH.
% # Prepare the baseband signal for transmission using the SDR hardware.
% # Send the baseband data to the SDR hardware for upsampling and
% continuous transmission at the desired center frequency.

% The transmitter is controlled using the
% parameters in the _txsim_ structure.
%

txsim.RC = 'R.7';       % Base RMC configuration, 10 MHz bandwidth
txsim.NCellID = 88;     % Cell identity
txsim.NFrame = 700;     % Initial frame number
txsim.TotFrames = 1;    % Number of frames to generate
txsim.DesiredCenterFrequency = 2.45e9; % Center frequency in Hz
txsim.NTxAnts = 2;      % Number of transmit antennas

% If using an FMCOMMS4, set number of TX antennas to 1 as there is only one
% channel available... 
if ~isempty(strfind(devInfo.RFBoardVersion, 'AD-FMCOMMS4-EBZ')) && (txsim.NTxAnts ~= 1)
    fprintf('\nFMCOMMS4 detected: Changing number of transmit antennas to 1.\n');
    txsim.NTxAnts = 1;
end

%%
% In order to visualize the benefit of using multi-channel transmission
% and reception over single-channel, you can reduce the transmitter gain
% parameter to impair the quality of the received waveform, as shown here:

% TX gain parameter: 
% Change this parameter to reduce transmission quality, and impair the
% signal. Suggested values:
%    * set to -10 for default gain (-10dB)
%    * set to -20 for reduced gain (-20dB)
%
% NOTE: These are suggested values -- depending on your antenna
% configuration, you may have to tweak these values.
txsim.Gain = -10;

%%
% *Prepare Image File*
% 
% The example reads data from the image file, scales it for transmission,
% and converts it to a binary data stream. 
%
% The size of the transmitted image directly impacts the number of LTE
% radio frames which are required for the transmission of the image data. A
% scaling factor of |scale = 0.5|, as shown below, requires the
% transmission of 5 LTE radio frames. Increasing the scaling factor will
% result in the transmission of more frames; conversely, reducing the scaling
% factor will reduce the number of frames.

% Input an image file and convert to binary stream
fileTx = 'peppers.png';            % Image file name
fData = imread(fileTx);            % Read image data from file
scale = 0.5;                       % Image scaling factor
origSize = size(fData);            % Original input image size
scaledSize = max(floor(scale.*origSize(1:2)),1); % Calculate new image size
heightIx = min(round(((1:scaledSize(1))-0.5)./scale+0.5),origSize(1));
widthIx = min(round(((1:scaledSize(2))-0.5)./scale+0.5),origSize(2));
fData = fData(heightIx,widthIx,:); % Resize image
imsize = size(fData);              % Store new image size
binData = dec2bin(fData(:),8);     % Convert to 8 bit unsigned binary
trData = reshape((binData-'0').',1,[]).'; % Create binary stream

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
    set(gca,'Visible','off'); % Hide axes
    set(findall(gca, 'type', 'text'), 'visible', 'on'); % Unhide title

pause(1); % Pause to plot Tx image
    
%%
% *Generate Baseband LTE Signal*
%
% The example uses the default configuration parameters defined in TS36.101
% Annex A.3 [ <#12 1> ] to generate an RMC by <matlab:doc('lteRMCDL')
% lteRMCDL>. The parameters within the configuration structure |rmc| can
% then be customized as required. The example generates a baseband
% waveform, |eNodeBOutput|, a fully populated resource grid, |txGrid|, and
% the full configuration of the RMC using <matlab:doc('lteRMCDLTool')
% lteRMCDLTool>. The example uses the binary data stream that was created
% from the input image file |trData| as input to the transport coding, and
% packs it into multiple transport blocks in the Physical Downlink Shared
% Channel (PDSCH). The number of frames that are generated for transmission
% is dependent on the image scaling that you set when importing the image
% file. The generation of the baseband LTE signal is shown in the
% following code:

% Create RMC
rmc = lteRMCDL(txsim.RC);

% Calculate the required number of LTE frames based on the size of the
% image data
trBlkSize = rmc.PDSCH.TrBlkSizes;
txsim.TotFrames = ceil(numel(trData)/sum(trBlkSize(:)));

% Customize RMC parameters
rmc.NCellID = txsim.NCellID;
rmc.NFrame = txsim.NFrame;
rmc.TotSubframes = txsim.TotFrames*10; % 10 subframes per frame
rmc.CellRefP = txsim.NTxAnts; % Configure number of cell reference ports
rmc.PDSCH.RVSeq = 0;

% Fill subframe 5 with dummy data
rmc.OCNGPDSCHEnable = 'On';
rmc.OCNGPDCCHEnable = 'On';

% If transmitting over two channels enable transmit diversity
if rmc.CellRefP == 2
    rmc.PDSCH.TxScheme = 'TxDiversity';
    rmc.PDSCH.NLayers = 2;
    rmc.OCNGPDSCH.TxScheme = 'TxDiversity';
end

fprintf('\nGenerating LTE transmit waveform:\n')
fprintf('  Packing image data into %d frame(s).\n\n', txsim.TotFrames);

% Pack the image data into a single LTE frame
[eNodeBOutput,txGrid,rmc] = lteRMCDLTool(rmc,trData);

%% 
% *Prepare for Transmission*
%
% The transmitter uses the |transmitRepeat| functionality to continuously
% transmit the baseband LTE waveform in a loop from the DDR memory on the
% Zynq-Based Radio platform. The applied channel map for the transmitter is
% displayed in the command window.
%

tx = sdrtx(txsim.SDRDeviceName);
tx.BasebandSampleRate = rmc.SamplingRate; % 15.36 Msps for default RMC (R.7) 
                                          % with a bandwidth of 10 MHz  
tx.CenterFrequency = txsim.DesiredCenterFrequency;
tx.ShowAdvancedProperties = true;
tx.BypassUserLogic = true;
tx.Gain = txsim.Gain;

% Apply TX channel mapping
if txsim.NTxAnts == 2
    fprintf('Setting channel map to ''[1 2]''.\n\n'); 
    tx.ChannelMapping = [1,2];
else
    fprintf('Setting channel map to ''1''.\n\n'); 
    tx.ChannelMapping = 1;
end;

% Scale the signal for better power output.
powerScaleFactor = 0.8;
if txsim.NTxAnts == 2
    eNodeBOutput = [eNodeBOutput(:,1).*(1/max(abs(eNodeBOutput(:,1)))*powerScaleFactor) ...
                    eNodeBOutput(:,2).*(1/max(abs(eNodeBOutput(:,2)))*powerScaleFactor)];       
else
    eNodeBOutput = eNodeBOutput.*(1/max(abs(eNodeBOutput))*powerScaleFactor);
end

% Cast the transmit signal to int16 --- 
% this is the native format for the SDR hardware. 
eNodeBOutput = int16(eNodeBOutput*2^15);

%%
% *Repeated transmission using SDR Hardware*
%
% The |transmitRepeat| function transfers the baseband LTE transmission to
% the SDR platform, and stores the signal samples in hardware memory. The
% example then transmits the waveform continuously over the air without
% gaps until the release method for the transmit object is released.
% Messages are displayed in the command window to confirm that transmission
% has started successfully.
tx.transmitRepeat(eNodeBOutput);

%% Receiver Design: System Architecture
% The general structure of the LTE receiver can be described as follows:
%
% # Capture a suitable number of frames of the transmitted LTE signal using
% SDR hardware.
% # Determine and correct the frequency offset of the received signal.
% # Synchronize the captured signal to the start of an LTE frame.
% # OFDM demodulate the received signal to get an LTE resource grid.
% # Perform a channel estimation for the received signal.
% # Decode the PDSCH and DL-SCH to obtain the transmitted data from the
% transport blocks of each radio frame.
% # Recombine received transport block data to form the received image.
%
% This example plots the power spectral density of the captured waveform,
% and shows visualizations of the estimated channel, equalized PDSCH
% symbols, and received image.

%%
% *Receiver Setup*
%
% The receiver is controlled using the parameters defined in the |rxsim|
% structure. The sample rate of the receiver is 15.36MHz, which is the
% standard sample rate for capturing an LTE bandwidth of 50 resource blocks
% (RBs). 50 RBs is equivalent to a signal bandwidth of 10 MHz.

% User defined parameters --- configure the same as transmitter
rxsim = struct;
rxsim.RadioFrontEndSampleRate = tx.BasebandSampleRate; % Configure for same sample rate
                                                       % as transmitter
rxsim.RadioCenterFrequency = txsim.DesiredCenterFrequency;
rxsim.NRxAnts = txsim.NTxAnts;
rxsim.FramesPerBurst = txsim.TotFrames+1; % Number of LTE frames to capture in each burst.
                                          % Capture 1 more LTE frame than transmitted to  
                                          % allow for timing offset wraparound...
rxsim.numBurstCaptures = 1; % Number of bursts to capture

% Derived parameters
samplesPerFrame = 10e-3*rxsim.RadioFrontEndSampleRate; % LTE frames period is 10 ms

%%
% An <matlab:sdrzdoc('commsdrrxzc706fmc23') SDR Receiver> system
% object is used with the named radio |'ZC706 and FMCOMMS2/3/4'| to
% receive baseband data from the SDR hardware.
%
% By default, the example is configured to run with ZC706 and ADI
% FMCOMMS2/3/4 hardware. You can replace the named hardware |'ZC706 and
% FMCOMMS2/3/4'| with |'ZedBoard and FMCOMMS2/3/4'| in the |rxsim| parameter
% structure to run with ZedBoard(TM) and ADI FMCOMMS2/3/4 hardware.

rxsim.SDRDeviceName = txsim.SDRDeviceName;

rx = sdrrx(rxsim.SDRDeviceName);
rx.BasebandSampleRate = rxsim.RadioFrontEndSampleRate;
rx.CenterFrequency = rxsim.RadioCenterFrequency;
rx.SamplesPerFrame = samplesPerFrame;
rx.OutputDataType = 'double';
rx.EnableBurstMode = true;
rx.NumFramesInBurst = rxsim.FramesPerBurst;

% Configure RX channel map 
if rxsim.NRxAnts == 2
    rx.ChannelMapping = [1,2];
else
    rx.ChannelMapping = 1;
end

% burstCaptures holds rx.FramesPerBurst number of consecutive frames worth
% of baseband LTE samples. Each column holds one LTE frame worth of data.
burstCaptures = zeros(samplesPerFrame,rxsim.NRxAnts,rxsim.FramesPerBurst);

%%
% *LTE Receiver Setup* 
%
% The example simplifies the LTE signal reception by assuming that the
% transmitted PDSCH parameters are known. FDD duplexing mode and a normal
% cyclic prefix length are also assumed, as well as four cell-specific
% reference ports (CellRefP) for the MIB decode. The number of actual
% CellRefP is provided by the MIB. A detailed example of how to perform a
% blind LTE cell search and recover basic system information from an LTE
% waveform is given in <matlab:showdemo('zynqRadioLTEReceiverAD9361AD9364ML') LTE
% Receiver with Analog Devices(TM) AD9361/AD9364>.

enb.PDSCH = rmc.PDSCH;
enb.DuplexMode = 'FDD';
enb.CyclicPrefix = 'Normal';
enb.CellRefP = 4; 

%%
% The sampling rate of the signal controls the captured bandwidth. The
% number of RBs captured is obtained from a lookup table using
% the chosen sampling rate, and is displayed to the command window.

% Bandwidth: {1.4 MHz, 3 MHz, 5 MHz, 10 MHz, 20 MHz}
SampleRateLUT = [1.92 3.84 7.68 15.36 30.72]*1e6;
NDLRBLUT = [6 15 25 50 100];
enb.NDLRB = NDLRBLUT(SampleRateLUT==rxsim.RadioFrontEndSampleRate);
if isempty(enb.NDLRB)
    error('Sampling rate not supported. Supported rates are %s.',...
            '1.92 MHz, 3.84 MHz, 7.68 MHz, 15.36 MHz, 30.72 MHz');
end
fprintf('\nSDR hardware sampling rate configured to capture %d LTE RBs.\n',enb.NDLRB);

%%
% Channel estimation is configured to be performed using cell-specific
% reference signals. A 9-by-9 averaging window is used to minimize the
% effect of noise.

% Channel estimation configuration structure
cec.PilotAverage = 'UserDefined';  % Type of pilot symbol averaging
cec.FreqWindow = 9;                % Frequency window size in REs
cec.TimeWindow = 9;                % Time window size in REs
cec.InterpType = 'Cubic';          % 2D interpolation type
cec.InterpWindow = 'Centered';     % Interpolation window type
cec.InterpWinSize = 3;             % Interpolation window size

%%
% *Signal Capture and Processing*
%
% The example uses a while loop to capture and decode bursts of LTE frames.
% As the LTE waveform is continually transmitted over the air in a loop,
% the first frame that is captured by the receiver is not guaranteed to be
% the first frame that was transmitted. This means that the frames may be
% decoded out of sequence. To enable the received frames to be recombined
% in the correct order, their frame numbers must be determined. The Master
% Information Block (MIB) contains information on the current system frame
% number, and therefore must be decoded. After the frame number has been
% determined, the PDSCH and DL-SCH are decoded, and the equalized PDSCH
% symbols are shown. No data is transmitted in subframe 5; therefore the
% captured data for subframe is ignored for the decoding. The Power
% Spectral Density (PSD) of the captured waveform is plotted to show the
% received LTE transmission. 
%
% When the LTE frames have been successfully decoded, the detected frame
% number is displayed in the command window on a frame-by-frame basis, and
% the equalized PDSCH symbol constellation is shown for each subframe. An
% estimate of the channel magnitude frequency response between cell
% reference point 0 and the receive antennae is also shown for each frame.

enbDefault = enb;

while rxsim.numBurstCaptures
    % Set default LTE parameters
    enb = enbDefault;
    
    % SDR Capture
    fprintf('\nStarting a new RF capture.\n\n')
    len = 0;
    for frame = 1:rxsim.FramesPerBurst
        while len == 0
            % Store one LTE frame worth of samples
            [data,len,lostSamples] = step(rx);
            burstCaptures(:,:,frame) = data;
        end
        if lostSamples
            warning('Dropped samples');
        end
        len = 0;
    end    
    if rxsim.NRxAnts == 2
        rxWaveform = reshape(permute(burstCaptures,[1 3 2]), ...
                        rxsim.FramesPerBurst*samplesPerFrame,rxsim.NRxAnts);
        hsa.ShowLegend = true; % Turn on legend for spectrum analyzer
        hsa.ChannelNames = {'SDR Channel 1','SDR Channel 2'};
    else
        rxWaveform = burstCaptures(:);
    end
    
    % Show power spectral density of captured burst
    hsa.SampleRate = rxsim.RadioFrontEndSampleRate;
    step(hsa,rxWaveform);
    
    % Perform frequency offset correction for known cell ID
    frequencyOffset = lteFrequencyOffset(enb,rxWaveform);
    rxWaveform = lteFrequencyCorrect(enb,rxWaveform,frequencyOffset);
    fprintf('\nCorrected a frequency offset of %i Hz.\n',frequencyOffset)
    
    % Perform the blind cell search to obtain cell identity and timing offset
    %   Use 'PostFFT' SSS detection method to improve speed
    cellSearch.SSSDetection = 'PostFFT'; cellSearch.MaxCellCount = 1;
    [NCellID,frameOffset] = lteCellSearch(enb,rxWaveform,cellSearch);
    fprintf('Detected a cell identity of %i.\n', NCellID);
    enb.NCellID = NCellID; % From lteCellSearch
    
    % Sync the captured samples to the start of an LTE frame, and trim off
    % any samples that are part of an incomplete frame.
    rxWaveform = rxWaveform(frameOffset+1:end,:);
    tailSamples = mod(length(rxWaveform),samplesPerFrame);
    rxWaveform = rxWaveform(1:end-tailSamples,:);
    enb.NSubframe = 0;
    fprintf('Corrected a timing offset of %i samples.\n',frameOffset)
    
    % OFDM demodulation
    rxGrid = lteOFDMDemodulate(enb,rxWaveform);
    
    % Perform channel estimation for 4 CellRefP as currently we do not
    % know the CellRefP for the eNodeB.
    [hest,nest] = lteDLChannelEstimate(enb,cec,rxGrid);
    
    sfDims = lteResourceGridSize(enb);
    Lsf = sfDims(2); % OFDM symbols per subframe
    LFrame = 10*Lsf; % OFDM symbols per frame
    numFullFrames = length(rxWaveform)/samplesPerFrame;
    
    rxDataFrame = zeros(sum(enb.PDSCH.TrBlkSizes(:)),numFullFrames);
    recFrames = zeros(numFullFrames,1);
    rxSymbols = []; txSymbols = [];
    
    % For each frame decode the MIB, PDSCH and DL-SCH
    for frame = 0:(numFullFrames-1)
        fprintf('\nPerforming DL-SCH Decode for frame %i of %i in burst:\n', ...
            frame+1,numFullFrames)
        
        % Extract subframe #0 from each frame of the received resource grid
        % and channel estimate.
        enb.NSubframe = 0;
        rxsf = rxGrid(:,frame*LFrame+(1:Lsf),:);
        hestsf = hest(:,frame*LFrame+(1:Lsf),:,:);
               
        % PBCH demodulation. Extract resource elements (REs)
        % corresponding to the PBCH from the received grid and channel
        % estimate grid for demodulation.
        enb.CellRefP = 4;
        pbchIndices = ltePBCHIndices(enb); 
        [pbchRx,pbchHest] = lteExtractResources(pbchIndices,rxsf,hestsf);
        [~,~,nfmod4,mib,CellRefP] = ltePBCHDecode(enb,pbchRx,pbchHest,nest);
        
        % If PBCH decoding successful CellRefP~=0 then update info
        if ~CellRefP
            fprintf('  No PBCH detected for frame.\n');
            continue;
        end
        enb.CellRefP = CellRefP; % From ltePBCHDecode
        
        % Decode the MIB to get current frame number
        enb = lteMIB(mib,enb);

        % Incorporate the nfmod4 value output from the function
        % ltePBCHDecode, as the NFrame value established from the MIB
        % is the system frame number modulo 4.
        enb.NFrame = enb.NFrame+nfmod4;
        fprintf('  Successful MIB Decode.\n')
        fprintf('  Frame number: %d.\n',enb.NFrame);
        
        % The eNodeB transmission bandwidth may be greater than the
        % captured bandwidth, so limit the bandwidth for processing
        enb.NDLRB = min(enbDefault.NDLRB,enb.NDLRB);
        
        % Store received frame number
        recFrames(frame+1) = enb.NFrame;
               
        % Process subframes within frame (ignoring subframe 5)
        for sf = 0:9
            if sf~=5 % Ignore subframe 5
                % Extract subframe
                enb.NSubframe = sf;
                rxsf = rxGrid(:,frame*LFrame+sf*Lsf+(1:Lsf),:);

                % Perform channel estimation with the correct number of CellRefP
                [hestsf,nestsf] = lteDLChannelEstimate(enb,cec,rxsf);

                % PCFICH demodulation. Extract REs corresponding to the PCFICH
                % from the received grid and channel estimate for demodulation.
                pcfichIndices = ltePCFICHIndices(enb);
                [pcfichRx,pcfichHest] = lteExtractResources(pcfichIndices,rxsf,hestsf);
                [cfiBits,recsym] = ltePCFICHDecode(enb,pcfichRx,pcfichHest,nestsf);

                % CFI decoding
                enb.CFI = lteCFIDecode(cfiBits);
                
                % Get PDSCH indices
                [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enb, enb.PDSCH, enb.PDSCH.PRBSet); 
                [pdschRx, pdschHest] = lteExtractResources(pdschIndices, rxsf, hestsf);

                % Perform deprecoding, layer demapping, demodulation and
                % descrambling on the received data using the estimate of
                % the channel
                [rxEncodedBits, rxEncodedSymb] = ltePDSCHDecode(enb,enb.PDSCH,pdschRx,...
                                               pdschHest,nestsf);

                % Append decoded symbol to stream
                rxSymbols = [rxSymbols; rxEncodedSymb{:}]; %#ok<AGROW>

                % Transport block sizes
                outLen = enb.PDSCH.TrBlkSizes(enb.NSubframe+1);  

                % Decode DownLink Shared Channel (DL-SCH)
                [decbits{sf+1}, blkcrc(sf+1)] = lteDLSCHDecode(enb,enb.PDSCH,...
                                                outLen, rxEncodedBits);  %#ok<SAGROW>

                % Recode transmitted PDSCH symbols for EVM calculation                            
                %   Encode transmitted DLSCH 
                txRecode = lteDLSCH(enb,enb.PDSCH,pdschIndicesInfo.G,decbits{sf+1});
                %   Modulate transmitted PDSCH
                txRemod = ltePDSCH(enb, enb.PDSCH, txRecode);
                %   Decode transmitted PDSCH
                [~,refSymbols] = ltePDSCHDecode(enb, enb.PDSCH, txRemod);
                %   Add encoded symbol to stream
                txSymbols = [txSymbols; refSymbols{:}]; %#ok<AGROW>

                release(hcd); % Release previous constellation plot
                step(hcd,rxEncodedSymb{:}); % Plot current constellation
            end
        end
        
        % Reassemble decoded bits
        fprintf('  Retrieving decoded transport block data.\n');
        rxdata = [];
        for i = 1:length(decbits)
            if i~=6 % Ignore subframe 5
                rxdata = [rxdata; decbits{i}{:}]; %#ok<AGROW>
            end
        end
        
        % Store data from receive frame
        rxDataFrame(:,frame+1) = rxdata;

        % Plot channel estimate between CellRefP 0 and the receive antennae
        focalFrameIdx = frame*LFrame+(1:LFrame);
        figure(hhest);
        hhest.Visible = 'On';
        surf(abs(hest(:,focalFrameIdx,1,1)));
        shading flat;
        xlabel('OFDM symbol index'); 
        ylabel('Subcarrier index');
        zlabel('Magnitude');   
        title('Estimate of Channel Magnitude Frequency Repsonse');                
    end
    rxsim.numBurstCaptures = rxsim.numBurstCaptures-1;
end
% Release both transmit and receive objects once reception is complete
release(tx);
release(rx);

%%
% *Result Qualification and Display*
%
% The bit error rate (BER) between the transmitted and received data is
% calculated to determine the quality of the received data. The received
% data is then reformed into an image and displayed.

% Determine index of first transmitted frame (lowest received frame number)
[~,frameIdx] = min(recFrames);

fprintf('\nRecombining received data blocks:\n');

decodedRxDataStream = zeros(length(rxDataFrame(:)),1);
frameLen = size(rxDataFrame,1);
% Recombine received data blocks (in correct order) into continuous stream
for n=1:numFullFrames
    currFrame = mod(frameIdx-1,numFullFrames)+1; % Get current frame index 
    decodedRxDataStream((n-1)*frameLen+1:n*frameLen) = rxDataFrame(:,currFrame);
    frameIdx = frameIdx+1; % Increment frame index
end

% Perform EVM calculation
if ~isempty(rxSymbols)
    hEVM = comm.EVM();
    hEVM.MaximumEVMOutputPort = true;
    [evm.RMS,evm.Peak] = step(hEVM,txSymbols, rxSymbols);
    fprintf('  EVM peak = %0.3f%%\n',evm.Peak);
    fprintf('  EVM RMS  = %0.3f%%\n',evm.RMS);
else
    fprintf('  No transport blocks decoded.\n');
end

% Perform bit error rate (BER) calculation
hBER = comm.ErrorRate;
err = step(hBER, decodedRxDataStream(1:length(trData)), trData);
fprintf('  Bit Error Rate (BER) = %0.5f.\n', err(1));
fprintf('  Number of bit errors = %d.\n', err(2));
fprintf('  Number of transmitted bits = %d.\n',length(trData));

% Recreate image from received data
fprintf('\nConstructing image from received data.\n');
str = reshape(sprintf('%d',decodedRxDataStream(1:length(trData))), 8, []).';
decdata = uint8(bin2dec(str));
receivedImage = reshape(decdata,imsize);

% Plot receive image
if exist('imFig', 'var') && ishandle(imFig) % If TX figure is open
    figure(imFig); subplot(212); 
else
    figure; subplot(212);
end
imshow(receivedImage);
title(sprintf('Received Image: %dx%d Antenna Configuration',txsim.NTxAnts, rxsim.NRxAnts));

%% Things to Try
% By default, the example will use multiple antennas for transmission and
% reception of the LTE waveform. You can modify the transmitter and receiver
% to use a single antenna and decrease the transmitter gain, to 
% observe the difference in the EVM and BER after signal reception and 
% processing. You should also be able to see any errors in the displayed,
% received image.

%% Troubleshooting the Example
%
% General tips for troubleshooting SDR hardware and the Communications
% System Toolbox Support Package for Xilinx Zynq-Based Radio can be found
% in <matlab:sdrzdoc('sdrz_troubleshoot') Common Problems and Fixes>.

%% Selected Bibliography
% # 3GPP TS 36.191. "User Equipment (UE) radio transmission and reception."
% 3rd Generation Partnership Project; Technical Specification Group Radio
% Access Network; Evolved Universal Terrestrial Radio Access (E-UTRA).

displayEndOfDemoMessage(mfilename)
