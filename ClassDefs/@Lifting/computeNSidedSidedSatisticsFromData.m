function [meanq, meanNSides, covNSides, riNSides, liftingOp, retractionOp, deltaMaxMin, deltaMin, deltaMax, deltaSplitPoint]  = computeNSidedSidedSatisticsFromData(NSides, qData, q0, NdT, SSingle, hSingle, inelasticParticipants)
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



% This function takes in 
%  UC       -> Uncertainty Model, containing properties of:
%     .Sigma    -> Covariance matrix Sigma governing state evolution
%     
%  Absolute bounds on state of uncertain process
%  T        -> Time horizon length T
%  n        -> Number of samples n per time step
%  q0       -> Current(Initial?) state of uncertain process
%  truncate -> Flag indicating if the state should be truncated to always
%               be within the bounds given in "?UC?"
% Output:
% 1) Nominal path of uncertain process
% 2) Variance of uncertain process relative to nominal
% 3) Polytope Delta (defined by S and h) defining bounds on delta as function of current state of uncertain process


%% GET THE SPLIT POINTS FOR THE N-SIDEDNESS
%  This needs to be the same function used in other places to ensure that
%  the same split point are computed based on the same "S" and "h"
%  description of the original uncertainty set
[deltaMaxMin, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(SSingle, hSingle, NSides);
% SYNTAX:
% [deltaMaxMin, deltaMin, deltaMax, deltaSplitPoint] = getSPlit...

%% Determine number of uncertainty states using the supplied covariance matrix
% Nd = size(UC.Sigma,1);
% if length(q0) ~= Nd
%     error('Initial state q0 does not have correct dimension for sigma')
% end
% Determine the number of samples
numSamples      = size(qData,1);
%NdT             = size(qData,2) - length(q0);
dataRangeSingle = (length(q0)+1):(+length(q0)+NdT );
numParticipants = max(size(inelasticParticipants));


%% Compute the "NdT" sizes
NdT_Single = NdT;
NdT_NSides = NSides*NdT;


%% CONVERT THE INPUT "qData" into N-SIDED DATA split about the "deltaSplitPoint"'s
% Compute the mean of the input data
%   - This takes mean of each column and return the result a row vector
meanq        =  mean( qData(:, dataRangeSingle), 1 )';

% Perform a sanity checks that things are of compatible size
if length(meanq) ~= NdT_Single
    error('The mean of the q passed in does not have a compatible dimension')
end


% Single Sided "delta" is defined about zero mean, therefore
%       minus "qmean" from the data
qSingleZeroMean = qData(:,dataRangeSingle)  -  kron( ones(numSamples,1) , meanq' );


% Initialise (pre-allocate) the N-Sided data set for speed
%qNSides = zeros(numSamples , NdT_NSides);
% NOTE: this is inefficient, should NOT store ALL the lifted samples at
% once, should instead compute the mean and cov sample-wise as the lifting
% is computed!!!!
% Now step through each sample and compute the N-Sided version of that
% sample
meanNSides = zeros(NdT_NSides, 1);
covNSides = zeros(NdT_NSides, NdT_NSides);
for iSamp = 1:numSamples
    % Get this sample from the appropriate row of all the samples
    thisq = qSingleZeroMean(iSamp, :);
    thisqNSides = zeros(1 , NdT_NSides);
    % Convert it to the N-Sided version based on "deltaSplitPoint"
    % First Side
    thisqNSides(1,1:NdT_Single) = min(thisq,deltaSplitPoint(:,1)');
    % All the middle sides
    for iSplit = 2:(NSides-1)
        rangeCol =  (NdT_Single*(iSplit-1)+1) : NdT_Single*iSplit;
        thisqNSides(1,rangeCol) = max( min(thisq,deltaSplitPoint(:,iSplit)') -deltaSplitPoint(:,(iSplit-1))' , 0 );
    end
    % Last side
    rangeCol =  (NdT_Single*(NSides-1)+1) : NdT_Single*NSides;
    thisqNSides(1,rangeCol) = max( thisq-deltaSplitPoint(:,(NSides-1))' , 0 );
    
    % Sum this into the "covReturn"
    meanNSides = meanNSides + thisqNSides';
    covNSides = covNSides + thisqNSides' * thisqNSides;
end


%% DEFINE THE RETRACTION AND LIFTING OPERATORS
% The retraction is a sum of each split component
%retractionOp = kron(ones(1,NSides), speye(NdT_Single) );
% The lifting operator is more difficult to define as a simple functional
%liftingOp = [];


% NOTE: not using these variables at the moment so return them as empty
retractionOp = [];
liftingOp = [];



%% COMPUTE THE STATSTICS - MEAN and SECOND MOMENT
% NOTE ON WHY THE ",1" IS NEED IN THE "var" AND "cov" FUNCTION:
% ",0" normalizes V by N ? 1 if N > 1, where N is the sample size. This is
%       an unbiased estimator of the variance of the population from which
%       X is drawn, as long as X consists of independent, identically
%       distributed samples.
% ",1" normalizes by N and produces the second moment of the sample about
%       its mean. var(X,0) is equivalent to var(X)
% Take mean of each column and return the result a row vector
% meanNSides   =  mean( qNSides, 1 )';
% 
% % Initialise the "covReturn" variable
% covNSides = zeros(NdT_NSides, NdT_NSides);
% % Step through each sample
% for iSamp = 1:numSamples
%     % Taking one row of "qDouble" and storing in "vi" as a column vector
%     vi = qNSides(iSamp,:)';
%     % Sum this into the "covReturn"
%     covNSides = covNSides + vi * vi';
% end
% Finally divide by the number of samples
meanNSides   = (1/numSamples) * meanNSides;
covNSides    = (1/numSamples) * covNSides;



%% NOW CONSTRUCT "ri" FOR EACH PARTICIPANT
riNSides = cell(numParticipants,1);
for iPart=1:numParticipants
    riNSides{iPart} = inelasticParticipants{iPart}.G * (meanq); %(meanq - meanOffset)
end






end  % <-- END OF FUNCTION
