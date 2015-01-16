%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     computeDistributionInfo.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnDistComputed] = compute_BuildingDef(inMin,inMax,inNumSidesPerDim,inSplit,inType)

%  AUTHOR:      Paul N. Beuchat
%  DATE:        01-Jun-2014
%  GOAL:        Generate distribution information
%
%  DESC:        > Function contains 
%               
%% --------------------------------------------------------------------- %%
%% USER DEFINED INPUTS (aka. "pre-compile" switches)

% Get the size of the base vector
n = length(inMin);

% Get the size of the lifted vector
n_lift = sum(inNumSidesPerDim,1);

% Sepcify the Number of Samples to be taken for the various methods
NSamples_PerDimension_Uniform = 1000;




%% --------------------------------------------------------------------- %%
%% COMPUTE THE DISTRIBUTION INFO BASED ON THE TYPE SPECIFIED

if strcmp('uniform', inType)
    
    % Compute the number of samples to be drawn
    % Reasoning for this number:
    %   -> 
    N = NSamples_PerDimension_Uniform * n_lift^2;
    
    % Get the samples - NAIVELY
    %xSamples = repmat(inMin,1,N) + repmat((inMax-inMin),1,N) .* rand(n,N);
    
    % BETTER:
    % Get the samples one at a time and compute the mean and covariace
    % iteratively
    % Intialise the mean and convaniance to zero
    mean_uniform        = zeros(n,1);
    cov_uniform         = zeros(n,n);
    mean_uniform_lift   = zeros(n_lift,1);
    cov_uniform_lift    = zeros(n_lift,n_lift);
    
    
    % -------------------
    % KEEP THE USER INFORMED OF THE PERCENTAGE COMPLETE
    disp([' ... Taking ',num2str(N),' samples to compute the distributional info']);
    displayNumIncrements = 50;
    if displayNumIncrements > N
        displayNumIncrements = ceil(N/10);
    end
    disp('     Percentage Complete:');
    fprintf('0');
    for iTemp = 1 : displayNumIncrements-1
        fprintf('-');
    end
    fprintf('100\n');
    fprintf('|')
    displayEveryNumSamples = floor(N/displayNumIncrements);
    % ------------------------
    
    
    % Step through the number of samples request
    for iSamp = 1:N
        % Get a random sample
        thisSamp = inMin + (inMax-inMin) .* rand(n,1);
        % Add its controibution to the mean
        mean_uniform = mean_uniform + thisSamp;
        % Add its controibution to the covariance
        cov_uniform  = cov_uniform + thisSamp * thisSamp';
        
        % Compute the lifted sample
        thisSampLift = computeLiftedVector(thisSamp,inMin,inMax,inNumSidesPerDim,inSplit);
        % Add its controibution to the mean
        mean_uniform_lift = mean_uniform_lift + thisSampLift;
        % Add its controibution to the covariance
        cov_uniform_lift  = cov_uniform_lift + thisSampLift * thisSampLift';
        
        % --------------------------
        if not(mod(iSamp,displayEveryNumSamples))
            fprintf('|');
        end
        % --------------------------
    end
    % --------------------------
    fprintf('Done\n');
    % --------------------------
    
    
    % Divide everything by the number of samples
    mean_uniform        = 1/N * mean_uniform;
    cov_uniform         = 1/N * cov_uniform;
    mean_uniform_lift   = 1/N * mean_uniform_lift;
    cov_uniform_lift    = 1/N * cov_uniform_lift;
    
    % Create the return variable for this type
    returnMean      = mean_uniform;
    returnCov       = cov_uniform;
    returnMeanLift  = mean_uniform_lift;
    returnCovLift   = cov_uniform_lift;
    
    returnNumSamples        = N;
    returnNumSamplesLift    = N;
    % Keep the memory a little clean
    clear mean_uniform;
    clear cov_uniform;
    clear mean_uniform_lift;
    clear cov_uniform_lift;
    
else
    % The "inType"
    
end

%% --------------------------------------------------------------------- %%
%% BUILD THE RETURN VARIABLE
% Put in the input specifications
returnDistComputed.params.min              = inMin;
returnDistComputed.params.max              = inMax;
returnDistComputed.params.numSidesPerDim   = inNumSidesPerDim;
returnDistComputed.params.split            = inSplit;
returnDistComputed.params.type             = inType;
% Put in the Computed mean and covariance, for both the normal and lifted
% distributions
returnDistComputed.distInfo.mean             = returnMean;
returnDistComputed.distInfo.cov              = returnCov;
returnDistComputed.distInfo.numSamples       = returnNumSamples;
returnDistComputed.distInfoLifted.mean       = returnMeanLift;
returnDistComputed.distInfoLifted.cov        = returnCovLift;
returnDistComputed.distInfoLifted.numSamples = returnNumSamplesLift;



%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
%  HOW TO USE:  1) Specify the specificaion of the distribution
%
% INPUTS:
%       > xxx
%
% OUTPUTS:
%       > yyy
