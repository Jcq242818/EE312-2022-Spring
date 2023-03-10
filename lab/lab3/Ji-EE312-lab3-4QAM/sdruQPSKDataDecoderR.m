classdef sdruQPSKDataDecoderR < matlab.System
    %#codegen
    % Copyright 2012 The MathWorks, Inc.
    
    properties (Nontunable)
        FrameSize
        BarkerLength
        ModulationOrder
        DataLength
        MessageLength
        DescramblerBase
        DescramblerPolynomial
        DescramblerInitialConditions
        PrintOption
    end
    
    properties (Access=private)
        pCount
        pDelay
        pPhase
        pBuffer
        pModulator
        pModulatedHeader
        pCorrelator
        pQPSKDemodulator
        pDescrambler
        pBitGenerator
        pBitGeneratorSync
        pBER
        pSyncFlag
        pSyncIndex
        pFrameIndex
    end
    
    
    methods
        function obj = sdruQPSKDataDecoderR(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    methods (Access=protected)
        function setupImpl(obj, ~)
            [obj.pCount, obj.pDelay, obj.pPhase] = deal(0);
            obj.pFrameIndex=1;
            obj.pSyncIndex=0;
            obj.pSyncFlag=true;
            obj.pBuffer=dsp.Buffer(obj.FrameSize*2, obj.FrameSize);
            bbc = [+1; +1; +1; +1; +1; -1; -1; +1; +1; -1; +1; -1; +1]; % Bipolar Barker Code
            ubc = ((bbc + 1) / 2)'; % Unipolar Barker Code
            header = (repmat(ubc,1,2))';
            header = header(:);
            
            obj.pModulator = comm.QPSKModulator('BitInput', true, ...
            'PhaseOffset', pi/4);
            
            %obj.pModulator = comm.RectangularQAMModulator(16, 'BitInput',true,...
            %    'NormalizationMethod','Average power',...
            %    'SymbolMapping', 'Custom', ...
            %    'CustomSymbolMapping', [11 10 14 15 9 8 12 13 1 0 4 5 3 2 6 7]);
            obj.pModulatedHeader = sqrt(2)/2 * (-1-1i)*bbc; % Modulate theheader;
            obj.pCorrelator = dsp.Crosscorrelator;
            
            obj.pQPSKDemodulator = comm.QPSKDemodulator('PhaseOffset',pi/4, ...
             'BitOutput', true);
            %obj.pQPSKDemodulator = comm.RectangularQAMDemodulator(...
            %    'ModulationOrder', 13, ...
            %    'BitOutput', true, ...
            %    'NormalizationMethod', 'Average power', 'SymbolMapping', 'Custom', ...
            %    'CustomSymbolMapping', [11 10 14 15 9 8 12 13 1 0 4 5 3 2 6 7]);
            
            obj.pDescrambler = comm.Descrambler(obj.DescramblerBase, ...
                obj.DescramblerPolynomial, obj.DescramblerInitialConditions);
            obj.pBER = comm.ErrorRate;
        end
        
        function BER = stepImpl(obj, DataIn)
            % Buffer one frame in case that contiguous data scatter across
            % two adjacent frames
            rxData = step(obj.pBuffer,DataIn);
            
            % Get a frame of data aligned on the frame boundary
            Data = rxData(obj.pDelay+1:obj.pDelay+length(rxData)/2);
            
            % Phase estimation
            y = mean(conj(obj.pModulatedHeader) .* Data(1:obj.BarkerLength));
            
            % Compensating for the phase offset
            if Data(1)~=0
                phShiftedData = Data .* exp(-1j*obj.pPhase);
            else
                phShiftedData = complex(zeros(size(Data)));
            end
            % Demodulate the phase recovered data
            demodOut = step(obj.pQPSKDemodulator, phShiftedData);
            
            % Perform descrambling
            deScrData = step(obj.pDescrambler, ...
                demodOut( ...
                obj.BarkerLength*log2(obj.ModulationOrder)+1 : ...
                obj.FrameSize*log2(obj.ModulationOrder)));
            
            % Recovering the message from the data
            Received = deScrData(1:obj.MessageLength);
            
            % Finding the delay to achieve frame synchronization
            z=abs(step(obj.pCorrelator,obj.pModulatedHeader,DataIn));
            [~, ind] = max(z);
            obj.pDelay = mod(length(DataIn)-ind,(length(DataIn)-1));
            
            % Phase ambiguity correction
            obj.pPhase = round(angle(y)*2/pi)/2*pi;
            
            % Print received frame and estimate the received frame index
            [estimatedFrameIndex,syncIndex]=bits2ASCII(obj,Received);
            obj.pSyncIndex = syncIndex;
            % Once it is possible to decode the frame index four times,
            % frame synchronization is achieved
            if ((obj.pSyncFlag) && (estimatedFrameIndex~=100) && (obj.pSyncIndex>=4))
                obj.pFrameIndex=estimatedFrameIndex;
                obj.pSyncFlag=false;
            end
            % With the estimated frame index, estimate the transmitted
            % message
            transmittedMessage=messEstimator(obj.pFrameIndex, obj);
            % Calculate the BER
            BER = step(obj.pBER,transmittedMessage,Received);
            obj.pCount = obj.pCount + 1;
            obj.pFrameIndex = obj.pFrameIndex + 1;
        end
        
        function resetImpl(obj)
            reset(obj.pBuffer);
        end
        
        function releaseImpl(obj)
            release(obj.pBuffer);
        end
        
    end
    
    methods (Access=private)
        function [estimatedFrameIndex,syncIndex]=bits2ASCII(obj,u)
            coder.extrinsic('disp')
            
            % Convert binary-valued column vector to 7-bit decimal values.
            w = [64 32 16 8 4 2 1]; % binary digit weighting
            Nbits = numel(u);
            Ny = Nbits/7;
            y = zeros(1,Ny);
            % Obtain ASCII values of received frame
            for i = 0:Ny-1
                y(i+1) = w*u(7*i+(1:7));
            end
            
            % Display ASCII message to command window
            if(obj.PrintOption)
                disp(char(y));
            end
            % Retrieve last 2 ASCII values
            decodedNumber=y(Ny-1:end);
            % Create lookup table of ASCII values and corresponding integer numbers
            look_tab=zeros(2,10);
            look_tab(1,:)=0:9;
            look_tab(2,:)=48:57;
            % Initialize variables
            estimatedFrameIndex=100;
            syncIndex=0;
            onesPlace=0;
            tensPlace=0;
            dec_found=false;
            unity_found=false;
            
            % Index lookup table with decoded ASCII values
            % There are more efficient ways to perform vector indexing
            % using MATLAB functions like find(). However, to meet codegen
            % requirements, the usage of the four loop was necessary.
            
            for ii=1:10
                % Find the ones place in the lookup table
                if ( decodedNumber(1) == look_tab(2,ii) )
                    onesPlace=10*look_tab(1,ii);
                    dec_found=true;
                end
                % Find the tens place in the lookup table
                if ( decodedNumber(2) == look_tab(2,ii) )
                    tensPlace=look_tab(1,ii);
                    unity_found=true;
                end
            end
            % Estimate the frame index
            if(dec_found && unity_found && obj.pSyncFlag)
                estimatedFrameIndex=onesPlace+tensPlace;
                syncIndex=obj.pSyncIndex+1;
            end
            
            
        end
        
        function msg = messEstimator(ind, obj)
            
            MsgStrSet = ['Hello world 000';...
              'Hello world 001';...
              'Hello world 002';...
              'Hello world 003';...
              'Hello world 004';...
              'Hello world 005';...
              'Hello world 006';...
              'Hello world 007';...
              'Hello world 008';...
              'Hello world 009';...
              'Hello world 010';...
              'Hello world 011';...
              'Hello world 012';...
              'Hello world 013';...
              'Hello world 014';...
              'Hello world 015';...
              'Hello world 016';...
              'Hello world 017';...
              'Hello world 018';...
              'Hello world 019';...
              'Hello world 020';...
              'Hello world 021';...
              'Hello world 022';...
              'Hello world 023';...
              'Hello world 024';...
              'Hello world 025';...
              'Hello world 026';...
              'Hello world 027';...
              'Hello world 028';...
              'Hello world 029';...
              'Hello world 030';...
              'Hello world 031';...
              'Hello world 032';...
              'Hello world 033';...
              'Hello world 034';...
              'Hello world 035';...
              'Hello world 036';...
              'Hello world 037';...
              'Hello world 038';...
              'Hello world 039';...
              'Hello world 040';...
              'Hello world 041';...
              'Hello world 042';...
              'Hello world 043';...
              'Hello world 044';...
              'Hello world 045';...
              'Hello world 046';...
              'Hello world 047';...
              'Hello world 048';...
              'Hello world 049';...
              'Hello world 050';...
              'Hello world 051';...
              'Hello world 052';...
              'Hello world 053';...
              'Hello world 054';...
              'Hello world 055';...
              'Hello world 056';...
              'Hello world 057';...
              'Hello world 058';...
              'Hello world 059';...
              'Hello world 060';...
              'Hello world 061';...
              'Hello world 062';...
              'Hello world 063';...
              'Hello world 064';...
              'Hello world 065';...
              'Hello world 066';...
              'Hello world 067';...
              'Hello world 068';...
              'Hello world 069';...
              'Hello world 070';...
              'Hello world 071';...
              'Hello world 072';...
              'Hello world 073';...
              'Hello world 074';...
              'Hello world 075';...
              'Hello world 076';...
              'Hello world 077';...
              'Hello world 078';...
              'Hello world 079';...
              'Hello world 080';...
              'Hello world 081';...
              'Hello world 082';...
              'Hello world 083';...
              'Hello world 084';...
              'Hello world 085';...
              'Hello world 086';...
              'Hello world 087';...
              'Hello world 088';...
              'Hello world 089';...
              'Hello world 090';...
              'Hello world 091';...
              'Hello world 092';...
              'Hello world 093';...
              'Hello world 094';...
              'Hello world 095';...
              'Hello world 096';...
              'Hello world 097';...
              'Hello world 098';...
              'Hello world 099']; 
            cycle = mod(ind,100);
            msgStr = MsgStrSet(cycle+1,:);
            msgBin = de2bi(int8(msgStr),7,'left-msb');
            msg = reshape(double(msgBin).',obj.MessageLength,1);
        end
        
        
    end
end