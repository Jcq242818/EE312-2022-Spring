%%
rangeFd = 60;
rangeTau = 8;
mind = min(RD,[],'all')
maxd = max(RD,[],'all')
figure(1);
colormap jet;
RD = RD/maxd;


disIndex = 12*[0:rangeTau];
dopIndex = -rangeFd:2:rangeFd;
imagesc(dopIndex, disIndex, 20 * log10(abs(RD)));
mind = min(20*log10(abs(RD)),[],'all')
maxd = max(20*log10(abs(RD)),[],'all')
set(gca,'CLim',[  -67.6763 maxd]);
h = colorbar;
set(get(h,'Title'),'string','dB');
xlabel('Doppler/Hz');
ylabel('Range/m');
title('Range-Doppler')

%%
mind = min(RD,[],'all')
maxd = max(RD,[],'all')
figure(1);
colormap jet;
RD(:,29:33) = mind;
disIndex = 0:rangeTau;
dopIndex = -rangeFd:2:rangeFd;
imagesc(dopIndex, disIndex, RD);
mind = min(RD,[],'all')
maxd = max(RD,[],'all')
set(gca,'CLim',[mind maxd]);
xlabel('Doppler/Hz');
ylabel('Range/m');
colorbar;