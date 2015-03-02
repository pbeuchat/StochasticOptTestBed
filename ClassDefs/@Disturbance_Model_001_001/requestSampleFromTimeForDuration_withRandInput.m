function returnSample = requestSampleFromTimeForDuration_withRandInput( obj , startTime , duration , startXi , inputRandNumbers )
% Defined for the "Disturbance_Model" class, this function return a sample
% drawn from this Disturbance Model is defined
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    if startTime == 1
        obj.flag_tempFirst = false;
        obj.tempOffset = 2*inputRandNumbers(1,1);
    end



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
    if ~( isvector(inputRandNumbers) && (length(inputRandNumbers) == obj.lengthRandInputVector) )
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
    sampleNoise = obj.covMatrixDecomp * inputRandNumbers;
    
    
    
    returnSample = sampleMean_Tamb + 0.3*sampleNoise + obj.tempOffset;
    
    % Finally check the sample to be passed back is the expected size
    
    

end
% END OF FUNCTION


%% --------------------------------------------------------------------- %%

%% SEE THIS WIKIPEDIA PAGE FOR THE THEORY BEHIND GENERATING THE "mvn" SAMPLE
%
%       http://en.wikipedia.org/wiki/Multivariate_normal_distribution#Drawing_values_from_the_distribution
%
%
%
%
%
%
%