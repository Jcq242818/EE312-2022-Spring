%% Receive Tone Signal with Analog Devices FMCOMMS1
%
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package and Communications System Toolbox(TM) software to perform a simple
% loopback of a tone (sinusoid) signal in RF with Software Defined Radio
% (SDR) hardware. The system transmits a tone signal from numerically
% controlled oscillator (NCO) in FPGA fabric to RF card and receive the RF signal
% in MATLAB(R). This simple example confirms that the SDR hardware is setup
% correctly and shows how to capture RF data from SDR hardware in MATLAB. 

% Copyright 2014 The MathWorks, Inc.

%% Configure SDR Hardware
% If you are running this example after performing the setup of 
% hardware using Support Package Installer then you can skip this section.
% Otherwise, you can uncomment the following lines to open the GUI for setting up
% the SDR hardware and follow step-by-step procedure. See
% <matlab:sdrzdoc('sdrzspsetup')  Support Package Hardware Setup> for
% details on configuring your host computer to work with the SDR hardware. 
% Connect a loopback cable with attenuation between the 'RX' and 'TX' SMA
% connectors or attach appropriate antennae for 2.4 GHz.

%%
% 
% % zynqradio = sdrdev('ZC706 and FMCOMMS1 RevB/C'); % create an SDR device
% % setupSession(zynqradio);
% % launchSetupWizard(zynqradio); % open the GUI to set up the SDR hardware
%
%%
% Connect the antennae suitable for 2.4 GHz frequency range at both TX and
% RX SMA connectors on RF Card or use a loop-back cable between the two SMA
% connectors.
% 

%% Running the Example
% This example can be run by executing <matlab:edit('sdrzToneReceiver')
% sdrzToneReceiver.m>. By default, the example is configured to run with
% ZedBoard(TM) and ADI FMCOMMS1 hardware. You can run this example with
% Xilinx ZC706 and ADI FMCOMMS1 by uncommenting the following lines.

% % prmToneRx.SDRDeviceName = 'ZC706 and FMCOMMS1 RevB/C'';

% % prmToneRx.IPAddress = '192.168.3.2';

if ~exist('prmToneRx', 'var')
    prmToneRx.SDRDeviceName = 'ZedBoard and FMCOMMS1 RevB/C';
    prmToneRx.IPAddress = '192.168.3.2';
end

%% Transmit a Tone Signal from FPGA
% Set the tone generator (NCO) in the FPGA fabric to transmit a complex sinusoid
% to RF card. This NCO is built into the FPGA logic primarily to shift the
% signal to the intermediate frequency. For the purpose of this example we will
% be using this NCO as a source in FPGA logic to transmit data to RF card.
%
% Create a transmitter System object(TM) to configure the RF card settings. Set
% the RF card to transmit data at a center frequency of 2.4 GHz.
hSDRtx = sdrtx(prmToneRx.SDRDeviceName, ...
             'IPAddress',       prmToneRx.IPAddress, ...
             'CenterFrequency', 2.4e9);

%%
% Set the NCO to transmit a complex sinusoid of 4MHz 
hSDRtx.IntermediateFrequency = 4e6;

%%
% Set the 'SourceSelect' property of tranmsitter System object to 'Sine
% Generator'. Next, call step method to initiate the transmission of data
% from NCO to RF card.

hSDRtx.SourceSelect = 'Sine generator';
step(hSDRtx, complex(zeros(100,1)));

%%
% Note that the simultaneous transmission and reception of data
% from MATLAB to RF card (duplex) is currently not supported. Therefore, for
% this example the data is generated in FPGA fabric and transmitted directly to the
% RF card. Data is not transmitted from MATLAB in streaming fashion. 
 
%% Capture RF Signal
% To capture the RF tone signal into MATLAB create an SDR receiver System
% object and configure it to receive samples at a rate of approximately
% 25MSPS. Set the ADC sampling rate to 98.304 MHz (this is the maximum
% allowed by the ADI FMComms receiver System object) and the decimation
% factor to 4. Set the radio frame length, which is the number of samples
% received in each step call of the System object, to 4000. This will
% result in the  the baseband rate of 24.576 MHz at which data is received
% in MATLAB.

% Radio parameters
RadioADCRate = 98.304e6;
RadioDecimationFactor = 4;
RadioFrameLength = 4000;
RadioBasebandRate = RadioADCRate/RadioDecimationFactor;

% Create a receiver System object with desired radio parameters
hSDRrx = sdrrx(prmToneRx.SDRDeviceName, ...
             'IPAddress',        prmToneRx.IPAddress, ...
             'CenterFrequency',  2.4e9, ...
             'ADCRate',          RadioADCRate,...
             'DecimationFactor', RadioDecimationFactor, ...
             'FrameLength',      RadioFrameLength, ...
             'OutputDataType',   'double');
%%
% To visualize the received signal in frequency and time domain use
% Spectrum Analyzer and Time Scope System objects. In addition, set up a
% Constellation Diagram System object for plotting signal in two
% dimensional scatter diagram in the complex plane.   

% Call helper function to initialize scopes and position them
[hSpectrum, hTimeScopes, hConstDiagm] = ...
        zynqRadioToneReceiverPlotSetup(RadioBasebandRate);

%%
% Set the simulation time to 10 miliseconds in order to capture and
% visualize tone 10 miliseconds of baseband data.

StopTime        = 1e-2;                                      % seconds
RadioFrameTime  = (RadioFrameLength / RadioBasebandRate); % seconds
%%
%
% If the processing of received data in MATLAB is slower than the speed at
% which the data is captured, you will encounter loss of samples. This will
% be reflected by non-zero value of |lostSamps| variable. To ensure
% reception of contiguous data in MATLAB you can capture signals by
% enabling *burst mode* and by specifying the number of frames as the size of
% burst. In this mode, the specified amount of data is captured in a buffer
% first and later it is available for processing in MATLAB.           

numFramesinBurst = ceil(RadioBasebandRate*StopTime/RadioFrameLength);
hSDRrx.EnableBurstMode = true;
hSDRrx.NumFramesInBurst = numFramesinBurst;

%%
% Capture data from SDR receiver System object and visualize it in scopes
% by calling step methods of System objects in a loop.

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
% You will notice a peak at 4MHz corresponding to the received tone signal
% in frequency spectrum in Signal Analyzer. You should see sinusoidal
% signal (real and imaginary) in time domain in Time Scope window. For
% constellation diagram, you should see a ring like plot visualizing the
% tone signal vector in complex plane. Depending on the quality of signal
% received, you may see a peak around DC and negative 4 MHz in frequency
% spectrum indicating existence of a DC offset and IQ imbalance
% respectively. The existence of IQ imbalance can also be visualized by
% non-circular ring in constellation diagram.               
%
% <<sdrzToneReceiverFreqSpectrum.png>>
%
% <<sdrzToneReceiverTimeScopePlot.png>>
%
% <<sdrzToneReceiverConstDiagmPlot.png>>

%%
% Release the SDR Transmitter/Receiver and visualization scopes System
% objects. 

release(hSDRrx);
release(hSDRtx);
release(hSpectrum);
release(hTimeScopes);
release(hConstDiagm);

%% Conclusion
% In this example, you used SDR Transmitter and Receiver System objects to
% transmit a tone signal from FPGA and receive it in the MATLAB. You
% visualized the received signal in time, frequency and complex plane. By
% performing this loopback of a tone signal from FPGA to RF and receiving
% it back from RF to FPGA to MATLAB, you can confirm that the SDR system is
% setup correctly. You can now proceed to use it in conjunction with
% Communication System Toolbox to develop your baseband algorithms and
% verify using real time RF data.       
displayEndOfDemoMessage(mfilename)
