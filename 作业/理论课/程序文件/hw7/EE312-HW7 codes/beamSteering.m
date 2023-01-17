function [redirectSignal] = beamSteering(deg, data)
%输入的参数有两个:接收到的天线数据与几根天线与散射信号的夹角
%这个函数的目的是从接收到的信号中恢复初始信号s(t)(由于接收路程差，每根天线接收到的信号都会存在一个相位的偏差)
X = data;
N = size(X);
N = N(1,1);
f = 2.12e9;                                       
c = 2.997e8;                                       
d = 0.07;                                   
beamTheta = deg;
beamSteeringMatrix = zeros(N,N);
for k = 1:N
    beamSteeringMatrix(k,k) = exp(-(k-1)*1i*2*pi*f*d*sin(deg2rad(beamTheta))/c);
end

redirectSignal = sum(beamSteeringMatrix*X)/N;

end

