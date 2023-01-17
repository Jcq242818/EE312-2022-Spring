function estimate = linear_music(iwave,RX,~,dd)
derad=pi/180;
twpi=2*pi;

[EV,D]=eig(RX);
EVA=diag(D)';
[EVA,I]=sort(EVA);
EVA=fliplr(EVA);
EV=fliplr(EV(:,I));
En=EV(:,iwave+1:end);

for iang=1:361
    angle(iang)=(iang-181)/2;
    phim=derad*angle(iang);
    a=exp(-j*twpi*dd*sin(phim)).';
    SP(iang)=(a'*a)/(a'*En*En'*a);
end
SP=abs(SP);
[PKS,LOCS]= findpeaks(SP,'minpeakheight',1000);
estimate=(LOCS-181)/2;