%% QPSK Receiver Using Analog Devices AD9361/AD9364
%
% This example shows how to use the Xilinx(R) Zynq-Based Radio Support
% Package and Communications System Toolbox(TM) software to implement a
% QPSK receiver in MATLAB(R). The receiver addresses practical issues in
% wireless communications, such as carrier frequency and phase offset,
% timing offset and frame synchronization. This system receives the signal
% sent by the <matlab:showdemo('zynqRadioQPSKTransmitterAD9361AD9364ML') QPSK Transmitter
% Using Analog Devices(TM) AD9361/AD9364> example. The receiver demodulates the received symbols
% and prints a simple message to the MATLAB command line.
%
% Refer to the <matlab:sdrzdoc('sdrzspsetup') Getting Started>
% documentation for details on configuring your host computer to work with
% the Support Package for Xilinx(R) Zynq-Based Radio.

% Copyright 2014-2015 The MathWorks, Inc.


%% Introduction
%
% This example receives a QPSK signal over the air using SDR hardware. It
% has two main objectives:
%
% * Implement a prototype QPSK-based receiver in MATLAB(R) using SDR System
% objects from the  Xilinx(R) Zynq-Based Radio Support Package.
%
% * Illustrate the use of key Communications System Toolbox(TM) System
% objects for QPSK system design.
%
% In this example, an <matlab:sdrzdoc('commsdrrxzc706fmc23')
% SDR Receiver> System object(TM) receives a signal impaired by
% the over-the-air transmission and outputs complex baseband signals that
% are processed by the <matlab:edit('sdrzQPSKRx.m') sdrzQPSKRx> object. This
% example provides a sample design of a practical digital receiver that can
% cope with wireless channel impairments. The receiver includes:
% 
% * FFT-based coarse frequency compensation
% * PLL-based fine frequency compensation
% * Timing recovery with fixed-rate resampling
% * Bit stuffing/skipping
% * Frame synchronization
% * Phase ambiguity correction


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
% <matlab:sdrzdoc('sdrz_tworadios') Setup For Two Radios-One Host>
% for help.
%
% 2. Ensure that a suitable signal is available for reception. This example
% is designed to work in conjunction with any of the following possible
% signal sources:
%
% * The <matlab:showdemo('zynqRadioQPSKTransmitterAD9361AD9364ML') QPSK Transmitter with
% Analog Devices AD9361/AD9364> MATLAB example.
% * The <matlab:showdemo('zynqRadioQPSKTxAD9361AD9364SL') QPSK Transmitter Using Analog Devices AD9361/AD9364> Simulink(R) example.
% * The <matlab:showdemo('zynqRadioQPSKTxFPGAAD9361AD9364SL') Targeting HDL-Optimized QPSK Transmitter Using Analog Devices AD9361/AD9364> Simulink example.


%% Running the Example
%
% The example can be run by executing <matlab:edit('zynqRadioQPSKReceiverAD9361AD9364ML.m')
% zynqRadioQPSKReceiverAD9361AD9364ML.m>. Make sure you have a suitable transmitter running
% before starting the receiver.

prmQPSKReceiver = zynqRadioQPSKReceiverAD9361AD9364ML_init; % Receiver parameter structure
%%
% The receiver initialization script, 
% <matlab:edit('zynqRadioQPSKReceiverAD9361AD9364ML_init.m') zynqRadioQPSKReceiverAD9361AD9364ML_init.m>,
% initializes the simulation parameters and generates the structure
% _prmQPSKReceiver_.
%
% Make sure that the _prmQPSKReceiver.CenterFrequency_ variable
% specifies a signal center frequency that matches the transmitter. With
% the default settings, the receiver expects the transmitted signal to be
% centered at 2.4 GHz. The expected signal
% center frequency can be changed by setting the
% _SimParams.CenterFrequency_ variable in the
% <matlab:edit('zynqRadioQPSKReceiverAD9361AD9364ML_init.m') zynqRadioQPSKReceiverAD9361AD9364ML_init.m> receiver initialization file.
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
%
% By default, the example is configured to run with ZC706 and ADI FMCOMMS2/3/4 hardware. 
% You can uncomment one of the following lines, as applicable, to
% set the |SDRDeviceName| field in structure variable |prmQPSKReceiver|.

% % prmQPSKReceiver.SDRDeviceName='ZedBoard and FMCOMMS2/3/4';
% % prmQPSKReceiver.SDRDeviceName='PicoZed SDR';

prmQPSKReceiver.SDRDeviceName = 'ZC706 and FMCOMMS2/3/4';
dev = sdrdev(prmQPSKReceiver.SDRDeviceName);
setupSession(dev);  % only needs called once per session, but multiple calls will cause no problems
compileIt  = true; % true if code is to be compiled for accelerated execution
useCodegen = true; % true to run the latest generated code (mex file) instead of MATLAB code

%%
% When you run the simulation, the received messages are decoded and
% printed out in the MATLAB command window while the simulation is running.
% If the received signal is decoded correctly, you should see 'Hello world
% 0##' messages in the MATLAB command line similar to those shown below.
% 
%  Hello world 031
%  Hello world 032
%  Hello world 033
%  Hello world 034
%  Hello world 035
%  Hello world 036
%  Hello world 037
%  Hello world 038
%  Hello world 039
%  Hello world 040
% 

%%
% BER information is shown at the end of the script execution. An example
% of the console output showing the receiver performance is shown below.
%
%  ==== Finished Reception ====
% 
%  Error rate is = 0.000453.
%  Number of detected errors = 119.
%  Total number of compared samples = 262710.
%

%%
% The calculation of the BER value includes the initial received frames.
% During this period some of the adaptive components of the QPSK receiver
% will not have converged yet and therefore the BER will be high.  Once the
% transient period is over, the receiver is able to estimate the
% transmitted frame and the BER improves. In this example, the default
% simulation duration is fairly short.  As such, the overall BER results
% are significantly affected by the high BER values at the beginning of the
% simulation. To increase the simulation duration and obtain lower BER
% values, you can change the _SimParams.StopTime_ variable in the
% <matlab:edit('zynqRadioQPSKReceiverAD9361AD9364ML_init.m') receiver initialization file>.

%% Receiver Design: System Architecture
% 
% The code below runs the receiver and returns the BER and if any samples
% were lost.

if compileIt
    fprintf('Compiling runZynqRadioQPSKReceiverAD9361AD9364ML...');
    codegen('runZynqRadioQPSKReceiverAD9361AD9364ML', '-args', {coder.Constant(prmQPSKReceiver)});
    fprintf('done!\n');
end
if useCodegen
    fprintf('Running using compiled code\n');
    fprintf('\n==== Starting Reception ====\n');
    clear runZynqRadioQPSKReceiverAD9361AD9364ML_mex
    [BER,lostSamples] = runZynqRadioQPSKReceiverAD9361AD9364ML_mex(prmQPSKReceiver);
else
    fprintf('Running using uncompiled code\n');
    fprintf('\n==== Starting Reception ====\n');
    [BER,lostSamples] = runZynqRadioQPSKReceiverAD9361AD9364ML(prmQPSKReceiver);
end

fprintf('\n==== Finished Reception ====\n\n');
fprintf('Error rate is = %f.\n',BER(1));
fprintf('Number of detected errors = %d.\n',BER(2));
fprintf('Total number of compared samples = %d.\n',BER(3));
if(lostSamples>0)
    fprintf('Lost samples detected.\n');
end


%%
% The function <matlab:edit('runZynqRadioQPSKReceiverAD9361AD9364ML.m') runZynqRadioQPSKReceiver>
% implements the QPSK receiver using two system objects:
% <matlab:edit('sdrzQPSKRx.m') sdrzRadioQPSKRx> and
% <matlab:sdrzdoc('commsdrrxzc706fmc23')
% SDR Receiver>. For a Simulink block diagram of the
% system, refer to the <matlab:showdemo('zynqRadioQPSKReceiverAD9361AD9364ML')
% QPSK Receiver Using
% Analog Devices AD9361/AD9364 example using Simulink>.
%
% *SDR Receiver*
%
% This example communicates with the radio hardware using the
% *commsdrrxzc706fmc23* system object.
% 
% * You can supply the IP address of the radio hardware as an argument when
% the object is constructed. The IP address of the radio can be any address
% within the same sub-network as the host computer. This example configures
% the SDR Receiver system object to use the default
% address 192.168.3.2. See
% <matlab:sdrzdoc('manual_sdrzspsetup') Support Package
% Hardware Setup> for additional information on setting IP addresses.
% * The parameter structure _prmQPSKReceiver_ defines the
% _CenterFrequency_, _GainSource_, SamplesPerFrame', _BasebandSampleRate_ and _Gain_.
%
% *QPSK Receiver*
%
% The <matlab:edit('sdrzQPSKRx.m') sdrzQPSKRx> component attempts to
% retrieve the original transmitted message. It is divided into a number of
% subcomponents, each modeled using system objects. Each subcomponent is
% modeled by other subcomponents that also use system objects, creating a
% reusable hierarchy of code. A brief overview of the five main receiver
% sections is given below.
% 
% # *Automatic Gain Control (AGC):* Sets its output amplitude to
% _1/sqrt(Upsampling Factor)_ (0.5), so that the equivalent gains of the
% phase and timing error detectors keep constant over time. The AGC is
% placed before the *Raised Cosine Receive Filter*, so that the signal
% amplitude can be measured with an oversampling factor of four. This
% process improves the accuracy of the estimate.
% # *Coarse Frequency Compensation:* Uses nonlinearity and a Fast Fourier
% Transform (FFT) to roughly estimate the frequency offset and then
% compensate for it. The object raises the input signal to the power of
% four to obtain a signal that is not a function of the QPSK modulation. It
% then performs an FFT on the modulation-independent signal to estimate the
% tone at four times the frequency offset. After dividing the estimate by
% four, the *Phase/Frequency Offset* system object corrects the frequency
% offset.
% # *Fine Frequency Compensation:* Performs closed-loop scalar processing
% and compensates for the frequency offset accurately. The Fine Frequency
% Compensation object implements a phase-locked loop (PLL) to track the
% residual frequency offset and the phase offset in the input signal. For
% more information, see Chapter 7 of [ <#13 1> ]. The PLL uses a *Direct
% Digital Synthesizer (DDS)* to generate the compensating phase that
% offsets the residual frequency and phase offsets. The phase offset
% estimate from *DDS* is the integral of the phase error output of the
% *Loop Filter*. To obtain details of PLL design, refer to Appendix C.2 of
% [ <#13 1> ].
% # *Timing Recovery:* Performs timing recovery with closed-loop scalar
% processing to overcome the effects of delay introduced by the channel.
% The *Timing Recovery* object implements a PLL, described in Chapter 8 of
% [ <#13 1> ], to correct the timing error in the received signal. The *NCO
% Control* object implements a decrementing modulo-1 counter described in
% Chapter 8.4.3 of [ <#13 1> ] to generate the control signal for the
% *Modified Buffer* to select the interpolants of the *Interpolation
% Filter*. This control signal also enables the *Timing Error Detector
% (TED)*, that then calculates the timing errors at the correct timing
% instants. The *NCO Control* object updates the timing difference for the
% *Interpolation Filter* , generating interpolants at optimum sampling
% instants. The *Interpolation Filter* is a Farrow parabolic filter with
% alpha set to 0.5 as described in Chapter 8.4.2 of [ <#13 1> ]. Based on
% the interpolants, timing errors are generated by a zero-crossing *Timing
% Error Detector* as described in Chapter 8.4.1 of [ <#13 1> ]. They are
% then filtered by a tunable proportional-plus-integral *Loop Filter* as
% described in Appendix C.2 of [ <#13 1> ], and fed into the *NCO Control*
% for a timing difference update. The _Loop Bandwidth_ (normalized by the
% sample rate) and _Loop Damping Factor_ are tunable for the *Loop Filter*.
% The default normalized loop bandwidth is set to 0.01 and the default
% damping factor is set to 1 for critical damping. These settings make sure
% that the PLL quickly locks to the correct timing while introducing little
% phase noise.
% # *Data Decoder:* Uses a Barker code to perform frame synchronization and
% phase ambiguity resolution, followed by signal demodulation. It also
% compares the regenerated message with the transmitted message and
% calculates the BER.


%% Alternative Implementations
%
% This example describes the MATLAB implementation of a QPSK receiver with
% SDR Hardware. You can also view a Simulink implementation of this
% example in <matlab:showdemo('zynqRadioQPSKRxAD9361AD9364SL') QPSK Receiver Using Analog Devices AD9361/AD9364
% using Simulink>.
%
% You can also explore a non-hardware QPSK transmitter and receiver example
% that models a general wireless communication system using an AWGN channel
% and simulated channel impairments with
% <matlab:showdemo('commQPSKTransmitterReceiver')
% commQPSKTransmitterReceiver>.


%% Troubleshooting the Example
% 
% If you fail to successfully receive any 'Hello world' messages, try the
% troubleshooting steps below:
% 
% * If you run the example and _lost samples are detected_, then the code
% ran slower than real time. Set the _compileIt_ and _useCodegen_ flags to
% _true_ to try to achieve real-time performance. If the example still runs
% slower than real time, you can try using
% <matlab:sdrzdoc('sdrz_burstmode') burst mode>.
% * The ability to decode the received signal depends on the received
% signal strength. If the message is not properly decoded by the receiver
% system, you can vary the gain applied to the received signal in the
% *commsdrrxzc706fmc23* system object by changing the _SimParams.RadioGain_
% value with the manual gain control mode or by changing the
% _prmFreqCalibRx.RadioGainControlMode_ to 'AGC Fast Attack' or 'AGC Slow
% Attack' in the <matlab:edit('zynqRadioQPSKReceiverAD9361AD9364ML_init.m')
% receiver initialization file>.
% * A large relative frequency offset between the transmit and receive
% radios can prevent the receiver from properly decoding the message.  If
% that happens, you can determine the offset by sending a tone at a known
% frequency from the transmitter to the receiver, and then measuring the
% offset between the transmitted and received frequency. This value can
% then be used to compensate the center frequency of the receiver block.
% See the <matlab:showdemo('zynqRadioFrequencyCalibrationTxAD9361AD9364SL') Frequency Offset Calibration
% Using Analog Devices AD9361/AD9364> example.
% 
% If you still fail to receive any messages, see
% <matlab:sdrzdoc('sdrz_troubleshoot') Xilinx Zynq-Based Radio Processing
% Errors and Fixes>.


%% List of Example Helper Files
%
% This example uses the following helper files:
%
% * <matlab:edit('runZynqRadioQPSKReceiverAD9361AD9364ML.m') runZynqRadioQPSKReceiver.m>: a codegen
% compatible function used to receive the QPSK signal using the SDR
% hardware and then try to decode it.
% * <matlab:edit('zynqRadioQPSKReceiverAD9361AD9364ML_init.m') zynqRadioqpskreceiver_init.m>:
% returns a structure of variables used to control the reception.
% * <matlab:edit('sdrzQPSKRx.m') sdrzQPSKRx.m>: a high level system object
% that implements the QPSK signal synchronization, demodulation and
% decoding.
% * <matlab:edit('sdrzQPSKDataDecoder.m') sdrzQPSKDataDecoder.m>: a lower
% level system object that implements the low level demodulation, decoding
% and BER comparison.
% * <matlab:edit('QPSKCoarseFrequencyCompensator.m')
% QPSKCoarseFrequencyCompensator.m>: a system object that
% implements coarse frequency compensation.
% * <matlab:edit('QPSKFineFrequencyCompensator.m')
% QPSKFineFrequencyCompensator.m>: a system object that performs fine
% frequency compensation.
% * <matlab:edit('QPSKTimingRecovery.m') QPSKTimingRecovery.m>: a System
% object that performs symbol timing recovery.


%% References
%
% 1. Rice, Michael. _Digital Communications - A Discrete-Time Approach_.
% 1st ed. New York, NY: Prentice Hall, 2008.


displayEndOfDemoMessage(mfilename)
