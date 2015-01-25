function [] = initiliaseDisturbanceModelParameters( obj )
% Defined for the "Disturbance_Model" class, this function return a sample
% drawn from this Disturbance Model is defined
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %


    %% Specify the means and covariances
    
    % Copmute an Ambient Temperature sample
    %sineWave_mean_Tamb = 7.5;
    %sineWave_amp_Tamb  = 7.5;
    %n_Tamb = 1;
    %sampleMean_Tamb =  ( - sineWave_amp_Tamb * cos( double(startTime_mod) * (2*pi()/double(obj.N_max)) ) + sineWave_mean_Tamb) * ones(n_Tamb,1);
    
    %bounds_lower_Tamb = - 20 * ones(n_Tamb,1);
    %bounds_upper_Tamb =   20 * ones(n_Tamb,1);
    
    covMatrix_Tamb = diag( 2^2 * ones(n_Tamb,1) );
    
    %bounds_lower = bounds_lower_Tamb;
    %bounds_upper = bounds_upper_Tamb;
    
    
    covMatrix = covMatrix_Tamb;
    
    
    %% NOW PERFORM THE DECOMPOSITION OF THE COVARIANCE MATRIX
    
    % By Spectral decomposition
    [U , D] = eig(covMatrix);
    
    D = sparse(D);
    
    obj.simgaDecomp = U * sqrt(D);
    
    obj.lengthRandInputVector = size(covMatrix,1);
    
    % By Cholesky decomposition
    %[L,p] = chol(covMatrix,'lower');
    %obj.simgaDecomp = L;
    %obj.lengthRandInputVector = size(covMatrix,1);
    
    
    

end
% END OF FUNCTION