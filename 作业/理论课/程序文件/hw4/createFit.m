function [pd1,pd2,pd3,pd4] = createFit(SNR_channel1,SNR_channel2,SNR_channel3,SNR_channel4)
%CREATEFIT    Create plot of datasets and fits
%   [PD1,PD2,PD3,PD4] = CREATEFIT(SNR_CHANNEL1,SNR_CHANNEL2,SNR_CHANNEL3,SNR_CHANNEL4)
%   Creates a plot, similar to the plot in the main distribution fitter
%   window, using the data that you provide as input.  You can
%   apply this function to the same data you used with distributionFitter
%   or with different data.  You may want to edit the function to
%   customize the code and this help message.
%
%   Number of datasets:  4
%   Number of fits:  4
%
%   See also FITDIST.

% This function was automatically generated on 05-Apr-2022 18:05:38

% Output fitted probablility distributions: PD1,PD2,PD3,PD4

% Data from dataset "SNR_channel1 data":
%    Y = SNR_channel1

% Data from dataset "SNR_channel2 data":
%    Y = SNR_channel2

% Data from dataset "SNR_channel3 data":
%    Y = SNR_channel3

% Data from dataset "SNR_channel4 data":
%    Y = SNR_channel4

% Force all inputs to be column vectors
SNR_channel1 = SNR_channel1(:);
SNR_channel2 = SNR_channel2(:);
SNR_channel3 = SNR_channel3(:);
SNR_channel4 = SNR_channel4(:);

% Prepare figure
clf;
hold on;
LegHandles = []; LegText = {};


% --- Plot data originally in dataset "SNR_channel1 data"
% This dataset does not appear on the plot

% --- Plot data originally in dataset "SNR_channel2 data"
% This dataset does not appear on the plot

% --- Plot data originally in dataset "SNR_channel3 data"
% This dataset does not appear on the plot

% --- Plot data originally in dataset "SNR_channel4 data"
% This dataset does not appear on the plot

% Get data limits to determine plotting range
XLim = [min(SNR_channel1), max(SNR_channel1)];
XLim = [min(SNR_channel1), max(SNR_channel1)];
XLim(1) = min(XLim(1), min(SNR_channel2));
XLim(2) = max(XLim(2), max(SNR_channel2));
XLim(1) = min(XLim(1), min(SNR_channel3));
XLim(2) = max(XLim(2), max(SNR_channel3));
XLim(1) = min(XLim(1), min(SNR_channel4));
XLim(2) = max(XLim(2), max(SNR_channel4));

% Create grid where function will be computed
XLim = XLim + [-1 1] * 0.01 * diff(XLim);
XGrid = linspace(XLim(1),XLim(2),100);


% --- Create fit "拟合 1"

% Fit this distribution to get parameter values
% To use parameter estimates from the original fit:
%     pd1 = ProbDistUnivParam('normal',[ 3.080919275743, 6.34891102616])
pd1 = fitdist(SNR_channel1, 'normal');
YPlot = pdf(pd1,XGrid);
hLine = plot(XGrid,YPlot,'Color',[1 0 0],...
    'LineStyle','-', 'LineWidth',2,...
    'Marker','none', 'MarkerSize',6);
LegHandles(end+1) = hLine;
LegText{end+1} = '拟合 1';

% --- Create fit "拟合 2"

% Fit this distribution to get parameter values
% To use parameter estimates from the original fit:
%     pd2 = ProbDistUnivParam('normal',[ 3.150108232609, 6.209315060871])
pd2 = fitdist(SNR_channel2, 'normal');
YPlot = pdf(pd2,XGrid);
hLine = plot(XGrid,YPlot,'Color',[0 0 1],...
    'LineStyle','-', 'LineWidth',2,...
    'Marker','none', 'MarkerSize',6);
LegHandles(end+1) = hLine;
LegText{end+1} = '拟合 2';

% --- Create fit "拟合 3"

% Fit this distribution to get parameter values
% To use parameter estimates from the original fit:
%     pd3 = ProbDistUnivParam('normal',[ 3.290738411265, 6.386704590091])
pd3 = fitdist(SNR_channel3, 'normal');
YPlot = pdf(pd3,XGrid);
hLine = plot(XGrid,YPlot,'Color',[0.666667 0.333333 0],...
    'LineStyle','-', 'LineWidth',2,...
    'Marker','none', 'MarkerSize',6);
LegHandles(end+1) = hLine;
LegText{end+1} = '拟合 3';

% --- Create fit "拟合 4"

% Fit this distribution to get parameter values
% To use parameter estimates from the original fit:
%     pd4 = ProbDistUnivParam('normal',[ 3.040347719451, 6.311224296083])
pd4 = fitdist(SNR_channel4, 'normal');
YPlot = pdf(pd4,XGrid);
hLine = plot(XGrid,YPlot,'Color',[0.333333 0.333333 0.333333],...
    'LineStyle','-', 'LineWidth',2,...
    'Marker','none', 'MarkerSize',6);
LegHandles(end+1) = hLine;
LegText{end+1} = '拟合 4';

% Adjust figure
box on;
grid on;
hold off;

% Create legend from accumulated handles and labels
hLegend = legend(LegHandles,LegText,'Orientation', 'vertical', 'FontSize', 9, 'Location', 'northeast');
set(hLegend,'Interpreter','none');
