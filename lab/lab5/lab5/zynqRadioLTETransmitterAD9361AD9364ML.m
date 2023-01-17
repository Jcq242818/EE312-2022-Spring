%% LTE Transmitter Using Analog Devices AD9361/AD9364
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package with MATLAB(R) and LTE System Toolbox(TM) to generate an LTE
% transmission. The transmitted signal can be received by the companion
% <matlab:showdemo('zynqRadioLTEReceiverAD9361AD9364ML') LTE Receiver Using Analog
% Devices AD9361/AD9364> example if you have a second SDR platform.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting Started>
% documentation for details on configuring your host computer to work with
% the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2016 The MathWorks, Inc.

%% Introduction
% LTE System Toolbox can be used to generate standard-compliant baseband IQ
% downlink and uplink reference measurement channel (RMC) waveforms and
% downlink test model (E-TM) waveforms. These baseband waveforms can be
% modulated for RF transmission using SDR Radio hardware such as Xilinx
% Zynq-Based Radio.
%
% In this example eight frames of a baseband RMC waveform are generated
% using the LTE System Toolbox. A continuous RF LTE waveform is created by
% looping transmission of these eight frames with the Zynq(R) radio hardware
% for a user-specified time period. 
%
% <<sdr_transmit_diagram_published.png>>
%
% The resultant waveform can be captured and the broadcast channel decoded
% using the companion example
% <matlab:showdemo('zynqRadioLTEReceiverAD9361AD9364ML') LTE Receiver Using
% Analog Devices(TM) AD9361/AD9364>, if you have a second SDR platform.

%% Setup
% This example requires LTE System Toolbox to run. Before running this
% example ensure you have performed the following steps:
%
% # Configure your host computer to work with the Support Package for
% Xilinx Zynq-Based Radio. See <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> for help. Some additional steps may be required if you want to
% run two radios from a single host computer. See
% <matlab:sdrzdoc('sdrz_tworadios') Setup for Two Radios - One
% Host> for help.
% # Ensure that you have a suitable receiver. This example is designed to
% work in conjunction with the <matlab:showdemo('zynqRadioLTEReceiverAD9361AD9364ML') LTE
% Receiver Using Analog Devices AD9361/AD9364> example.

% Check that LTE System Toolbox is installed, and that there is a valid license
if isempty(ver('lte')) % Check for LST install
    error('zynqRadioLTETransmitter:NoLST','Please install LTE System Toolbox to run this example.');
elseif ~license('test', 'LTE_Toolbox') % Check that a valid license is present
    error('zynqRadioLTETransmitter:NoLST','A valid license for LTE System Toolbox is required to run this example.');
end

%% Running the Example
% The example can be run by executing <matlab:edit('zynqRadioLTETransmitterAD9361AD9364ML.m')
% zynqRadioLTETransmitterAD9361AD9364ML.m>. The transmitter is controlled using the values in
% the _txsim_ structure. In particular, you may wish to increase the
% _txsim.RunTime_ parameter to ensure the transmission is active long
% enough for the receive example to execute. In this example the cell
% identity, and initial frame number can be customized.

txsim.RC = 'R.4';         % Base RMC configuration, 1.4 MHz bandwidth.
txsim.NCellID = 17;       % Cell identity
txsim.NFrame = 700;       % Initial frame number
txsim.TotFrames = 8;      % Number of frames to generate
txsim.RunTime = 20;       % Time period to loop waveform in seconds
txsim.DesiredCenterFrequency = 2.45e9; % Center frequency in Hz

%% Transmitter Design: System Architecture
% The general structure of the LTE transmitter can be described as follows:
%
% # Generate a baseband LTE signal using LTE System Toolbox
% # Prepare the baseband signal for transmission using the SDR hardware
% # Send the baseband data to the SDR hardware for upsampling and
% transmission at the desired center frequency

%%
% *Generating the Baseband LTE Signal*
%
% The default configuration parameters defined in TS36.101 Annex A.3 [ <#12
% 1> ] required to generate an RMC are provided by <matlab:doc('lteRMCDL')
% lteRMCDL>. The parameters within the configuration structure |rmc| can
% then be customized as required. The baseband waveform, |eNodeBOutput|, a
% fully populated resource grid, |txGrid|, and the full configuration of
% the RMC are created using <matlab:doc('lteRMCDLTool') lteRMCDLTool>.

% Generate RMC configuration and customize parameters
rmc = lteRMCDL(txsim.RC);
rmc.NCellID = txsim.NCellID;
rmc.NFrame = txsim.NFrame;
rmc.TotSubframes = txsim.TotFrames*10; % 10 subframes per frame
rmc.OCNGPDSCHEnable = 'On'; % Add noise to unallocated PDSCH resource elements

% Generate RMC waveform
trData = [1;0;0;1]; % Transport data
[eNodeBOutput,txGrid,rmc] = lteRMCDLTool(rmc,trData);
txsim.SamplingRate = rmc.SamplingRate;

%%
% The populated resource grid is displayed with channels highlighted. The
% power spectral density of the LTE baseband signal can be viewed using the
% <http://www.mathworks.com/products/dsp-system/ DSP System Toolbox(TM)>
% <matlab:doc('dsp.SpectrumAnalyzer') spectrum analyzer>. As expected, the
% 1.4 MHz signal bandwidth is clearly visible at baseband.

hTxGridPlot = sdrzPlotDLResourceGrid(rmc,txGrid);
hTxGridPlot.CurrentAxes.Children(1).EdgeColor = 'none';
title('Transmitted Resource Grid');

% Display the power spectral density
hsa = dsp.SpectrumAnalyzer( ...
    'SampleRate',      txsim.SamplingRate, ...
    'SpectrumType',    'Power density', ...
    'SpectralAverages', 10, ...
    'Title',           'Baseband LTE Signal Spectrum', ...
    'YLimits',         [-90 -50], ...
    'YLabel',          'Power spectral density');
step(hsa,eNodeBOutput);

%%
% *Preparing for Transmission*
%
% The transmitter plays the LTE signal in a loop. The baseband signal is
% split into LTE frames of data, and a full LTE frame is transmitted with
% each _step_ of the SDR Transmitter object. The baseband LTE signal is
% reshaped into an M-by-N array, where M is the number of samples per LTE
% frame and N is the number of frames generated.
%
% An <matlab:sdrzdoc('commsdrtxzc706fmc23') SDR Transmitter>
% system object is used with the named radio |'ZC706 and FMCOMMS2/3/4'|
% to transmit baseband data to the SDR hardware.
%
% By default, the example is configured to run with ZC706 and ADI
% FMCOMMS2/3/4 hardware. You can replace the named hardware |'ZC706 and
% FMCOMMS2/3/4'| with |'ZedBoard and FMCOMMS2/3/4'| or |'PicoZed SDR'| in
% the |txsim| parameter structure to run with ZedBoard(TM) and ADI
% FMCOMMS2, FMCOMMS3, FMCOMMS4 hardware or PicoZed(TM) SDR.
txsim.RadioCenterFrequency = txsim.DesiredCenterFrequency;
txsim.RadioChannelMapping = 1;
txsim.SDRDeviceName = 'ZC706 and FMCOMMS2/3/4';

hdev = sdrdev(txsim.SDRDeviceName);
setupSession(hdev);
hSDR = sdrtx( ...
    txsim.SDRDeviceName, ...
    'IPAddress',             '192.168.3.2', ...
    'CenterFrequency',       txsim.RadioCenterFrequency, ...
    'ChannelMapping',        txsim.RadioChannelMapping, ...
    'BasebandSampleRate',    txsim.SamplingRate);

% Scale the signal for better power output and cast to int16. This is the
% native format for the SDR hardware. Since we are transmitting the same
% signal in a loop, we can do the cast once to save processing time.
powerScaleFactor = 0.7;
eNodeBOutput = eNodeBOutput.*(1/max(abs(eNodeBOutput))*powerScaleFactor);
eNodeBOutput = int16(eNodeBOutput*2^15);

% LTE frames are 10 ms long
samplesPerFrame = 10e-3*txsim.SamplingRate;
numFrames = length(eNodeBOutput)/samplesPerFrame;

% Ensure we are using an integer number of frames
if mod(numFrames,1) 
    warning('Not integer number of frames. Trimming transmission...')
    numFrames = floor(numFrames);
end

% Reshape the baseband LTE data into frames and create dummy second
% channel data
fprintf('Splitting transmission into %i frames\n',numFrames)
txFrame = reshape(eNodeBOutput(1:samplesPerFrame*numFrames),samplesPerFrame,numFrames); 

%%
% *Transmission using SDR Hardware*
%
% The transfer of baseband data to the SDR hardware is enclosed in a
% try/catch block. This means that if an error occurs during the
% transmission, the hardware resources used by the SDR System object(TM) are
% released. Each _step_ of the _hSDR_ System object transmits one frame of
% LTE data.

fprintf('Starting transmission at Fs = %g MHz\n',txsim.SamplingRate/1e6)
currentTime = 0;
try
    while currentTime<txsim.RunTime
        for n = 1:numFrames
            bufferUnderflow = step(hSDR,txFrame(:,n));
            if bufferUnderflow~=0
                warning('Dropped samples')
            end
        end
        currentTime = currentTime+numFrames*10e-3; % One frame is 10 ms
    end
catch ME
    release(hSDR);
    rethrow(ME)
end
fprintf('Transmission finished\n')
release(hSDR);

%% Things to Try
% The companion example <matlab:showdemo('zynqRadioLTEReceiverAD9361AD9364ML') LTE Receiver
% Using Analog Devices AD9361/AD9364> can be used to decode the broadcast channel of the
% waveform generated by this example. Try changing the cell identity and
% initial system frame number and observe the detected cell identity and
% frame number at the receiver.

%% Troubleshooting the Example
%
% General tips for troubleshooting SDR hardware can be found in
% <matlab:sdrzdoc('sdrz_troubleshoot') Xilinx Zynq-Based Radio Processing
% Errors and Fixes>.

%% List of Example Helper Files
%
% This example uses the following helper files:
%
% * <matlab:edit('sdrzPlotDLResourceGrid.m')
% sdrzPlotDLResourceGrid.m>: plots the transmit resource grid

%% Selected Bibliography
% # 3GPP TS 36.191. "User Equipment (UE) radio transmission and reception."
% 3rd Generation Partnership Project; Technical Specification Group Radio
% Access Network; Evolved Universal Terrestrial Radio Access (E-UTRA).

displayEndOfDemoMessage(mfilename)
