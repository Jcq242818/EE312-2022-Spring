%% QPSK Transmit Repeat Using Analog Devices AD9361/AD9364
%
% This example shows how to use the
% <matlab:sdrzdoc('sdrz_repeatedwaveformtx') Repeated Waveform Transmitter>
% feature of the Xilinx(R) Zynq-Based Radio Support Package with Analog
% Devices AD9361/AD9364 to continuously transmit QPSK data. Transmitted
% data can be sourced from a provided QPSK signal or generated using the
% companion <matlab:zynqRadioQPSKTransmitRepeatRecordSL
% zynqRadioQPSKTransmitRepeatRecordSL> model. The transmitted data can then
% be received and decoded on the existing MATLAB(R) and Simulink(R) based QPSK
% receivers, all while using a single radio.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting Started>
% documentation for details on configuring your host computer to work with
% the Support Package for Xilinx Zynq-Based Radio.

% Copyright 2015 The MathWorks, Inc.

%% Introduction
% 
% The <matlab:sdrzdoc('sdrz_repeatedwaveformtx') Repeated Waveform
% Transmitter> is a useful feature that allows recorded baseband data to be
% stored in hardware memory and repeatedly transmitted without gaps. The
% signal can then be received by the receiver on the same hardware. This
% example uses the *transmitRepeat* functionality to store and transmit
% pre-recorded QPSK data while using one of the MATLAB or Simulink QPSK
% receivers to capture and decode it on the same radio.

%% Setup
% 
% Before running the example, ensure you have performed the following
% steps:
%
% 1. Configure your host computer to work with the Support Package for
% Xilinx Zynq-Based Radio. See <matlab:sdrzdoc('sdrzspsetup')
% Getting Started> for help.
%
% 2. Any of the following examples can be used to receive and decode the
% data: 
%
% * The <matlab:showdemo('zynqRadioQPSKReceiverAD9361AD9364ML') QPSK
% Receiver Using Analog Devices(TM) AD9361/AD9364> MATLAB example.
% * The <matlab:showdemo('zynqRadioQPSKRxAD9361AD9364SL') QPSK Receiver
% Using Analog Devices AD9361/AD9364> Simulink example.
% * The <matlab:showdemo('zynqRadioQPSKRxFPGAAD9361AD9364SL') Targeting
% HDL Optimized QPSK Receiver Using Analog Devices AD9361/AD9364> Simulink
% example.

%% Running the Example
% 
% You can run this example by executing the
% <matlab:edit('zynqRadioQPSKTransmitRepeatAD9361AD9364ML') 
% zynqRadioQPSKTransmitRepeatAD9361AD9364ML> script.

%% Example Structure
% 
% This simple example shows how to use the transmitRepeat feature with
% recorded data to exercise a receiver algorithm:
%
% # Loads the provided data.
% # Creates the <matlab:sdrzdoc('commsdrtxzc706fmc23') SDR Transmitter>
% object, which will be used to communicate with the SDR hardware.
% # Uses the transmitRepeat method to store the QPSK data onto the hardware
% memory and continue transmitting until the release method is called.
%
%%
% *Load Data into the Workspace*
%
% A dataset called 'zynqRadioQPSKTransmitData.mat' has been provided, and
% can be loaded using the following command.

load('zynqRadioQPSKTransmitData.mat'); % Comment out if using own data from workspace

%%
% Alternatively you can load the companion
% <matlab:zynqRadioQPSKTransmitRepeatRecordSL
% zynqRadioQPSKTransmitRepeatRecordSL> model and generate your own custom
% dataset. In this case the load line can be commented out. See <#10
% Generating Custom Data for Transmission> for more information on
% generating your own data.

%%
% *Create the SDR Transmitter System Object*
%
% This example communicates with the radio hardware using the
% <matlab:sdrzdoc('commsdrtxzc706fmc23') SDR Transmitter> system object.
% By default the created object is set to communicate with the ZC706 and
% ADI FMCOMMS2/3/4 SDR hardware. If you are using different hardware you
% can replace the 'ZC706 and FMCOMMS2/3/4' string with the appropriate one
% for your system. The Center Frequency and Baseband Sample Rate should
% match those used in the receiver.

tx = sdrtx('ZC706 and FMCOMMS2/3/4', ...
              'BasebandSampleRate',      520.841e3, ...
              'CenterFrequency',         2.4e9, ...
              'ChannelMapping',          1, ...
              'ShowAdvancedProperties',  true, ...
              'BypassUserLogic',         true);

%%
% *Begin Transmission*
%
% The *transmitRepeat* method transfers the baseband QPSK transmission to
% the SDR platform, and stores the signal samples in hardware memory. The
% example then transmits the waveform continuously over the air without
% gaps until the release method for the transmit object is called.
% Messages are displayed in the command window to confirm that transmission
% has started successfully.

transmitRepeat(tx, zynqRadioQPSKTransmitData);

%%
% To end the transmission, call the release method (release(tx)) from the MATLAB command
% window.

%% Receiving the Data
%
% You can now run your receiver. QPSK modulated messages will be
% transmitted continuously from the radio and running a receiver will not
% affect the transmitted data. For best performance, attach antennas or a
% loopback cable between transmit and receive antennas.
%
% Execute the <matlab:edit('zynqRadioQPSKReceiverAD9361AD9364ML') zynqRadioQPSKReceiverAD9361AD9364ML> script
% after transmission has started and you should soon begin to see the
% decoded 'Hello World ###' messages.
%
% HDL-optimized models, such as <matlab:zynqRadioQPSKRxFPGAAD9361AD9364SL
% zynqRadioQPSKRxFPGAAD9361AD9364SL> can be run with or without targeting,
% however you should make sure that the targeted bitstream is already loaded
% before calling the *transmitRepeat* method.
%

%% Generating Custom Data for Transmission
%
% An example of how to generate a custom dataset for transmission is
% provided in the <matlab:zynqRadioQPSKTransmitRepeatRecordSL
% zynqRadioQPSKTransmitRepeatRecordSL> model. The model is based on the
% <matlab:zynqRadioQPSKTxAD9361AD9364SL zynqRadioQPSKTxAD9361AD9364SL> QPSK
% transmitter model, except now the data gets saved into a workspace
% variable rather than transmitted directly by the radio.
%
% Note that in order for the recorded data to be successfully stored in
% the hardware buffer, the data you create cannot result in less than
% *4096* samples or exceed *8 million* samples (4 million if using 2
% channels).
pause(1);
displayEndOfDemoMessage(mfilename)
