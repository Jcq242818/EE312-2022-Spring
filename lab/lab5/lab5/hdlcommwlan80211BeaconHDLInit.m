function p80211hdl = hdlcommwlan80211BeaconHDLInit(p80211)

% Copyright MathWorks, Inc.

spreadingcode =  [ 1 1 -1 -1 1 1 1 1 -1 -1 1 1 1 1 1 1 -1 -1 -1 -1 -1 -1]';
syncsig =  p80211.SynchronizationSignal;
 tsync = zeros(128,1);

% find syncsig128
      for  m = 1:128
          yy = syncsig(1+22*(m-1):22*m);
         tsync(m,1) = yy'*spreadingcode; 
      end
syncsig128 = tsync/22;


p80211hdl.spreadingcode = spreadingcode;
p80211hdl.syncsig128 = syncsig128;

p80211hdl.tb = atan(2.^-[1:5]);
p80211hdl.rad_WL = 16;
p80211hdl.car_WL = 32;
p80211hdl.rad_FL = 13;
p80211hdl.car_FL =  26;

M= 2; 
L=4;
Naccu =  24;
p80211hdl.pInc_const = 2^Naccu/(M*(L+1)*44);

%p80211hdl.rcRxFilt = [0.0084136487845067817 -0.0012779096107435872 -0.023416382101133094 0.031830988618379061 0.040020036765270169 -0.10861435786336783 -0.053034100250923456 0.43511459293103077 0.76506964167771518 0.43511459293103077 -0.053034100250923456 -0.10861435786336783 0.040020036765270169 0.031830988618379061 -0.023416382101133094 -0.0012779096107435872 0.0084136487845067817];

N     = 20;   % Order
Fpass = 0.1;  % Passband Frequency
Fstop = 0.2;  % Stopband Frequency
decimRate = 44;

h = fdesign.decimator(decimRate, 'Lowpass', 'n,fp,fst', N, Fpass, Fstop);

Hd = design(h, 'equiripple', ...
  'StopbandShape', 'flat', 'SystemObject', true);
assignin('base','Hd',Hd);
%ts = p80211.SamplesPerChannelFrame / (p80211.ChipRate*p80211.SamplesPerChip)/2816;
p80211hdl.dataCount = (p80211.NumPLCPSamples+...
        p80211.ScramblerAmbiguitySamples+p80211.MaximumPayloadSamples)/22;
end