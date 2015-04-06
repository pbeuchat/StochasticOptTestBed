function [deltaMaxMin, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPerDimensionMinMax(SSingle, hSinlge, NSides)
% UNDER CONSTRUCTION
%  ---------------------------------------------------------------------  %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        1 Oct 2013
%  GOAL:        Towards Double-Sided OPF
%  DESCRIPTION: > This script ...
%               > xxx
%  HOW TO USE:  ... edit the ...
%               ... use the "pre-compile" switches on turn on/off the
%                   the following features
%
% INPUTS:
%       > "getSysMode" - is an integer flag specifing which model to use
%
% OUTPUTS:
%       > Prints out the following:
%           - xxx
%
% ----------------------------------------------------------------------- %
% This file is part of the Stochastic Optimisation Test Bed.
%
% The Stochastic Optimisation Test Bed - Copyright (C) 2015 Paul Beuchat
%
% The Stochastic Optimisation Test Bed is free software: you can
% redistribute it and/or modify it under the terms of the GNU General
% Public License as published by the Free Software Foundation, either
% version 3 of the License, or (at your option) any later version.
% 
% The Stochastic Optimisation Test Bed is distributed in the hope that it
% will be useful, but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with the Stochastic Optimisation Test Bed.  If not, see
% <http://www.gnu.org/licenses/>.
%  ---------------------------------------------------------------------  %




%% EXTRACT THE "thisNdT" SIZE FROM THE INPUT "SSingle" MATRIX
thisNdT = size(SSingle,2);


% Find the max Delta for the +ve/-ve of each direction
deltaMaxMin = getElementwiseMaxAndMinForSet(SSingle, hSinlge);
deltaMin = -deltaMaxMin(thisNdT+1:2*thisNdT);
deltaMax =  deltaMaxMin(1:thisNdT,1);

[deltaMaxMin, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPerDimensionMinMax(deltaMin, deltaMax);


% Choose the split points
% NOTE: it is very important to remember that "deltaMax" returned 
% agrees with the definition of "delta" in use. ie. there are two halves
% with the first half as the max of each dimension and the second half
% as the negative min of each dimension

% Compute 1 percant of the delta span in each dimension
deltaRange = deltaMax - deltaMin;
%deltaRange1percent = deltaRange * 0.01;

% Choose the size of each piece for the 3-way split and round to the
% nearest 1 percent
if NSides < 2; error(' NUMBER OF SPLITS MUST BE GREATER THAN 1'); end


deltaSplitSizeRaw = deltaRange./NSides;


% IF ONE OF THE SPLIT POINTS IS WITHIN 25% OF ZERO THEN FORCE THAT SPLIT
% POINT TO BE AT ZERO AND SPLIT THE PARTS ABOVE AND BELOW EVENLY
%deltaSplit25percent = deltaSplitSizeRaw * 0.4;

% Initilaise the index of which split point to force to zero
setThisSplitToZero = zeros(thisNdT,1);
% The split can be adjusted dimension-by-dimension
for iDim = 1:thisNdT
    % Step through the number of sides and check each one
    for iSplit = 1:NSides-1
        % Compute where the split point would be for this dimension
        thisSplitPoint = deltaMin(iDim)+deltaSplitSizeRaw(iDim)*iSplit;
        
        if (thisSplitPoint > 0)
            if iSplit == 1
                setThisSplitToZero(iDim,1) = 1;
            else
                % Check which one is closer
                previousSPlitPoint = deltaMin(iDim)+deltaSplitSizeRaw(iDim)*(iSplit-1);
                if abs(previousSPlitPoint) < abs(thisSplitPoint)
                    setThisSplitToZero(iDim,1) = iSplit-1;
                else
                    setThisSplitToZero(iDim,1) = iSplit;
                end
            end
            break;
        end
        
%         % Check if it is with 20 percent of zero
%         if abs(thisSplitPoint) < deltaSplit25percent(iDim)
%             % If so, then store this as the index for that dimension
%             setThisSplitToZero(iDim,1) = iSplit;
%         end
    end
    
    if setThisSplitToZero(iDim,1) == 0
        setThisSplitToZero(iDim,1) = NSides-1;
    end
end


% INITIALISE THE "SPLIT POINT" RETURN ARRAY
deltaSplitPoint = zeros(thisNdT, NSides-1);

% STEP THROUGH EACH DIMENSION AGAIN
for iDim = 1:thisNdT
    % IF THERE IS NO SPLIT TO SET TO ZERO THEN JUST SPLIT EVENLY
    if setThisSplitToZero(iDim,1) == 0
        disp('A split point was not set to zero');
        deltaSplitSizeRaw = deltaRange(iDim,1)/NSides;
        %deltaSplitSize = floor(deltaSplitSizeRaw / deltaRange1percent(iDim,1)) * deltaRange1percent(iDim,1);
        deltaSplitSize = deltaSplitSizeRaw;

        % Compute the break points (ie. per dimension we get a vector like
        %      [min, split1, split2, max]   with  min<split1<split2<max
        for iSplit = 1:NSides-1
            deltaSplitPoint(iDim,iSplit) = deltaMin(iDim)+deltaSplitSize*iSplit;
        end
        % THESE ARE AN INDICATION OF THE FORMAT
        % deltaSplitPoint = [deltaMin+deltaSplitSize*1  deltaMin+deltaSplitSize*2 ...  deltaMin+deltaSplitSize*(numSplits-1)];
        % deltaMinSplitPointsMax = [deltaMin  deltaMin+deltaSplitSize  deltaMin+deltaSplitSize*2  deltaMax];

    % ELSE, THERE IS A SPLIT POINT TO FORCE SET TO ZERO THEN DO THAT
    else
        % Get the index of the split that should be set to zero
        thisIndexToSetToZero = setThisSplitToZero(iDim,1);
        % Compute the number of sides above and below
        NSidesBelow = thisIndexToSetToZero;
        NSidesAbove = NSides - NSidesBelow;
        % Compute the split points below only if there is more than 1 side
        if (NSidesBelow > 1)
            deltaRangeBelow         = 0 - deltaMin(iDim,1);
            %deltaRange1percentBelow = deltaRangeBelow * 0.01;
            deltaSplitSizeRawBelow  = deltaRangeBelow/NSidesBelow;
            %deltaSplitSizeBelow     = floor(deltaSplitSizeRawBelow / deltaRange1percentBelow) * deltaRange1percentBelow;
            deltaSplitSizeBelow = deltaSplitSizeRawBelow;
            % Step through the number of splits below
            deltaSplitPointBelow = zeros(1, NSidesBelow-1);
            for iSplit = 1:NSidesBelow-1
                deltaSplitPointBelow(1,iSplit) = deltaMin(iDim)+deltaSplitSizeBelow*iSplit;
            end
        else
            deltaSplitPointBelow = zeros(1,0);
        end
        
        % Compute the split points above only if there is more than 1 side
        if (NSidesAbove > 1)
            deltaRangeAbove         = deltaMax(iDim,1);
            %deltaRange1percentAbove = deltaRangeAbove * 0.01;
            deltaSplitSizeRawAbove  = deltaRangeAbove/NSidesAbove;
            %deltaSplitSizeAbove     = floor(deltaSplitSizeRawAbove / deltaRange1percentAbove) * deltaRange1percentAbove;
            deltaSplitSizeAbove = deltaSplitSizeRawAbove;
            % Step through the number of splits below
            deltaSplitPointAbove = zeros(1, NSidesAbove-1);
            for iSplit = 1:NSidesAbove-1
                deltaSplitPointAbove(1,iSplit) = 0+deltaSplitSizeAbove*iSplit;
            end
        else
            deltaSplitPointAbove = zeros(1,0);
        end
        
        % Now put them together
        temp_deltaSplitPoint        = [deltaSplitPointBelow   0   deltaSplitPointAbove];
        
        % Check that it is of the correct size
        check1 = ( size(temp_deltaSplitPoint,2) == (NSides-1) );
        if not(check1)
            disp(' ... ERROR: The number of split points is not correct');
            error(' Terminating now :-( See previous messages and ammend');
        end
        
        deltaSplitPoint(iDim,:) = temp_deltaSplitPoint;
        
    end
end
end  % <-- END OF FUNCTION