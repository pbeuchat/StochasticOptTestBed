function [ returnMin , returnMax , returnMask , returnMaskChanged ] = getElementwiseMinAndMaxForSet(A, b, inputMask)
% Defined for the "Lifting" class, this function get the Piecewise Split
% Points for a given input polytope.
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



%% NOTATION FOR THIS FUNCTION:
%  x        - is the variable which the set dsectibes
%  n        - is the size of "x"
%  A,b      - describe the \mathcal{X} polytopic set 
%               "A x <= b"

%% INFER THE SIZE OF THE VARIABLE "x"
n = size(A,2);

%% EXTRACT THE INTERPRET THE "mask" THAT WAS INPUT
% First check if the mask is empty
if isempty(inputMask)
    mask = true(n,1);
    returnMaskChanged = true;
else
    % ELSE: check that mask is consitent with the size of "x"
    if not( isvector(inputMask) && (length(inputMask) == n) )
        disp( ' ... ERROR: the "inputMask" was not a vector and/or was not the correct length' );
        disp(['            length(inputMask) = ',num2str(length(inputMask)),', but it was expected to be of length = ',num2str(n) ]);
        disp(['            isvector(inputMask) = ',num2str(isvector(inputMask)) ]);
        disp( '            Using the mask "true(n,1)" instead' );
        mask = true(n,1);
        returnMaskChanged = true;
    else
        mask = inputMask;
    end
end
    

%% INITIALISE THE RETURN VARIABLE
returnMin = -inf * ones(n,1);
returnMax =  inf * ones(n,1);

%% DEFINE THE OPTIONS TO BE USED FOR THE SUBSEQUENT "linprog" OPTIMISATIONS 
if isempty(strfind(path,'mosek'))
    options_lp = optimoptions(@linprog,'Algorithm','interior-point','Diagnostics','off','Display','off','MaxIter',200,'TolFun',1e-8);
else
    options_lp = mskoptimset('');
    options_lp = mskoptimset(options_lp,'Algorithm','interior-point','Diagnostics','off','Display','off','MaxIter',200,'TolFun',1e-8);
end

%% STEP THROUGH EACH DIMENSION FOR WHICH THE MASK IS TRUE, COMPUTING "MIN" AND "MAX"

% Specify the +ve/-ve objective scaling used for each "true" dimension
fElement = [1; -1];
fElementResult = {'minimise';'maximise'};

% Step through the dimensions
for iDim = 1 : n
    % Get the mask for this dimension
    thisMask = mask(n);
    % Only compute the min and max if requested to via the "mask"
    if thisMask
        % Step through finding the "min" and "max" (resp. +ve and -ve "side)
        for iSide = 1:2
            % Get the objective scaling for this "side"
            thisfElement = fElement(iSide);
            % Create the objecitive vector "f"
            f = sparse(iElement,1,thisfElement,n,1);

            % Pass into "linprog" (this will minimise the objective)
            [~,LPfval,LPexitflag,~,~] = linprog(f,A,b,[],[],[],[],[],options_lp);

            % Check the exit flag from the optimisation
            if not(LPexitflag == 1)
                disp(' ... ERROR: "linprog" did not convergee to a solution');
                disp(['     Occurred for element ',num2str(iElement),' out of ',num2str(n),' elements']);
                thisElementResult = fElementResult{iSide,1};
                disp(['     Occurred while attempting to find the "x" that ',thisElementResult,' this element']);
                error( bbConstants.errorMsg );
            end

            % Store the result in the appropriate return variable
            if iSide == 1
                returnMin(iDim,1) = thisfElement * LPfval;
            else
                returnMax(iDim,1) = thisfElement * LPfval;
            end
        end % END OF: "for iSide = 1:2"
    end % END OF: "if thisMask"
end % END OF: "for iDim = 1 : n"


%% PUT THE MASK USED INTO THE RETURN VARIABLE
returnMask = mask;


end  % <-- END OF FUNCTION


%% LINPROG INFO
%
% "linprop" EXIT FLAGS: (as per "mosek" or "matlab" ????)
%       1  linprog converged to a solution X.
%       0  Maximum number of iterations reached.
%      -2  No feasible point found.
%      -3  Problem is unbounded.
%      -4  NaN value encountered during execution of algorithm.
%      -5  Both primal and dual problems are infeasible.
%      -7  Magnitude of search direction became too small; no further 
%           progress can be made. The problem is ill-posed or badly 
%           conditioned.

