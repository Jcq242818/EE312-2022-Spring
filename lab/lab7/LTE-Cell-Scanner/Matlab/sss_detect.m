function peak_out = sss_detect(peak,capbuf,thresh2_n_sigma,fc,sampling_carrier_twist,tdd_flag, varargin)
% Perform maximum likelihood estimation of the SSS.
%��ʼ�������ĸ�ֵ
peak_loc=peak.ind; % ��¼PSS xcorr���λ��
peak_freq=peak.freq; % ��¼PSS xcorr���Ӧ��Ƶ��
n_id_2_est=peak.n_id_2; % ȡPSS xcorr���n_id_2��Ϣ��Ϊn_id_2����ʼ����ֵ
%1.81GHzΪ�ز�������Ƶ�ʣ����ز�sampling_carrier_twist��ֵΪ1������������k_factor��ֵ��k_factor����˹�ŵ����ŵ�k���ӣ�
%��֮��k_factor��ֵΪpeak��k_factor����ֵ;
% % fc*k_factor is the receiver's actual RX center frequency.
if sampling_carrier_twist==1
    k_factor=(fc-peak.freq)/fc;
% else
%     k_factor=1;
else
    k_factor = peak.k_factor;
end
%ȷ�����ǲ��õĴ���ģʽ:ʱ�ָ��û���Ƶ�ָ���(TDD or FDD)
%��ͨ�����SSS�����ǾͿ���֪��С���ǹ�����FDDģʽ����TDDģʽ
if tdd_flag == 1  %TDDģʽ�µĸ�ֵ
    min_idx = 3*(128+32)+32;%����ϵͳ������TDDģʽ��,����ä������Сλ��

    sss_ext_offset = 3*(128+32);
    sss_nrm_offset = 412;
else   %FDDģʽ�µĸ�ֵ
    min_idx = 163-9;%����ϵͳ������FDDģʽ��,����ä������Сλ��
    sss_ext_offset = 128+32;
    sss_nrm_offset = 128+9;
end
%TDDģʽ��Ѱ�ҷ�ֵ
if (peak_loc<min_idx) % ��peakloc��ֵ����һ���ĸĽ����õ������г�ʼλ�õ����
  peak_loc=peak_loc+9600*k_factor;
end
 
pss_loc_set=peak_loc:9600*k_factor:length(capbuf)-125-9;
%�������ó���Ϊ16�����Ϊ9600�����б�ʶloc_set
% pss_loc_set=peak_loc + (0:9600:7*9600);
% pss_loc_set=peak_loc + (8*9600:9600:15*9600);
n_pss=length(pss_loc_set); %pss_loc_set���ܳ���Ϊ16
pss_np=NaN(1,n_pss);
%����16*62�վ��󣬲�δ��ֵ
h_raw=NaN(n_pss,62);
h_sm=NaN(n_pss,62);
%��������ͨѭ��ǰ׺ģʽ����չѭ��ǰ׺ģʽ(normal and extend)
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
%��ȷ������ģʽ�󣬳��Լ��SSS��ȷ��λ�á�����ѭ��ǰ׺�ĳ�����δ֪�ģ����Ƚ���ä��⣬ɨ��SSS��һЩ���ܵ�λ�á�
%���UE��ʹ�������Ȼ���ƺ��ҵ�SSS���ܳ��ֵ�λ�á�
for k=1:n_pss % forѭ���ķ�Χ��1-16
  pss_loc=round(pss_loc_set(k));
  %�����forѭ�����ж�ÿ��ѭ�������ҵ���PSS���е�λ��
  %�ҵ�PSS���и���Ҷ�任��λ��
  pss_dft_location=pss_loc+9-2;
  %if (pss_dft_location+127>length(capbuf))
  %  break;
  %end
  %�����ŵ���Ӧh
  %ȡ���ҵ�PSS���и���Ҷ�任��λ�ú��128�����������ƶ�
  %��Ҳ���ǰ��ź��±�Ƶ�������źţ�
  % �ƶ�����:��Ƶ��Ϊ0�Ĳ��֣�������뵽Ƶ���׵�����λ��  
  dft_in=fshift(capbuf(pss_dft_location:pss_dft_location+127),-peak_freq,fs_lte/16);
  % TOC
  %��PSS����֡�Ƶ�ĩβ��λ
  dft_in=[dft_in(3:end) dft_in(1:2)];
  %ͨ��DFT�õ����
  dft_out=dft(dft_in);
  %ȥ����Ӧ��ѭ��ǰ׺����ȡ������62��Ԫ�ط��õ�h_raw�е�k��
  h_raw(k,:)=[dft_out(end-30:end) dft_out(2:32)];
  %������ˣ�����ÿһ�����ز��źŵ��ŵ���Ӧ
  h_raw(k,:)=h_raw(k,:).*conj(pss(n_id_2_est));
  %plot(angle(h_raw(k,:)));
  %ylim([-pi pi]);
  %drawnow;
  %pause
 
  % Smoothening... Basic...
  for t=1:62
%�����forѭ���ж�����lt��rt
%ͨ�������������ǻ���ƽ�����ڵ���ʼ������ֹ��
    %arm_length=min([6 t-1 62-t]);
    lt=max([1 t-6]);
    rt=min([62 t+6]);
    % Growing matrix...
    %h_sm(k,t)=mean(h_raw(k,t-arm_length:t+arm_length));
    %����hraw�д�lt:rt�ܹ�7��Ԫ�ص�ƽ��ֵ����ƽ���ŵ�����h
    h_sm(k,t)=mean(h_raw(k,lt:rt));
  end
  %�����������ʣ��ɸոռ�������ľ�ֵ��ȥ����ĳ�ʼֵ���ɵõ�����
  % Estimate noise power.
  pss_np(k)=sigpower(h_sm(k,:)-h_raw(k,:));
  
  % ��Ƶ�����SSS
  %1.����SSS����չѭ��ǰ׺��λ��
  sss_ext_dft_location=pss_dft_location-sss_ext_offset;
  %����������85-92�еĴ���ע����һ���ģ���ҪĿ�ľ���Ϊ�˸�DFT�任����׼��
  dft_in=fshift(capbuf(sss_ext_dft_location:sss_ext_dft_location+127),-peak_freq,fs_lte/16);
  % TOC
  dft_in=[dft_in(3:end) dft_in(1:2)];
  %����DFT�任�õ����
  dft_out=dft(dft_in);
  %ȥ����Ӧ��ѭ��ǰ׺����ȡ������62��Ԫ�ط��õ�h_raw�е�k��
  sss_ext_raw(k,1:62)=[dft_out(end-30:end) dft_out(2:32)];
  
 
  % Calculate the SSS in the frequency domain (nrm)
  %2.����SSS����ͨѭ��ǰ׺��λ��
  sss_nrm_dft_location=pss_dft_location-sss_nrm_offset;
  dft_in=fshift(capbuf(sss_nrm_dft_location:sss_nrm_dft_location+127),-peak_freq,fs_lte/16);
  % TOC
  dft_in=[dft_in(3:end) dft_in(1:2)];
  dft_out=dft(dft_in);
  sss_nrm_raw(k,1:62)=[dft_out(end-30:end) dft_out(2:32)];
  %��132-137�еĲ����ͼ�����չѭ��ǰ׺ʱʹ�õĲ�����һ���ģ�����Ͳ��ٽ�����
end
 
if nargin == 6
    figure(4);
    %����ƽ��ǰ��ƽ�����ŵ������ģ�������
    subplot(2,2,1); pcolor(abs(h_raw)); shading flat; drawnow;
    subplot(2,2,2); pcolor(angle(h_raw)); shading flat; drawnow;
    subplot(2,2,3); pcolor(abs(h_sm)); shading flat; drawnow;
    subplot(2,2,4); pcolor(angle(h_sm)); shading flat; drawnow;
 
figure(5);
%ȡ�ŵ������ǰ���У�����ƽ��ǰ��ƽ�����ŵ������ģ�������
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
%��¼������������ֵ��ֱ�Ӹ���һ���ŵ�����H��PSS��ֵ?
h_sm_ext_interp = h_sm;
h_sm_nrm_interp = h_sm;
pss_np_ext = pss_np;
pss_np_nrm = pss_np;
 
% Combine results from different slots
%����8��1*62�Ŀ��������ֱ����ͬ��slot�������ͨѭ��ǰ׺ģʽ����չѭ��ǰ׺ģʽ,Ŀ����Ϊ�˷����ڴ档
sss_h1_nrm_np_est=NaN(1,62);
sss_h2_nrm_np_est=NaN(1,62);
sss_h1_ext_np_est=NaN(1,62);
sss_h2_ext_np_est=NaN(1,62);
 
sss_h1_nrm_est=NaN(1,62);
sss_h2_nrm_est=NaN(1,62);
sss_h1_ext_est=NaN(1,62);
sss_h2_ext_est=NaN(1,62);
for t=1:62
  %����forѭ�����л���ؼ���
   %��ͨѭ��ǰ׺ģʽ
sss_h1_nrm_np_est(t)=real((1+ctranspose(h_sm_nrm_interp(1:2:end,t))*diag(1./pss_np_nrm(1:2:end))*h_sm_nrm_interp(1:2:end,t))^-1);
  sss_h2_nrm_np_est(t)=real((1+ctranspose(h_sm_nrm_interp(2:2:end,t))*diag(1./pss_np_nrm(2:2:end))*h_sm_nrm_interp(2:2:end,t))^-1);
 
  %��չѭ��ǰ׺ģʽsss_h1_ext_np_est(t)=real((1+ctranspose(h_sm_ext_interp(1:2:end,t))*diag(1./pss_np_ext(1:2:end))*h_sm_ext_interp(1:2:end,t))^-1);
  sss_h2_ext_np_est(t)=real((1+ctranspose(h_sm_ext_interp(2:2:end,t))*diag(1./pss_np_ext(2:2:end))*h_sm_ext_interp(2:2:end,t))^-1);
 
  % ����ͨ���ŵ�����H����ź�S
sss_h1_nrm_est(t)=sss_h1_nrm_np_est(t)*ctranspose(h_sm_nrm_interp(1:2:end,t))*diag(1./pss_np_nrm(1:2:end))*sss_nrm_raw(1:2:end,t);
  sss_h2_nrm_est(t)=sss_h2_nrm_np_est(t)*ctranspose(h_sm_nrm_interp(2:2:end,t))*diag(1./pss_np_nrm(2:2:end))*sss_nrm_raw(2:2:end,t);
 
  sss_h1_ext_est(t)=sss_h1_ext_np_est(t)*ctranspose(h_sm_ext_interp(1:2:end,t))*diag(1./pss_np_ext(1:2:end))*sss_ext_raw(1:2:end,t);
  sss_h2_ext_est(t)=sss_h2_ext_np_est(t)*ctranspose(h_sm_ext_interp(2:2:end,t))*diag(1./pss_np_ext(2:2:end))*sss_ext_raw(2:2:end,t);
end
 
% Maximum likelihood detection of SSS
%�������Ȼ�����㷨���SSS
%��������18=68*2�Ŀվ����Ա���к���Ĵ���
log_lik_nrm=NaN(168,2);
log_lik_ext=NaN(168,2);
for t=0:167
  %����������ѡ����
  sss_h1_try=sss(t,n_id_2_est,0);
  sss_h2_try=sss(t,n_id_2_est,10);
 
%����ͨѭ��ǰ׺��ת��ѡ������ƥ��������С�
%������λƫ����
  ang=angle(sum(conj([sss_h1_nrm_est sss_h2_nrm_est]).*[sss_h1_try sss_h2_try]));
  sss_h1_try=sss_h1_try*exp(j*-ang);
  sss_h2_try=sss_h2_try*exp(j*-ang);  %������λƫ��
  df=[sss_h1_try sss_h2_try]-[sss_h1_nrm_est sss_h2_nrm_est];
  log_lik_nrm(t+1,1)=sum(-[real(df) imag(df)].^2./repmat([sss_h1_nrm_np_est sss_h2_nrm_np_est],1,2));
 
%ʹ�������Ȼ���ж�SSS
%��h1��h2����(ͨ����ʱ����temp)���ظ�����������������ת
%����ͨѭ��ǰ׺����չѭ��ǰ׺��һ���Ĵ����
  temp=sss_h1_try;
  sss_h1_try=sss_h2_try;
  sss_h2_try=temp;
  ang=angle(sum(conj([sss_h1_nrm_est sss_h2_nrm_est]).*[sss_h1_try sss_h2_try]));
  sss_h1_try=sss_h1_try*exp(j*-ang);
  sss_h2_try=sss_h2_try*exp(j*-ang);
  df=[sss_h1_try sss_h2_try]-[sss_h1_nrm_est sss_h2_nrm_est];
  log_lik_nrm(t+1,2)=sum(-[real(df) imag(df)].^2./repmat([sss_h1_nrm_np_est sss_h2_nrm_np_est],1,2));
 
  %����չѭ��ǰ׺��ת��ѡ������ƥ��������С�(�ظ���������ȫ��ͬ�Ĳ�����������ﲻ�ٽ���)
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
 
%�ж�����SSS��ѭ��ǰ׺�����ͣ�ȷ����ģʽ����ͨѭ��ǰ׺������չѭ��ǰ׺
%warning('Check code here!!!!');
% cp_type_flag = 0;
if (max(log_lik_nrm(:))>max(log_lik_ext(:)))
  %�����ͨѭ��ǰ׺�Ķ�����Ȼ��������,���ж�Ϊnormal CP SSS 
  cp_type_est='normal';
  cp_type_flag = 0;
  log_lik=log_lik_nrm;
else
%�����չѭ��ǰ׺�Ķ�����Ȼ��������,���ж�Ϊnormal CP SSS 

  cp_type_est='extended';
  cp_type_flag = 1;
  log_lik=log_lik_ext;
end
 
% frame_start��֡ѭ��ǰ׺����ʼλ�á�
%֡�ĵ�һ��DFTӦ��λ��frame_start+cp_length
if tdd_flag==1
    if cp_type_flag == 0
        frame_start=peak_loc+(-(2*(128+9)+1)-1920-2)*k_factor; % TDD����ͨѭ��ǰ׺��Ӧ����ʼλ��
    else
        frame_start=peak_loc+(-(2*(128+32))-1920-2)*k_factor; % TDD����չѭ��ǰ׺��Ӧ����ʼλ��
    end
else
    frame_start=peak_loc+(128+9-960-2)*k_factor; % FDDѭ��ǰ׺��Ӧ����ʼλ��
end
%������Ҳ����Ѱ��frame_start����ʼλ��
if (max(log_lik(:,1))>max(log_lik(:,2)))
  ll=log_lik(:,1);
else
  frame_start=frame_start+9600*k_factor;
  ll=log_lik(:,2);
end
frame_start=wrap(frame_start,0.5,2*9600+.5);
[lik_final, n_id_1_est]=max(ll);
n_id_1_est=n_id_1_est-1;  %���n_id_1��SSS���Ĺ���ֵ
 
% ���еڶ�����ֵ��鲢��������ķ�ֵpeak_out�������Ϣ:������Ҫ��n_id_1��SSS���Ĺ���ֵ
L=[log_lik_nrm log_lik_ext];
L_mean=mean(L(:));%��þ�ֵ
L_var=var(L(:));
if nargin == 6
    figure(6);
    plot(0:167,[log_lik_nrm log_lik_ext],[0 167],repmat(L_mean,1,2),[0 167],repmat(L_mean+sqrt(L_var)*thresh2_n_sigma,1,2));%�����ֵ
    zgo;
    drawnow;
end
peak_out=peak;
%�ж���ֵ
%������ǵ���Ȼ��������ֵС����ʧ��
if (lik_final<L_mean+sqrt(L_var)*thresh2_n_sigma)
  %disp('Thresh2 fail');
  %��������ķ�ֵpeak_out�������Ϣ
  peak_out.n_id_1=NaN;
  peak_out.cp_type='';
  peak_out.cp_type_val=-1;
  peak_out.frame_start=NaN;
  peak_out.duplex_mode=NaN;
else
  peak_out.n_id_1=n_id_1_est;%N_id_1�Ĺ���ֵ
  peak_out.cp_type=cp_type_est;% �õ���ѭ��ǰ׺������
  peak_out.cp_type_val=cp_type_flag;
  peak_out.frame_start=frame_start;% �õ�֡��ʼʱ��
  peak_out.duplex_mode=tdd_flag;% �жϽ����TDD ���� FDD
end