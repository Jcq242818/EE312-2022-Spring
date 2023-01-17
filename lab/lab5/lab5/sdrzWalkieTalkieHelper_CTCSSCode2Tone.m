function toneFrequency = sdrzWalkieTalkieHelper_CTCSSCode2Tone(code)
%SDRZWALKIETALKIEHELPER_CTCSSCODE2TONE return the frequency of a CTCSS code
%
% Map a CTCSS code to its corresponding tone frequency.
%
% TONEFREQUENCY = sdrzWalkieTalkieHelper_CTCSSCode2Tone(CODE) returns the
% tone frequency, TONEFREQUENCY, in Hertz that matches the input CODE.

% Copyright 2014 The MathWorks, Inc.

smallestCode = 1;
largestCode = 38;
validateattributes(code, {'numeric'}, ...
                   {'scalar', '>=', smallestCode, '<=', largestCode, ...
                    'integer', 'real', 'finite', 'nonnan'})
tones = ...
  [67.0 71.9 74.4 77.0 79.7 82.5 85.4 88.5  91.5 94.8 97.4  ...
   100.0 103.5 107.2 110.9 114.8 118.8 123.0 127.3 131.8 136.5 141.3 ...
   146.2 151.4 156.7 162.2 167.9 173.8 179.9 186.2 192.8 ...
   203.5 210.7 218.1 225.7 233.6 241.8 250.3]';
toneFrequency = tones(code);
end