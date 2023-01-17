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
road = [];
temp = zeros(1,10);
temp2 = zeros(1,10);
temp3 = zeros(1,10);
Data_aoa1=Data_aoa(:,1:1247500);
Data_aoa2=Data_aoa(:,1247501:2495000);
Data_aoa3=Data_aoa(:,2495001:3742500);
Data_aoa4=Data_aoa(:,3742501:4990000);
Data_aoa5=Data_aoa(:,4990001:6237500);
Data_aoa6=Data_aoa(:,6237501:7485000);
Data_aoa7=Data_aoa(:,7485001:8732500);
Data_aoa8=Data_aoa(:,8732501:9980000);
Data_aoa9=Data_aoa(:,9980001:11227500);
Data_aoa10=Data_aoa(:,11227501:12475000);
data_all = [Data_aoa1,Data_aoa2,Data_aoa3,Data_aoa4,Data_aoa5, Data_aoa6 ,Data_aoa7,Data_aoa8,Data_aoa9,Data_aoa10];


for k = 0:9
    data = data_all(:,k*1247500+1:(k+1)*1247500);
    [temp(1,k+1), temp3(1,k+1)]= getDopplerFre(data,30,0); 
    temp2(1,k+1) = temp(1,k+1)*c/2/f;
end
road=zeros(1,11)
sum=0
DopplerFre= temp;
Range = temp3;
Speed = temp2;
for n=1:10
    sum=sum+temp2(n)*0.05;
    road(1,n+1)=sum;
end    

figure(1)
x=0:0.05:0.5;
plot(x,road,'LineWidth',3.5);
title('Distance verus Time', 'fontsize', 16);
xlabel('Time', 'fontsize', 16);
ylabel('Distance', 'fontsize', 16);

