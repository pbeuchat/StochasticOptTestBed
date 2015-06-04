function returnSuccess = setSubStreamNumberForDisturbanceRandStream( obj , inputSubStream )
% Defined for the "Disturbance_Model" class, this function set the
% "Sub-Stream" of the Random Stream object if possible
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
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



    %% SET THE "SUB-STREAM" IF THE RAND OBJECT IS A TYPE THAT ALLOWS IT
    if strcmp(obj.randStreamObject.Type,'mrg32k3a') || strcmp(obj.randStreamObject.Type,'mlfg6331_64')
        obj.randStreamObject.Substream = inputSubStream;
    end


end
% END OF FUNCTION
