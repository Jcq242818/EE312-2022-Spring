% fss.m
% Code For Music Algorithm
% The Signals Are All Coherent
% Author:Ñ÷ÑòÑò
% Date£º2020/10/29

clc; clear all; close all;
%% -------------------------initialization-------------------------
f = 500;                                        % frequency
c = 1500;                                       % speed sound
lambda = c/f;                                   % wavelength
d = lambda/2;                                   % array element spacing
M = 20;                                         % number of array elements
N = 100;                                        % number of snapshot
K = 6;                                          % number of sources
coef = [1; exp(1i*pi/6);... 
        exp(1i*pi/3); exp(1i*pi/2);... 
        exp(2i*pi/3); exp(1i*2*pi)];            % coherence coefficient, K*1
doa_phi = [-30, 0, 20, 40, 60, 75];             % direction of arrivals

%% generate signal
dd = (0:M-1)'*d;                                % distance between array elements and reference element
A = exp(-1i*2*pi*dd*sind(doa_phi)/lambda);      % manifold array, M*K
S = sqrt(2)\(randn(1,N)+1i*randn(1,N));         % vector of random signal, 1*N
X = A*(coef*S);                                 % received data without noise, M*N
X = awgn(X,10,'measured');                      % received data with SNR 10dB

%% calculate the covariance matrix of received data and do eigenvalue decomposition
Rxx = X*X'/N;                                   % covariance matrix
[U,V] = eig(Rxx);                               % eigenvalue decomposition
V = diag(V);                                    % vectorize eigenvalue matrix
[V,idx] = sort(V,'descend');                    % sort the eigenvalues in descending order
U = U(:,idx);                                   % reset the eigenvector
P = sum(V);                                     % power of received data
P_cum = cumsum(V);                              % cumsum of V

%% define the noise space
J = find(P_cum/P>=0.95);                        % or the coefficient is 0.9
J = J(1);                                       % number of principal component
Un = U(:,J+1:end);

%% music for doa; seek the peek
theta = -90:0.1:90;                             % steer theta
doa_a = exp(-1i*2*pi*dd*sind(theta)/lambda);    % manifold array for seeking peak
music = abs(diag(1./(doa_a'*(Un*Un')*doa_a)));  % the result of each theta
music = 10*log10(music/max(music));             % normalize the result and convert it to dB

%% plot
figure;
plot(theta, music, 'linewidth', 2);
title('Music Algorithm For Doa', 'fontsize', 16);
xlabel('Theta(¡ã)', 'fontsize', 16);
ylabel('Spatial Spectrum(dB)', 'fontsize', 16);
grid on;

