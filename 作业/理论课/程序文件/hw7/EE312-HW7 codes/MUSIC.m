function [theta, result] = MUSIC(data, noiseThreshold)

X = data;
f = 2.12e9;                                        % frequency
c = 2.997e8;                                       % speed sound
lambda = c/f;                                   % wavelength
d = 0.07;                                   % array element spacing
M = size(X);                                         % number of array elements
M = M(1,1);
N = size(X);                                        % number of snapshot
N = N(1,2);
K = 1;                                          % number of sources
L = 1;                                         % number of subarray
L_N = M-L+1;                                    % number of array elements in each subarray



Rxx = X*X'/N;                                   % origin covariance matrix
[U,lanmuda] = eig(Rxx);                                % eigenvalue decomposition
lanmuda = diag(lanmuda);                                    % vectorize eigenvalue matrix
[lanmuda,idx] = sort(lanmuda,'descend');                    % sort the eigenvalues in descending order
U = U(:,idx);                                   % reset the eigenvector
P = sum(lanmuda);                                     % power of received data
P_sum = cumsum(lanmuda);                              % cumsum of V
Noise = find(P_sum/P>=Threshold);                        % or the coefficient is 0.95                                        % number of principal component
Un = U(:,Noise(1)+1:end);


theta = -90:0.5:90;                                         % steer theta
a_theta = exp(-1i*2*pi*((0:M-1)'*d)*sind(theta)/lambda);            % manifold array for seeking peak
result = abs(diag(1./(a_theta'*(Un*Un')*a_theta)));            % the result of each theta
result = 10*log10(result/max(result));                              % normalize the result and convert it to dB


end