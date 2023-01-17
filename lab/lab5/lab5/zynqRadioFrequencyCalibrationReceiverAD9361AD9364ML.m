%% Frequency Offset Calibration Receiver Using Analog Devices AD9361/AD9364
%
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package with MATLAB(R) to determine the frequency offset between SDR
% devices using Analog Devices(TM) AD9361 and AD9364. The example comprises of two 
% complementary scripts: one for the transmitter and another for the receiver.
% The transmitter sends a 10 kHz sine wave with the
% <matlab:showdemo('zynqRadioFrequencyCalibrationTransmitterAD9361AD9364ML') Frequency Offset
% Calibration Transmitter Using Analog Devices AD9361/AD9364> script. The receiver receives
% the signal, calculates the frequency offset and displays the offset using
% the <matlab:edit('zynqRadioFrequencyCalibrationReceiverAD9361AD9364ML') Frequency Offset
% Calibration Receiver Using Analog Devices AD9361 and AD9364> script.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> documentation for details on configuring your host computer to
% work with the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2014-2015 The MathWorks, Inc.

%% Introduction
%
% This example uses a matched pair of scripts to determine the frequency
% offset between two SDR devices:
%
% * The transmit script
% is <matlab:edit('zynqRadioFrequencyCalibrationTransmitterAD9361AD9364ML') Frequency Offset
% Calibration Transmitter Using Analog Devices AD9361 and AD9364>
% * The receive script is <matlab:edit('zynqRadioFrequencyCalibrationReceiverAD9361AD9364ML')
% Frequency Offset Calibration Receiver Using Analog Devices AD9361 and AD9364>
%
% The transmitter sends a 10 kHz tone. The receiver detects the transmitted
% tone using an FFT-based detection method. The offset between the
% transmitted 10 kHz tone and the received tone can then be calculated and
% used to compensate for the offset at the receiver. The pair of scripts
% provides the following information:
%
% * A quantitative value of the frequency offset
% * A graphical view of the spur-free dynamic range of the receiver
% * A graphical view of the qualitative SNR level of the received signal


%% Setup
%
% Before running the example, make sure you have performed the following
% steps:
%
% 1. Configure your host computer to work with the Support Package for
% Xilinx(R) Zynq-Based Radio. See <matlab:sdrzdoc('sdrzspsetup')
% Getting Started> for help.
%
% * Some additional steps may be required if you want to run two radios
% from a single host computer. See
% <matlab:sdrzdoc('sdrz_tworadios') Setup for Two Radios-One Host>
% for help.
%
% 2. Make sure that you have both the transmitter script
% <matlab:edit('zynqRadioFrequencyCalibrationTransmitterAD9361AD9364ML') Frequency Offset
% Calibration Transmitter Using Analog Devices AD9361 and AD9364> and the receiver script
% <matlab:edit('zynqRadioFrequencyCalibrationReceiverAD9361AD9364ML') Frequency Offset
% Calibration Receiver Using Analog Devices AD9361 and AD9364> open, with each configured to run
% on its own SDR hardware in its own instance of MATLAB.


%% Running the Example
%
% By default, the example is configured to run with ZC706 and ADI FMCOMMS2/3/4
% hardware. You can uncomment one of the following lines as applicable to
% set the |SDRDeviceName| field in structure variable |prmFreqCalibRx|.

% % prmFreqCalibRx.SDRDeviceName='ZedBoard and FMCOMMS2/3/4';
% % prmFreqCalibRx.SDRDeviceName='PicoZed SDR';

prmFreqCalibRx.SDRDeviceName = 'ZC706 and FMCOMMS2/3/4';

%%
% Make sure that the transmitter is sending the 10 kHz tone, and then start
% the receiver script. See
% <matlab:showdemo('zynqRadioFrequencyCalibrationTransmitterAD9361AD9364ML') Frequency Offset
% Calibration Transmitter Analog Devices AD9361 and AD9364> for help with the transmitter.
%
% The calculated frequency offset is displayed in the MATLAB command
% window. A <matlab:doc('dsp.SpectrumAnalyzer') dsp.SpectrumAnalyzer>
% object is used to visualize the spectrum of the received signal. A sample
% of a received spectrum is shown below.
%
% <<freqcalibfmc234spectrum.png>>
%
% In this case, the frequency with the maximum received signal power is at
% about 2.85kHz. Since the transmitter is sending a tone at 10 kHz, this
% means the frequency offset is about 7.15kHz. The spurious free dynamic
% range of the signal is about 46 dB.
%
% To compensate for a transmitter/receiver frequency offset, set the
% _prmFreqCalibRx.OffsetCompensation_ variable to the value displayed in
% the command window. This value is added to the _Center frequency_
% of the SDR Receiver object. Be sure to use the sign of the offset in your
% addition. Rerun the receiver with the applied frequency offset
% compensation. The calculated offset frequency displayed should now be
% close to zero, and the peak in the spectrum should be close to 10 kHz.
%
% It is important to note that the frequency offset value is only valid for
% the center frequency used to run the calibration.
%

%% Receiver Design: System Architecture
%
%%
% *Initialization*
%
% The code below sets up the parameters used to control the receiver.

% The approximate length of time the receiver runs for in seconds
prmFreqCalibRx.RunTime = 10;
% Set the offset value to compensate by
prmFreqCalibRx.OffsetCompensation =   0;

% SDR Receiver parameters
% Make sure setupSession() has been called. Multiple calls are allowed
dev = sdrdev(prmFreqCalibRx.SDRDeviceName);
setupSession(dev);
prmFreqCalibRx.RadioIP = '192.168.3.2';
prmFreqCalibRx.RadioOutputDataType  = 'double';
prmFreqCalibRx.RadioSamplesPerFrame = 4096;
prmFreqCalibRx.RadioChannelMapping = 1;
prmFreqCalibRx.DesiredRadioCenterFrequency = 2.4e9;
prmFreqCalibRx.RadioBasebandSampleRate = 520.841e3;
prmFreqCalibRx.RadioCenterFrequency = ...
    prmFreqCalibRx.DesiredRadioCenterFrequency + ...
    prmFreqCalibRx.OffsetCompensation;
prmFreqCalibRx.RadioGainControlMode = 'AGC Fast Attack';

% Expected sine wave parameters
prmFreqCalibRx.RxSineFrequency = 10e3; % in Hertz
prmFreqCalibRx.Fs = prmFreqCalibRx.RadioBasebandSampleRate;

% FFT length for calculating the frequency offset
prmFreqCalibRx.FocFFTSize = 4096;

%%
% Using the parameters above, three system objects are created:
%
% # The <matlab:sdrzdoc('commsdrrxzc706fmc23')
% SDR Receiver> system object used with the named radio |'ZC706 and FMCOMMS2/3/4'| receives the baseband sine wave
% from the SDR hardware.
% # The <matlab:edit('sdrzCoarseFrequencyOffset.m')
% sdrzCoarseFrequencyOffset> object performs an FFT and returns the
% frequency of maximum power
% # The <matlab:doc('dsp.SpectrumAnalyzer') dsp.SpectrumAnalyzer> object is
% used to visualize the spectrum of the received signal
%
% The _prmFreqCalibRx.FocFFTSize_ variable sets the size of the FFT used to
% calculate the frequency offset. The default value of 4096 means that the
% frequency offset calculated is limited to a resolution of 48 Hz.

hSDRRx = sdrrx( prmFreqCalibRx.SDRDeviceName,...
    'IPAddress',             prmFreqCalibRx.RadioIP, ...
    'CenterFrequency',       prmFreqCalibRx.RadioCenterFrequency, ...
    'GainSource',            prmFreqCalibRx.RadioGainControlMode, ...
    'SamplesPerFrame',       prmFreqCalibRx.RadioSamplesPerFrame, ...
    'BasebandSampleRate',    prmFreqCalibRx.RadioBasebandSampleRate, ...
    'OutputDataType',        prmFreqCalibRx.RadioOutputDataType,...
    'ChannelMapping',        prmFreqCalibRx.RadioChannelMapping);

hCFO = sdrzCoarseFrequencyOffset(...
    'FFTSize',    prmFreqCalibRx.FocFFTSize ,...
    'SampleRate', prmFreqCalibRx.Fs);

hSpectrumAnalyzer = dsp.SpectrumAnalyzer(...
    'SpectrumType',              'Power',...
    'FrequencySpan',             'Full', ...
    'FrequencyResolutionMethod', 'RBW', ...
    'RBWSource',                 'Property', ...
    'RBW',                       48, ...
    'SampleRate',                prmFreqCalibRx.Fs, ...
    'YLimits',                   [-120, 20],...
    'SpectralAverages',          10);

%%
% *Reception and Baseband Signal Processing*
%
% The receiver is then run for the target amount of time.

prmFreqCalibRx.currentTime = 0;
prmFreqCalibRx.timePerStep = (1 / prmFreqCalibRx.Fs) * ...
    prmFreqCalibRx.RadioSamplesPerFrame;
len = 0;
while prmFreqCalibRx.currentTime < prmFreqCalibRx.RunTime
    % Keep calling the Receiver until there is data available
    while len == 0
        [rxSig, len] = step(hSDRRx);
    end
    
    % Display received frequency spectrum.
    step(hSpectrumAnalyzer, rxSig);
    % Compute the frequency offset. Since the SDRCoarseFrequencyOffset
    % object returns the frequency of the peak power, we need to compensate
    % for the fact we are transmitting at prmFreqCalibRx.RxSineFrequency.
    % The value 'offset' represents the frequency shift that needs to be
    % applied to the Center Frequency.
    offset = step(hCFO, rxSig) + prmFreqCalibRx.RxSineFrequency;
    % Print the frequency offset compensation value in MATLAB command
    % window.
    compensationValue = -offset %#ok<NOPTS>
    prmFreqCalibRx.currentTime = prmFreqCalibRx.currentTime + ...
        prmFreqCalibRx.timePerStep;
    % reset len so we can wait for new data
    len = 0;
end
% Release all system objects
release(hSDRRx);
release(hCFO);
release(hSpectrumAnalyzer);
clear hSDRRx hCFO prmFreqCalibRx


%% Alternative Implementations
%
% This example describes the MATLAB implementation of a receiver for
% performing frequency offset calibration between two SDR devices using the
% Analog Devices AD9361 and AD9364. The matched transmitter is
% <matlab:showdemo('zynqRadioFrequencyCalibrationTransmitterAD9361AD9364ML') Frequency Offset
% Calibration Transmitter Using Analog Devices AD9361 and AD9364>.
%
% You can also view a Simulink(R) implementation of these examples in
% <matlab:showdemo('zynqRadioFrequencyCalibrationTxAD9361AD9364SL') Frequency Offset
% Calibration Using Analog Devices AD9361 and AD9364 using Simulink>.


%% Troubleshooting the Example
%
% If the received signal is very weak, you can try increasing the receiver
% gain by changing the _prmFreqCalibRx.RadioGain_ variable with the manual gain control mode 
% or by changing the _prmFreqCalibRx.RadioGainControlMode_ to 'AGC Fast Attack' or 'AGC Slow
% Attack'.
%
% If you run the example as described but fail to see a signal like the one
% shown (e.g. you only receive noise or the spectrum display is never
% shown), see <matlab:sdrzdoc('sdrz_troubleshoot') Xilinx FPGA-Based
% Radio Processing Errors and Fixes>.


%% Appendix
%
% This example uses the following helper files:
%
% * <matlab:edit('sdrzCoarseFrequencyOffset') sdrzCoarseFrequencyOffset.m>:
% a system object for calculating the frequency offset.


displayEndOfDemoMessage(mfilename)
