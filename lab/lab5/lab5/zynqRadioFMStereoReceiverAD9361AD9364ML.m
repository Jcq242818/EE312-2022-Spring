%% FM Stereo Receiver Using Analog Devices AD9361/AD9364
%
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package with MATLAB(R) to build an FM stereo receiver. The receiver
% receives and demodulates the FM signal transmitted by the stereo FM
% broadcast radio.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> documentation for details on configuring your host computer to
% work with the Support Package for Xilinx(R) Zynq-Based Radio.
%
% Copyright 2014-2015 The MathWorks, Inc.

%% Introduction
%
% The example configures the SDR hardware to receive an FM stereo signal
% over the air. The example plays both the left and right channels. The
% example is designed to run on a Xilinx Zynq-Based SDR hardware Using
% Analog Devices(TM) AD9361/AD9364.
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
%% FM Stereo Receiver Design: System Architecture
%
%%
% *Initialization*
%
% The <matlab:edit('getParamsFMExamplesAD9361AD9364.m')
% getParamsFMExamplesAD9361AD9364.m> script initialize some simulation
% parameters and generates a structure, |stereoFMRxParams|. The fields of
% this structure are the parameters of the FM receiver system.

stereoFMRxParams = getParamsFMExamplesAD9361AD9364 %#ok<NOPTS>

%%
% By default, the example is configured to run with ZC706 and ADI
% FMCOMMS2/3/4 hardware. You can uncomment one of the following lines as
% applicable to set the |RadioDeviceName| field in structure variable
% |stereoFMRxParams|.

% % stereoFM.RadioDeviceName='ZedBoard and FMCOMMS2/3/4';
% % stereoFM.RadioDeviceName='PicoZed SDR';

stereoFMRxParams.RadioDeviceName = 'ZC706 and FMCOMMS2/3/4';

%% 
% *SDR Receiver*
%
% The SDR receiver <matlab:sdrzdoc('commsdrrxzc706fmc23')
% SDR Receiver> System object(TM) used with the named radio |'ZC706 and FMCOMMS2/3/4'| 
% receives the radio baseband data from the SDR Hardware.
% The baseband sampling rate of the SDR Hardware is set to
% 960 kHz using the _BasebandSampleRate_ parameter of the SDR receiver System object.  
% The center frequency is set as 102.5 MHz.
%
%%
% Set the baseband sampling rate to 960 kHz so that the example uses round
% numbers to convert the sampling rate to 152 kHz and then 48 kHz using
% small resampling filters. Frame length controls the number of samples at
% the output of the SDR Receiver System object, which is the input to the
% rate converter filter. The frame length is set to 4800 samples. The
% output data type is set as single to reduce the required memory and speed
% up execution.

radio = sdrrx(stereoFMRxParams.RadioDeviceName, ...
    'IPAddress', '192.168.3.2', ...
    'CenterFrequency', stereoFMRxParams.CenterFrequency, ...
    'GainSource', stereoFMRxParams.RadioGainControlMode, ...
    'SamplesPerFrame', stereoFMRxParams.RadioFrameLength, ...
    'BasebandSampleRate', stereoFMRxParams.RadioSampleRate, ...
    'OutputDataType', stereoFMRxParams.RadioOutputDataType); 
%% 
% *FM Demodulator*
%
% This example uses the FM Broadcast Demodulator Baseband System object(TM)
% to demodulate the received signal. The block also converts the sampling
% rate of 960 kHz to 48 kHz, a native sampling rate for your host
% computer's audio device. According to the FM broadcast standard in the
% United States, the deemphasis lowpass filter time constant is set to 75
% microseconds.

fmBroadcastDemod = comm.FMBroadcastDemodulator(...
    'SampleRate', stereoFMRxParams.RadioSampleRate, ...
    'FrequencyDeviation', stereoFMRxParams.FrequencyDeviation, ...
    'FilterTimeConstant', stereoFMRxParams.FilterTimeConstant, ...
    'AudioSampleRate', stereoFMRxParams.AudioSampleRate, ...
    'PlaySound', true, ...
    'BufferSize', stereoFMRxParams.BufferSize, ...
    'Stereo', true);

%%
% To perform stereo decoding, the FM Broadcast Demodulator Baseband block 
% uses a peaking filter which picks out the 19 kHz pilot tone from which 
% the 38 kHz carrier is created. Using the obtained carrier signal, the 
% FM Broadcast Demodulator Baseband block downconverts the L-R signal, 
% centered at 38 kHz, to baseband. Afterwards, the L-R and L+R signals 
% pass through a 75 microsecond deemphasis filter . The FM Broadcast 
% Demodulator Baseband block separates the L and R signals and converts 
% them to the 48 kHz audio signal.


%%
% Refer to the Simulink(R) model in the
% <zynqRadioFMStereoAD9361AD9364SL.html FM Stereo Receiver Using Analog
% Devices(TM) AD9361/AD9364> example for a block diagram view of the
% system.
%
%% Stream Processing Loop
%
% FM signals are captured and stereo FM demodulation is applied for 10
% seconds, which is specified by stereoFMRxParams.StopTime. The SDR
% Receiver System object returns a column vector, _rxSig_. The data from
% one of the channels is captured in _rxSigCh1_ for further processing.
% Since the MATLAB script may run faster than the hardware, the object also
% returns the actual size of the valid data in _rxSigCh1_ using the second
% output argument, len. If len is zero, then there is no new data for the
% demodulator code to process. The actual reception and processing of the
% data is enclosed in a try/catch block. This means that if there is an
% error, the system objects still get released properly.

try
    % The first step call on the SDR receiver object does some initial
    % setup and takes about 4s. Calling the step method once and discarding
    % the data means the setup time is not included as part of the desired
    % run time
    
    [~, ~] = step(radio);
    display('Starting reception')
    timeCounter = 0;
    while timeCounter < stereoFMRxParams.StopTime
        [rxSig, len] = step(radio);
        rxSigCh1 = rxSig(:,1); % Receive the data on Channel 1
        if len > 0
            % FM demodulation
            step(fmBroadcastDemod, rxSigCh1);
            % Update counter
            timeCounter = timeCounter + stereoFMRxParams.AudioFrameTime; 
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
% demodulating and processing an FM stereo signal transmitted by the stereo
% FM broadcast radio. The example uses Communications System Toolbox(TM)
% System objects and Zynq-based Hardware support package to build a stereo
% FM receiver using SDR hardware with Analog Devices AD9361 and AD9364.
%
% You can also view a Simulink(R) implementation of these examples in
% <matlab:showdemo('zynqRadioFMStereoAD9361AD9364SL') FM Stereo Receiver
% Using Analog Devices AD9361/AD9364 using Simulink>

%% Further Exploration
%
% To further explore the example, you can vary the center frequency of the
% SDR Hardware and listen to other radio stations.
%
% If you have your own FM transmitter that can transmit .wma files, you can
% duplicate the test that shows the channel separation result above. Load
% the |sdrzFMStereoTestSignal.wma| file into your transmitter. The channel
% separation can be easily observed from the spectrum and heard from the
% audio device. You can also adjust the gain compensation to see its effect
% on stereo separation.
%
% To optimize the filtering speed, you can combine the resampling filter in
% the 19n/6 resampler and the deemphasis filter into a single filter.

%% Appendix
% The following scripts are used in this example.
%
% * <matlab:edit('getParamsFMExamplesAD9361AD9364.m') getParamsFMExamplesAD9361AD9364.m>

%% References 
% 
% * <http://en.wikipedia.org/wiki/FM_broadcasting FM broadcasting on Wikipedia(R)>
%

displayEndOfDemoMessage(mfilename)
