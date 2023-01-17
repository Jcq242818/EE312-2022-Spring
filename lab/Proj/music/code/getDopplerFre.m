function [dopplerF, range] = getDopplerFre(data,Ydeg,Xdeg)
%UNTITLED5 此处显示有关此函数的摘要
%   此处显示详细说明
shape = size(data);
rangeD = 80;


f = 2.12e9;                                        % frequency
c = 2.997e8;                                       % speed sound
d = 0.07;                                   % array element spacing
beamThetaY = Ydeg;
beamThetaX = Xdeg;



Y = data(1:8,10:end);
redirectedY = beamSteering(beamThetaY,Y);

X = data(9:12,:);
redirectedX = beamSteering(beamThetaX,X);
temp = -inf;
for c = 1 : 6
    for d = -rangeD:rangeD
        k = 1:shape(1,2);
        k = exp(1i*2*pi*d*k/25000000);
        
        Cor = abs(sum(redirectedX(1,10-c+1:10-c+length(Y)).*k(10:end).*conj(redirectedY(1,:))));
        if Cor > temp
            dopplerF = d;
            range = c*12;
            temp = Cor;
        end
        
    end
end

end

