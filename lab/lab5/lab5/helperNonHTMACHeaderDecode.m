function [mac,packetSeq] = helperNonHTMACHeaderDecode(inp)
% helperNonHTMACHeaderDecode Featured example helper function 
%
%   [MAC,PACKETSEQ] = helperNonHTMACHeaderDecode(INP) recover information
%   in the MAC header of an MPDU.

% Copyright 2015 The MathWorks, Inc.

%#codegen

bitsPerOctet = 8; % Bit length in 2 Octets
mac = struct;
mac.FrameControl = [0 0];


% Create MPUD header from receive bits
% Extract frame control bits
mac.FrameControl = getFrameControl(inp(1:2*bitsPerOctet));

% Initialize the mac structure field
mac.Duration = [0 0];         % Duration of frame for NAV (2 octets)
mac.Address1 = [0 0 0 0 0 0]; % Destination address (6 octets) 
mac.Address2 = [0 0 0 0 0 0]; % Station address (6 octets)
mac.Address3 = [0 0 0 0 0 0]; % BSSID (6 octets)
mac.Sequence = [0 0];         % Sequence control (2 octets)
mac.Address4 = [0 0 0 0 0 0]; % 6 octets
mac.QoS = [0 0];              % 2 octets

% The length of the input bits should be equal to the MAC header length
% of 32 octets or 256 bits
if length(inp) < 256
   error('The input length is less than the number of octets expected in the MAC header');
end

mac = convertToOctets(inp(17:end),mac,bitsPerOctet);

% Arrange sequence control field
packetSeq = bitor(bitshift(mac.Sequence(1),-4),mac.Sequence(2)*16);

end

% Frame control fields
function frameCtrl = getFrameControl(bits)
    frameCtrl = struct;
    frameCtrl.ProtocolVersion = uint8(bi2de(bits(1:2).','right-msb'));
    frameCtrl.Type            = uint8(bi2de(bits(3:4).','right-msb'));
    frameCtrl.Subtype         = uint8(bi2de(bits(5:8).','right-msb'));
    frameCtrl.ToDS            = uint8(bi2de(bits(9) ,'right-msb'));
    frameCtrl.FromDS          = uint8(bi2de(bits(10),'right-msb'));
    frameCtrl.MoreFragments   = uint8(bi2de(bits(11),'right-msb'));
    frameCtrl.Retry           = uint8(bi2de(bits(12),'right-msb'));
    frameCtrl.PowerManagement = uint8(bi2de(bits(13),'right-msb'));
    frameCtrl.MoreData        = uint8(bi2de(bits(14),'right-msb'));
    frameCtrl.ProtectedFrame  = uint8(bi2de(bits(15),'right-msb'));
    frameCtrl.Order           = uint8(bi2de(bits(16),'right-msb'));
end


function str = convertToOctets(inp,str,bitsPerOctet)
    
    fnames = fieldnames(str); 
    numFields = numel(fnames);
    totalOctet = length(inp)/bitsPerOctet;
    mask = (2.^(0:bitsPerOctet-1));
    numOctets = 0;
    previousOctLength = 0;
    out = zeros(1,totalOctet,'uint8');
    for f = 2:numFields % Start after Frame Control field
        octets = str.(fnames{f});
        for p=1:numel(octets)
          out(p+numOctets) = mask*(double(inp( (p-1)*bitsPerOctet+1 + numOctets*bitsPerOctet:p*bitsPerOctet + numOctets*bitsPerOctet )));
        end
        numOctets = numOctets + numel(octets);
        str = setfield(str,fnames{f},(out(previousOctLength+1:numOctets))); %#ok<SFLD>
        previousOctLength = numOctets;
    end
    
end

% [EOF]