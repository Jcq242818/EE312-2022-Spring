%% QPSK Transmitter and Receiver
% This example shows a digital communications system using QPSK modulation.
% The example uses Communications System objects to simulate the QPSK
% transceiver. In particular, this example illustrates
% methods to address real-world wireless communications issues like carrier
% frequency and phase offset, timing recovery and frame synchronization.

%   Copyright 2011-2016 The MathWorks, Inc.

%% Implementations
% This example describes the MATLAB implementation of the QPSK transceiver.
%
% MATLAB script using System objects:
% <matlab:edit([matlabroot,'\toolbox\comm\commdemos\commQPSKTransmitterReceiver.m'])
% commQPSKTransmitterReceiver.m>.
%
% For a Simulink(R) implementation using blocks, check:
% <matlab:commqpsktxrx commqpsktxrx.slx>.

%% Introduction
% The transmitted QPSK data undergoes impairments that simulate the effects
% of wireless transmission such as addition of Additive White Gaussian
% Noise (AWGN), introduction of carrier frequency and phase offset, and
% timing delay. To cope with these impairments, this example provides a
% reference design of a practical digital receiver. The receiver includes
% FFT-based coarse frequency compensation, PLL-based fine frequency
% compensation, PLL-based symbol timing recovery, frame synchronization,
% and phase ambiguity resolution.
%
% This example serves three main purposes:
%
% * To model a general wireless communication system that is able to
% successfully recover a message, which was corrupted by various simulated  
% channel impairments.
%
% * To illustrate the use of key Communications System Toolbox(TM) System objects 
% for QPSK system design, including coarse and fine carrier frequency 
% compensation, closed-loop timing recovery with bit stuffing and stripping, 
% frame synchronization, carrier phase ambiguity resolution, and message 
% decoding.
%
% * To illustrate the creation of higher level System objects that contain
% other System objects in order to model larger components of the system
% under test

%% Initialization
% The <matlab:edit('commqpsktxrx_init.m') commqpsktxrx_init.m> script
% initializes simulation parameters and generates the structure prmQPSKTxRx. 
prmQPSKTxRx = commqpsktxrx_init % QPSK system parameters 

useScopes = true; % true if scopes are to be used
printReceivedData = true; %true if the received data is to be printed
compileIt = false; % true if code is to be compiled
useCodegen = false; % true to run the generated mex file

%% Code Architecture for the System Under Test
% This example models a digital communication system using QPSK modulation.
% The function runQPSKSystemUnderTest models this communication
% environment. The QPSK transceiver model in this script is divided into 
% the following four main components. 
%
% 1) QPSKTransmitter: generates the bit stream and then encodes, modulates
% and filters it.
%
% 2) QPSKChannel: models the channel with carrier offset, timing
% offset, and AWGN.
%
% 3) QPSKReceiver: models the receiver, including components for phase 
% recovery, timing recovery, decoding, demodulation, etc.
%
% 4) QPSKScopes: optionally visualizes the signal using time scopes,
% frequency scopes, and constellation diagrams.
%
% Each component is modeled using a System object. To see the construction 
% of the four main System object components, refer to 
% <matlab:edit([matlabroot,'\toolbox\comm\commdemos\runQPSKSystemUnderTest.m']) runQPSKSystemUnderTest.m>. 

%% Description of the Individual Components
% *Transmitter*
% 
% This component generates a message using ASCII characters, converts the characters to 
% bits, and prepends a Barker code for receiver frame synchronization. This 
% data is then modulated using QPSK and filtered with a square root
% raised cosine filter.
%
% *Channel*
%
% This component simulates the effects of over-the-air transmission. It
% degrades the transmitted signal with both phase and frequency offset, a time-varying 
% delay to mimic clock skew between transmitter and receiver, and AWGN.
%
% *Receiver*
%
% This component regenerates the original transmitted message. It is
% divided into six subcomponents, modeled using System objects. 
%
% 1) Automatic Gain Control: Sets its output power to _1/sqrt(Upsampling
% Factor)_ (0.5) so that the input amplitude of the *Coarse Frequency
% Compensation* subcomponent is stable and roughly one.  This ensures that
% the equivalent gains of the phase and timing error detectors keep
% constant over time. The AGC is placed before the *Raised Cosine Receive
% Filter* so that the signal amplitude can be measured with an oversampling
% factor of four. This process improves the accuracy of the estimate.
%
% 2) Coarse frequency compensation: Uses nonlinearity and a Fast Fourier
% Transform (FFT) to roughly estimate the frequency offset and then
% compensate for it. The frequency offset is estimated by using a
% *comm.PSKCoarseFrequencyEstimator* System object and the compensation is
% performed by using a *comm.PhaseFrequencyOffset* System object. 
%
% 3) Fine frequency compensation: Performs closed-loop scalar processing
% and compensates for the frequency offset accurately, using a
% *comm.CarrierSynchronizer* System object. The object implements a
% phase-locked loop (PLL) to track the residual frequency offset and the
% phase offset in the input signal.
%
% 4) Timing recovery: Performs timing recovery with closed-loop scalar
% processing to overcome the effects of delay introduced by the channel,
% using a *comm.SymbolSynchronizer* System object. The object implements a
% PLL to correct the symbol timing error in the received signal. The
% Zero-Crossing timing error detector is chosen for the object in this
% example. The input to the object is a fixed-length frame of samples. The
% output of the object is a frame of symbols whose length can vary due
% stuffing and stripping, depending on actual channel delays. 
%
% 5) Frame Synchronization: Performs frame synchronization with the known
% Barker code and, meanwhile, convert the variable-length symbol inputs
% into fixed-length outputs, using a *FrameFormation* System object for
% examples. The step method of the object has a secondary output that is a
% boolean scalar indicating if the first frame output is valid.
% 
% 6) Data decoder: Performs phase ambiguity resolution and demodulation.
% Also, the data decoder compares the regenerated message with the
% transmitted one and calculates the BER.
%
% *Scopes*
%
% This component provides optional visualization by plotting the following
% diagrams:
%
% * a time scope showing the normalized time delay,
%
% * a spectrum scope depicting the received signal after square root raised
% cosine filtering,
%
% * constellation diagrams showing the received signal after receiver
% filtering, and then after carrier phase.
%
% For more information about the system components, refer to the  
% <matlab:showdemo('commqpsktxrx') QPSK Transmitter and Receiver example
% using Simulink>.

%% System Under Test
% The main loop in the system under test script processes the data
% frame-by-frame. Set the MATLAB variable compileIt to true in order to
% generate code; this can be accomplished by using the *codegen* command
% provided by the MATLAB Coder(TM) product. The *codegen* command
% translates MATLAB(R) functions to a C++ static or dynamic library,
% executable, or to a MEX file, producing a code for accelerated execution.
% The generated C code runs several times faster than the original MATLAB
% code. For this example, set useCodegen to true to use the code generated
% by *codegen* instead of the MATLAB code.
%
% The inner loop of runQPSKSystemUnderTest uses the four System objects previously
% mentioned. There is a for-loop around the system under test to process one frame at a
% time.
%
%  for count = 1:prmQPSKTxRx.FrameCount
%      transmittedSignal = step(hTx);
%      corruptSignal = step(hChan, transmittedSignal, count);
%      [RCRxSignal,coarseCompBuffer, timingRecBuffer,BER] = step(hRx,corruptSignal);
%      if useScopes
%          stepQPSKScopes(hScopes,RCRxSignal,coarseCompBuffer, timingRecBuffer);
%      end
%  end

%% Execution and Results
% To run the System Under Test script and obtain BER values for the
% simulated QPSK communication, the following code is executed.
% When you run the simulations, it displays the bit error rate data, and 
% some graphical results. The figures displayed are, respectively:
%
% 1) Constellation diagram of the *Raised Cosine Receive Filter* output.
%
% 2) Power spectrum of the *Raised Cosine Receive Filter* output.
%
% 3) Constellation diagram of the *Fine Frequency Compensation* output.
%
% 4) Estimated (fractional) timing error from the *Timing Recovery*.

if compileIt
    codegen -report runQPSKSystemUnderTest.m -args {coder.Constant(prmQPSKTxRx),coder.Constant(useScopes),coder.Constant(printReceivedData)} %#ok
end
if useCodegen
    BER = runQPSKSystemUnderTest_mex(prmQPSKTxRx, useScopes, printReceivedData);  
else
    BER = runQPSKSystemUnderTest(prmQPSKTxRx, useScopes, printReceivedData);
end
fprintf('Error rate = %f.\n',BER(1));
fprintf('Number of detected errors = %d.\n',BER(2));
fprintf('Total number of compared samples = %d.\n',BER(3));

%% Alternate Execution Options
% As already mentioned in the section *Run System Under Test*, by using the
% global variables at the beginning of the example, it is possible to
% interact with the code to explore different aspects of System objects and
% coding options.
%
% By default, the variables useScopes and printReceivedData are set to true
% and false, respectively. The useScopes variable enables MATLAB scopes
% to be opened during the example execution. Using the scopes, you can see how the
% simulated subcomponent behave and also obtain a better understanding of how the
% system functions in simulation time. When you set this variable to false,
% the scopes will not open during the example execution. When you set 
% printReceivedData to true, you can also see the decoded received packets 
% printed in the command window. The other two variables, compileIt and 
% useCodegen, are related to speed performance and can be used to analyze 
% design tradeoffs.
% 
% When you set compileIt to true, this example script will use MATLAB Coder(TM)
% capabilities to compile the script runQPSKSystemUnderText for accelerated
% execution. This command will create a MEX file (runQPSKSystemUnderTest_mex)
% and save it in the current folder. Once you set useCodegen to true to
% run the mex file, the example is able to run the system
% implemented in MATLAB much faster. This feature is essential for
% implementation of real-time systems and is an important simulation tool. 
% To maximize simulation speed, set useScopes to false and useCodegen to true
% to run the mex file.
%
% For other exploration options, refer to the 
% <matlab:showdemo('commqpsktxrx') QPSK Transmitter and Receiver example
% using Simulink>.
% 
%% Summary
% This example utilizes several System objects to simulate digital
% communication over an AWGN channel. It shows how to model several parts
% of the QPSK system such as modulation, frequency and phase recovery,
% timing recovery, and frame synchronization. It measures the system
% performance by calculating BER. It also shows that the generated C code
% runs several times faster than the original MATLAB code.

%% Appendix
% This example uses the following script and helper functions:
%
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\runQPSKSystemUnderTest.m']) runQPSKSystemUnderTest.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\QPSKTransmitter.m']) QPSKTransmitter.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\QPSKChannel.m']) QPSKChannel.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\QPSKReceiver.m']) QPSKReceiver.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\QPSKScopes.m']) QPSKScopes.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\QPSKBitsGenerator.m']) QPSKBitsGenerator.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\QPSKDataDecoder.m']) QPSKDataDecoder.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\FrameFormation.m']) FrameFormation.m>

%% References
% 1. Rice, Michael. _Digital Communications - A Discrete-Time
% Approach_. 1st ed. New York, NY: Prentice Hall, 2008.

displayEndOfDemoMessage(mfilename)
