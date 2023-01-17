%% Frequency Offset Calibration Transmitter with Analog Devices FMCOMMS1
%
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package with MATLAB(R) to determine the frequency offset between SDR
% devices. The example comprises of two complementary scripts: one for the
% transmitter and one for the receiver. This is the help for the
% transmitter. The transmitter sends a 10 kHz sine wave with the
% <matlab:edit('sdrzFrequencyCalibrationTransmitter') Frequency Offset
% Calibration Transmitter with Analog Devices(TM) FMCOMMS1> script. The receiver receives
% the signal, calculates the frequency offset and displays the offset using
% the <matlab:showdemo('sdrzFrequencyCalibrationReceiver') Frequency Offset
% Calibration Receiver with Analog Devices FMCOMMS1> script.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> documentation for details on configuring your host computer to
% work with the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2014 The MathWorks, Inc.

%% Introduction
%
% This example uses a matched pair of scripts to determine the frequency
% offset between two SDR devices:
%
% * The transmit script
% is <matlab:edit('sdrzFrequencyCalibrationTransmitter') Frequency Offset
% Calibration Transmitter with Analog Devices FMCOMMS1>
% * The receive script is <matlab:edit('sdrzFrequencyCalibrationReceiver')
% Frequency Offset Calibration Receiver with Analog Devices FMCOMMS1>
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
% <matlab:edit('sdrzFrequencyCalibrationTransmitter') Frequency Offset
% Calibration Transmitter with Analog Devices FMCOMMS1> and the receiver script
% <matlab:edit('sdrzFrequencyCalibrationReceiver') Frequency Offset
% Calibration Receiver with Analog Devices FMCOMMS1> open, with each configured to run
% on its own SDR hardware in its own instance of MATLAB.


%% Running the Example
%
% Execute <matlab:edit('sdrzFrequencyCalibrationTransmitter')
% sdrzFrequencyCalibrationTransmitter.m>.  By default, the example is 
% configured to run with ZC706 and ADI FMCOMMS1 hardware. You can uncomment 
% one of the following lines, as applicable, to
% set the |SDRDeviceName| field in structure variable |prmFreqCalibTx|.

% % prmFreqCalibTx.SDRDeviceName='ZedBoard and FMCOMMS1 RevB/C';

    prmFreqCalibTx.SDRDeviceName = 'ZC706 and FMCOMMS1 RevB/C';
%%    
% The transmitter will run for approximately 10 seconds. You can increase the transmission
% duration by changing the _prmFreqCalibTx.RunTime_ variable. When the
% transmission starts, the message
%
%  Starting transmission
%%
% will be shown in the MATLAB command window. Once the transmission is
% finished, the message
%
%  Finished transmission
%%
% will be displayed. While the SDR hardware is transmitting, start the
% receiver script <matlab:edit('sdrzFrequencyCalibrationReceiver')
% sdrzFrequencyCalibrationReceiver.m> in its own instance of MATLAB and on
% its own SDR hardware. See the documentation for the
% <matlab:showdemo('sdrzFrequencyCalibrationReceiver') Frequency Offset
% Calibration Receiver with Analog Devices FMCOMMS1> example for more details.


%% Transmitter Design: System Architecture
%
%% 
% *Initialization*
%
% The code below sets up the parameters used to control the transmitter.

% amount of time the transmission runs for in seconds
prmFreqCalibTx.RunTime = 10; 

% SDR Transmitter parameters
dev = sdrdev(prmFreqCalibTx.SDRDeviceName); % Make sure settupSession() has been called. Multiple calls are allowed.
setupSession(dev);
prmFreqCalibTx.RadioIP = '192.168.3.2';
prmFreqCalibTx.RadioDACRate = 98.304e6; 
prmFreqCalibTx.DesiredRFCenterFrequency =  2.415e9;
prmFreqCalibTx.RadioIntermediateFrequency = 3e6;
prmFreqCalibTx.RadioCenterFrequency = ...
    prmFreqCalibTx.DesiredRFCenterFrequency - ...
    prmFreqCalibTx.RadioIntermediateFrequency;
prmFreqCalibTx.RadioInterpolationFactor = 500;      
prmFreqCalibTx.RadioFrontEndSampleRate = prmFreqCalibTx.RadioDACRate / ...
    prmFreqCalibTx.RadioInterpolationFactor; 

% Sine wave generation parameters
prmFreqCalibTx.Fs = prmFreqCalibTx.RadioFrontEndSampleRate;
prmFreqCalibTx.SineAmplitude               = 0.9;
prmFreqCalibTx.SineFrequency               = 10e3; % in Hertz
prmFreqCalibTx.SineComplexOutput           = true;
prmFreqCalibTx.SineOutputDataType          = 'double';
prmFreqCalibTx.SineFrameLength             = 4096;

%%
% Using the parameters above, three system objects are created:
%
% # The <matlab:doc('dsp.SineWave') dsp.SineWave> object generates the sine
% wave to be transmitted
% # An <matlab:sdrzdoc('commsdrtxzc706fmc1') SDR Transmitter>
% system object used with the named radio |'ZC706 and FMCOMMS1 RevB/C'|,
% sends the baseband sine wave to the SDR hardware for upsampling and
% transmission.
% # The <matlab:doc('dsp.SpectrumAnalyzer') dsp.SpectrumAnalyzer> object is
% used to visualize the spectrum of the baseband signal that is transmitted

hSineSource = dsp.SineWave (...
    'Frequency',       prmFreqCalibTx.SineFrequency, ...
    'Amplitude',       prmFreqCalibTx.SineAmplitude,...
    'ComplexOutput',   prmFreqCalibTx.SineComplexOutput, ...
    'SampleRate',      prmFreqCalibTx.Fs, ...
    'SamplesPerFrame', prmFreqCalibTx.SineFrameLength, ...
    'OutputDataType',  prmFreqCalibTx.SineOutputDataType);

hSDRTx = sdrtx( prmFreqCalibTx.SDRDeviceName,...
    'IPAddress',             prmFreqCalibTx.RadioIP, ...
    'DACRate',               prmFreqCalibTx.RadioDACRate, ...
    'CenterFrequency',       prmFreqCalibTx.RadioCenterFrequency, ...
    'InterpolationFactor',   prmFreqCalibTx.RadioInterpolationFactor, ...
    'IntermediateFrequency', prmFreqCalibTx.RadioIntermediateFrequency, ...
    'BypassUserLogic',       true);

hSpectrumAnalyzer = dsp.SpectrumAnalyzer(...
    'Name',             'Frequency of the transmit sine wave',...
    'Title',            'Frequency of the transmit sine wave',...
    'FrequencySpan',    'Full', ...
    'SampleRate',       prmFreqCalibTx.Fs, ...
    'SpectralAverages', 50, ...
    'YLimits',          [-250 20]);

%% 
% *Baseband Signal Generation and Transmission*
%
% The transmitter is then run for the target amount of time. The sine
% generator is stepped once before the loop so that the spectrum can be
% displayed. Stepping the spectrum analyzer for each loop would be
% processor intensive. Only stepping the spectrum analyzer once maximizes
% the transmitter performance.

prmFreqCalibTx.currentTime = 0;
prmFreqCalibTx.timePerStep = (1 / prmFreqCalibTx.Fs) * ...
    prmFreqCalibTx.SineFrameLength;

% generate the sine wave and display the spectrum
data = step(hSineSource); 
step(hSpectrumAnalyzer, data);

display('Starting transmission')
while prmFreqCalibTx.currentTime < prmFreqCalibTx.RunTime
    % send the baseband data to the SDR hardware for RF transmission
    step(hSDRTx, data); 
    % generate the next sine wave baseband data block
    data = step(hSineSource);
    % Update the transmission timing loop control variable
    prmFreqCalibTx.currentTime = prmFreqCalibTx.currentTime + ...
        prmFreqCalibTx.timePerStep;
end
disp('Finished transmission')

% Clean up the system objects and variables created, but leave the spectrum
% analyzer open
release(hSineSource);
release(hSDRTx);
release(hSpectrumAnalyzer);
clear hSineSource hSDRTx prmFreqCalibTx data

%%
% Note that his example does not check for any dropped samples during the
% transmission.

%% Alternative Implementations
%
% This example describes the MATLAB implementation of a transmitter for
% performing frequency offset calibration between two SDR devices. The
% matched receiver is <matlab:showdemo('sdrzFrequencyCalibrationReceiver')
% Frequency Offset Calibration Receiver with Analog Devices FMCOMMS1>. 
%
% You can also view a Simulink(R) implementation of these examples in
% <matlab:showdemo('sdrzfreqcalib') Frequency Offset
% Calibration with Analog Devices FMCOMMS1>.

displayEndOfDemoMessage(mfilename)