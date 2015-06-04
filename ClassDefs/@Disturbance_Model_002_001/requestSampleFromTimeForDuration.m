function returnSample = requestSampleFromTimeForDuration( obj , startTime , duration , startXi )
% Defined for the "Disturbance_Model" class, this function return a sample
% drawn from this Disturbance Model is defined
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



    % Check that "startXi" is note empty if the model is "Time Correlated"
    if obj.isTimeCorrelated && isempty(startXi)
        disp(' ... ERROR: this Distuabnce Model is Time Correlated but a starting "xi" was not supplied');
        error(bbConstants.errorMsg);
    end

    % Check that the start time is positve
    if startTime <= 0
        disp(' ... ERROR: the start time must be input as a postive number');
        error(bbConstants.errorMsg);
    end
    
    % "mod" the start time back into the cycle range
    startTime_mod = mod(startTime-1 , obj.N_max)+1;
    
    
    % Copmute an Ambient Temperature sample
    sineWave_mean_Tamb = 7.5;
    sineWave_amp_Tamb  = 7.5;
    n_Tamb = 1;
    sampleMean_Tamb =  ( - sineWave_amp_Tamb * cos( double(startTime_mod) * (2*pi()/double(obj.N_max)) ) + sineWave_mean_Tamb) * ones(n_Tamb,1);
    
    
    returnSample = sampleMean_Tamb;
    
    
    % Finally check the sample to be passed back is the expected size
    
    

end
% END OF FUNCTION