%load('data_aoa.mat')
a = size(Data_aoa);  % read data size
R = 1;               % set mode, 1: view reference signal 0: view passive signal
noiseThreshold = 0.95;  % set the noise space, P_cum/P>=noiseThreshold
%**************************************************************************%
% V = diag(V);                                    % vectorize eigenvalue matrix
% [V,idx] = sort(V,'descend');                    % sort the eigenvalues in descending order
% U = U(:,idx);                                   % reset the eigenvector
% P = sum(V);                                     % power of received data
% P_cum = cumsum(V);                              % cumsum of V
%**************************************************************************%

f = 2.12e9;                                        % frequency
c = 2.997e8;                                       % speed sound

% initial the gif
M = moviein(20);
if R == 0
    filename = 'passiveFB.gif';
else
    filename = 'referenceFB.gif';
end


frameSize = 20000;% set the number of samples in a gif frame
DopplerFre = [];
Range = [];
Speed = [];

for k = 11:600000:a(1,2)-frameSize-2
    if R == 0
        data = Data_aoa(1:8,k:k+frameSize);
    else
        data = Data_aoa(9:12,k:k+frameSize);
    end
    
    [theta, music] = DOA_MUSICFB(data, noiseThreshold);

    
    p = polarplot(deg2rad(theta),music);
    rmin = min(music);
    rmax = max(music);
    rlim([rmin rmax])

    M(:,end+1) = getframe;
    
    %gif printer
    [A,map] = rgb2ind(frame2im(getframe),256);
    if k == 11
        imwrite(A,map,filename,'gif', 'Loopcount',inf,'DelayTime',0.1);
    else
        imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',0.1);
    end
end

figure(4)
[theta, music] = DOA_MUSICFB(data, noiseThreshold);
plot(theta, music, 'linewidth', 2);
title('Music Algorithm For Doa', 'fontsize', 16);
xlabel('Theta(бу)', 'fontsize', 16);
ylabel('Spatial Spectrum(dB)', 'fontsize', 16);
xlim([-60 60]);
grid on;
