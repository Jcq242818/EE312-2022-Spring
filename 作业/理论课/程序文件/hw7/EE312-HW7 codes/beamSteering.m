function [redirectSignal] = beamSteering(deg, data)
%����Ĳ���������:���յ������������뼸��������ɢ���źŵļн�
%���������Ŀ���Ǵӽ��յ����ź��лָ���ʼ�ź�s(t)(���ڽ���·�̲ÿ�����߽��յ����źŶ������һ����λ��ƫ��)
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

