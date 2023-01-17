load('data_aoa.mat')
a = size(Data_aoa);

f = 2.12e9;                                       
c = 3e8;
DopplerF = zeros(1,10);
Speed = zeros(1,10);
Range = zeros(1,10);

for k = 0:9
    data = Data_aoa(:,k*1247500+1:(k+1)*1247500);
    [DopplerF(1,k+1), Range(1,k+1)]= getDopplerFre(data,30,0);
    Speed(1,k+1) = DopplerF(1,k+1)*c/2/f;
end

figure(1)
x=0:0.05:0.5;
DopplerF=[0 DopplerF];
scatter(x,DopplerF,'*')
title('Doppler Frequency vs Time', 'fontsize', 16);
xlabel('Time(m/s)', 'fontsize', 16);
ylabel('Dopper Frequency(Hz)', 'fontsize', 16);

road=zeros(1,11);
sum=0;
for n=1:10
    sum=sum+Speed(n)*0.05;
    road(1,n+1)=sum;
end    



figure(2)
plot(x,road,'LineWidth',3.5);
title('Distance verus Time', 'fontsize', 16);
xlabel('Time(s) ', 'fontsize', 16);
ylabel('Distance(m)', 'fontsize', 16);