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



    % Get a random sample 
    tempRandNumbers = randn(obj.lengthRandInputVector , 1);
    
    % and pass it through
    %returnSample = requestSampleFromTimeForDuration_withRandInput( obj , startTime , duration , startXi , tempSample );
    
    
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
    
    % Check that "inputRandNumbers" is a vector of the expected size
    if ~( isvector(tempRandNumbers) && (length(tempRandNumbers) == obj.lengthRandInputVector) )
        disp( ' ... ERROR: this "inputRandNumbers" is either not a vector or not the correct length');
        disp(['            length(inputRandNumbers) = ',num2str(length(inputRandNumbers)) ]);
        disp(['            expected length          = ',num2str(obj.lengthRandInputVector) ]);
        error(bbConstants.errorMsg);
    end
    
    % "mod" the start time back into the cycle range
    startTime_mod = mod(startTime-1 , obj.N_max)+1;
    
    
    % Copmute an Ambient Temperature sample
    sampleMean_Tamb =  ( - obj.sineWave_amp_Tamb * cos( double(startTime_mod) * (2*pi()/double(obj.N_max)) ) + obj.sineWave_mean_Tamb) * ones(obj.n_Tamb,1);
    
    
    %covMatrix_Tamb = diag( 2^2 * ones(n_Tamb,1) );
    
    %bounds_lower = bounds_lower_Tamb;
    %bounds_upper = bounds_upper_Tamb;
    %covMatrix = covMatrix_Tamb;
    
%     foundValidSample = 0;
%     while ~foundValidSample
%         % Draw a sample from a Normal distribution
%         thisSample = mvnrnd( zeros(obj.n_xi,1) , obj.covMatrix , 1)';
%         % Check this sample satisfies the bounds
%         checkLower = sum( thisSample < obj.bounds_lower );
%         checkUpper = sum( thisSample > obj.bounds_upper );
%         if (~checkLower) && (~checkUpper)
%             foundValidSample = 1;
%         end
%         
%     end
% sampleNoise = thisSample;

    % Convert the input random vector into a multivariant sample for the
    % described disturbance
    sampleNoise = obj.covMatrixDecomp * tempRandNumbers;
    
    
    
    returnSample = sampleMean_Tamb + sampleNoise;
    
    % Finally check the sample to be passed back is the expected size
    

end
% END OF FUNCTION