function centerFrequency = sdrzWalkieTalkieHelper_Channel2Frequency(protocol, channel)
%SDRZWALKIETALKIEHELPER_CHANNEL2FREQUENCY Map channel to center frequency
%
% Map an integer channel number for a given protocol to the equivalent RF
% center frequency.
% 
% CENTERFREQUENCY = sdrzWalkieTalkieHelper_Channel2Frequency(PROTOCOL,
% CHANNEL) returns the center frequency of CHANNEL for the given PROTOCOL.
%
% INPUTS:
%     PROTOCOL - A string identifying the walkie-talkie protocol in use.
%                Valid values include:
%                    'FRS'
%                    'PMR446'
%     CHANNEL - An integer value representing the channel number given
%               below.
%
% OUTPUTS:
%     CENTERFREQUENCY - a double giving the RF center frequency for the
%                       channel in Hertz.
%
% Mapping for each protocol is as follows:
%     
%      Channel   Frequency    Frequency
%                  (MHz)        (MHz)
%         1       462.5625    446.00625
%         2       462.5875    446.01875
%         3       462.6125    446.03125
%         4       462.6375    446.04375
%         5       462.6625    446.05625
%         6       462.6875    446.06875
%         7       462.7125    446.08125
%         8       467.5625    446.09375
%         9       467.5875   
%        10       467.6125    
%        11       467.6375    
%        12       467.6625   
%        13       467.6875   
%        14       467.7125  
%

% Copyright 2014 The MathWorks, Inc.

checkInputs(protocol, channel);

% Determine the base frequency and offset to get the center frequency.
% Notice that FRS has a gap between channel 7 and channel 8.
switch protocol
    case 'FRS'
        channelSpacing = 25e3; % in Hertz
        if channel <= 7
            baseFrequency = 462.5625e6; % in Hertz
            offsetFrequency = channelSpacing * (channel - 1);
        else
            baseFrequency = 467.5625e6; % in Hertz
            offsetFrequency = channelSpacing * (channel - 8);
        end
    case 'PMR446'
        channelSpacing = 12.5e3; % in Hertz
        baseFrequency = 446.00625e6; % in Hertz
        offsetFrequency = channelSpacing * (channel - 1);
end
centerFrequency = baseFrequency + offsetFrequency;
end

function [] = checkInputs(protocol, channel)
%CHECKINPUTS validate the protocol and channel inputs
%
% 'protocol' should be 'FRS' or 'PMR446'.
%
% 'channel' should be 1 to 14 for 'FRS' or 1 to 8 for 'PMR446'

protocol = validatestring(protocol, {'FRS', 'PMR446'}, ...
                          mfilename, 'protocol');

% Check channel is valid based on the protocol selected
if strcmp(protocol, 'FRS')
    maxChannel = 14;
elseif strcmp(protocol, 'PMR446')
    maxChannel = 8;
end
validateattributes(channel, {'numeric'}, ...
        {'scalar', 'real', 'nonnan', 'integer', ...
        '>=', 1, '<=' maxChannel}, ...
        mfilename, 'channel');
end