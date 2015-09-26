function returnSuccess = initialiseDisturbanceRandStreamWithRandStream( obj , inputRandStream )
% Defined for the "Disturbance_Model" class, this function initialises a
% Random Stream Object from the input Seed and the type of Rand Stream that
% should be specified in the input details
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



    % Rather than directly assign the "input Rand Stream" object to the
    % respective property of this "Disturbance Model" object, we extract
    % the details from it and create an identical RandStream object
    % instead.
    % This is done to ensure that there is no "shallow-copy" type
    % interdependencies between the various copies of the "Disturbance
    % Coordinators" that could lead to all sampling happening from the same
    % "Random Stream" and hence destroy the reproducability of the results

    %% EXTRACT THE DETAILS FROM THE INPUT
    rng_seed            = inputRandStream.Seed;
    rng_generatorType   = inputRandStream.Type;
    rng_numStreams      = inputRandStream.NumStreams;
    rng_streamIndices   = inputRandStream.StreamIndex;


    % Separate depending on whether the "Generator Type" supports multiple sub-streams
    % FOR GENERATORS THAT SUPPORT "SUB-STREAMS"
    if strcmp(rng_generatorType,'mrg32k3a') || strcmp(rng_generatorType,'mlfg6331_64')
        % Create the Rand Stream Object
        obj.randStreamObject = RandStream.create(rng_generatorType,'numstreams',rng_numStreams,'streamindices',rng_streamIndices,'Seed',rng_seed);

    % FOR GENERATORS THAT DON'T SUPPORT "SUB-STREAMS"
    elseif strcmp(rng_generatorType,'mt19937ar')
        % Create the Rand Stream Object
        obj.randStreamObject = RandStream.create(rng_generatorType,'Seed',rng_seed);

    % FOR GENERATORS THAT ARE NOT RECOGNISED
    else
        disp( ' ... ERROR: the specified random number "Generator Type" was not recognised' );
        disp(['            The specified type was:   "',rng_generatorType,'"' ]);
        error(bbConstants.errorMsg);
    end

    % If the code makes it to here then it was successful
    returnSuccess = true;


end
% END OF FUNCTION


%% THE DETAILS ACCESSIBLE FROM A RAND STREAM OBJECT
%
%         .Type
%         .Seed
%         .NumStreams
%         .StreamIndex
%         .State
%         .Substream
%         .NormalTransform
%         .Antithetic
%         .FullPrecision