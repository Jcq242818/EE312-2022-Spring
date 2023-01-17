function [redirectSignal] = beamSteering(deg, data)
%UNTITLED3 此处显示有关此函数的摘要
%   此处显示详细说明
X = data;
N = size(X);
N = N(1,1);
f = 2.12e9;                                        % frequency
c = 2.997e8;                                       % speed sound
d = 0.07;                                   % array element spacing
beamTheta = deg;
beamSteeringFactor = zeros(1,N);
beamSteeringMatrix = zeros(N,N);
for k = 1:N
    n = N - k;
    %beamSteeringMatrix(k,k) = exp(-(n)*1i*2*pi*f*d*cos(deg2rad(beamTheta))/c);
    beamSteeringMatrix(k,k) = exp(-(k-1)*1i*2*pi*f*d*sin(deg2rad(beamTheta))/c);
    %beamSteeringFactor(1,k) = exp(-(n)*1i*2*pi*f*d*cos(deg2rad(beamTheta))/c);
end

redirectSignal = sum(beamSteeringMatrix*X)/N;

end

