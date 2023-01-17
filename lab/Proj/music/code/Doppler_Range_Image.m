%load('data_aoa.mat')
Ydeg = 30;
Xdeg = 0;
rangeFd = 60;
rangeTau = 8;
RD = getAmbiguity(Data_aoa,Ydeg,Xdeg);

%%
mind = min(RD,[],'all');
maxd = max(RD,[],'all');

figure(1);
colormap jet;
RD = RD/maxd;
disIndex = 0:rangeTau;
dopIndex = -rangeFd:2:rangeFd;
imagesc(dopIndex, disIndex, 20 * log10(abs(RD)));
mind = min(20*log10(abs(RD)),[],'all')
maxd = max(20*log10(abs(RD)),[],'all')
set(gca,'CLim',[mind maxd]);
xlabel('Doppler/Hz');
ylabel('Range/m');
h = colorbar;
set(get(h,'Title'),'string','dB');