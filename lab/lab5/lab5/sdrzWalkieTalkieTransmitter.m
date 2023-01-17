%% Walkie-Talkie Transmitter with Analog Devices FMCOMMS1
%
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package with MATLAB(R) to implement a walkie-talkie transmitter. The
% transmitted signal can be received by a compatible commercial
% walkie-talkie. Alternatively, the signal can be received by the companion
% <matlab:showdemo('sdrzWalkieTalkieReceiver') Walkie-Talkie Receiver with
% Analog Devices(TM) FMCOMMS1> example if you have a second SDR platform.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> documentation for details on configuring your host computer to
% work with the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2014-2015 The MathWorks, Inc.


%% Introduction
%
% Walkie-talkies provide a subscription-free method of communicating over
% short distances. There are a number of different standards used around
% the world. This example uses MATLAB SDR system objects to implement two
% of these standards: *Family Radio Service* and *Personal Mobile Radio
% 446*.
%
% * *Family Radio Service (FRS):* Operates on 14 channels at frequencies
% around 462 MHz and 467 MHz. The channel spacing is 25 kHz. FRS radios are
% commonly found in the North and South America. More details on FRS can be
% found in [ <#16 1> ].
% * *Personal Mobile Radio 446 (PMR446):* Operates on 8 channels around 446
% MHz. The channel spacing is 12.5 kHz. PMR446 radios are commonly found in
% Europe. More details on PMR446 can be found in [ <#16 2> ].
%
% Both FRS and PMR446 use analog frequency modulation (FM) with a maximum
% frequency deviation of +-2.5 kHz. They also use a *Continuous Tone-Code
% Squelch System (CTCSS)* to filter unwanted signals at the receiver. CTCSS
% is implemented in this example.
%
% This example allows the transmitted audio to be a continuous tone, a
% chirp signal or voice from an audio file. The audio sample rate is always
% 8 kHz.

%% Setup
%
% Before running the example, ensure you have performed the following
% steps:
%
% 1. Configure your host computer to work with the Support Package for
% Xilinx(R) Zynq-Based Radio. See <matlab:sdrzdoc('sdrzspsetup')
% Getting Started> for help.
%
% * Some additional steps may be required if you want to run two radios
% from a single host computer. See
% <matlab:sdrzdoc('sdrz_tworadios') Setup for Two Radios - One
% Host> for help.
%
% 2. Ensure that you have a suitable receiver. This example is designed to
% work in conjunction with any of the following possible receivers:
%
% * The <matlab:showdemo('sdrzWalkieTalkieReceiver') Walkie-Talkie
% Receiver with Analog Devices FMCOMMS1> MATLAB example
% * The <matlab:showdemo('sdrzWalkieTalkieRx') Walkie-Talkie Receiver with
% Analog Devices FMCOMMS1> Simulink(R) example
% * A commercial FRS/PMR446 radio
%
% 3. Ensure that your receiver is set to the same protocol, channel and
% CTCSS code.


%% Running the Example
%
% Before running the example, make sure that the _protocol_ variable is set
% to a standard that is legal for use in your location. The example can be
% run by executing <matlab:edit('sdrzWalkieTalkieTransmitter.m')
% sdrzWalkieTalkieTransmitter.m>.
%
% Once both the transmitter and receiver are active, you should hear the
% transmitted audio on your receiver. By default, a voice signal is
% transmitted.

%% Transmitter Design: System Architecture
%
% The general structure of the walkie-talkie transmitter can be described
% as follows:
%
% # Generate the audio signal to be transmitted
% # Generate the CTCSS tone
% # Combine the CTCSS tone with the audio signal
% # Upsample the 8 kHz audio signal to 64 kHz
% # FM modulate the audio signal
% # Send the modulated signal to the SDR hardware for further upsampling
% and transmission
%
% The high level functionality of the transmitter, such as the protocol
% used and the channel, can be controlled by changing the variables in the
% code section below. 
%

% Set the variables that control the transmitter. 
% The protocol variable should be set to 'FRS' or 'PMR446' depending on
% which standard is legal in your location. The audio variable can be
% 'Audio file', 'Chirp' or 'Pure tone'.

protocol = 'FRS';
% protocol = 'PMR446';
channel = 1;
CTCSSCode = 5;
audioSource = 'Audio file';
% audioSource = 'Chirp';
% audioSource = 'Pure tone';
transmissionStopTime = 20; % in seconds

% Set the variables that control the system sample rates
baseFrameSize = 512;
audioSampleRate = 8e3; % constant, in Hertz
radioDACRate = 32.768e6; % in Hertz
radioInterpolationFactor = 512;
radioSampleRate = radioDACRate / radioInterpolationFactor; % in Hertz
softwareInterpolationFactor = radioSampleRate / audioSampleRate;

% Create the interpolation filter for 8 kHz to 64 kHz
interpolatorCoefficients = ...
    dspmltiFIRDefaultFilter(softwareInterpolationFactor);                   
softwareInterpolator = dsp.FIRInterpolator(softwareInterpolationFactor, ...
    interpolatorCoefficients);

%%
% Each component of the transmitter is described in more detail in the
% following sections.


%% 
% *Generating the Audio Signal*
%
% The audio to be transmitted is composed of two components:
%
% # The actual audio, such as a speech signal, that will be audible at the
% receiver. This audio is generated by a custom system object,
% <matlab:edit('sdrzWalkieTalkieTransmitter_AudioSource')
% sdrzWalkieTalkieTransmitter_AudioSource>.
% # The CTCSS tone, that is generated by a <matlab:doc('dsp.SineWave')
% dsp.SineWave> system object.
%
% *Continuous Tone-Coded Squelch System (CTCSS)*
%
% Walkie-Talkies operate on a shared public channel, allowing multiple
% users to access the same channel simultaneously. CTCSS [ <#16 3> ]
% systems filter out undesired communication or interference from these
% other users. The transmitter generates a tone between 67 Hz and 250 Hz
% and transmits it along with the source signal. The receiver contains
% logic to detect this tone, and acknowledges a message if the detected
% tone matches the code setting on the receiver. The receiver filters out
% the tone so that the user does not hear it.
%
% The CTCSS tone generator generates a continuous phase sine wave with a
% frequency corresponding to the selected private code. The amplitude of
% the tone is usually 10%-15% of the maximum amplitude of the modulating
% signal. Note that because the maximum amplitude of all the source signals
% is 1, the default amplitude of 0.15 for the CTCSS tone corresponds to 15%
% of the modulating signal's maximum amplitude.

audioGenerator = sdrzWalkieTalkieTransmitter_AudioSource( ...
                     'SignalSource', audioSource, ...
                     'SamplesPerFrame', baseFrameSize);
CTCSSAmplitude = 0.15; % normalized amplitude i.e. 0 to 1;
% Convert the CTCSS code to a frequency
CTCSSTone = sdrzWalkieTalkieHelper_CTCSSCode2Tone(CTCSSCode);
CTCSSGenerator = dsp.SineWave(...
                              'Frequency', CTCSSTone, ...
                              'Amplitude', CTCSSAmplitude, ...
                              'SampleRate', audioSampleRate, ...
                              'SamplesPerFrame', baseFrameSize, ...
                              'OutputDataType',   'single');

%%
% *Performing the Frequency Modulation*
%
% This example implements the FM modulator using a simple digital IIR
% filter as an integrator. The IIR filter is implemented using a
% <matlab:doc('dsp.IIRFilter') dsp.IIRFilter> system object. The frequency
% sensitivity parameter, _frequencySensitivityGain_, is used to control the
% modulation. It is related to the frequency deviation by the formula:
%
% _frequencySensitivityGain = frequencyDeviation * (2*pi*Ts) / A_
%
% where _peakFrequencyDeviation_ is 2.5 kHz, _Ts_ is the sampling period of
% the SDR transmitter, and _A_ represents the maximum amplitude of the
% modulating signal i.e. the audio signal. This example assumes the
% generated audio is normalized and therefore has a peak amplitude of 1.
%
% See [ <#16 4> ] for more information on frequency modulation.

integratingFilter = dsp.IIRFilter(...
  'Structure',    'Direct form I', ...
  'Numerator',    1, ...
  'Denominator',  [1 -1]);

peakAudioAmplitude = 1;
frequencyDeviation = 2.5e3;
radioSamplePeriod = (1/radioSampleRate);
frequencySensitivityGain  = frequencyDeviation * 2 * pi * ...
                                radioSamplePeriod / peakAudioAmplitude;

%% 
% *Creating the SDR Transmitter system object*
%
% By default, the example is 
% configured to run with ZC706 and ADI FMCOMMS1 hardware. You can uncomment 
% one of the following lines, as applicable, to
% set the |SDRDeviceName|.

% % SDRDeviceName='ZedBoard and FMCOMMS1 RevB/C';

SDRDeviceName = 'ZC706 and FMCOMMS1 RevB/C';
dev = sdrdev(SDRDeviceName);
setupSession(dev); % Only needed once per session, but multiple calls are OK
%%
% An <matlab:sdrzdoc('commsdrtxzc706fmc1') SDR Transmitter> system object is used to send baseband
% data to the SDR hardware. The SDR hardware is configured to use an
% intermediate frequency of 10 MHz. 

radioIntermediateFrequency = 10e6;
radioDesiredCenterFrequency = sdrzWalkieTalkieHelper_Channel2Frequency( ...
                                  protocol, channel);
radioCenterFrequency = radioDesiredCenterFrequency - ...
                           radioIntermediateFrequency;
SDRTransmitter = sdrtx(SDRDeviceName, ...
        'IPAddress',              '192.168.3.2', ...
        'CenterFrequency',        radioCenterFrequency, ...
        'DACRate',                radioDACRate, ...     
        'IntermediateFrequency',  radioIntermediateFrequency, ...
        'InterpolationFactor',    radioInterpolationFactor, ...
        'BypassUserLogic',        true);

%%
% *Baseband Processing and Transmission*
%
% The actual processing and transmission of the data is enclosed in a
% try/catch block. This means that if there is an error, the system objects
% still get released properly.
%
% By enclosing the data processing and transmission in a while loop
% controlled using a tic/toc pair, the transmission will run for
% approximately the desired real world time.

try
    % The first step call on the SDR transmit object takes about 4 s to
    % establish a connection. Calling step once with very small complex
    % values as the input will establish this connection with the correct
    % data type but not send any significant data. Note that the RF carrier
    % will be present.
    dummyData = single(complex(ones(4096,1),ones(4096,1))*1e-12);
    step(SDRTransmitter, dummyData);
    display('Starting transmission')
    
    tic; % start timing the transmission
    while toc < transmissionStopTime
        % Generate the audio data to be transmitted
        audioData = step(audioGenerator);       
        
        % Generate the CTCSS tone
        CTCSSData = step(CTCSSGenerator);
        
        % Combine the CTCSS tone with the audio data
        audioPlusCTCSS = audioData + CTCSSData;
        
        % Upsample the 8 kHz audio to 64 kHz
        upsampledBasebandData = step(softwareInterpolator, audioPlusCTCSS);
        
        % FM modulate the audio
        outInteg  = step(integratingFilter, upsampledBasebandData);
        FMPhase = exp(1i * frequencySensitivityGain * outInteg);
        FMAmplitude = 0.9; % can be used to control the transmit power
        FMModulatedData    = FMAmplitude .* FMPhase;
                           
        % Send the data to the SDR hardware
        droppedSamples = step(SDRTransmitter,FMModulatedData);
        
        if droppedSamples
            disp('Unable to send data fast enough to SDR hardware!')
        end
    end
    disp('Finished transmitting')
catch ME
    rethrow(ME)
end
% Release system objects associated with hardware
release(SDRTransmitter);


%% Transmitter Design: System Sample Rates
%
% The system has three different sample rates:
%
% # The audio sample rate, *8 kHz*
% # The SDR hardware baseband rate, *64 kHz*
% # The SDR hardware DAC rate, *32.768 MHz*
%
% The upsample by 8 from 8 kHz to 64 kHz is done in software using a
% <matlab:doc('dsp.FIRInterpolator') dsp.FIRInterpolator> object,
% _softwareInterpolator_. The upsample to
% 64 kHz is necessary for two reasons:
%
% # By Carson's rule, the approximate passband bandwidth of the desired FM
% signal is 2*(frequencyDeviation + peakAudioFrequency). In this example,
% that equates to a signal bandwidth of _2*(2.5e3 + 4e3) = 13 kHz_. This
% means we need to use a sample rate greater than 13 kHz.
% # The sample rates in software have no relation to the real world
% transmission rates. The actually transmission rate is determined entirely
% by the SDR hardware DAC rate and the SDR hardware interpolation factor.
% To make the software sample rates meaningful, the sample rates at the
% software/hardware interface must match. For the FMCOMMS1, the lowest
% possible baseband sample rate that is a multiple of 8 kHz that is greater
% than 13 kHz is 64 kHz. Using an integer upsample factor means a smaller
% interpolation filter (fewer taps) can be used.
%
%% Things to Try
%
% To modify the example, save a local copy of
% <matlab:edit('sdrzWalkieTalkieTransmitter')
% sdrzWalkieTalkieTransmitter.m>. Some possible modifications include:
%
% * Try changing the channel by changing the _channel_ variable.
% * Try changing the CTCSS code by changing the _CTCSSCode_ variable. Note
% that the receiver will not play the transmission out loud unless it has
% the same CTCSS code, or it has CTCSS disabled by setting the code to 0.
% * Try changing the audio source by changing the _audioSource_ variable.
% You can send a voice recording, a single tone or a chirp signal.
% * Try replacing the sdrzWalkieTalkieTransmitter_AudioSource object with a
% <matlab:doc('audioDeviceReader') audioDeviceReader> System object, so
% that you can transmit audio captured from a microphone in real time. This
% requires Audio System Toolbox(TM).

%% Alternative Implementations
%
% This example implements a walkie-talkie transmitter in MATLAB. You can
% also view the equivalent system implemented using Simulink in the
% <matlab:showdemo('sdrzWalkieTalkieTx') Walkie-Talkie Transmitter with Analog Devices FMCOMMS1 using Simulink> example.

%% Troubleshooting the Example
%
% If you cannot hear the transmitted signal on your receiver, try the
% following:
%
% * Make sure that the transmitter and the receiver are set to the same
% protocol, channel and CTCSS code.
% * Disable CTCSS on the receiver by setting the code to 0. Note that
% codes higher than 38 use Digital Coded Squelch, which is not implemented
% in this example.
% * Vary the relative amplitude of the CTCSS tone by changing the
% _CTCSSAmplitude_ variable.
%
% General tips for troubleshooting SDR hardware can be found in
% <matlab:sdrzdoc('sdrz_troubleshoot') Xilinx Zynq-Based Radio Processing
% Errors and Fixes>.

%% List of Example Helper Files
%
% This example uses the following helper functions
%
% * <matlab:edit('sdrzWalkieTalkieHelper_CTCSSCode2Tone.m')
% sdrzWalkieTalkieHelper_CTCSSCode2Tone.m>: converts a CTCSS code to a
% frequency.
% * <matlab:edit('sdrzWalkieTalkieHelper_Channel2Frequency.m')
% sdrzWalkieTalkieHelper_Channel2Frequency.m>: converts a channel number to
% an RF frequency.
% * <matlab:edit('sdrzWalkieTalkieTransmitter_AudioSource.m')
% sdrzWalkieTalkieTransmitter_AudioSource.m>: generates an audio signal for
% transmission.
% * sdrzWalkieTalkieHelper_voice.wav: the audio file used when the
% audio source is set to _'Audio file'_.

%% References
%
% # <http://en.wikipedia.org/wiki/Family_Radio_Service Family Radio
% Service> on Wikipedia(R)
% # <http://en.wikipedia.org/wiki/PMR446 PMR446> on Wikipedia
% # <http://en.wikipedia.org/wiki/Continuous_Tone-Coded_Squelch_System
% Continuous Tone-Coded Squelch System> on Wikipedia
% # <http://en.wikipedia.org/wiki/Frequency_modulation Frequency
% Modulation> on Wikipedia

displayEndOfDemoMessage(mfilename)