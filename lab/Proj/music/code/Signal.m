derad = pi/180;         %角度转弧度
radeg = 180/pi;         %弧度转角度
twpi = 2*pi;
%输入阵列配置参数：阵元数量、阵元坐标（间距）
kelm = 12;              % 阵列数量（阵元数量）
dd = 0.5;               % 阵元间距d = lambda/2  （阵元间距与波长的比值）
d=0:dd:(kelm-1)*dd;     % 阵元序列
iwave = 3;              % 信号源数目
%构建阵元接收信号
theta = [0 55 80];      % 入射信号角度
snr = 10;               
n = 12475000;                %快拍个数(采样点数)
A=exp(-j*twpi*d.'*sin(theta*derad)); %构建信号导向矢量矩阵
S=randn(iwave,n);       %（randn生成标准正态分布随机数 3*n的）  (空间信号源矩阵)
X=A*S;
X1=awgn(X,snr,'measured'); %加入高斯白噪声
                           %（将白高斯噪声添加到向量信号x中。标量snr指定了每一个采样点信号与噪声的比率，单位为dB。先测了x的能量）
Rxx=X1*X1'/n;
F=rank(Rxx);
angle=linear_music(iwave,Rxx,kelm,d);