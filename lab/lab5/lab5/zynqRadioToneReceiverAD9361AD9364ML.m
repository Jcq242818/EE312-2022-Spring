%% Receive Tone Signal Using Analog Devices AD9361/AD9364
%
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package and Communications System Toolbox(TM) software to perform a
% simple loopback of a complex sinusoid signal at RF Using Analog
% Devices(TM) AD9361/AD9364. A Direct Digital
% Synthesizer (DDS) in the FPGA generates a complex sinusoid and transmits
% it using the RF card. The transmitted signal is then received by the RF
% card and the downsampled baseband signal is visualized in MATLAB(R). This
% simple example confirms that the SDR hardware is setup correctly and
% shows how to capture RF data from SDR hardware using MATLAB.

% Copyright 2014-2015 The MathWorks, Inc.

%% Configure SDR Hardware
% If you are running this example after performing the setup of 
% hardware using Support Package Installer then you can skip this section.
% Otherwise, follow <matlab:sdrzdoc('sdrzspsetup')  Guided Hardware Setup>
% to configure your host computer to work with the SDR hardware.  
% Connect an SMA loopback cable with attenuation between TX1A and RX1A (for
% FMCOMMS2 or FMCOMMS3) or between TXA and RXA (for FMCOMMS4) or attach
% appropriate antenna suitable for 2.4 GHz band.

%% Running the Example
% This example can be run by executing
% <matlab:edit('zynqRadioToneReceiverAD9361AD9364ML')
% zynqRadioToneReceiverAD9361AD9364ML.m>. By default, the example is configured to
% run with Xilinx ZC706 and ADI FMCOMMS2/3/4 RF card. You can run this
% example with ZedBoard(TM) and ADI FMCOMMS2/3/4 or PicoZed(TM) SDR by
% uncommenting the appropriate line.

% % prmToneRx.SDRDeviceName = 'ZedBoard and FMCOMMS2/3/4';
% % prmToneRx.SDRDeviceName = 'PicoZed SDR';
% % prmToneRx.IPAddress = '192.168.3.2'; 

if ~exist('prmToneRx', 'var')
    prmToneRx.SDRDeviceName = 'ZC706 and FMCOMMS2/3/4';
    prmToneRx.IPAddress = '192.168.3.2';
end

%% Transmit a Tone Signal from the FPGA
% Set the Direct Digital Synthesizer (DDS) in the FPGA fabric to transmit a
% complex sinusoid to the RF card. This is provided in the FPGA for testing
% and debugging purposes. 

%%
% Create a transmitter System object(TM) to configure the RF card settings. Set
% the RF card to transmit data at a center frequency of 2.4 GHz.

RadioBasebandRate = 1e6;
CenterFrequency = 2.4e9;
ToneFrequency = 25e3;

hSDRtx = sdrtx(prmToneRx.SDRDeviceName, ...
             'IPAddress',       prmToneRx.IPAddress, ...
             'CenterFrequency', CenterFrequency);

%%
% Turn on the properties related to DDS by setting
% |ShowAdvancedProperties| to true. Set the |DataSourceSelect| property of
% transmitter System object to 'DDS'. Set the tone frequency and scale for
% DDS.  

hSDRtx.ShowAdvancedProperties = true;
hSDRtx.BasebandSampleRate = RadioBasebandRate;
hSDRtx.EnableBurstMode = true;
hSDRtx.DataSourceSelect = 'DDS';
hSDRtx.DDSScale = [100e3 100e3;0 0];
hSDRtx.DDSFrequency = [ToneFrequency ToneFrequency;0 0];
hSDRtx.Gain = 0;

%%
% Next, call the step method to initiate the transmission of data from DDS
% to RF card.  

hSDRtx.DataSourceSelect = 'DDS';
step(hSDRtx,complex(ones(1,1), ones(1,1)));

%%
% Note that the simultaneous transmission and reception of data
% from MATLAB to RF card (duplex) is currently not supported. Therefore, for
% this example the data is generated in FPGA using DDS and transmitted directly to the
% RF card. MATLAB is only used for signal reception   
 
%% Capture RF Signal
% To capture the RF tone signal into MATLAB create an SDR receiver System
% object and configure it to receive the samples at the baseband rate.

% Radio parameters
RadioFrameLength = 4000;

% Create a receiver System object with desired radio parameters
hSDRrx = sdrrx(prmToneRx.SDRDeviceName, ...
             'IPAddress',        prmToneRx.IPAddress, ...
             'CenterFrequency',  CenterFrequency, ...
             'BasebandSampleRate', RadioBasebandRate,...
             'GainSource', 'AGC Fast Attack', ...
             'SamplesPerFrame', RadioFrameLength, ...
             'ChannelMapping',  1, ...
             'OutputDataType',   'double');
%%
% To visualize the received signal in frequency and time domain use
% Spectrum Analyzer and Time Scope System objects. In addition, set up a
% Constellation Diagram System object for plotting signal as two
% dimensional scatter diagram in the complex plane.   

% Call helper function to initialize scopes and position them
[hSpectrum, hTimeScopes, hConstDiagm] = ...
        zynqRadioToneReceiverPlotSetup(RadioBasebandRate);

%%
% Set the simulation to capture 100 milliseconds of data.

StopTime        = 100e-3;                                 % seconds
RadioFrameTime  = (RadioFrameLength / RadioBasebandRate); % seconds
%%
%
% If the processing of received data in MATLAB is slower than the speed at
% which the data is captured, you will encounter loss of samples. This will
% be reflected by non-zero value of |lostSamps| variable. To ensure
% reception of contiguous data in MATLAB you can capture signals by
% enabling <matlab:sdrzdoc('sdrz_burstmode') burst mode> and by specifying
% the number of frames as the size of burst. In this mode, the specified
% amount of data is captured in a buffer first and later it is available
% for processing in MATLAB.

numFramesinBurst = ceil(RadioBasebandRate*StopTime/RadioFrameLength);
hSDRrx.EnableBurstMode = true;
hSDRrx.NumFramesInBurst = numFramesinBurst;
%%
% Call step methods of System objects in a loop to capture and visualize
% the data. 

try
  % Loop until the example reaches the target stop time.
  timeCounter = 0;
  while timeCounter < StopTime

    [data, len, lostSamps] = step(hSDRrx);
    if (lostSamps > 0)
        warning(['### ' num2str(lostSamps) ' samples from the radio have been lost.']);
    end

    if len > 0
        % Visualize frequency spectrum
        step(hSpectrum,data);   
        % Visualize in time domain
        step(hTimeScopes,[real(data), imag(data)]);
    	% Visualize the scatter plot
        step(hConstDiagm,data); 
        
        % Set the limits in scopes
        dataMaxLimit = max(abs([real(data); imag(data)]));
        hConstDiagm.XLimits = [-dataMaxLimit*1.5, dataMaxLimit*1.5];
        hConstDiagm.YLimits = [-dataMaxLimit*1.5, dataMaxLimit*1.5];        
        hTimeScopes.YLimits = [-dataMaxLimit*2, dataMaxLimit*2];    
        timeCounter = timeCounter + RadioFrameTime;
    end
  end
catch ME
  rethrow(ME);
end

%% Visualize Signal
% You will notice a peak at 25 kHz corresponding to the received tone signal
% in frequency spectrum in Signal Analyzer. Depending on the quality of signal
% received, you may see a peak around DC and negative 25 kHz in frequency
% spectrum indicating existence of a DC offset and IQ imbalance
% respectively. You should see sinusoidal signals (real and imaginary) in
% the time domain, shown in the Time Scope display. In Constellation
% Diagram display, you should see a ring like plot visualizing the complex
% sinusoidal vector signal in the complex plane. The ring should be a
% perfect circle. Any warping of the circle is an indication of IQ
% imbalance.      
%
% <<zynqRadioToneReceiverFreqSpectrumAD9361AD9364ML.png>>
%
% <<zynqRadioToneReceiverTimeScopePlotAD9361AD9364ML.png>>
%
% <<zynqRadioToneReceiverConstDiagmPlotAD9361AD9364ML.png>>

%%
% Release the SDR Transmitter/Receiver and visualization scopes.

release(hSDRrx);
release(hSDRtx);
release(hSpectrum);
release(hTimeScopes);
release(hConstDiagm);

%% Conclusion
% In this example, you used SDR Transmitter and Receiver System objects to
% transmit a complex sinusoidal signal from the FPGA and receive it in the MATLAB. You
% visualized the received signal in time, frequency and on the complex plane. By
% performing this loopback test, you can confirm that the SDR system is
% setup correctly. You can now proceed to use it in conjunction with
% Communication System Toolbox to develop your baseband algorithms and
% verify using real world RF data.       
displayEndOfDemoMessage(mfilename)
