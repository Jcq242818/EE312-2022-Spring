load('data_aoa.mat')
a = size(Data_aoa);

noiseThreshold = 0.8;

f = 2.12e9;                                        % frequency
c = 2.997e8;                                       % speed sound

frameSize = 20000;
DopplerFre = [];
RangeAll = [];
Speed = [];
Range = [];
for deg = -60:1:60
    temp = [];
    temp2 = [];
    temp3 = [];
for k = 11:600000:a(1,2)-frameSize-2

    data = Data_aoa(:,k-10:k+frameSize);
    [temp(1,end+1), temp3(1,end+1)]= getDopplerFre(data,deg,0); %
    temp2(1,end+1) = temp(1,end)*c/2/f;
   

end
DopplerFre(end+1,:) = temp;
RangeAll(end+1,:) = temp3;
Speed(end+1,:) = sum(temp2)/length(temp2);
Range(end+1,:) = sum(temp3)/length(temp3);
deg
end
% DopplerFre;
% bar3(DopplerFre(4:15,:))
% title('Doppler Angle')
% ylabel('Angle')
% xlabel('Frame')
% zlabel('DopplerFre')

figure(2)
bar3(Speed)
title('Speed Angle')
ylabel('Angle')
xlabel('Frame')
zlabel('Speed')

figure(3)
deg = -60:1:60;
stem(deg,Speed)
title('Speed Angle', 'fontsize', 16);
xlabel('Theta(бу)', 'fontsize', 16);
ylabel('Speed(m/s)', 'fontsize', 16);
grid on;
Speed;

figure(4)
data = Data_aoa(1:8,k:k+frameSize);
[theta, music] = DOA_MUSICFB(data, noiseThreshold);
plot(theta, music, 'linewidth', 2);
title('Music Algorithm For Doa', 'fontsize', 16);
xlabel('Theta(бу)', 'fontsize', 16);
ylabel('Spatial Spectrum(dB)', 'fontsize', 16);
xlim([-60 60]);
grid on;

figure(5)
bar3(Range)
title('Range Angle')
ylabel('Angle')
xlabel('Frame')
zlabel('Range')