classdef sdrzWalkieTalkieTransmitter_AudioSource < matlab.System
%SDRZWALKIETALKIETRANSMITTER_AUDIOSOURCE Audio source for sdrz walkie-talkie examples
%
% H = sdrzWalkieTalkieTransmitter_AudioSource(Name,Value) creates an audio
% source object, H, with the specified property Name set to the specified
% Value. You can specify additional name-value pair arguments in any order
% as (Name1,Value1,...,NameN,ValueN).
%
% H = sdrzWalkieTalkieTransmitter_AudioSource(SourceSignal) creates an
% audio source object, H, with the specified SourceSignal. All other
% properties are left as default.
%
% Step method syntax:
%
% Y = step(H) returns an audio signal, Y, which can be a pure tone, a chirp
% or audio from the file 'sdrzWalkieTalkieHelper_voice.wav'. Y is a
% single precision column vector. The FrameLength property determines the
% length of the output.
%
% sdrzWalkieTalkieTransmitter_AudioSource methods:
%
%   step     - Generate source signal (see above)
%   release  - Allow property value and input characteristics changes
%   clone    - Create source object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset states of source object
%
% sdrzWalkieTalkieTransmitter_AudioSource properties:
%
%   SignalSource             - Output signal type e.g. pure tone
%   SampleRate               - Sample rate in Hz
%   SamplesPerFrame          - Samples per frame
%   ToneFrequency            - Pure tone frequency in Hz
%   ChirpSweepTime           - Chirp sweep time in seconds
%
% Example:
%     hSource = sdrzWalkieTalkieTransmitter_AudioSource('Audio file')
%     hSink = audioDeviceWriter(hSource.SampleRate)
%     tic; while toc < 10
%     data = step(hSource);
%     step(hSink, data);
%     end
%     release(hSink); release(hSource);
%
%   See also sdrzWalkieTalkieTransmitter.

%   Copyright 2014 The MathWorks, Inc.

properties (Nontunable)
  %SignalSource  Output signal type e.g. pure tone
  %   Specify the output signal type as one of 'Pure tone' | 'Chirp' |
  %   'Audio file'. The default is 'Audio file'.
  SignalSource = 'Audio file';
  %SamplesPerFrame Samples per frame
  %   Specify the number of samples in an output frame as an integer valued
  %   double or single precision integer valued positive scalar. The
  %   default is 512.
  SamplesPerFrame = 512;
  %ToneFrequency Pure tone frequency in Hz
  %   Specify the pure tone frequency as a double or single precision
  %   scalar. The default is 880 Hz. This property applies when you set the
  %   Signal property to 'Pure tone'.
  ToneFrequency = 880;
  %ChirpSweepTime Chirp sweep time in seconds
  %   Specify the chirp sweep time as a double or single precision positive
  %   scalar. The default is 3. This property applies when you set the 
  %   Signal property to 'Chirp'.
  ChirpSweepTime = 3;
  %AudioFileName Name of audio file
  %   The name of the audio file used when SignalSource is 'Audio file'.
  AudioFileName = 'sdrzWalkieTalkieHelper_voice.wav';
end

properties (Constant)
  %SampleRate Sample rate in Hz
  %   The sample rate of the output signal in Hertz.
  SampleRate = 8000;
end

properties (Access = private, Nontunable)
    %AudioGenerator The object creating audio data
    AudioGenerator
end

properties (Constant, Hidden, Transient)
    % This forces the SignalSource property to only be settable to one of
    % the specified strings
    SignalSourceSet = matlab.system.StringSet( ...
                          {'Pure tone', 'Chirp', 'Audio file'});
end

methods
    function obj = sdrzWalkieTalkieTransmitter_AudioSource(varargin)
        % Constructor for sdrzWalkieTalkieTransmitter_AudioSource.
        % Allow creation using name-value pairs, or just but passing the
        % value of the SignalSource property.
        setProperties(obj, nargin, varargin{:}, 'SignalSource');
    end
end

methods
% The functions in this section are validation checks performed when
% setting certain properties of the object.
    function set.SamplesPerFrame(obj, aLength)
        validateattributes(aLength, {'double', 'single'}, ...
            {'scalar', 'real', 'nonnan', 'finite', 'integer', 'positive'}, ...
            'sdrzWalkieTalkieTransmitter_AudioSource', 'SamplesPerFrame');
        obj.SamplesPerFrame = aLength;
    end
    
    function set.ToneFrequency(obj, aFreq)
        validateattributes(aFreq, {'double', 'single'}, ...
            {'scalar', 'real', 'nonnan', 'finite', 'positive', ...
            '>=', 500, '<=', 3400}, ...
            'sdrzWalkieTalkieTransmitter_AudioSource', 'ToneFrequency');
        obj.ToneFrequency = aFreq;
    end
    
    function set.ChirpSweepTime(obj, aTime)
        validateattributes(aTime, {'double', 'single'}, ...
            {'scalar', 'real', 'nonnan', 'finite', 'positive'}, ...
            'sdrzWalkieTalkieTransmitter_AudioSource', 'ChirpSweepTime');
        obj.ChirpSweepTime = aTime;
    end
    
    function set.AudioFileName(obj, aFileName)
        testAudioSource = dsp.AudioFileReader( ...
            'Filename', aFileName);
        if ~isequal(testAudioSource.SampleRate, obj.SampleRate)
            ME = MException('sdrzWalkieTalkieHelper:invalidAudioFile', ...
                ['Expected the audio file %s to have a ' ...
                'sample rate of %i. Actual sample rate was %i.'], ...
                aFileName, obj.SampleRate, ...
                testAudioSource.SampleRate);
            throw(ME)
        end
        obj.AudioFileName = aFileName;
    end
end

methods (Access = protected)
% The methods in this section are required for 
% sdrzWalkieTalkieTransmitter_AudioSource to be a valid System object.
    function setupImpl(obj)
        switch obj.SignalSource
            case 'Pure tone'
                obj.AudioGenerator = dsp.SineWave( ...
                    'Frequency', obj.ToneFrequency, ...
                    'SampleRate', obj.SampleRate, ...
                    'SamplesPerFrame', obj.SamplesPerFrame, ...
                    'OutputDataType', 'single');
            case 'Chirp'
                obj.AudioGenerator = dsp.Chirp( ...
                    'InitialFrequency', 500, ...
                    'TargetFrequency', 3400, ...
                    'TargetTime', obj.ChirpSweepTime, ...
                    'SweepTime', obj.ChirpSweepTime, ...
                    'SampleRate', obj.SampleRate, ...
                    'SamplesPerFrame', obj.SamplesPerFrame, ...
                    'OutputDataType', 'single');
            case 'Audio file'
                obj.AudioGenerator = dsp.AudioFileReader(...
                    'Filename', obj.AudioFileName, ...
                    'PlayCount', inf, ...
                    'SamplesPerFrame', obj.SamplesPerFrame, ...
                    'OutputDataType', 'single');
        end
    end
    
    function out = stepImpl(obj)
        out = step(obj.AudioGenerator);
    end
    
    function resetImpl(obj)
        reset(obj.AudioGenerator);
    end
    
    function releaseImpl(obj)
        release(obj.AudioGenerator);
    end
    
    function num = getNumInputsImpl(obj) %#ok<MANU>
        num = 0;
    end
end

methods (Access = protected)
    function flag = isInactivePropertyImpl(obj, prop)
        % Show/hide properties when the object is displayed. Only show the
        % properties that are relevant to the current SignalSource.
        flag = false;
        switch prop
            case 'ToneFrequency'
                if ~strcmp(obj.SignalSource, 'Pure tone')
                    flag = true;
                end
            case 'ChirpSweepTime'
                if ~strcmp(obj.SignalSource, 'Chirp')
                    flag = true;
                end
            case 'AudioFileName'
                if ~strcmp(obj.SignalSource, 'Audio file')
                    flag = true;
                end
        end
    end
end
end