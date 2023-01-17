clc;
clear;

SimParams.MasterClockRate = 100e6; %Hz
SimParams.Fs = 200e3; % Sample rate

% General simulation parameters
SimParams.M = 4; % M-PSK alphabet size
SimParams.Upsampling = 4; % Upsampling factor
SimParams.Downsampling = 2; % Downsampling factor
SimParams.Ts = 1/SimParams.Fs; % Sample time
SimParams.FrameSize = 100; % Number of modulated symbols per frame

% Tx parameters
SimParams.BarkerLength = 13; % Number of Barker code symbols
SimParams.DataLength = (SimParams.FrameSize - SimParams.BarkerLength)*2; % Number of data payload bits per frame
SimParams.MessageLength = 105; % Number of message bits per frame, 7 ASCII characters
SimParams.FrameCount = 100;
SimParams.ScramblerBase = 2;
SimParams.ScramblerPolynomial = [1 1 1 0 1];
SimParams.ScramblerInitialConditions = [0 0 0 0];

SimParams.RxBufferedFrames = 10; % Received buffer length (in frames)
SimParams.RCFiltSpan = 10; % Filter span of Raised Cosine Tx Rx filters (in symbols)

% Generate square root raised cosine filter coefficients (required only for MATLAB example)
SimParams.SquareRootRaisedCosineFilterOrder = SimParams.Upsampling*SimParams.RCFiltSpan;
SimParams.RollOff = 0.5;

% Square root raised cosine receive filter
hRxFilt = fdesign.decimator(SimParams.Upsampling/SimParams.Downsampling, ...
                'Square Root Raised Cosine', SimParams.Upsampling, ...
                'N,Beta', SimParams.SquareRootRaisedCosineFilterOrder, SimParams.RollOff);
hDRxFilt = design(hRxFilt, 'SystemObject', true);
SimParams.ReceiverFilterCoefficients = hDRxFilt.Numerator; 

% Rx parameters
K = 1;
A = 1/sqrt(2);
% Look into model for details for details of PLL parameter choice. Refer equation 7.30 of "Digital Communications - A Discrete-Time Approach" by Michael Rice. 
SimParams.PhaseErrorDetectorGain = 2*K*A^2+2*K*A^2; % K_p for Fine Frequency Compensation PLL, determined by 2KA^2 (for binary PAM), QPSK could be treated as two individual binary PAM
SimParams.PhaseRecoveryGain = 1; % K_0 for Fine Frequency Compensation PLL
SimParams.TimingErrorDetectorGain = 2.7*2*K*A^2+2.7*2*K*A^2; % K_p for Timing Recovery PLL, determined by 2KA^2*2.7 (for binary PAM), QPSK could be treated as two individual binary PAM, 2.7 is for raised cosine filter with roll-off factor 0.5
SimParams.TimingRecoveryGain = -1; % K_0 for Timing Recovery PLL, fixed due to modulo-1 counter structure
SimParams.CoarseCompFrequencyResolution = 50; % Frequency resolution for coarse frequency compensation
SimParams.PhaseRecoveryLoopBandwidth = 0.01; % Normalized loop bandwidth for fine frequency compensation
SimParams.PhaseRecoveryDampingFactor = 1; % Damping Factor for fine frequency compensation
SimParams.TimingRecoveryLoopBandwidth = 0.01; % Normalized loop bandwidth for timing recovery
SimParams.TimingRecoveryDampingFactor = 1; % Damping Factor for timing recovery

%SDRu receiver parameters
SimParams.USRPCenterFrequency = 900e6;
SimParams.USRPGain = 31;
SimParams.USRPDecimationFactor = SimParams.MasterClockRate/SimParams.Fs;
SimParams.USRPFrontEndSampleRate = 1/SimParams.Fs;
SimParams.USRPFrameLength = SimParams.Upsampling*SimParams.FrameSize*SimParams.RxBufferedFrames;

%Simulation parameters
SimParams.FrameTime = SimParams.USRPFrameLength/SimParams.Fs;
SimParams.StopTime = 100;

prmQPSKReceiver=SimParams ;
prmQPSKReceiver.Platform =  'N200/N210/USRP2';
prmQPSKReceiver.Address =  '192.168.10.2';

hRx = sdruQPSKRx( ...
        'DesiredAmplitude',               1/sqrt(prmQPSKReceiver.Upsampling), ...
        'ModulationOrder',                prmQPSKReceiver.M, ...
        'DownsamplingFactor',             prmQPSKReceiver.Downsampling, ...
        'CoarseCompFrequencyResolution',	prmQPSKReceiver.CoarseCompFrequencyResolution, ...
        'PhaseRecoveryLoopBandwidth',     prmQPSKReceiver.PhaseRecoveryLoopBandwidth, ...
        'PhaseRecoveryDampingFactor',     prmQPSKReceiver.PhaseRecoveryDampingFactor, ...
        'TimingRecoveryLoopBandwidth',    prmQPSKReceiver.TimingRecoveryLoopBandwidth, ...
        'TimingRecoveryDampingFactor',    prmQPSKReceiver.PhaseRecoveryDampingFactor, ...
        'PostFilterOversampling',         prmQPSKReceiver.Upsampling/prmQPSKReceiver.Downsampling, ...
        'PhaseErrorDetectorGain',         prmQPSKReceiver.PhaseErrorDetectorGain, ...
        'PhaseRecoveryGain',              prmQPSKReceiver.PhaseRecoveryGain, ...
        'TimingErrorDetectorGain',        prmQPSKReceiver.TimingErrorDetectorGain, ...
        'TimingRecoveryGain',             prmQPSKReceiver.TimingRecoveryGain, ...
        'FrameSize',                      prmQPSKReceiver.FrameSize, ...
        'BarkerLength',                   prmQPSKReceiver.BarkerLength, ...
        'MessageLength',                  prmQPSKReceiver.MessageLength, ...
        'SampleRate',                     prmQPSKReceiver.Fs, ...
        'DataLength',                     prmQPSKReceiver.DataLength, ...
        'ReceiverFilterCoefficients',     prmQPSKReceiver.ReceiverFilterCoefficients, ...
        'DescramblerBase',                prmQPSKReceiver.ScramblerBase, ...
        'DescramblerPolynomial',          prmQPSKReceiver.ScramblerPolynomial, ...
        'DescramblerInitialConditions',   prmQPSKReceiver.ScramblerInitialConditions,...
        'PrintOption',                    true);

  % Create and configure the SDRu System object. Set the SerialNum for B2xx
  % radios and IPAddress for X3xx, N2xx, and USRP2 radios. MasterClockRate
  % is not configurable for N2xx and USRP2 radios.

radio = comm.SDRuReceiver(...
        'IPAddress',            prmQPSKReceiver.Address, ...
        'CenterFrequency',      prmQPSKReceiver.USRPCenterFrequency, ...
        'Gain',                 prmQPSKReceiver.USRPGain, ...
        'DecimationFactor',     prmQPSKReceiver.USRPDecimationFactor, ...
        'FrameLength',          prmQPSKReceiver.USRPFrameLength, ...
        'OutputDataType',       'double');
    
hSpectrum = dsp.SpectrumAnalyzer(...
    'Name',             'Actual Frequency Offset',...
    'Title',            'Actual Frequency Offset', ...
    'SpectrumType',     'Power density',...
    'FrequencySpan',    'Full', ...
    'SampleRate',       200e3, ...
    'YLimits',          [-130,0],...
    'SpectralAverages', 50, ...
    'FrequencySpan',    'Start and stop frequencies', ...
    'StartFrequency',   -100e3, ...
    'StopFrequency',    100e3,...
    'Position',         figposition([50 30 30 40]));
% Initialize variables
errorIndex=0;
m=1;
%load ReceSignal.mat
while (true)
   %1. 从USRP读取IQ信号；
    [corruptSignal, len] = step(radio);
     %corruptSignal=ReceSignal(:,m);
     m=m+1;
   
    % len=400;
   %2. 如果未能成功读取我们希望的长度，报错
   if len < prmQPSKReceiver.USRPFrameLength 
      errorIndex = errorIndex+1;
      disp ( 'Not enough samples returned!' ) ;
      disp(errorIndex)
   else
       
  if m>=1200
      break;
  end

%     %3. 如果成功读取，画出接收信号的频谱图
      corruptSignal = corruptSignal - mean(corruptSignal);  % remove DC component
      step(hSpectrum, corruptSignal);  
%     
%    %4. 如果成功读取，画出接收信号的星座图
%      figure(1)
%      plot(corruptSignal(1:SimParams.Upsampling:end),'ro')
%     axis([-1 1 -1 1])
%      drawnow
% %   
%    %5. AGC（自动增益控制）以及匹配滤波后，得到RCRxSignal，频偏纠正得到coarseCompSignal，误码率计算得到BER
     [RCRxSignal,coarseCompSignal,BER]= step(hRx, corruptSignal);
%           
% %    %6. 画出匹配滤波后信号的星座图
%      figure(2)
%      plot(RCRxSignal(1:SimParams.Upsampling:end),'go')
%      axis([-1 1 -1 1])
%      drawnow    
% %     
% %     %7. 画出匹配滤波后信号的星座图
      figure(3)
      plot(coarseCompSignal(1:SimParams.Upsampling:end),'bo')
      axis([-1 1 -1 1])
      drawnow    
%     %8. 输出BER
%     %fprintf('Error rate is = %f.\n',BER(1))
    end
end    
release(hRx);
release(radio);
