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
    
    % Copmute a sample
    sineWave_mean = 15;
    sineWave_amp  = 5;
    sampleMean =  ( - sineWave_amp * cos( double(startTime_mod) * (2*pi()/double(obj.N_max)) ) + sineWave_mean) * ones(obj.n_xi,1);
    
    bounds_lower = - 1.5 * ones(obj.n_xi,1);
    bounds_upper =   1.5 * ones(obj.n_xi,1);
    
    covMatrix = diag( 0.7^2 * ones(obj.n_xi,1) );
    
    foundValidSample = 0;
    while ~foundValidSample
        % Draw a sample from a Normal distribution
        thisSample = mvnrnd( zeros(obj.n_xi,1) , covMatrix , 1)';
        % Check this sample satisfies the bounds
        checkLower = sum( thisSample < bounds_lower );
        checkUpper = sum( thisSample > bounds_upper );
        if (~checkLower) && (~checkUpper)
            foundValidSample = 1;
        end
        
    end
    
    sampleNoise = thisSample;
    
    
    returnSample = sampleMean + sampleNoise;
    
    % Finally check the sample to be passed back is the expected size
    
    

end
% END OF FUNCTION