%% QPSK Transmitter with Analog Devices FMCOMMS1
%
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package with MATLAB(R) to implement a QPSK transmitter. The SDR device in
% example model will keep transmitting indexed 'Hello world' messages at
% its specified center frequency. You can demodulate the transmitted
% message using the <matlab:showdemo('sdrzQPSKReceiver') QPSK Receiver with
% Analog Devices(TM) FMCOMMS1> example with additional SDR hardware.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting
% Started> documentation for details on configuring your host computer to
% work with the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2014 The MathWorks, Inc.

%% Introduction
% 
% This example transmits a QPSK signal over the air using SDR hardware. The
% transmitted packets are indexed 'Hello world' messages. This example has
% two main objectives:
%
% * Implement a prototype QPSK-based transmitter in MATLAB using
% SDR system objects from the Xilinx(R) Zynq-Based Radio Support Package.
%
% * Illustrate the use of key Communications System Toolbox(TM) System
% objects for QPSK system design.

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
% <matlab:sdrzdoc('sdrz_tworadios') Setup for Two Radios-One Host>
% for help.
%
% 2. Ensure that you have a suitable receiver. This example
% is designed to work in conjunction with any of the following possible
% receiver examples:
%
% * The <matlab:showdemo('sdrzQPSKReceiver') QPSK Receiver with Analog Devices FMCOMMS1>
% MATLAB example
% * The <matlab:showdemo('sdrzqpskrx') QPSK Receiver with Analog Devices FMCOMMS1>
% Simulink(R) example
% * The <matlab:showdemo('sdrzQPSKRxFPGA') Targeting HDL-Optimized QPSK Receiver
% with Analog Devices FMCOMMS1> Simulink example


%% Running the Example
%
% The example can be run by executing <matlab:edit('sdrzQPSKTransmitter')
% sdrzQPSKTransmitter.m>.
%
% The transmitter initialization script, 
% <matlab:edit('sdrzqpsktransmitter_init.m') sdrzqpsktransmitter_init.m>,
% initializes the simulation parameters and generates the structure
% _prmQPSKTransmitter_.

prmQPSKTransmitter = sdrzqpsktransmitter_init; % Transmitter parameter structure
%%
% Make sure that the _prmQPSKTransmitter.DesiredRFCenterFrequency_ variable
% specifies a signal center frequency that matches the receiver. With
% the default settings, the signal is transmitted at 2.415 GHz.
%
% By using the _compileIt_ and _useCodegen_ flags, you can interact with
% the code to explore different execution options.  Set the MATLAB variable
% _compileIt_ to _true_ and MATLAB will use the *codegen* command provided
% by the MATLAB Coder(TM) product to generate C code. The *codegen* command
% compiles MATLAB functions to a C-based static or dynamic library,
% executable, or MEX file, producing code for accelerated execution. The
% generated executable runs several times faster than the original MATLAB
% code. Set _useCodegen_ to _true_ to run the compiled executable generated
% by *codegen* instead of the MATLAB code.
%%
% By default, the example is configured to run with ZC706 and ADI FMCOMMS1 hardware. You can uncomment 
% one of the following lines, as applicable, to
% set the |SDRDeviceName| field in structure variable |prmQPSKTransmitter|.

% %prmQPSKTransmitter.SDRDeviceName = 'ZedBoard and FMCOMMS1 RevB/C';

% only needs called once per session, but multiple calls will cause no problems
prmQPSKTransmitter.SDRDeviceName = 'ZC706 and FMCOMMS1 RevB/C';
dev = sdrdev(prmQPSKTransmitter.SDRDeviceName);
setupSession(dev);
compileIt  = false; % true if code is to be compiled for accelerated execution 
useCodegen = false; % true to run the latest generated mex file


%% Transmitter Design: System Architecture
% 
% The code below either runs the transmitter directly or compiles and runs
% the compiled code based on the _compileIt_ and _useCodegen_ flags.
if compileIt
    fprintf('Compiling runSDRZQPSKTransmitter...');
    codegen('runSDRZQPSKTransmitter', '-args', {coder.Constant(prmQPSKTransmitter)});
    fprintf('done!\n');
end

if useCodegen
    fprintf('Running using compiled code\n');
    clear runSDRZQPSKTransmitter_mex
    runSDRZQPSKTransmitter_mex(prmQPSKTransmitter);
else
    fprintf('Running using uncompiled code\n');
    runSDRZQPSKTransmitter(prmQPSKTransmitter);
end

fprintf('\n==== Finished Transmission ====\n');

%%
% The function <matlab:edit('runSDRZQPSKTransmitter')
% runSDRZQPSKTransmitter> implements the QPSK transmitter using two top
% level system objects: <matlab:edit('QPSKTransmitter.m') QPSKTransmitter> and
% <matlab:sdrzdoc('commsdrtxzc706fmc1')
% SDR Transmitter>. For a Simulink block diagram of the
% system, refer to the <matlab:showdemo('sdrzqpsktx') QPSK Transmitter with
% Analog Devices FMCOMMS1 example using Simulink>.
%
% *SDR Transmitter*
%
% This example communicates with the radio hardware using the
% <matlab:sdrzdoc('commsdrtxzc706fmc1') SDR Transmitter> system object.
% 
% The parameter structure _prmQPSKTransmitter_ defines the control
% parameters for the radio. Changes to radio parameters _IPAddress_,
% _CenterFrequency_, _DACRate_, _IntermediateFrequency_ and
% _InterpolationFactor_ should be made in
% <matlab:edit('sdrzqpsktransmitter_init.m') sdrzqpsktransmitter_init.m>.
%
% *QPSK Transmitter*
%
% The custom <matlab:edit('QPSKTransmitter.m') QPSKTransmitter> object
% generates
% the baseband samples to be sent to the SDR transmitter. It is divided
% into a number of subcomponents, each modeled using system objects. A
% brief overview of each component is given below.
% 
% 1. *QPSKBitsGenerator:* Generates data frames. Each frame is 200 bits
% long. The first 26 bits are a frame header, and the remaining 174 bits
% represent a data payload. The payload is scrambled to guarantee a
% balanced distribution of zeroes and ones for the timing recovery operation
% in the receiver.
%
% * The 26 header bits result in a 13-symbol Barker code to use as a
% preamble. The preamble is used aid in overcoming channel impairments in
% the receiver.
% * The first 105 bits of the payload correspond to the ASCII
% representation of 'Hello world ###', where '###' is a repeating sequence
% of '001', '002', '003',..., '099'.
% * The remaining payload bits are random.
%
% 2. *comm.QPSKModulator:* Modulates pairs of bits from the output of the
% QPSKBitsGenerator object to QPSK constellation points. Each QPSK symbol
% is represented by one complex sample.
%
% 3. *dsp.FIRInterpolator:* Performs root raised cosine pulse shaping with
% a roll off factor of 0.5. It also upsamples the baseband signal by a
% factor of 4.


%% Alternative Implementations
%
% This example describes the MATLAB implementation of a QPSK transmitter
% with SDR Hardware. You can also view a Simulink implementation of this
% example in <matlab:showdemo('sdrzqpskrx') QPSK Transmitter with Analog Devices FMCOMMS1 using Simulink>.
%
% You can also explore a non-hardware QPSK transmitter and receiver example
% that models a general wireless communication system using an AWGN channel
% and simulated channel impairments with
% <matlab:showdemo('commQPSKTransmitterReceiver')
% commQPSKTransmitterReceiver>.


%% Troubleshooting the Example
% 
% If you run the example and you get the message |WARNING: SDR hardware Tx
% data buffer underflow!| in the command window, then the simulation ran
% slower than real time. To achieve real time processing, you can enable 
% the *Codegen* mode by setting the _compileIt_ and _useCodegen_ flags to true.
% The Codegen mode requires MATLAB Coder(TM)  installation. 
% You can also try the <matlab:sdrzdoc('sdrz_burstmode') burst mode>.
% 
% If you still fail to receive any messages, see
% <matlab:sdrzdoc('sdrz_troubleshoot') Xilinx Zynq-Based Radio Processing
% Errors and Fixes>.


%% List of Example Helper Files
%
% This example uses the following helper files:
%
% * <matlab:edit('runSDRZQPSKTransmitter.m') runSDRZQPSKTransmitter.m>: a
% codegen compatible function used to generate and transmit the QPSK signal
% using the SDR hardware.
% * <matlab:edit('sdrzqpsktransmitter_init.m') sdrzqpsktransmitter_init.m>:
% returns a structure of variables used to control the transmission.
% * <matlab:edit('QPSKTransmitter.m') QPSKTransmitter.m>: generates the
% baseband QPSK signal to be sent to the SDR hardware.
% * <matlab:edit('QPSKBitsGenerator.m') QPSKBitsGenerator.m>: generates the
% raw frames of bits to be transmitter.

displayEndOfDemoMessage(mfilename)