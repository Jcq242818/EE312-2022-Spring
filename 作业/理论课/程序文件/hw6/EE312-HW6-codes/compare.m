
% code
% Cell Configuration

ueConfig=struct('NULRB',6,'DuplexMode','FDD','CyclicPrefix','Normal');

prachConfig0=struct('Format',0,'SeqIdx',0,'PreambleIdx',0,'CyclicShiftIdx',1,'HighSpeed',0,'TimingOffset',0,'FreqIdx',0,'FreqOffset',0);
prachConfig1=struct('Format',1,'SeqIdx',0,'PreambleIdx',0,'CyclicShiftIdx',1,'HighSpeed',0,'TimingOffset',0,'FreqIdx',0,'FreqOffset',0);
prachConfig2=struct('Format',2,'SeqIdx',0,'PreambleIdx',0,'CyclicShiftIdx',1,'HighSpeed',0,'TimingOffset',0,'FreqIdx',0,'FreqOffset',0);
prachConfig3=struct('Format',3,'SeqIdx',0,'PreambleIdx',0,'CyclicShiftIdx',1,'HighSpeed',0,'TimingOffset',0,'FreqIdx',0,'FreqOffset',0);
ue.NULRB = 6;
ue.DuplexMode = 'FDD';

% Sequence
N_ZC = 839;

sequence = lteZadoffChuSeq(129, 839);

% DFT -> Subcarrier Mapping -> IFFT

preambleDFT = fft(sequence, N_ZC);

preamble864subcarriers = [ zeros(13,1); preambleDFT; zeros(12,1)];

preambleMapped = [ zeros(336,1); preamble864subcarriers; zeros(336,1)]; % Only ' conjugate the complex numbers as well!!!

preambleIFFT = ifft(preambleMapped,1536);

% ADD CP and Guard Band
% preamble for format 0 自己生成导频
CPpreambleGP0 = [preambleIFFT(end-198+1:end); preambleIFFT; zeros(186,1)];
figure(1);
x = 1:1:1920;
plot(x,abs(CPpreambleGP0));

% MATLAB LTE Toolbox Generation
% preamble for format 0 利用MATLAB Toolbox生成本地导频
[matlabPreamble0, ~]=ltePRACH(ueConfig,prachConfig0);
figure(2);
x = 1:1:1920;
plot(x,abs(matlabPreamble0));

figure(3)
stem(abs(xcorr(CPpreambleGP0,matlabPreamble0)))
title('Cross correlation between Preamble we generate and local Preamble (Format 0)')

% preamble for format 1
CPpreambleGP1 = [preambleIFFT(end-1313+1:end); preambleIFFT; zeros(991,1)];
figure(4);
x = 1:1:3840;
plot(x,abs(CPpreambleGP1));

% MATLAB LTE Toolbox Generation

[matlabPreamble1, ~]=ltePRACH(ueConfig,prachConfig1);
figure(5);
x = 1:1:3840;
plot(x,abs(matlabPreamble1));

figure(6)
stem(abs(xcorr(CPpreambleGP1,matlabPreamble1)))
title('Cross correlation between Preamble we generate and local Preamble (Format 1)')

% preamble for format 2
CPpreambleGP2 = [preambleIFFT(end-390+1:end); preambleIFFT; preambleIFFT; zeros(378,1)];
figure(7);
x = 1:1:3840;
plot(x,abs(CPpreambleGP2));

% MATLAB LTE Toolbox Generation

[matlabPreamble2, ~]=ltePRACH(ueConfig,prachConfig2);
figure(8);
x = 1:1:3840;
plot(x,abs(matlabPreamble2));

figure(9)
stem(abs(xcorr(CPpreambleGP2,matlabPreamble2)))
title('Cross correlation between Preamble we generate and local Preamble (Format 2)')

% preamble for format 3
CPpreambleGP3 = [preambleIFFT(end-1313+1:end); preambleIFFT; preambleIFFT;zeros(1375,1)];
figure(10);
x = 1:1:5760;
plot(x,abs(CPpreambleGP3));

% MATLAB LTE Toolbox Generation

[matlabPreamble3, info]=ltePRACH(ueConfig,prachConfig3);
figure(11);
x = 1:1:5760;
plot(x,abs(matlabPreamble3));

figure(12)
stem(abs(xcorr(CPpreambleGP3,matlabPreamble3)))
title('Cross correlation between Preamble we generate and local Preamble (Format 3)')

%不为同一个Preamble的互相关
figure(13)
stem(abs(xcorr(CPpreambleGP0,matlabPreamble1)))
title('Cross correlation between different Preamble(Format 0 and Format 1)')

figure(14)
stem(abs(xcorr(CPpreambleGP0,matlabPreamble2)))
title('Cross correlation between Preamble(Format 0 and Format 2)')

figure(15)
stem(abs(xcorr(CPpreambleGP0,matlabPreamble3)))
title('Cross correlation between Preamble(Format 0 and Format 3)')



