%% 重新定义传输图像的尺寸

%%
function [fData_Resize]=ResizeImage(fileTx,scale)

%（1）读取图像文件
fData = imread(fileTx);   % Read image data from file

%（2）原始图像尺寸
origSize = size(fData);   % Original input image size

%（3）需要传输的图像尺寸 Calculate new image size
scaledSize = max(floor(scale.*origSize(1:2)),1); 

heightIx = min(round(((1:scaledSize(1))-0.5)./scale+0.5),origSize(1));
widthIx = min(round(((1:scaledSize(2))-0.5)./scale+0.5),origSize(2));

%（4）重新组合数据
fData_Resize = fData(heightIx,widthIx,:); % Resize image
