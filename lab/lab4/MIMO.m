%% MIMO
% model a 2x2 MIMO link with flat fading gains and 3 equalizer schemes: 
% Pre-coding, Zero-forcing and MMSE
% ** Pre-coding has perfect CSIT, where Zero-forcing and MMSE has CSIR

clear; close; clc;
%% Parameter Setup
M = 4;             % modulation order--------------------->调制阶数
k = log2(M);       % coded bits per symbol---------------->单符号传递比特数
nSyms = 1e4;       % number of symbols to send------------>发送符号总数
nBits = nSyms * k; % number of Bitsls to send------------->发送比特总数

nChan = 3;         % number of flat fading MIMO channels-->平坦衰落信道
EbNo = -10:2:30;   % Eb/No-------------------------------->信噪比
snrVector = EbNo + 10*log10(k); % Es/No before adding noise

% 2 x 2 MIMO channel
Mt = 2;            % ------------------------------------->发射机天线数
Mr = 2;            % ------------------------------------->接收机天线数

% initialize
berZeroForcing = zeros(nChan, length(snrVector));%-------->迫零算法
berMMSE = zeros(nChan, length(snrVector));%--------------->MMSE(最小均方)

%% Transmit Precoding and Receiver Shaping Scheme
% Reference
% Goldsmith, $Wireless\;Communications$ [pp. 323-324]

% Transmit precoding: x = V*(x_hat)
% Receiver shaping: (y_hat) = (U_hermitian_transposed)*y

[berPreCoding]=PreCoding(M,nBits,nChan,snrVector,Mt,Mr);%-->需要编写的函数

%% Zero Forcing Scheme
txData = zeros(Mt, 1, nBits);
rxData = zeros(Mr, 1, nBits);
W = zeros(Mr, Mt, nBits);

disp('MIMO zero forcing');
for i = 1:nChan
    fprintf('Channel: %d\n',i);
    % unique MIMO channel for 'Mr' receive and 'Mt' transmit antennas
    H = ( randn(Mr, Mt, nBits) + 1j*randn(Mr, Mt, nBits) ) / sqrt(2);

    % generate a sequence of random message bits and QAM modulate
    data = randi([0 M-1], Mt, 1, nBits);
    dataMod = qammod(data, M);
    
    for bit = 1:nBits
        % send over the fading channel
        txData(:,:,bit) = H(:,:,bit) * dataMod(:,:,bit);
    end
    
    fprintf('SNR:\t');
    for j = 1:length(snrVector)
       fprintf('%d\t',j);
       % add white Gaussian noise (x_noisy <-- x + noise)
       % double-sided white noise, (y_hat = U^(H) * y)
       noise = randn(Mr, 1, nBits) + 1j*randn(Mr, 1, nBits) / sqrt(2);
       txNoisy = txData +  noise * 10^(-snrVector(j)/10/2);
       
       for bit = 1:nBits
           % (1) W_{zf} = H_{Pseudoinverse} = (H^{H} * H)^{-1} * H^{H}
           W(:,:,bit) = (H(:,:,bit)' * H(:,:,bit))^-1 * H(:,:,bit)';
           rxData(:,:,bit) = W(:,:,bit) * txNoisy(:,:,bit);
           % (2) or simply solve linear system H*x = y for x, if full rank
           % rxData(:,:,bit) = H(:,:,bit) \ txNoisy(:,:,bit);
       end
       
       % QAM demodulate and compute bit error rate
       rxData = qamdemod(rxData,M);
       [~,berZeroForcing(i,j)] = biterr(data, rxData); 
    end
    fprintf('\n');
end
% take average of all 3 fading channels
berZeroForcing = mean(berZeroForcing);


%% MMSE Scheme
txData = zeros(Mt, 1, nBits);
rxData = zeros(Mr, 1, nBits);
W = zeros(Mr, Mt, nBits);

disp('MIMO MMSE');
for i = 1:nChan
    fprintf('Channel: %d\n',i);
    % unique MIMO channel for 'Mr' receive and 'Mt' transmit antennas
    H = ( randn(Mr, Mt, nBits) + 1j*randn(Mr, Mt, nBits) ) / sqrt(2);

    % generate a sequence of random message bits and QAM modulate
    data = randi([0 M-1], Mt, 1, nBits);
    dataMod = qammod(data, M);
    
    for bit = 1:nBits
        % send over the fading channel
        txData(:,:,bit) = H(:,:,bit) * dataMod(:,:,bit);
    end

    fprintf('SNR:\t');
    for j = 1:length(snrVector)
       fprintf('%d\t',j);
       % add white Gaussian noise (x_noisy <-- x + noise)
       % for double-sided white noise,  (y_hat = U^(H) * y)
       noise = randn(Mr, 1, nBits) + 1j*randn(Mr, 1, nBits) / sqrt(2);
       txNoisy = txData +  noise * 10^(-snrVector(j)/10/2);
       
       for bit = 1:nBits
           % add noise variations 
           W(:,:,bit) = (H(:,:,bit)' * H(:,:,bit) + ...
                      + eye(Mt)*10^(-snrVector(j)/10/2))^-1 * H(:,:,bit)';
           rxData(:,:,bit) = W(:,:,bit) * txNoisy(:,:,bit);
       end
       
       % QAM demodulate and compute bit error rate
       rxData = qamdemod(rxData,M);
       [~,berMMSE(i,j)] = biterr(data, rxData); 
    end
    fprintf('\n');
end
% take average of all 3 fading channels
berMMSE = mean(berMMSE);


%% MIMO BER Curves
figure;
semilogy(EbNo, berPreCoding,'-o', ...
         EbNo, berZeroForcing ,'-v', ...
         EbNo, berMMSE,'-s','LineWidth',1);
grid on;
xlim([EbNo(1)-2 EbNo(end)+2]);
title(sprintf('%d Tx x %d Rx MIMO: BER Curves by Equalizer, M = %d QAM', Mt, Mr, M));
set(gca, 'FontWeight','bold','LineWidth',1);
xlabel('Eb/No (dB)');
ylabel('Bit Error Rate (avg over 3 flat fading channels)');
legend('Pre-Coding','Zero Forcing','MMSE');
snapnow;
    
 
