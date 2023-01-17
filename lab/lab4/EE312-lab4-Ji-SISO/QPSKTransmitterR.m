classdef QPSKTransmitterR < matlab.System  
%#codegen
% Generates the QPSK signal to be transmitted
    
%   Copyright 2012 The MathWorks, Inc.
    
    properties (Nontunable)
        UpsamplingFactor = 4;
        MessageLength = 105;
        DataLength = 174;
        TransmitterFilterCoefficients = 1;
        ScramblerBase = 2;
        ScramblerPolynomial = [1 1 1 0 1];
        ScramblerInitialConditions = [0 0 0 0];
    end
    
     properties (Access=private)
        pBitGenerator
        pQPSKModulator 
        pTransmitterFilter
    end
    
    methods
        function obj = QPSKTransmitterR(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj)
            obj.pBitGenerator = QPSKBitsGeneratorR(...
                'MessageLength', obj.MessageLength, ...
                'BernoulliLength', obj.DataLength-obj.MessageLength, ...
                'ScramblerBase', obj.ScramblerBase, ...
                'ScramblerPolynomial', obj.ScramblerPolynomial, ...
                'ScramblerInitialConditions', obj.ScramblerInitialConditions);
           obj.pQPSKModulator  = comm.QPSKModulator('BitInput',true, ...
                'PhaseOffset', pi/4);
            
            obj.pTransmitterFilter = dsp.FIRInterpolator(obj.UpsamplingFactor, ...
                obj.TransmitterFilterCoefficients);
        end
        
        function [transmittedSignal,transmittedData,modulatedData]= stepImpl(obj)
            % Generates the data to be transmitted
            [transmittedData, ~] = step(obj.pBitGenerator);
            
            % Modulates the bits into QPSK symbols
            modulatedData = step(obj.pQPSKModulator, transmittedData); 
            
            % Square root Raised Cosine Transmit Filter
            transmittedSignal = step(obj.pTransmitterFilter, modulatedData);
        end
        
        function resetImpl(obj)
            reset(obj.pBitGenerator);
            reset(obj.pQPSKModulator );
            reset(obj.pTransmitterFilter);
        end
        
        function releaseImpl(obj)
            release(obj.pBitGenerator);
            release(obj.pQPSKModulator );
            release(obj.pTransmitterFilter);
        end
        
        function N = getNumInputsImpl(~)
            N = 0;
        end
    end
end

