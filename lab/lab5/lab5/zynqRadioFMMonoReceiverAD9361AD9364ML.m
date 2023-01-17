%% FM Monophonic Receiver Using Analog Devices AD9361/AD9364
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package with MATLAB(R) to build an FM mono receiver. The receiver
% receives and demodulates the FM signal transmitted by the FM broadcast
% radio.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> documentation for details on configuring your host computer to
% work with the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2014-2015 The MathWorks, Inc.

%% Introduction
%
% The example configures the SDR hardware to receive an FM signal over the
% air. The FM Mono receiver performs FM demodulation, deemphasis filter and
% rate conversion. The example is designed to run on a Xilinx Zynq-Based
% SDR hardware Using Analog Devices(TM) AD9361 and AD9364.
%
%% Setup
%
% Before running the example, ensure you have performed the following
% steps:
%
% Configure your host computer to work with the Support Package for
% Xilinx(R) Zynq-Based Radio. See <matlab:sdrzdoc('sdrzspsetup')
% Getting Started> for help.
%
% * Some additional steps may be required if you want to run two radios
% from a single host computer. See
% <matlab:sdrzdoc('sdrz_tworadios') Setup for Two Radios - One
% Host> for help.
%
%% FM Mono Receiver Design: System Architecture
%
%%
% *Initialization*
%
% The <matlab:edit('getParamsFMExamplesAD9361AD9364.m')
% getParamsFMExamplesAD9361AD9364.m> script initializes some simulation
% parameters and generates a structure |monoFMRxParams|. The fields of this
% structure are the parameters of the FM demodulator system.

monoFMRxParams = getParamsFMExamplesAD9361AD9364 %#ok<NOPTS>

%%
% By default, the example is configured to run with ZC706 and ADI
% FMCOMMS2/3/4 hardware. You can uncomment one of the following lines as
% applicable to set the |RadioDeviceName| field in structure variable
% |monoFMRxParams|.

% % monoFMRxParams.RadioDeviceName='ZedBoard and FMCOMMS2/3/4';
% % monoFMRxParams.RadioDeviceName='PicoZed SDR';

monoFMRxParams.RadioDeviceName = 'ZC706 and FMCOMMS2/3/4';

%%
% Refer to the Simulink(R) model in the <matlab:showdemo('zynqRadioFMMonoAD9361AD9364SL')
% FM Monophonic Receiver Using Analog Devices AD9361/AD9364>
% for a block diagram view of the system.

%%
% *SDR Receiver*
%
% The SDR receiver <matlab:sdrzdoc('commsdrrxzc706fmc23') SDR Receiver>
% System object(TM) used with the named radio |'ZC706 and FMCOMMS2/3/4'|
% receives the radio baseband data from the SDR Hardware. The baseband
% sampling rate of the SDR Hardware is set to 960 kHz using the
% _BasebandSampleRate_ parameter of the SDR receiver System object. Frame
% length controls the number of samples at the output of the SDR Receiver
% System object. These samples are the input for the rate converter filter.
% The frame length must be an integer multiple of the decimation factor,
% which is 20 in this example. The frame length is set as 4800 samples. The
% output data type is set as single to reduce the required memory and speed
% up execution. The center frequency is set to 102.5 MHz.

radio = sdrrx(monoFMRxParams.RadioDeviceName, ...
    'IPAddress', '192.168.3.2', ...
    'CenterFrequency', monoFMRxParams.CenterFrequency, ...
    'GainSource', monoFMRxParams.RadioGainControlMode, ...
    'SamplesPerFrame', monoFMRxParams.RadioFrameLength, ...
    'BasebandSampleRate', monoFMRxParams.RadioSampleRate, ...
    'OutputDataType', monoFMRxParams.RadioOutputDataType);  

%%
% *Mono FM Demodulation*
%
% The FM Broadcast Demodulator Baseband block converts the sampling rate 
% of 960 kHz to 48 kHz, a native sampling rate for your host computer's 
% audio device. According to the FM broadcast standard in the United States, 
% the deemphasis lowpass filter time constant is set to 75 microseconds. 

fmBroadcastDemod = comm.FMBroadcastDemodulator(...
    'SampleRate', monoFMRxParams.RadioSampleRate, ...
    'FrequencyDeviation', monoFMRxParams.FrequencyDeviation, ...
    'FilterTimeConstant', monoFMRxParams.FilterTimeConstant, ...
    'AudioSampleRate', monoFMRxParams.AudioSampleRate, ...
    'PlaySound', true, ...
    'BufferSize', monoFMRxParams.BufferSize, ...
    'Stereo', false);

%% Reception and Baseband Signal Processing
%
% FM signals are captured and mono FM demodulation is applied for 10
% seconds, which is specified by monoFMRxParams.StopTime. The SDR Receiver
% System object returns a column vector, _rxSig_. The data from one of the
% channels is captured in _rxSigCh1_ for further processing. Since the
% MATLAB script may run faster than the hardware, the object returns the
% second output argument, _len_. Since the MATLAB script may run faster
% than the hardware, the object also returns the actual size of the valid
% data in _rxSigCh1_ using the second output argument, len. If len is zero,
% then there is no new data for the demodulator code to process. The
% demodulator code runs only if len is greater than 0. The actual reception
% and processing of the data is enclosed in a try/catch block. This means
% that if there is an error, the system objects still get released
% properly.
%
try
    % The first step call on the SDR receiver object does some initial
    % setup and takes about 4s. Calling the step method once and discarding
    % the data means the setup time is not included as part of the desired
    % run time.
  [~, ~] = step(radio);
  display('Starting reception')  
  timeCounter = 0;
  while timeCounter < monoFMRxParams.StopTime
    % Get baseband samples from FMCOMMS RF card
    [rxSig, len] = step(radio);
    rxSigCh1 = rxSig(:,1); % Receive the data on Channel 1
    if len > 0
      % FM demodulation
      step(fmBroadcastDemod, rxSigCh1);
      % Update counter
      timeCounter = timeCounter + monoFMRxParams.AudioFrameTime;
    end
  end
 disp('Finished reception')
catch ME
    rethrow(ME)
end
  
% Release all System objects
release(fmBroadcastDemod);
release(radio);

%% Alternative Implementations
%
% The example describes the MATLAB implementation of a receiver for
% demodulating and processing an FM Mono signal transmitted by the FM
% broadcast radio. The example uses Communications System Toolbox(TM)
% System objects and Zynq-based Hardware support package to build a
% monophonic FM receiver using SDR hardware with Analog Devices
% AD9361 and AD9364.
%
% You can also view a Simulink(R) implementation of these examples in
% <matlab:showdemo('zynqRadioFMMonoAD9361AD9364SL') FM Monophonic Receiver
% Using Analog Devices AD9361/AD9364>

%% Further Exploration
% To further explore the example, you can vary the center frequency of the
% SDR Hardware and listen to other radio stations.
%
% To optimize the filtering speed, combine the resampling filter in
% the 5n/1 resampler and the deemphasis filter into a single filter.

%% Appendix
% The following scripts are used in this example.
%
% * <matlab:edit('getParamsFMExamplesAD9361AD9364.m')
% getParamsFMExamplesAD9361AD9364.m>

%% Troubleshooting the Example
%
% If the received signal is very weak, you can try increasing the receiver
% gain by changing the _prmFreqCalibRx.RadioGain_ variable with the manual
% gain control mode or by changing the
% _prmFreqCalibRx.RadioGainControlMode_ to 'AGC Fast Attack' or 'AGC Slow
% Attack'.
%
% General tips for troubleshooting SDR hardware can be found in
% <matlab:sdrzdoc('sdrz_troubleshoot') Xilinx Zynq-Based Radio Processing
% Errors and Fixes>.

%% References 
% 
% * <http://en.wikipedia.org/wiki/FM_broadcasting FM broadcasting on Wikipedia(R)>
%

displayEndOfDemoMessage(mfilename)
