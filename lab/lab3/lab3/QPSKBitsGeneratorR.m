classdef QPSKBitsGeneratorR < matlab.System
%#codegen
% Generates the bits for each frame
% Copyright 2012 The MathWorks, Inc.
 properties (Nontunable)
 MessageLength = 105;
 BernoulliLength = 69;
 ScramblerBase = 2;
 ScramblerPolynomial = [1 1 1 0 1];
 ScramblerInitialConditions = [0 0 0 0];
 end
 
 properties (Access=private)
 pHeader
 pScrambler
 pMsgStrSet
 pCount
 end
 
 methods
 function obj = QPSKBitsGeneratorR(varargin)
 setProperties(obj,nargin,varargin{:});
 end
 end
 
 methods (Access=protected)
 function setupImpl(obj, ~)
 bbc = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1 +1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]; % Bipolar Barker Code
 ubc = ((bbc + 1) / 2)'; % Unipolar Barker Code
 temp = (repmat(ubc,1,2))';
 obj.pHeader = temp(:);
 obj.pCount = 0;
 obj.pScrambler = comm.Scrambler(obj.ScramblerBase, ...
 obj.ScramblerPolynomial, obj.ScramblerInitialConditions);
 obj.pMsgStrSet = ['Hello world 1000';...
 'Hello world 1001';...
 'Hello world 1002';...
 'Hello world 1003';...
 'Hello world 1004';...
 'Hello world 1005';...
 'Hello world 1006';...
 'Hello world 1007';...
 'Hello world 1008';...
 'Hello world 1009';...
 'Hello world 1010';...
 'Hello world 1011';...
 'Hello world 1012';...
 'Hello world 1013';...
 'Hello world 1014';...
 'Hello world 1015';...
 'Hello world 1016';...
 'Hello world 1017';...
 'Hello world 1018';...
 'Hello world 1019';...
 'Hello world 1020';...
 'Hello world 1021';...
 'Hello world 1022';...
 'Hello world 1023';...
 'Hello world 1024';...
 'Hello world 1025';...
 'Hello world 1026';...
 'Hello world 1027';...
 'Hello world 1028';...
 'Hello world 1029';...
 'Hello world 1030';...
 'Hello world 1031';...
 'Hello world 1032';...
 'Hello world 1033';...
 'Hello world 1034';...
 'Hello world 1035';...
 'Hello world 1036';...
 'Hello world 1037';...
 'Hello world 1038';...
 'Hello world 1039';...
 'Hello world 1040';...
 'Hello world 1041';...
 'Hello world 1042';...
 'Hello world 1043';...
 'Hello world 1044';...
 'Hello world 1045';...
 'Hello world 1046';...
 'Hello world 1047';...
 'Hello world 1048';...
 'Hello world 1049';...
 'Hello world 1050';...
 'Hello world 1051';...
 'Hello world 1052';...
 'Hello world 1053';...
 'Hello world 1054';...
 'Hello world 1055';...
 'Hello world 1056';...
 'Hello world 1057';...
 'Hello world 1058';...
 'Hello world 1059';...
 'Hello world 1060';...
 'Hello world 1061';...
 'Hello world 1062';...
 'Hello world 1063';...
 'Hello world 1064';...
 'Hello world 1065';...
 'Hello world 1066';...
 'Hello world 1067';...
 'Hello world 1068';...
 'Hello world 1069';...
 'Hello world 1070';...
 'Hello world 1071';...
 'Hello world 1072';...
 'Hello world 1073';...
 'Hello world 1074';...
 'Hello world 1075';...
 'Hello world 1076';...
 'Hello world 1077';...
 'Hello world 1078';...
 'Hello world 1079';...
 'Hello world 1080';...
 'Hello world 1081';...
 'Hello world 1082';...
 'Hello world 1083';...
 'Hello world 1084';...
 'Hello world 1085';...
 'Hello world 1086';...
 'Hello world 1087';...
 'Hello world 1088';...
 'Hello world 1089';...
 'Hello world 1090';...
 'Hello world 1091';...
 'Hello world 1092';...
 'Hello world 1093';...
 'Hello world 1094';...
 'Hello world 1095';...
 'Hello world 1096';...
 'Hello world 1097';...
 'Hello world 1098';...
 'Hello world 1099']; 
 end
 
 function [y,msg] = stepImpl(obj)
 
 % Converts the message string to bit format
 cycle = mod(obj.pCount,100);
 msgStr = obj.pMsgStrSet(cycle+1,:);
 msgBin = de2bi(int8(msgStr),7,'left-msb');
 msg = reshape(double(msgBin).',obj.MessageLength,1);
 data = [msg ; randi([0 1], obj.BernoulliLength, 1)];
 
 % Scramble the data
 scrambledData = step(obj.pScrambler, data);
 
 % Append the scrambled bit sequence to the header
 y = [obj.pHeader ; scrambledData];
 
 obj.pCount = obj.pCount+1;
 end
 
 function resetImpl(obj)
 obj.pCount = 0;
 reset(obj.pScrambler);
 end
 
 function releaseImpl(obj)
 release(obj.pScrambler);
 end
 
 function N = getNumInputsImpl(~)
 N = 0; 
 end
 
 function N = getNumOutputsImpl(~)
 N = 2;
 end
 end
end