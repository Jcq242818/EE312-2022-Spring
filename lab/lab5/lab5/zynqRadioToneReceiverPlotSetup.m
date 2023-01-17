% zynqRadioToneReceiverAD9361AD9364ML_Plots configure scopes and
% corresponding screen layout for zynqRadioToneReceiverAD9361AD9364ML
% example

% Copyright 2014-2015 The MathWorks, Inc.

function [hSpectrum,hTimeScopes,hConstDiagm] = zynqRadioToneReceiverPlotSetup(fs)
       
% Current screen resolution:
% -- res(3) is width of the screen
% -- res(4) is the height of the screen
res = get(0,'ScreenSize');

% Get width
width = res(3);

if (width>=1280) % Only resize if screen is big enough
    % Get height
    height = res(4);
    
    % Scope positioning is specified from the bottom-left-hand corner of
    % the screen, not taking into account window borders. Specifying an x-
    % and y-position of '0' would postion the scope window border off of
    % the screen. This must be accounted for.
    
    % 90 is roughly the height of the scope's toolbar plus OS title bar
    header = 85;
    % 7 is roughly the size of a single side border
    border = 7;
    
    xpos = fix(width*[0 0.25]+(width/4));
    % Width of scope
    xsize = xpos(2) - xpos(1);
    % Take border sizes into account now
    xpos = fix(xpos + [border 22]);
    % Scope height, to make scope square
    ysize = fix(xsize - header);
    % Middle of screen plus border width
    ypos(2) = fix(height/2) + border;
    % Middle of screen, minus scope height, minus header, minus border
    ypos(1) = fix(ypos(2) - ysize - header - border);
    
    % Flag resize plots
    repositionPlots = true;
else % Otherwise don't alter default position
    repositionPlots = false;
end

% Create a Spectrum Analyzer System object
hSpectrum = dsp.SpectrumAnalyzer('SampleRate', fs);
if (repositionPlots)  % Resize if screen is big enough 
    % Make scope double width
    hSpectrum.Position = [xpos(1) ypos(2) ((xsize*2)+(2*border)) ysize];
end       

% Create a Time Scope System object
hTimeScopes = dsp.TimeScope('TimeSpan', 50);
if (repositionPlots) % Resize if screen is big enough 
    hTimeScopes.Position = [xpos(1) ypos(1) xsize ysize];
end

% Create a Constellation diagram System object
hConstDiagm = comm.ConstellationDiagram('ShowReferenceConstellation', false);
if (repositionPlots)  % Resize if screen is big enough 
    hConstDiagm.Position = [xpos(2) ypos(1) xsize ysize];
end