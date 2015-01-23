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
    
    % Compute an internal gain sample
    sineWave_mean_IG = 0.1;
    sineWave_amp_IG  = 0.1;
    n_IG = 7;
    sampleMean_IG =  ( - sineWave_amp_IG * cos( double(startTime_mod) * (2*pi()/double(obj.N_max)) ) + sineWave_mean_IG) * ones(n_IG,1);
    
    bounds_lower_IG = - 0.05 * ones(n_IG,1);
    bounds_upper_IG =   0.05 * ones(n_IG,1);
    
    covMatrix_IG = diag( 0.02^2 * ones(n_IG,1) );
    
    % Copmute an Ambient Temperature sample
    sineWave_mean_Tamb = 7.5;
    sineWave_amp_Tamb  = 7.5;
    n_Tamb = 1;
    sampleMean_Tamb =  ( - sineWave_amp_Tamb * cos( double(startTime_mod) * (2*pi()/double(obj.N_max)) ) + sineWave_mean_Tamb) * ones(n_Tamb,1);
    
    bounds_lower_Tamb = - 20 * ones(n_Tamb,1);
    bounds_upper_Tamb =   20 * ones(n_Tamb,1);
    
    covMatrix_Tamb = diag( 1^2 * ones(n_Tamb,1) );
    
    % Copmute a Solar Radiation sample
    sineWave_mean_SolarRad = 0.5;
    sineWave_amp_SolarRad  = 0.5;
    n_SolarRad = 1;
    sampleMean_SolarRad =  ( - sineWave_amp_SolarRad * cos( double(startTime_mod) * (2*pi()/double(obj.N_max)) ) + sineWave_mean_SolarRad) * ones(n_SolarRad,1);
    
    bounds_lower_SolarRad = - 0.5 * ones(n_SolarRad,1);
    bounds_upper_SolarRad =   0.5 * ones(n_SolarRad,1);
    
    covMatrix_SolarRad = diag( 0.25^2 * ones(n_SolarRad,1) );
    
    bounds_lower = [ bounds_lower_IG ; bounds_lower_Tamb ; bounds_lower_SolarRad ];
    bounds_upper = [ bounds_upper_IG ; bounds_upper_Tamb ; bounds_upper_SolarRad ];
    
    covMatrix = blkdiag( covMatrix_IG , covMatrix_Tamb , covMatrix_SolarRad );
    
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
    
    
    returnSample = [sampleMean_IG ; sampleMean_Tamb ; sampleMean_SolarRad ] + sampleNoise;
    
    % Finally check the sample to be passed back is the expected size
    
    

end
% END OF FUNCTION