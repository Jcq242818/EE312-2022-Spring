
% code

% Cell Configuration

ueConfig=struct('NULRB',6,'DuplexMode','FDD','CyclicPrefix','Normal');

prachConfig=struct('Format',0,'SeqIdx',0,'PreambleIdx',0,'CyclicShiftIdx',1,'HighSpeed',0,'TimingOffset',0,'FreqIdx',0,'FreqOffset',0);

ue.NULRB = 6;

ue.DuplexMode = 'FDD';

% Sequence

N_ZC = 839;

sequence = lteZadoffChuSeq(129, 839);

% DFT -> Subcarrier Mapping -> IFFT

preambleDFT = fft(sequence, N_ZC);

preamble864subcarriers = [ zeros(13,1); preambleDFT; zeros(12,1)];

% preambleMapped = [ zeros(336,1); preamble864subcarriers; zeros(336,1)]; % Only ' conjugate the complex numbers as well!!!

preambleIFFT = ifft(preamble864subcarriers,800);

% ADD CP and Guard Band

CPpreambleGP0 = [preambleIFFT(end-103+1:end); preambleIFFT; zeros(97,1)];
x = 1:1:length(CPpreambleGP0);
figure(1);
plot(x,abs(CPpreambleGP0));

CPpreambleGP1 = [preambleIFFT(end-684+1:end); preambleIFFT; zeros(516,1)];
x = 1:1:length(CPpreambleGP1);
figure(2);
plot(x,abs(CPpreambleGP1));

CPpreambleGP2 = [preambleIFFT(end-203+1:end); preambleIFFT; preambleIFFT; zeros(197,1)];
x = 1:1:length(CPpreambleGP2);
figure(3);
plot(x,abs(CPpreambleGP2));

CPpreambleGP3 = [preambleIFFT(end-684+1:end); preambleIFFT; preambleIFFT; zeros(716,1)];
x = 1:1:length(CPpreambleGP3);
figure(4);
plot(x,abs(CPpreambleGP3));




