function [RD] = getAmbiguity(data,Ydeg,Xdeg)
% calculate the ambiguity function
%   此处显示详细说明
shape = size(data);
rangeFd = 60;
rangeTau = 6;


f = 2.12e9;                                        % frequency
c = 2.997e8;                                       % speed sound
d = 0.07;                                   % array element spacing
beamThetaY = Ydeg;
beamThetaX = Xdeg;

fd = -rangeFd:2:rangeFd;
tau = 0:rangeTau;
RD = zeros(length(tau),length(fd));

Y = data(1:8,10:end);
redirectedY = beamSteering(beamThetaY,Y);

X = data(9:12,:);
redirectedX = beamSteering(beamThetaX,X);

col = 1;
for fd = -rangeFd:2:rangeFd
    row = 1;
    for tau = 0:rangeTau
        
        
        k = 1:shape(1,2);
        k = exp(1i*2*pi*fd*k/25000000);
        
        RD(row,col) = abs(sum(redirectedX(1,10-tau:10-tau+length(Y)-1).*k(10:end).*conj(redirectedY(1,:))));
        row = row + 1;
        bar = [row,col]
    end
    
    col = col + 1;
    
end


end

