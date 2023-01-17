%% ���¶��崫��ͼ��ĳߴ�

%%
function [fData_Resize]=ResizeImage(fileTx,scale)

%��1����ȡͼ���ļ�
fData = imread(fileTx);   % Read image data from file

%��2��ԭʼͼ��ߴ�
origSize = size(fData);   % Original input image size

%��3����Ҫ�����ͼ��ߴ� Calculate new image size
scaledSize = max(floor(scale.*origSize(1:2)),1); 

heightIx = min(round(((1:scaledSize(1))-0.5)./scale+0.5),origSize(1));
widthIx = min(round(((1:scaledSize(2))-0.5)./scale+0.5),origSize(2));

%��4�������������
fData_Resize = fData(heightIx,widthIx,:); % Resize image
