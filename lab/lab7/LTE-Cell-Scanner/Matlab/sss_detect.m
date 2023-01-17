function peak_out = sss_detect(peak,capbuf,thresh2_n_sigma,fc,sampling_carrier_twist,tdd_flag, varargin)
% Perform maximum likelihood estimation of the SSS.
%初始化变量的赋值
peak_loc=peak.ind; % 记录PSS xcorr峰的位置
peak_freq=peak.freq; % 记录PSS xcorr峰对应的频率
n_id_2_est=peak.n_id_2; % 取PSS xcorr峰的n_id_2信息作为n_id_2的起始估计值
%1.81GHz为载波的中心频率，若载波sampling_carrier_twist的值为1，则接下来会对k_factor赋值（k_factor是莱斯信道的信道k因子）
%反之则将k_factor赋值为peak的k_factor属性值;
% % fc*k_factor is the receiver's actual RX center frequency.
if sampling_carrier_twist==1
    k_factor=(fc-peak.freq)/fc;
% else
%     k_factor=1;
else
    k_factor = peak.k_factor;
end
%确定我们采用的传输模式:时分复用或还是频分复用(TDD or FDD)
%即通过检测SSS，我们就可以知道小区是工作在FDD模式还是TDD模式
if tdd_flag == 1  %TDD模式下的赋值
    min_idx = 3*(128+32)+32;%假如系统工作在TDD模式下,设置盲检测的最小位置

    sss_ext_offset = 3*(128+32);
    sss_nrm_offset = 412;
else   %FDD模式下的赋值
    min_idx = 163-9;%假如系统工作在FDD模式下,设置盲检测的最小位置
    sss_ext_offset = 128+32;
    sss_nrm_offset = 128+9;
end
%TDD模式下寻找峰值
if (peak_loc<min_idx) % 对peakloc的值进行一定的改进，得到序列中初始位置的序号
  peak_loc=peak_loc+9600*k_factor;
end
 
pss_loc_set=peak_loc:9600*k_factor:length(capbuf)-125-9;
%在这里获得长度为16，间隔为9600的序列标识loc_set
% pss_loc_set=peak_loc + (0:9600:7*9600);
% pss_loc_set=peak_loc + (8*9600:9600:15*9600);
n_pss=length(pss_loc_set); %pss_loc_set的总长度为16
pss_np=NaN(1,n_pss);
%创建16*62空矩阵，并未赋值
h_raw=NaN(n_pss,62);
h_sm=NaN(n_pss,62);
%定义了普通循环前缀模式与拓展循环前缀模式(normal and extend)
sss_nrm_raw=NaN(n_pss,62);
sss_ext_raw=NaN(n_pss,62);
 
% % fo correction and ce by my method
% [~, td_pss] = pss_gen;
% tmp_store = zeros(n_pss, 128);
% pss_local = td_pss(:, n_id_2_est+1);
% pss_local = pss_local(10:end);
% pss_local_fft = fft(pss_local);
% for k=1:n_pss
%   pss_loc=round(pss_loc_set(k));
%   pss_dft_location=pss_loc + 9;
%   dft_in=fshift(capbuf(pss_dft_location:pss_dft_location+127),-peak_freq,fs_lte/16);
%   late = pss_loc - pss_loc_set(k);
%   fd_data = fft(dft_in);
%   fd_data = [fd_data(65:end) fd_data(1:64)];
%   fd_data = fd_data.*exp(1i.*2.*pi.*late./128);
%   fd_data = [fd_data(65:end) fd_data(1:64)];
%   fd_data(2:32) = fd_data(2:32)./(pss_local_fft(2:32).');
%   fd_data(98:end) = fd_data(98:end)./(pss_local_fft(98:end).');
% %   dft_in = ifft(fd_data);
%   tmp_store(k, :) = fd_data;
%   tmp_store(k, 1) = 0;
%   tmp_store(k, 33:97) = 0;
% %   
% %   figure;
% %   scatterplot(exp(1i.* angle(dft_in.*(pss_local'))) );
% end
% figure;
% subplot(2,1,1); plot(abs(tmp_store).');
% subplot(2,1,2); plot(angle(tmp_store).');
% return;
%在确定功能模式后，尝试检测SSS的确切位置。由于循环前缀的长度是未知的，会先进行盲检测，扫描SSS的一些可能的位置。
%随后，UE将使用最大似然估计和找到SSS可能出现的位置。
for k=1:n_pss % for循环的范围是1-16
  pss_loc=round(pss_loc_set(k));
  %在这个for循环中判断每次循环所查找到的PSS序列的位置
  %找到PSS进行傅里叶变换的位置
  pss_dft_location=pss_loc+9-2;
  %if (pss_dft_location+127>length(capbuf))
  %  break;
  %end
  %计算信道相应h
  %取出找到PSS进行傅里叶变换的位置后的128个数并进行移动
  %（也就是把信号下变频到基带信号）
  % 移动方法:将频率为0的部分，将其插入到频率谱的中心位置  
  dft_in=fshift(capbuf(pss_dft_location:pss_dft_location+127),-peak_freq,fs_lte/16);
  % TOC
  %将PSS的子帧移到末尾两位
  dft_in=[dft_in(3:end) dft_in(1:2)];
  %通过DFT得到结果
  dft_out=dft(dft_in);
  %去除相应的循环前缀，并取出其中62个元素放置到h_raw中第k行
  h_raw(k,:)=[dft_out(end-30:end) dft_out(2:32)];
  %共轭相乘，计算每一个子载波信号的信道响应
  h_raw(k,:)=h_raw(k,:).*conj(pss(n_id_2_est));
  %plot(angle(h_raw(k,:)));
  %ylim([-pi pi]);
  %drawnow;
  %pause
 
  % Smoothening... Basic...
  for t=1:62
%在这个for循环中定义了lt和rt
%通过查阅资料这是滑动平均窗口的起始点与终止点
    %arm_length=min([6 t-1 62-t]);
    lt=max([1 t-6]);
    rt=min([62 t+6]);
    % Growing matrix...
    %h_sm(k,t)=mean(h_raw(k,t-arm_length:t+arm_length));
    %计算hraw中从lt:rt总共7个元素的平均值，即平滑信道矩阵h
    h_sm(k,t)=mean(h_raw(k,lt:rt));
  end
  %估计噪声功率，由刚刚计算出来的均值减去各项的初始值即可得到噪声
  % Estimate noise power.
  pss_np(k)=sigpower(h_sm(k,:)-h_raw(k,:));
  
  % 在频域计算SSS
  %1.计算SSS的拓展循环前缀的位置
  sss_ext_dft_location=pss_dft_location-sss_ext_offset;
  %这里和上面第85-92行的代码注释是一样的，主要目的就是为了个DFT变换而做准备
  dft_in=fshift(capbuf(sss_ext_dft_location:sss_ext_dft_location+127),-peak_freq,fs_lte/16);
  % TOC
  dft_in=[dft_in(3:end) dft_in(1:2)];
  %进行DFT变换得到结果
  dft_out=dft(dft_in);
  %去除相应的循环前缀，并取出其中62个元素放置到h_raw中第k行
  sss_ext_raw(k,1:62)=[dft_out(end-30:end) dft_out(2:32)];
  
 
  % Calculate the SSS in the frequency domain (nrm)
  %2.计算SSS的普通循环前缀的位置
  sss_nrm_dft_location=pss_dft_location-sss_nrm_offset;
  dft_in=fshift(capbuf(sss_nrm_dft_location:sss_nrm_dft_location+127),-peak_freq,fs_lte/16);
  % TOC
  dft_in=[dft_in(3:end) dft_in(1:2)];
  dft_out=dft(dft_in);
  sss_nrm_raw(k,1:62)=[dft_out(end-30:end) dft_out(2:32)];
  %从132-137行的操作和计算拓展循环前缀时使用的操作是一样的，这里就不再解释了
end
 
if nargin == 6
    figure(4);
    %绘制平滑前和平滑后信道矩阵的模长与辐角
    subplot(2,2,1); pcolor(abs(h_raw)); shading flat; drawnow;
    subplot(2,2,2); pcolor(angle(h_raw)); shading flat; drawnow;
    subplot(2,2,3); pcolor(abs(h_sm)); shading flat; drawnow;
    subplot(2,2,4); pcolor(angle(h_sm)); shading flat; drawnow;
 
figure(5);
%取信道矩阵的前三行，绘制平滑前和平滑后信道矩阵的模长与辐角
    subplot(2,2,1); plot(abs(h_raw(1:3,:).'));drawnow;
    subplot(2,2,2); plot(angle(h_raw(1:3,:).')); drawnow;
    subplot(2,2,3); plot(abs(h_sm(1:3,:).')); drawnow;
    subplot(2,2,4); plot(angle(h_sm(1:3,:).')); drawnow;
end
 
% % interpolation along time to get accurate response at sss.
% h_sm_ext_interp = zeros(n_pss, 62);
% h_sm_nrm_interp = zeros(n_pss, 62);
% for t=1:62
%     h_sm_ext_interp(:,t) = interp1(pss_loc_set, h_sm(:,t), pss_loc_set-sss_ext_offset, 'linear','extrap');
%     h_sm_nrm_interp(:,t) = interp1(pss_loc_set, h_sm(:,t), pss_loc_set-sss_nrm_offset, 'linear','extrap');
% end
% 
% h_raw_ext_interp = zeros(n_pss, 62);
% h_raw_nrm_interp = zeros(n_pss, 62);
% for t=1:62
%     h_raw_ext_interp(:,t) = interp1(pss_loc_set, h_raw(:,t), pss_loc_set-sss_ext_offset, 'linear','extrap');
%     h_raw_nrm_interp(:,t) = interp1(pss_loc_set, h_raw(:,t), pss_loc_set-sss_nrm_offset, 'linear','extrap');
% end
% 
% pss_np_ext=zeros(1,n_pss);
% pss_np_nrm=zeros(1,n_pss);
% for k=1:n_pss
%     pss_np_ext(k)=sigpower(h_sm_ext_interp(k,:)-h_raw_ext_interp(k,:));
%     pss_np_nrm(k)=sigpower(h_sm_nrm_interp(k,:)-h_raw_nrm_interp(k,:));
% end
 
% ----recover original algorithm by using following 4 lines
%记录上述计算结果的值，直接复制一遍信道矩阵H和PSS的值?
h_sm_ext_interp = h_sm;
h_sm_nrm_interp = h_sm;
pss_np_ext = pss_np;
pss_np_nrm = pss_np;
 
% Combine results from different slots
%创建8个1*62的空向量，分别代表不同的slot里面的普通循环前缀模式和拓展循环前缀模式,目的是为了分配内存。
sss_h1_nrm_np_est=NaN(1,62);
sss_h2_nrm_np_est=NaN(1,62);
sss_h1_ext_np_est=NaN(1,62);
sss_h2_ext_np_est=NaN(1,62);
 
sss_h1_nrm_est=NaN(1,62);
sss_h2_nrm_est=NaN(1,62);
sss_h1_ext_est=NaN(1,62);
sss_h2_ext_est=NaN(1,62);
for t=1:62
  %利用for循环进行互相关计算
   %普通循环前缀模式
sss_h1_nrm_np_est(t)=real((1+ctranspose(h_sm_nrm_interp(1:2:end,t))*diag(1./pss_np_nrm(1:2:end))*h_sm_nrm_interp(1:2:end,t))^-1);
  sss_h2_nrm_np_est(t)=real((1+ctranspose(h_sm_nrm_interp(2:2:end,t))*diag(1./pss_np_nrm(2:2:end))*h_sm_nrm_interp(2:2:end,t))^-1);
 
  %拓展循环前缀模式sss_h1_ext_np_est(t)=real((1+ctranspose(h_sm_ext_interp(1:2:end,t))*diag(1./pss_np_ext(1:2:end))*h_sm_ext_interp(1:2:end,t))^-1);
  sss_h2_ext_np_est(t)=real((1+ctranspose(h_sm_ext_interp(2:2:end,t))*diag(1./pss_np_ext(2:2:end))*h_sm_ext_interp(2:2:end,t))^-1);
 
  % 计算通过信道矩阵H后的信号S
sss_h1_nrm_est(t)=sss_h1_nrm_np_est(t)*ctranspose(h_sm_nrm_interp(1:2:end,t))*diag(1./pss_np_nrm(1:2:end))*sss_nrm_raw(1:2:end,t);
  sss_h2_nrm_est(t)=sss_h2_nrm_np_est(t)*ctranspose(h_sm_nrm_interp(2:2:end,t))*diag(1./pss_np_nrm(2:2:end))*sss_nrm_raw(2:2:end,t);
 
  sss_h1_ext_est(t)=sss_h1_ext_np_est(t)*ctranspose(h_sm_ext_interp(1:2:end,t))*diag(1./pss_np_ext(1:2:end))*sss_ext_raw(1:2:end,t);
  sss_h2_ext_est(t)=sss_h2_ext_np_est(t)*ctranspose(h_sm_ext_interp(2:2:end,t))*diag(1./pss_np_ext(2:2:end))*sss_ext_raw(2:2:end,t);
end
 
% Maximum likelihood detection of SSS
%用最大似然估计算法检测SSS
%创建两个18=68*2的空矩阵，以便进行后面的处理
log_lik_nrm=NaN(168,2);
log_lik_ext=NaN(168,2);
for t=0:167
  %创建两个候选序列
  sss_h1_try=sss(t,n_id_2_est,0);
  sss_h2_try=sss(t,n_id_2_est,10);
 
%对普通循环前缀旋转候选序列以匹配接收序列。
%计算相位偏差量
  ang=angle(sum(conj([sss_h1_nrm_est sss_h2_nrm_est]).*[sss_h1_try sss_h2_try]));
  sss_h1_try=sss_h1_try*exp(j*-ang);
  sss_h2_try=sss_h2_try*exp(j*-ang);  %纠正相位偏差
  df=[sss_h1_try sss_h2_try]-[sss_h1_nrm_est sss_h2_nrm_est];
  log_lik_nrm(t+1,1)=sum(-[real(df) imag(df)].^2./repmat([sss_h1_nrm_np_est sss_h2_nrm_np_est],1,2));
 
%使用最大似然法判定SSS
%将h1与h2交换(通过临时变量temp)，重复上述操作来进行旋转
%对普通循环前缀和拓展循环前缀是一样的代码块
  temp=sss_h1_try;
  sss_h1_try=sss_h2_try;
  sss_h2_try=temp;
  ang=angle(sum(conj([sss_h1_nrm_est sss_h2_nrm_est]).*[sss_h1_try sss_h2_try]));
  sss_h1_try=sss_h1_try*exp(j*-ang);
  sss_h2_try=sss_h2_try*exp(j*-ang);
  df=[sss_h1_try sss_h2_try]-[sss_h1_nrm_est sss_h2_nrm_est];
  log_lik_nrm(t+1,2)=sum(-[real(df) imag(df)].^2./repmat([sss_h1_nrm_np_est sss_h2_nrm_np_est],1,2));
 
  %对拓展循环前缀旋转候选序列以匹配接收序列。(重复和上面完全相同的操作，因此这里不再解释)
  % Re-do for extended prefix
  % Rotate the candiate sequence to match the received sequence.
  temp=sss_h1_try;
  sss_h1_try=sss_h2_try;
  sss_h2_try=temp;
  ang=angle(sum(conj([sss_h1_ext_est sss_h2_ext_est]).*[sss_h1_try sss_h2_try]));
  sss_h1_try=sss_h1_try*exp(j*-ang);
  sss_h2_try=sss_h2_try*exp(j*-ang);
  df=[sss_h1_try sss_h2_try]-[sss_h1_ext_est sss_h2_ext_est];
  log_lik_ext(t+1,1)=sum(-[real(df) imag(df)].^2./repmat([sss_h1_ext_np_est sss_h2_ext_np_est],1,2));
 
  % Exchange h1 and h2 and re-do
  temp=sss_h1_try;
  sss_h1_try=sss_h2_try;
  sss_h2_try=temp;
  ang=angle(sum(conj([sss_h1_ext_est sss_h2_ext_est]).*[sss_h1_try sss_h2_try]));
  sss_h1_try=sss_h1_try*exp(j*-ang);
  sss_h2_try=sss_h2_try*exp(j*-ang);
  df=[sss_h1_try sss_h2_try]-[sss_h1_ext_est sss_h2_ext_est];
  log_lik_ext(t+1,2)=sum(-[real(df) imag(df)].^2./repmat([sss_h1_ext_np_est sss_h2_ext_np_est],1,2));
end
 
%判断所得SSS的循环前缀的类型，确定其模式是普通循环前缀还是拓展循环前缀
%warning('Check code here!!!!');
% cp_type_flag = 0;
if (max(log_lik_nrm(:))>max(log_lik_ext(:)))
  %如果普通循环前缀的对数似然函数更大,则判定为normal CP SSS 
  cp_type_est='normal';
  cp_type_flag = 0;
  log_lik=log_lik_nrm;
else
%如果拓展循环前缀的对数似然函数更大,则判定为normal CP SSS 

  cp_type_est='extended';
  cp_type_flag = 1;
  log_lik=log_lik_ext;
end
 
% frame_start是帧循环前缀的起始位置。
%帧的第一个DFT应该位于frame_start+cp_length
if tdd_flag==1
    if cp_type_flag == 0
        frame_start=peak_loc+(-(2*(128+9)+1)-1920-2)*k_factor; % TDD的普通循环前缀对应的起始位置
    else
        frame_start=peak_loc+(-(2*(128+32))-1920-2)*k_factor; % TDD的拓展循环前缀对应的起始位置
    end
else
    frame_start=peak_loc+(128+9-960-2)*k_factor; % FDD循环前缀对应的起始位置
end
%这块代码也是在寻找frame_start的起始位置
if (max(log_lik(:,1))>max(log_lik(:,2)))
  ll=log_lik(:,1);
else
  frame_start=frame_start+9600*k_factor;
  ll=log_lik(:,2);
end
frame_start=wrap(frame_start,0.5,2*9600+.5);
[lik_final, n_id_1_est]=max(ll);
n_id_1_est=n_id_1_est-1;  %获得n_id_1（SSS）的估计值
 
% 进行第二次阈值检查并更新输出的峰值peak_out的相关信息:比如重要的n_id_1（SSS）的估计值
L=[log_lik_nrm log_lik_ext];
L_mean=mean(L(:));%获得均值
L_var=var(L(:));
if nargin == 6
    figure(6);
    plot(0:167,[log_lik_nrm log_lik_ext],[0 167],repmat(L_mean,1,2),[0 167],repmat(L_mean+sqrt(L_var)*thresh2_n_sigma,1,2));%获得阈值
    zgo;
    drawnow;
end
peak_out=peak;
%判定阈值
%如果我们的似然函数比阈值小，则失败
if (lik_final<L_mean+sqrt(L_var)*thresh2_n_sigma)
  %disp('Thresh2 fail');
  %更新输出的峰值peak_out的相关信息
  peak_out.n_id_1=NaN;
  peak_out.cp_type='';
  peak_out.cp_type_val=-1;
  peak_out.frame_start=NaN;
  peak_out.duplex_mode=NaN;
else
  peak_out.n_id_1=n_id_1_est;%N_id_1的估计值
  peak_out.cp_type=cp_type_est;% 得到了循环前缀的类型
  peak_out.cp_type_val=cp_type_flag;
  peak_out.frame_start=frame_start;% 得到帧起始时刻
  peak_out.duplex_mode=tdd_flag;% 判断结果是TDD 还是 FDD
end