function [theta, music] = DOA_MUSICFB(data, noiseThreshold)

% clc; clear; close all;
% load('data_5000000_5010000.mat')
%% -------------------------initialization-------------------------
% shape = size(data);
% X = data(1:8,1:1000);
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



%% reconstruct convariance matrix
%% calculate the covariance matrix of received data and do eigenvalue decomposition
Rxx = X*X'/N;                                   % origin covariance matrix
H = fliplr(eye(M));                             % transpose matrix
Rxxb = H*(conj(Rxx))*H;
Rxxfb = (Rxx+Rxxb)/2;
Rf = zeros(L_N, L_N);                           % reconstructed covariance matrix
for i = 1:L
    Rf = Rf+Rxxfb(i:i+L_N-1,i:i+L_N-1);
end
Rf = Rf/L;
[U,V] = eig(Rf);                                % eigenvalue decomposition
V = diag(V);                                    % vectorize eigenvalue matrix
[V,idx] = sort(V,'descend');                    % sort the eigenvalues in descending order
U = U(:,idx);                                   % reset the eigenvector
P = sum(V);                                     % power of received data
P_cum = cumsum(V);                              % cumsum of V

%% define the noise space
J = find(P_cum/P>=noiseThreshold);                        % or the coefficient is 0.95
J = J(1);                                       % number of principal component
Un = U(:,J+1:end);

%% music for doa; seek the peek
dd1 = (0:L_N-1)'*d;
theta = -90:0.1:90;                             % steer theta
doa_a = exp(-1i*2*pi*dd1*sind(theta)/lambda);   % manifold array for seeking peak
music = abs(diag(1./(doa_a'*(Un*Un')*doa_a)));  % the result of each theta
music = 10*log10(music/max(music));             % normalize the result and convert it to dB

%% plot
% figure(1);
% plot(theta, music, 'linewidth', 2);
% title('Music Algorithm For Doa', 'fontsize', 16);
% xlabel('Theta(掳)', 'fontsize', 16);
% ylabel('Spatial Spectrum(dB)', 'fontsize', 16);
% grid on;
% 
% figure(2)
% polarplot(deg2rad(theta),music)
% rmin = min(music);
% rmax = max(music);
% rlim([rmin rmax])
% AOA = 1;

end
