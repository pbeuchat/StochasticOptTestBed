classdef Lifting
% UNDER CONSTRUCTION
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This class is intended to be a "Static" class that
%                 contains the various methods required to "lift" a given
%                 set into a higher-diensional space by splitting the
%                 dimensions into multiple pieces 
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
   
   
   
   
    properties(Constant)
        
        
    end %properties(Constant)
   
    % We do not allow an instantion of this object
    methods(Access=private)
        % constructor
        function obj = Lifting()
            % Nothing to do here
        end % Lifting
    end %methods(Access=private)
   
    
    
    methods(Static=true , Access=public)
        
        %% --------------------------------------------------------------- %
        %% FUNCTIONS IMPLEMENTED IN OTHER FILES:
        
        % FUNCTION: [...] = getSplitPointFromPolytopeSingleForNSides(..)
        [deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(SSingle, hSinlge, NSides)
        
        % FUNCTION: [...] = getSplitPointFromPerDimensionMinMax(..)
        [deltaSplitPoint] = getSplitPointFromPerDimensionMinMax(deltaMin, deltaMax);
                
        % FUNCTION [...] = buildLiftedUncertaintySet(...)
        [returnS,  returnh] = buildLiftedUncertaintySet(something)
        
        
        % FUNCTION [...] = getElementwiseMinAndMaxForSet(...)
        [ returnMin , returnMax , returnMask , returnMaskChanged ] = getElementwiseMaxAndMinForSet(A, b, inputMask);
        
        %% --------------------------------------------------------------- %
        %% FUNCTIONS IMPLEMENTED DIRECTLY HERE:
        % FUNCTION: 
        %function returnVariable = functionName( inputVariable ) 
        
    end
    % END OF: methods(Static)
    
end
% END OF: "classdef bbConstants"
