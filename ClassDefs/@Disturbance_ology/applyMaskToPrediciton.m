function returnPred = applyMaskToPrediciton( inputStatsIncluded , inputPred , inputMask , duration )
% Defined for the "Disturbance-ology" class, this function returns the
% predicitons required at each time step
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
%               > The "trace" input is optional
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




%% KEEP THE USER UPDATES ABOUT WHAT IS HAPPENING
%disp([' ... Now loading the predictions information at time step ',num2str(startTime),' for a prediction horizon of ',num2str(duration) ]);


%% --------------------------------------------------------------------- %%
%% SPLIT THE "statsIncluded" INTO ITS INDIVIDUAL FLAGS

% NOTE: that the masking convention is defined in the constants file
getMean         = inputStatsIncluded(1,1);
getCov          = inputStatsIncluded(2,1);
getBoundsBox    = inputStatsIncluded(3,1);


%% --------------------------------------------------------------------- %%
%% CHECK THE NEED FOR A "trace" TO COMPUTE THE STATISTICS
% This is an input, to minimise the dependence on "getter" methods
%isTimeCorrelated = isDisturbanceModelTimeCorrelated( obj.myDisturbanceModel);

% if isTimeCorrelated
%     traceRequired = 1;
% else
%     traceRequired = 0;
% end



%% --------------------------------------------------------------------- %%
%% NOW EXTRACT THE APPROPRIATE PARTS OF THE PREDICITONS

%% FOR THE "MEAN"
if getMean
    returnPred.mean = inputPred.mean( repmat(inputMask , duration , 1) , 1 );
end


%% FOR THE "COV"
if getCov
    returnPred.cov = inputPred.cov( repmat(inputMask , duration , 1) , repmat(inputMask , duration , 1) );
end


%% FOR THE "BOUNDS BOX-TYPE"
if getBoundsBox
    returnPred.bounds_boxtype_lower = inputPred.bounds_boxtype_lower( repmat(inputMask , duration , 1) , 1 );
    returnPred.bounds_boxtype_upper = inputPred.bounds_boxtype_upper( repmat(inputMask , duration ,1 ) , 1 );
end



%% SET THE RETURN VARIABLE OF SUCCESS OR NOT
% if getMean
%     returnPred.mean = returnMean;
% end
% 
% if getCov
%     returnPred.cov = returnCov;
% end
% 
% if getBoundsBox
%     returnPred.bounds_boxtype_lower = reutrnBounds_boxtype_lower;
%     returnPred.bounds_boxtype_upper = reutrnBounds_boxtype_upper;
% end




end
% END OF FUNCTION
