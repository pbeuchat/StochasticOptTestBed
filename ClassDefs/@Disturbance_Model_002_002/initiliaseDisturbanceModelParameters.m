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