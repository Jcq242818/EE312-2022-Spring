function[berPreCoding] = PreCoding(M,nBits,nChan,snrVector,Mt,Mr)

berPrecoding = zeros(nChan, length(snrVector));

U = zeros(Mr, Mt , nBits);
S= zeros(Mr, Mt , nBits);
V = zeros(Mr, Mt , nBits);
prefiltered = zeros(Mt, 1 , nBits);
txData = zeros(Mt, 1 , nBits);
rxData = zeros(Mt, 1 , nBits);

disp('MIMO precoding');
for i = 1:nChan
    fprintf('Channel:%d\n',i);
    H = (randn(Mr, Mt , nBits)+ 1j*randn(Mr, Mt , nBits))/sqrt(2);
    data = randi([0 M-1],Mt,1,nBits);
    dataMod = qammod(data,M);
    
    for bit = 1:nBits
        [U(:,:,bit),S(:,:,bit),V(:,:,bit)] = svd(H(:,:,bit));
        prefiltered(:,:,bit) = V(:,:,bit)*dataMod(:,:,bit);
        txData(:,:,bit) = H(:,:,bit) *prefiltered(:,:,bit);
    end
    fprintf('SNR:\t');
    
    for j = 1:length(snrVector)
        fprintf('%d\t',j);
        noise = randn(Mr,1,nBits) +  1j*randn(Mr,1,nBits)/sqrt(2);
        txNoisy = txData + noise * 10^(-snrVector(j)/10/2);
        
        for bit = 1:nBits
            rxData(:,:,bit) = U(:,:,bit)' * txNoisy(:,:,bit);
        end
        
        rxData = qamdemod(rxData,M);
        [~,berPreCoding(i,j)] = biterr(data,rxData);
    end
    fprintf('\n');
end
berPreCoding = mean(berPreCoding);
for j = 1:length(snrVector)
    fprintf('%d\t',j);
    noise = randn(Mr,1,nBits) +1j*randn(Mr,1,nBits)/sqrt(2);
    txNoisy = txData + noise*10^(-snrVector(j)/10/2);
    
    for bit = 1:nBits
        W(:,:,bit) = H(:,:,bit)' * H(:,:,bit)^-1*H(:,:,bit)';
        rxData(:,:,bit) = W(:,:,bit)*txNoisy(:,:,bit);
    end
    rxData = qamdemod(rxData,M);
     [~,berZeroForcing(i,j)] = biterr(data,rxData);
end

 for j = 1:length(snrVector)
    fprintf('%d\t',j);
    noise = randn(Mr,1,nBits) +1j*randn(Mr,1,nBits)/sqrt(2);
    txNoisy = txData + noise*10^(-snrVector(j)/10/2);
    
    for bit = 1:nBits
        W(:,:,bit) = (H(:,:,bit)' * H(:,:,bit) + ...
            + eye(Mt)*10^(-snrVector(j)/10/2))^-1*H(:,:,bit)';
        rxData(:,:,bit) = W(:,:,bit)*txNoisy(:,:,bit);
    end
    rxData = qamdemod(rxData,M);
     [~,berMMSE(i,j)] = biterr(data,rxData);
end
       
 
            
      
    