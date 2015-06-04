function [disturbanceModelReturn,  T] = buildLiftedUncertaintySet(disturbanceModelStr, thisTrace, thisRHStep, thisPolicy, T)
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



%  AUTHOR:      Paul N. Beuchat
%  DATE:        1 Oct 2013
%  GOAL:        Towards Double-Sided OPF
%  DESCRIPTION: > This script ...
%               > xxx
%  HOW TO USE:  ... edit the ...
%               ... use the "pre-compile" switches on turn on/off the
%                   the following features
%
% INPUTS:
%       > No inputs required
%
% OUTPUTS:
%       > "networkConfig" is a matrix describing which buses are connected
%           to which
%           - xxx
%       > "disturbanceModelReturn" is a struct returned with the following properties
%             disturbanceModelReturn.Nd       = thisNd;
%             disturbanceModelReturn.NdT      = thisNdT;
%             disturbanceModelReturn.NdT2     = thisNdT2;
%             disturbanceModelReturn.Eq       = thisEq;
%             disturbanceModelReturn.Ed       = thisEd;
%             disturbanceModelReturn.Edd      = thisEdd;
%             disturbanceModelReturn.ri       = thisri;
%             disturbanceModelReturn.S        = thisSSingle;
%             disturbanceModelReturn.h        = thishSingle;
%             disturbanceModelReturn.q        = thisq;
%
%             disturbanceModelReturn.single2part            = thisSingle2part;
%             disturbanceModelReturn.numSides               = thisNumSides;
%             disturbanceModelReturn.numDiElements          = thisNumDiElements;
%             disturbanceModelReturn.sizeDiWidth            = thisSizeDiWidth;
% 
%             disturbanceModelReturn.inelaticParticipants   = inelasticParticipants;
%


%% LOAD THE REQUIRED PARTS OF THE DISTURBANCE MODEL FROM STRING INPUT
%disturbanceModelLocal = evalin('base',[disturbanceModelStr,'.property']);

% Properties (likely) available from the Disturbance Model
% disturbanceModel.timeHorizonMax;
% disturbanceModel.recedingHorizonMax;
% disturbanceModel.timeEnd;
% disturbanceModel.numTraces;
% disturbanceModel.Nd;
% disturbanceModel.NdT;
% disturbanceModel.UC;
% disturbanceModel.participants;      % Gives the inelastic particpants
% disturbanceModelFull.qTraces;
% disturbanceModelFull.stats{iTrace, iRHTimeStep}
%       .Single.mean;
%              .cov;
%              .ri;
%              .S;
%              .h;
%       .Double.mean;
%              .cov;
%              .ri;
%              .S;
%              .h;
%              .SAbs;
%              .hAbs;
%       .Tmax;
%       .Nd;
%       .NdT;
%       .UC;
%       .q0;
%       .inelaticParticipants.G;
%                            .n;

include_RoC_Constraints_Default = 0;

%% LOAD THE "stats" FOR THIS TRACE AND RH-STEP
% Call the "stats" property from the disturbance model in the workspace
% for this particular trace and Receding Horizon step
thisDistStats = evalin('base',[disturbanceModelStr,'.stats{',num2str(thisTrace),',',num2str(thisRHStep),'}']);

% The "q1" distburnce that will occur for progressing the RH simulation
% (This is atually a doggy way to do it cause can't do the full possible
% number of RH Steps)
%thisq1 = evalin('base',[disturbanceModelStr,'.stats{',num2str(thisTrace),',',num2str(thisRHStep+1),'}.q0']);

% The "q0" distburnce is where this set of statistics starts from
thisq0 = thisDistStats.q0;
thisTraceFull = (evalin('base',[disturbanceModelStr,'.qTraces(',num2str(thisTrace),',:)']) )';
thisTraceFull = thisTraceFull( (length(thisq0)+1):end , 1 );
full_Nd = evalin('base',[disturbanceModelStr,'.Nd']);
if thisRHStep == 1
    startNdT = 0;
else
    startNdT = sum( full_Nd(1:thisRHStep-1,1) );
end

% Extrace the trace portion for the time horizon specified
%    Note: the traces are NOT stored with "q0" at the start
thisq1 = thisTraceFull((startNdT+1):(startNdT+full_Nd(thisRHStep,1)) , 1);



%% GET THE DATA THAT IS THE SAME FOR ALL POLICIES
% Retreive the cell array of inelastic participant models from the
% Disturbance Modeller
inelasticParticipants = thisDistStats.inelaticParticipants;
numParts = max(size(inelasticParticipants));


% Check that the time horizon requested for the input is able to be
% forecast by the Disturbance Modellers
timeHorizonMax = thisDistStats.Tmax;
if (T > timeHorizonMax)
    T = timeHorizonMax;
    disp([' ... ERROR: the time horizon of ',num2str(T),' requested was greater than the max of ',num2str(timeHorizonMax),' available from the Disturbance Modellers']);
    disp([' ...        Hence the time horizon has been adjusted to the max of ',num2str(timeHorizonMax),' time steps']);
end


% Get the size of disturbance vector
Nd = thisDistStats.Nd;
% Compute the "NdT" for one side over a full horizon
NdTMax = sum(Nd,1);
% Extract only the T horizon from Nd
thisNd = Nd(1:T,:);
% Compute the commonly used variables "Nd*T" and "Nd*T*T"
thisNdT = sum(thisNd,1);
thisNdT2 = thisNdT * T;


% Get the respective portion of the UC Model
clear thisUC
thisUC.Sigma    =  thisDistStats.UC.Sigma(1:thisNdT, 1:thisNdT);
thisUC.A        =  thisDistStats.UC.A(1:T,1);
thisUC.b        =  thisDistStats.UC.b(1:T,1);

thisUC.LB       =  thisDistStats.UC.LB(1:thisNdT,1);
thisUC.UB       =  thisDistStats.UC.UB(1:thisNdT,1);

thisUC.truncate =  thisDistStats.UC.truncate;



%% GET THE POLICY DEPENDENT DATA FROM THE APPROPRIATE PLACE
% DEFINE THE VALID POLICIES
validPolicies = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
% IF NO VALID POLICY-TYPE was specified THEN USE POLICY "1" (ie. use Single Sided)
if not(sum(validPolicies == thisPolicy))
    disp(' ... > ERROR: no valid policy type was selected');
    error(' TERMINATING NOW :-( See Previous Messages and ammend!!');
    %disp('       USING SINGLE-SIDED AFFINE CONROL POLICY AS THE DEFAULT');
    %thisPolicy = 1;
end


% We always need to return the Single-Sided polytope
thisEqSingle  = thisDistStats.Single.meanq(1:thisNdT,:);
thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
thisEddSingle = thisDistStats.Single.cov(1:thisNdT,1:thisNdT);
include_RoC_Constraints = include_RoC_Constraints_Default;
[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEqSingle, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);    
thisqSingle = size(thisSSingle,1);


%% POLICY 1 - SINGLE-SIDED
% Getting the SINGLE-SIDED data
if (thisPolicy == 1)
    % Get the covariance matrix of the disturbance
    thisEq  = thisDistStats.Single.meanq(1:thisNdT,:);
    thisEd  = thisDistStats.Single.mean(1:thisNdT,:);
    thisEdd = thisDistStats.Single.cov(1:thisNdT,1:thisNdT);
    % Get the nominal prediction for each participant
    fullri = thisDistStats.Single.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    include_RoC_Constraints = include_RoC_Constraints_Default;
    [thisS, thish] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEd, thisDistStats.q0, include_RoC_Constraints);    
    thisq = size(thisS,1);
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) delta;
    thisSingle2part = speye(thisNdT);
    thisNumSides = 1;
    thisNumDiElements = thisNdT2;
    thisSizeDiWidth = thisNdT;
    
    % EVEN FOR SINGLE SIDED RETURN THE max, min & split
    % Find the max Delta for the +ve/-ve of each direction
    deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin    =  -deltaMaxMin(thisNdT+1:2*thisNdT);
    thisDeltaMax    =  deltaMaxMin(1:thisNdT,1);
    thisDeltaSplit  =  [];
    
    
%% POLICY 2 - SINGLE-SIDED OFFSET
% Getting the SINGLE-SIDED OFFSET data    
elseif (thisPolicy == 2)
    % Get the covariance matrix of the disturbance
    thisEq  = thisDistStats.SingleOff.meanq(1:thisNdT,:);
    thisEd  = thisDistStats.SingleOff.mean(1:thisNdT,:);
    thisEdd = thisDistStats.SingleOff.cov(1:thisNdT,1:thisNdT);
    % Get the nominal prediction for each participant
    fullri = thisDistStats.SingleOff.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    include_RoC_Constraints = include_RoC_Constraints_Default;
    [thisS, thish] = constructSingleSidedOffsetPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEd, thisDistStats.q0, include_RoC_Constraints);    
    thisq = size(thisS,1);
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) delta;
    thisSingle2part = speye(thisNdT);
    thisNumSides = 1;
    thisNumDiElements = thisNdT2;
    thisSizeDiWidth = thisNdT;
    
    % EVEN FOR SINGLE SIDED RETURN THE max, min & split
    % Find the max Delta for the +ve/-ve of each direction
    deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin    =  -deltaMaxMin(thisNdT+1:2*thisNdT);
    thisDeltaMax    =  deltaMaxMin(1:thisNdT,1);
    thisDeltaSplit  =  [];
    
   
%% POLICY 3 - SINGLE-SIDED OUTER HYPER-RECTANGLE
% Getting the SINGLE-SIDED OUTER HYPER-RECTANGLE
elseif (thisPolicy == 3)
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  = thisDistStats.Single.meanq(1:thisNdT,:);
    thisEd  = thisDistStats.Single.mean(1:thisNdT,:);
    thisEdd = thisDistStats.Single.cov(1:thisNdT,1:thisNdT);
    % Get the nominal prediction for each participant
    fullri = thisDistStats.Double.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end        
    end
    % Construct the Polytopic description for the disturbance set
    deltaMax = getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    
    thisS = [   speye(thisNdT);
               -speye(thisNdT)];
               
    thish = [ sparse( deltaMax(1:thisNdT,1) );
              sparse( deltaMax(thisNdT+1:2*thisNdT,1) ) ];
    
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) delta;
    thisSingle2part = speye(thisNdT);
    thisNumSides = 1;
    thisNumDiElements = thisNdT2;
    thisSizeDiWidth = thisNdT;   



%% POLICY 4 - DOUBLE-SIDED (Using Box Outer Approximation)
% Getting the DOUBLE-SIDED data by CONSTRUCTUNG A BIGGER SET IN A
% STRUCTURED MANNER
elseif (thisPolicy == 4)
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  = thisDistStats.Double.meanq(1:thisNdT,:);
    thisEd  = [thisDistStats.Double.mean(1:thisNdT,:);
               thisDistStats.Double.mean(NdTMax+1:NdTMax+thisNdT,:)];
    thisEdd = [thisDistStats.Double.cov(1:thisNdT,1:thisNdT)                  thisDistStats.Double.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT);
               thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)    thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)];
    % Get the nominal prediction for each participant
    fullri = thisDistStats.Double.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the Double-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % Find the max Delta for the +ve/-ve of each direction
    deltaMax = getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    %deltaMax = deltaMax + 1e-3;
    %closingPlaneConst = sum( max( deltaMax(1:thisNdT,1),deltaMax(thisNdT+1:2*thisNdT,1) ) );
    
    if (include_RoC_Constraints_Default)
        thisS = [[thisSSingle   -thisSSingle];
                    sparse( [diag(1./(deltaMax(1:thisNdT,1)))     diag(1./(deltaMax(thisNdT+1:2*thisNdT,1)))] );
                   -speye(thisNdT*2)];
                   %sparse(ones(1,thisNdT*2));

        thish = [ thishSingle;
                  sparse(ones(thisNdT,1));
                  sparse([],[],[],thisNdT*2,1,0)];
                    %sparse(1,1,closingPlaneConst,1,1,1);
    else
        thisS = [   sparse( [diag(1./(deltaMax(1:thisNdT,1)))     diag(1./(deltaMax(thisNdT+1:2*thisNdT,1)))] );
                   -speye(thisNdT*2)];

        thish = [ sparse(ones(thisNdT,1));
                  sparse([],[],[],thisNdT*2,1,0)];
    end
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) [max(delta,0); max(-delta,0)];
    thisSingle2part = [speye(thisNdT), -speye(thisNdT)];
    thisNumSides = 2;
    thisNumDiElements = 2* thisNdT2;
    thisSizeDiWidth   = 2* thisNdT;
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % ... DECIDED TO INCLUDE THIS FOR 2-SIDES ALSO
    % Find the max Delta for the +ve/-ve of each direction
    %deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin    = -deltaMax(thisNdT+1:2*thisNdT);
    thisDeltaMax    =  deltaMax(1:thisNdT,1);
    thisDeltaSplit  =  zeros(thisNdT, 1);
    
    


    
%% POLICY 5 - TRIPLE-SIDED (Using Box Outer Approximation)
% Getting the TRIPLE-SIDED data by CONSTRUCTUNG A BIGGER SET IN A
% STRUCTURED MANNER
elseif (thisPolicy == 5)
    % Specify Triple Sided
    NSides = 3;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)];
           
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % GET THE SAME SINGLE SIDED POLYTOPE THAT WAS USED TO CONSTRUCT THE
    % SPLIT POINTS
    %thisSSingleForNSides = thisDistStats.NSided{indexForNSides}.SSingle;
    %thishSingleForNSides = thisDistStats.NSided{indexForNSides}.hSingle;
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... NOTE: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        %error(' ... Terminating now :-( See previous messges an ammend');
        disp(' ...       > Using the split point used to compute the statistics and');
        disp(' ...         using the "deltaMin", "deltaMax" from this polytope');
        
        deltaSplitPoint = thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:);
    end
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    thisS = [ [thisSSingle   thisSSingle  thisSSingle];
              thisSBoxCH];
               
    thish = [ thishSingle;
              thishBoxCH];
    
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 3 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max(     delta-deltaSplitPoint(:,2)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;

    
    

    
%% POLICY 6 - FOUR-SIDED - (Using Box Outer Approximation)
% Getting the FOUR-SIDED data by CONSTRUCTUNG A BIGGER SET IN A
% STRUCTURED MANNER
elseif (thisPolicy == 6)
    % Specify Triple Sided
    NSides = 4;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(3*NdTMax+1:3*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)                             thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,3*NdTMax+1:3*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT) ];
           
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        %error(' ... Terminating now :-( See previous messges an ammend');
        disp(' ...       > Using the split point used to compute the statistics and');
        disp(' ...         using the "deltaMin", "deltaMax" from this polytope');
        
        deltaSplitPoint = thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:);
    end
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    if (include_RoC_Constraints_Default)
        thisS = [ [thisSSingle   thisSSingle  thisSSingle thisSSingle];
                  thisSBoxCH];

        thish = [ thishSingle;
                  thishBoxCH];
    else
        thisS = thisSBoxCH;

        thish = thishBoxCH;
    end
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 4 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max(     delta-deltaSplitPoint(:,3)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;  
    
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;

    

%% POLICY 7 - FIVE-SIDED - (Using Box Outer Approximation)
% Getting the FIVE-SIDED data by CONSTRUCTUNG A BIGGER SET IN A
% STRUCTURED MANNER
elseif (thisPolicy == 7)
    % Specify Triple Sided
    NSides = 5;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(3*NdTMax+1:3*NdTMax+thisNdT,:); 
               thisDistStats.NSided{indexForNSides}.mean(4*NdTMax+1:4*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)                             thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,4*NdTMax+1:4*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT); ];
           
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        %error(' ... Terminating now :-( See previous messges an ammend');
        disp(' ...       > Using the split point used to compute the statistics and');
        disp(' ...         using the "deltaMin", "deltaMax" from this polytope');
        
        deltaSplitPoint = thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:);
    end
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    thisS = [ [thisSSingle   thisSSingle  thisSSingle  thisSSingle  thisSSingle];
              thisSBoxCH];
               
    thish = [ thishSingle;
              thishBoxCH];
    
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 5 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max( min(delta,deltaSplitPoint(:,4)) -deltaSplitPoint(:,3) , 0 );
                              max(     delta-deltaSplitPoint(:,4)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;  
    
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;

    
%% POLICY 8 - SIX-SIDED - (Using Box Outer Approximation)
% Getting the SIX-SIDED data by CONSTRUCTUNG A BIGGER SET IN A
% STRUCTURED MANNER
elseif (thisPolicy == 8)
    % Specify Triple Sided
    NSides = 6;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(3*NdTMax+1:3*NdTMax+thisNdT,:); 
               thisDistStats.NSided{indexForNSides}.mean(4*NdTMax+1:4*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(5*NdTMax+1:5*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)                             thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT); ];
            
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        %error(' ... Terminating now :-( See previous messges an ammend');
        disp(' ...       > Using the split point used to compute the statistics and');
        disp(' ...         using the "deltaMin", "deltaMax" from this polytope');
        
        deltaSplitPoint = thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:);
    end
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    thisS = [ [thisSSingle   thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle];
              thisSBoxCH];
               
    thish = [ thishSingle;
              thishBoxCH];
    
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 6 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max( min(delta,deltaSplitPoint(:,4)) -deltaSplitPoint(:,3) , 0 );
                              max( min(delta,deltaSplitPoint(:,5)) -deltaSplitPoint(:,4) , 0 );
                              max(     delta-deltaSplitPoint(:,5)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;  
    
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;


%% POLICY 9 - SEVEN-SIDED - (Using Box Outer Approximation)
% Getting the SEVEN-SIDED data by CONSTRUCTUNG A BIGGER SET IN A
% STRUCTURED MANNER
elseif (thisPolicy == 9)
    % Specify Triple Sided
    NSides = 7;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(3*NdTMax+1:3*NdTMax+thisNdT,:); 
               thisDistStats.NSided{indexForNSides}.mean(4*NdTMax+1:4*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(5*NdTMax+1:5*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(6*NdTMax+1:6*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)                             thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,6*NdTMax+1:6*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)  ];
            
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        %error(' ... Terminating now :-( See previous messges an ammend');
        disp(' ...       > Using the split point used to compute the statistics and');
        disp(' ...         using the "deltaMin", "deltaMax" from this polytope');
        
        deltaSplitPoint = thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:);
    end
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    thisS = [ [thisSSingle   thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle];
              thisSBoxCH];
               
    thish = [ thishSingle;
              thishBoxCH];
    
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 6 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max( min(delta,deltaSplitPoint(:,4)) -deltaSplitPoint(:,3) , 0 );
                              max( min(delta,deltaSplitPoint(:,5)) -deltaSplitPoint(:,4) , 0 );
                              max( min(delta,deltaSplitPoint(:,6)) -deltaSplitPoint(:,5) , 0 );
                              max(     delta-deltaSplitPoint(:,6)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;  
    
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;

    

%% POLICY 10 - EIGHT-SIDED - (Using Box Outer Approximation)
% Getting the EIGHT-SIDED data by CONSTRUCTUNG A BIGGER SET IN A
% STRUCTURED MANNER
elseif (thisPolicy == 10)
    % Specify Triple Sided
    NSides = 8;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
%     thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
%                thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
%                thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:);
%                thisDistStats.NSided{indexForNSides}.mean(3*NdTMax+1:3*NdTMax+thisNdT,:); 
%                thisDistStats.NSided{indexForNSides}.mean(4*NdTMax+1:4*NdTMax+thisNdT,:);
%                thisDistStats.NSided{indexForNSides}.mean(5*NdTMax+1:5*NdTMax+thisNdT,:);
%                thisDistStats.NSided{indexForNSides}.mean(6*NdTMax+1:6*NdTMax+thisNdT,:);
%                thisDistStats.NSided{indexForNSides}.mean(7*NdTMax+1:7*NdTMax+thisNdT,:) ];
%            
%     thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)                             thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,7*NdTMax+1:7*NdTMax+thisNdT);
%                thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,7*NdTMax+1:7*NdTMax+thisNdT);
%                thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,7*NdTMax+1:7*NdTMax+thisNdT);
%                thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,7*NdTMax+1:7*NdTMax+thisNdT);
%                thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,7*NdTMax+1:7*NdTMax+thisNdT);
%                thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,7*NdTMax+1:7*NdTMax+thisNdT);
%                thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(6*NdTMax+1:6*NdTMax+thisNdT,7*NdTMax+1:7*NdTMax+thisNdT);
%                thisDistStats.NSided{indexForNSides}.cov(7*NdTMax+1:7*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(7*NdTMax+1:7*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(7*NdTMax+1:7*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(7*NdTMax+1:7*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(7*NdTMax+1:7*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(7*NdTMax+1:7*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(7*NdTMax+1:7*NdTMax+thisNdT,6*NdTMax+1:6*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(7*NdTMax+1:7*NdTMax+thisNdT,7*NdTMax+1:7*NdTMax+thisNdT)  ];
        
           
    thisEd  =  zeros(thisNdT*NSides,1);
    thisEdd =  zeros(thisNdT*NSides,thisNdT*NSides);
    
    for iSide = 0:NSides-1
        rangeFrom = iSide * NdTMax  + 1  :  iSide * NdTMax  + thisNdT;
        rangeTo   = iSide * thisNdT + 1  :  iSide * thisNdT + thisNdT;
        thisEd(rangeTo,:)  = thisDistStats.NSided{indexForNSides}.mean(rangeFrom,:); 
    end
    
    for iSide = 0:NSides-1
        for jSide = 0:iSide
            iRangeFrom = iSide * NdTMax  + 1  :  iSide * NdTMax  + thisNdT;
            jRangeFrom = jSide * NdTMax  + 1  :  jSide * NdTMax  + thisNdT;
            iRangeTo   = iSide * thisNdT + 1  :  iSide * thisNdT + thisNdT;
            jRangeTo   = jSide * thisNdT + 1  :  jSide * thisNdT + thisNdT;
            
            thisEdd(iRangeTo,jRangeTo)  = thisDistStats.NSided{indexForNSides}.cov(iRangeFrom,jRangeFrom);
            
            if not(iSide == jSide)
                thisEdd(jRangeTo,iRangeTo)  = thisDistStats.NSided{indexForNSides}.cov(jRangeFrom,iRangeFrom);
            end
        end
    end
           
           
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        %error(' ... Terminating now :-( See previous messges an ammend');
        disp(' ...       > Using the split point used to compute the statistics and');
        disp(' ...         using the "deltaMin", "deltaMax" from this polytope');
        
        deltaSplitPoint = thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:);
    end
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    if (include_RoC_Constraints_Default)
        thisS = [ [thisSSingle   thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle];
                  thisSBoxCH];

        thish = [ thishSingle;
                  thishBoxCH];
    else
        thisS = thisSBoxCH;
        thish = thishBoxCH;
    end
    
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 6 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max( min(delta,deltaSplitPoint(:,4)) -deltaSplitPoint(:,3) , 0 );
                              max( min(delta,deltaSplitPoint(:,5)) -deltaSplitPoint(:,4) , 0 );
                              max( min(delta,deltaSplitPoint(:,6)) -deltaSplitPoint(:,5) , 0 );
                              max( min(delta,deltaSplitPoint(:,7)) -deltaSplitPoint(:,6) , 0 );
                              max(     delta-deltaSplitPoint(:,7)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;  
    
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;

    
    
    
    
    
%% POLICY 20 - SIXTEEN-SIDED - (Using Box Outer Approximation)
% Getting the EIGHT-SIDED data by CONSTRUCTUNG A BIGGER SET IN A
% STRUCTURED MANNER
elseif (thisPolicy == 20)
    % Specify Triple Sided
    NSides = 16;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  =  zeros(thisNdT*NSides,1);
    thisEdd =  zeros(thisNdT*NSides,thisNdT*NSides);
    
    for iSide = 0:NSides-1
        rangeFrom = iSide * NdTMax  + 1  :  iSide * NdTMax  + thisNdT;
        rangeTo   = iSide * thisNdT + 1  :  iSide * thisNdT + thisNdT;
        thisEd(rangeTo,:)  = thisDistStats.NSided{indexForNSides}.mean(rangeFrom,:); 
    end
    
    for iSide = 0:NSides-1
        for jSide = 0:iSide
            iRangeFrom = iSide * NdTMax  + 1  :  iSide * NdTMax  + thisNdT;
            jRangeFrom = jSide * NdTMax  + 1  :  jSide * NdTMax  + thisNdT;
            iRangeTo   = iSide * thisNdT + 1  :  iSide * thisNdT + thisNdT;
            jRangeTo   = jSide * thisNdT + 1  :  jSide * thisNdT + thisNdT;
            
            thisEdd(iRangeTo,jRangeTo)  = thisDistStats.NSided{indexForNSides}.cov(iRangeFrom,jRangeFrom);
            
            if not(iSide == jSide)
                thisEdd(jRangeTo,iRangeTo)  = thisDistStats.NSided{indexForNSides}.cov(jRangeFrom,iRangeFrom);
            end
        end
    end
    
            
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        %error(' ... Terminating now :-( See previous messges an ammend');
        disp(' ...       > Using the split point used to compute the statistics and');
        disp(' ...         using the "deltaMin", "deltaMax" from this polytope');
        
        deltaSplitPoint = thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:);
    end
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    if (include_RoC_Constraints_Default)
        thisS = [ [thisSSingle   thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle  thisSSingle];
                  thisSBoxCH];

        thish = [ thishSingle;
                  thishBoxCH];
    else
        thisS = thisSBoxCH;
        thish = thishBoxCH;
    end
    
    thisq = size(thisS,1);
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 6 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max( min(delta,deltaSplitPoint(:,4)) -deltaSplitPoint(:,3) , 0 );
                              max( min(delta,deltaSplitPoint(:,5)) -deltaSplitPoint(:,4) , 0 );
                              max( min(delta,deltaSplitPoint(:,6)) -deltaSplitPoint(:,5) , 0 );
                              max( min(delta,deltaSplitPoint(:,7)) -deltaSplitPoint(:,6) , 0 );
                              max( min(delta,deltaSplitPoint(:,8)) -deltaSplitPoint(:,7) , 0 );
                              max( min(delta,deltaSplitPoint(:,9)) -deltaSplitPoint(:,8) , 0 );
                              max( min(delta,deltaSplitPoint(:,10)) -deltaSplitPoint(:,9) , 0 );
                              max( min(delta,deltaSplitPoint(:,11)) -deltaSplitPoint(:,10) , 0 );
                              max( min(delta,deltaSplitPoint(:,12)) -deltaSplitPoint(:,11) , 0 );
                              max( min(delta,deltaSplitPoint(:,13)) -deltaSplitPoint(:,12) , 0 );
                              max( min(delta,deltaSplitPoint(:,14)) -deltaSplitPoint(:,13) , 0 );
                              max( min(delta,deltaSplitPoint(:,15)) -deltaSplitPoint(:,14) , 0 );
                              max(     delta-deltaSplitPoint(:,15)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;  
    
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;

    
    
    
%% POLICY 11 - SINGLE-SIDED HARD-CODED
% Getting the SINGLE-SIDED HARD-CODED Data
elseif (thisPolicy == 11)
    % Get the covariance matrix of the disturbance
    thisEq  = thisDistStats.Single.meanq(1:thisNdT,:);
    thisEd  = thisDistStats.Single.mean(1:thisNdT,:);
    thisEdd = thisDistStats.Single.cov(1:thisNdT,1:thisNdT);
    % Get the nominal prediction for each participant
    fullri = thisDistStats.Single.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    %[thisS, thish] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEd, thisDistStats.q0, include_RoC_Constraints);    
    %thisq = size(thisS,1);
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) delta;
    thisSingle2part = speye(thisNdT);
    thisNumSides = 1;
    thisNumDiElements = thisNdT2;
    thisSizeDiWidth = thisNdT;
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
    
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    thisS = [ 1;
             -1
             ];
    thish = [50;
             50;
            ];
    
    thisq = size(thisS,1);
    
    thishSingle = [50;50];
        
    thisS = sparse( thisS );
    thish = sparse( thish );
    
    % EVEN FOR SINGLE SIDED RETURN THE max, min & split
    % Find the max Delta for the +ve/-ve of each direction
    deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin    =  -deltaMaxMin(thisNdT+1:2*thisNdT);
    thisDeltaMax    =  deltaMaxMin(1:thisNdT,1);
    thisDeltaSplit  =  [];
    

    
%% POLICY 12 - DOUBLE-SIDED HARD-CODED Convex Hull
% Getting the DOUBLE-SIDED HARD-CODED Data
elseif (thisPolicy == 12)
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  = thisDistStats.Double.meanq(1:thisNdT,:);
    thisEd  = [thisDistStats.Double.mean(1:thisNdT,:);
               thisDistStats.Double.mean(NdTMax+1:NdTMax+thisNdT,:)];
    thisEdd = [thisDistStats.Double.cov(1:thisNdT,1:thisNdT)                  thisDistStats.Double.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT);
               thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)    thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)];
    % Get the nominal prediction for each participant
    fullri = thisDistStats.Double.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    %[thisS, thish] = constructDoubleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEd, thisDistStats.q0, include_RoC_Constraints);    
    %thisq = size(thisS,1);
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) [max(delta,0); max(-delta,0)];
    thisSingle2part = [speye(thisNdT), -speye(thisNdT)];
    thisNumSides = 2;
    thisNumDiElements = 2*thisNdT2;
    thisSizeDiWidth = thisNdT*2;
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
         
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    thisS = sparse([ 1   1;
             -1   0;
              0  -1
             ]);
    thish = [50;
             0;
             0
            ];
    
    thisq = size(thisS,1);
    
    thishSingle = [50;50];

    thisS = sparse( thisS );
    thish = sparse( thish );
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % ... DECIDED TO INCLUDE THIS FOR 2-SIDES ALSO
    % Find the max Delta for the +ve/-ve of each direction
    deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin    = -deltaMaxMin(thisNdT+1:2*thisNdT);
    thisDeltaMax    =  deltaMaxMin(1:thisNdT,1);
    thisDeltaSplit  =  zeros(thisNdT, 1);
    

    
%% POLICY 13 - DOUBLE-SIDED HARD-CODED Box
% Getting the DOUBLE-SIDED HARD-CODED Data
elseif (thisPolicy == 13)
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  = thisDistStats.Double.meanq(1:thisNdT,:);
    thisEd  = [thisDistStats.Double.mean(1:thisNdT,:);
               thisDistStats.Double.mean(NdTMax+1:NdTMax+thisNdT,:)];
    thisEdd = [thisDistStats.Double.cov(1:thisNdT,1:thisNdT)                  thisDistStats.Double.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT);
               thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)    thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)];
    % Get the nominal prediction for each participant
    fullri = thisDistStats.Double.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    %[thisS, thish] = constructDoubleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEd, thisDistStats.q0, include_RoC_Constraints);    
    %thisq = size(thisS,1);
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) [max(delta,0); max(-delta,0)];
    thisSingle2part = [speye(thisNdT), -speye(thisNdT)];
    thisNumSides = 2;
    thisNumDiElements = 2*thisNdT2;
    thisSizeDiWidth = thisNdT*2;
    
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
         
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    thisS = [ 1   0;
              0   1;
             -1   0;
              0  -1
             ];
    thish = [50;
             50;
             0;
             0
            ];
    
    thisq = size(thisS,1);    
    
    thishSingle = [50;50];

    thisS = sparse( thisS );
    thish = sparse( thish );
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % ... DECIDED TO INCLUDE THIS FOR 2-SIDES ALSO
    % Find the max Delta for the +ve/-ve of each direction
    deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin    = -deltaMaxMin(thisNdT+1:2*thisNdT);
    thisDeltaMax    =  deltaMaxMin(1:thisNdT,1);
    thisDeltaSplit  =  zeros(thisNdT, 1);
    

    
%% POLICY 14 - DOUBLE-SIDED HARD-CODED Big1
% Getting the DOUBLE-SIDED HARD-CODED Data
elseif (thisPolicy == 14)
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  = thisDistStats.Double.meanq(1:thisNdT,:);
    thisEd  = [thisDistStats.Double.mean(1:thisNdT,:);
               thisDistStats.Double.mean(NdTMax+1:NdTMax+thisNdT,:)];
    thisEdd = [thisDistStats.Double.cov(1:thisNdT,1:thisNdT)                  thisDistStats.Double.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT);
               thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)    thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)];
    % Get the nominal prediction for each participant
    fullri = thisDistStats.Double.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    %[thisS, thish] = constructDoubleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEd, thisDistStats.q0, include_RoC_Constraints);    
    %thisq = size(thisS,1);
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) [max(delta,0); max(-delta,0)];
    thisSingle2part = [speye(thisNdT), -speye(thisNdT)];
    thisNumSides = 2;
    thisNumDiElements = 2*thisNdT2;
    thisSizeDiWidth = thisNdT*2;
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
    
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    thisS = [-1   1;
              1  -1;
              1   1;
             -1   0;
              0  -1
             ];
    thish = [50;
             50;
             124.9;
             0;
             0
            ];
    
    thisq = size(thisS,1);    
    
    thishSingle = [50;50];
    
    thisS = sparse( thisS );
    thish = sparse( thish );
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % ... DECIDED TO INCLUDE THIS FOR 2-SIDES ALSO
    % Find the max Delta for the +ve/-ve of each direction
    deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin    = -deltaMaxMin(thisNdT+1:2*thisNdT);
    thisDeltaMax    =  deltaMaxMin(1:thisNdT,1);
    thisDeltaSplit  =  zeros(thisNdT, 1);

    
    
%% POLICY 15 - DOUBLE-SIDED HARD-CODED Big2
% Getting the DOUBLE-SIDED HARD-CODED Data
elseif (thisPolicy == 15)
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  = thisDistStats.Double.meanq(1:thisNdT,:);
    thisEd  = [thisDistStats.Double.mean(1:thisNdT,:);
               thisDistStats.Double.mean(NdTMax+1:NdTMax+thisNdT,:)];
    thisEdd = [thisDistStats.Double.cov(1:thisNdT,1:thisNdT)                  thisDistStats.Double.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT);
               thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)    thisDistStats.Double.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)];
    % Get the nominal prediction for each participant
    fullri = thisDistStats.Double.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    %[thisS, thish] = constructDoubleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEd, thisDistStats.q0, include_RoC_Constraints);    
    %thisq = size(thisS,1);
    
    % @TODO - where does this belong
    thisLiftingOp = @(delta) [max(delta,0); max(-delta,0)];
    thisSingle2part = [speye(thisNdT), -speye(thisNdT)];
    thisNumSides = 2;
    thisNumDiElements = 2*thisNdT2;
    thisSizeDiWidth = thisNdT*2;
    
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
    
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    thisS = [-1   1;
              1  -1;
              1   1;
             -1   0;
              0  -1
             ];
    thish = [50;
             50;
             125.1;
             0;
             0
            ];
    
    thisq = size(thisS,1);
    
    thishSingle = [50;50];
    
    thisS = sparse( thisS );
    thish = sparse( thish );
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % ... DECIDED TO INCLUDE THIS FOR 2-SIDES ALSO
    % Find the max Delta for the +ve/-ve of each direction
    deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin    = -deltaMaxMin(thisNdT+1:2*thisNdT);
    thisDeltaMax    =  deltaMaxMin(1:thisNdT,1);
    thisDeltaSplit  =  zeros(thisNdT, 1);
    
    
    
%% POLICY 16 - TRIPLE-SIDED HARD-CODED
% Getting the TRIPLE-SIDED HARD-CODED Data
elseif (thisPolicy == 16)
    % Specify Triple Sided
    NSides = 3;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)];
    
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % GET THE SAME SINGLE SIDED POLYTOPE THAT WAS USED TO CONSTRUCT THE
    % SPLIT POINTS
    %thisSSingleForNSides = thisDistStats.NSided{indexForNSides}.SSingle;
    %thishSingleForNSides = thisDistStats.NSided{indexForNSides}.hSingle;
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    
    
    
    
    % OVERWRITE THE \delta MIN & MAX TO MAKE THINGS NICER (and more square)
    deltaMin = -50;
    deltaMax =  50;
    
    
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    %thisS = [ [thisSSingle   thisSSingle  thisSSingle];
    %          thisSBoxCH];
    thisS = thisSBoxCH;
               
    %thish = [ thishSingle;
    %          thishBoxCH];
    thish = thishBoxCH;
    
    thisq = size(thisS,1);
    
    
    

    
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
    
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    % The "harcoded" polygon was constructed above by setting \delta min
    % and max to fixed values.

    thishSingle = [50;50];
    
    thisS = sparse( thisS );
    thish = sparse( thish );
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 3 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max(     delta-deltaSplitPoint(:,2)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % Find the max Delta for the +ve/-ve of each direction
    %deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;
    
   
    
    
    
%% POLICY 17 - FOUR-SIDED HARD-CODED
% Getting the FOUR-SIDED HARD-CODED Data
elseif (thisPolicy == 17)
    % Specify Triple Sided
    NSides = 4;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(3*NdTMax+1:3*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)                             thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,3*NdTMax+1:3*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT) ];
           
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % GET THE SAME SINGLE SIDED POLYTOPE THAT WAS USED TO CONSTRUCT THE
    % SPLIT POINTS
    %thisSSingleForNSides = thisDistStats.NSided{indexForNSides}.SSingle;
    %thishSingleForNSides = thisDistStats.NSided{indexForNSides}.hSingle;
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    
    
    
    
    % OVERWRITE THE \delta MIN & MAX TO MAKE THINGS NICER (and more square)
    deltaMin = -50;
    deltaMax =  50;
    
    
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    %thisS = [ [thisSSingle   thisSSingle  thisSSingle];
    %          thisSBoxCH];
    thisS = thisSBoxCH;
               
    %thish = [ thishSingle;
    %          thishBoxCH];
    thish = thishBoxCH;
    
    thisq = size(thisS,1);
    
    
    

    
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
    
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    % The "harcoded" polygon was constructed above by setting \delta min
    % and max to fixed values.

    thishSingle = [50;50];
    
    thisS = sparse( thisS );
    thish = sparse( thish );
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 4 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max(     delta-deltaSplitPoint(:,3)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % Find the max Delta for the +ve/-ve of each direction
    %deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;
    

    

    
%% POLICY 18 - FIVE-SIDED HARD-CODED
% Getting the FIVE-SIDED HARD-CODED Data
elseif (thisPolicy == 18)
    % Specify Triple Sided
    NSides = 5;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(3*NdTMax+1:3*NdTMax+thisNdT,:); 
               thisDistStats.NSided{indexForNSides}.mean(4*NdTMax+1:4*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)                             thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,4*NdTMax+1:4*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT); ];
           
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % GET THE SAME SINGLE SIDED POLYTOPE THAT WAS USED TO CONSTRUCT THE
    % SPLIT POINTS
    %thisSSingleForNSides = thisDistStats.NSided{indexForNSides}.SSingle;
    %thishSingleForNSides = thisDistStats.NSided{indexForNSides}.hSingle;
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    
    
    
    
    % OVERWRITE THE \delta MIN & MAX TO MAKE THINGS NICER (and more square)
    deltaMin = -50;
    deltaMax =  50;
    
    
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    %thisS = [ [thisSSingle   thisSSingle  thisSSingle];
    %          thisSBoxCH];
    thisS = thisSBoxCH;
               
    %thish = [ thishSingle;
    %          thishBoxCH];
    thish = thishBoxCH;
    
    thisq = size(thisS,1);
    
    
    

    
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
    
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    % The "harcoded" polygon was constructed above by setting \delta min
    % and max to fixed values.

    thishSingle = [50;50];
    
    thisS = sparse( thisS );
    thish = sparse( thish );
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 4 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max( min(delta,deltaSplitPoint(:,4)) -deltaSplitPoint(:,3) , 0 );
                              max(     delta-deltaSplitPoint(:,4)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % Find the max Delta for the +ve/-ve of each direction
    %deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;
    

    
    

%% POLICY 19 - SIX-SIDED HARD-CODED
% Getting the SIX-SIDED HARD-CODED Data
elseif (thisPolicy == 19)
    % Specify Triple Sided
    NSides = 6;
    % Find the index that corresponds N-Sidedness required
    numPossibleSidedness = length( thisDistStats.NSided );
    indexForNSides = 0;
    for iSidedness = 1:numPossibleSidedness
        thisNSides = thisDistStats.NSided{iSidedness}.NSides;
        if (thisNSides == NSides)
            indexForNSides = iSidedness;
        end
    end
    if (indexForNSides == 0)
        disp(' ... ERROR: Could not find data in the disturbance model for the sidedness requested');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    % Get the mean vector and covariance matrix of the disturbance
    thisEq  =  thisDistStats.NSided{indexForNSides}.meanq(1:thisNdT,:);
    
    thisEd  = [thisDistStats.NSided{indexForNSides}.mean(1:thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(NdTMax+1:NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(2*NdTMax+1:2*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(3*NdTMax+1:3*NdTMax+thisNdT,:); 
               thisDistStats.NSided{indexForNSides}.mean(4*NdTMax+1:4*NdTMax+thisNdT,:);
               thisDistStats.NSided{indexForNSides}.mean(5*NdTMax+1:5*NdTMax+thisNdT,:) ];
           
    thisEdd = [thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,1:thisNdT)                        thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,NdTMax+1:NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)                             thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)                         thisDistStats.NSided{indexForNSides}.cov(1:thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,1:thisNdT)          thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)               thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(NdTMax+1:NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(2*NdTMax+1:2*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(3*NdTMax+1:3*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(4*NdTMax+1:4*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT);
               thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,1:thisNdT)      thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,NdTMax+1:NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,2*NdTMax+1:2*NdTMax+thisNdT)           thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,3*NdTMax+1:3*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,4*NdTMax+1:4*NdTMax+thisNdT)       thisDistStats.NSided{indexForNSides}.cov(5*NdTMax+1:5*NdTMax+thisNdT,5*NdTMax+1:5*NdTMax+thisNdT); ];
           
    % Get the nominal prediction for each participant
    fullri = thisDistStats.NSided{indexForNSides}.ri;
    thisri = cell(numParts,1);
    thisGi = cell(numParts,1);
    for iPart = 1:numParts
        if (inelasticParticipants{iPart}.inelastic)
            if isfield( inelasticParticipants{iPart} , 'rOffset' )
                thisrOffset = inelasticParticipants{iPart}.rOffset(1:T,:);
            else
                thisrOffset = zeros(T,1);
            end
            thisri{iPart} = fullri{iPart}(1:T,:) + thisrOffset;
            thisGi{iPart} = inelasticParticipants{iPart}.G(1:T,1:thisNdT);
        else
            thisri{iPart} = zeros(T,1);
            thisGi{iPart} = zeros(T,thisNdT);
        end
    end
    % Construct the Polytopic description for the disturbance set
    %include_RoC_Constraints = include_RoC_Constraints_Default;
    % Get the Single Sided set first
    %thisEdSingle  = thisDistStats.Single.mean(1:thisNdT,:);
    %[thisSSingle, thishSingle] = constructSingleSidedPolytopeFromUCAndStats(thisDistStats.UC, T, thisNd, thisNdT, thisEq, thisEdSingle, thisDistStats.q0, include_RoC_Constraints);
    % Turn this into the N-Sided Semi-Infinite Slab Set
    % Cutting off the slab with a plane far enough out
    % And making the box set
    
    % GET THE SAME SINGLE SIDED POLYTOPE THAT WAS USED TO CONSTRUCT THE
    % SPLIT POINTS
    %thisSSingleForNSides = thisDistStats.NSided{indexForNSides}.SSingle;
    %thishSingleForNSides = thisDistStats.NSided{indexForNSides}.hSingle;
    
    % Get the split points for each dimension
    [~, deltaMin, deltaMax, deltaSplitPoint] = getSplitPointFromPolytopeSingleForNSides(thisSSingle, thishSingle, NSides);
    
    % Double check these split points agree with those used to compute the
    % statistics
    threshhold = 1e-4;
    check1 =     sum( abs(deltaMin          -  thisDistStats.NSided{indexForNSides}.deltaMin(1:thisNdT,1))      >  threshhold );
    check2 =     sum( abs(deltaMax          -  thisDistStats.NSided{indexForNSides}.deltaMax(1:thisNdT,1))      >  threshhold );
    check3 = sum(sum( abs(deltaSplitPoint   -  thisDistStats.NSided{indexForNSides}.deltaSplit(1:thisNdT,:))    >  threshhold ));
    
    if ( check1 || check2 || check3 )
        disp(' ... ERROR: The split points computed for get info from the disturbance model');
        disp(' ...        does NOT agree with the split points used to compute the statistics');
        error(' ... Terminating now :-( See previous messges an ammend');
    end
    
    
    
    
    % OVERWRITE THE \delta MIN & MAX TO MAKE THINGS NICER (and more square)
    deltaMin = -50;
    deltaMax =  50;
    
    
    
    
    % Now construct Angelos' Convex Hulled Piecewise split Hyper-rectangle Set 
    %
    % BUILD THE CONSTANT TERM WHICH BECOMES THE rhs OF THE INEQUALITY
    % AND THE V inv TERM WHICH BECOMES THE lhs OF THE INEQUALITY
    % For each dimension compute this part
    % Hence pre-allocate space
    thishCell = cell(thisNdT,1);
    thisVCell = cell(thisNdT,1);
    % Step through each dimension
    for iDim = 1:thisNdT
        % For the constant term of size (numSplits+1 -by- 1)
        thishTerms = [   deltaSplitPoint(iDim,1) / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  , ...
                        -deltaMin(iDim,1)        / (deltaSplitPoint(iDim,1) - deltaMin(iDim,1))  ];
        thishCell{iDim} = sparse([1 2],[1 1],thishTerms,NSides+1,1);
        
        % Each V inverse is of size  (numSplits+1 -by- numSplits) with
        % 2*numSplits non-zero elements
        %thisV = sparse([],[],[],numSplits+1,numSplits, 2*numSplits);
        iSparse = [1   kron(2:NSides,[1 1])   NSides+1]';
        jSparse = kron(1:NSides,[1 1])';
        sSparse = zeros(2*NSides,1);
        sSparse(1:2) = [-1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1));
                         1/(deltaSplitPoint(iDim,1) - deltaMin(iDim,1)) ];
        if NSides > 2
            for iSplit = 2:NSides-1
                rangeTemp = (2*iSplit-1):(2*iSplit);
                sSparse(rangeTemp,1) = [-1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1));
                                         1/(deltaSplitPoint(iDim,iSplit) - deltaSplitPoint(iDim,iSplit-1)) ];
            end
        end
        
        sSparse( (2*NSides-1):(2*NSides) , 1) = [-1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1));
                                                  1/(deltaMax(iDim,1) - deltaSplitPoint(iDim,NSides-1)) ];
        
        % Create the V inv matrix as per the structure in Angelos' paper
        tempV = sparse(iSparse,jSparse,sSparse,NSides+1,NSides, 2*NSides);
        % Then space it out to agree with our layout of the lifted
        % dimensions
        thisVCell{iDim} = kron(tempV , sparse(1,iDim,1,1,thisNdT,1));
    end
    
    % NOW STACK ALL THESE POLYTOPES BLOCK DIAGONALLY
    % Noting that the dimension were carefully laid out in the above
    thisSBoxCH = -vertcat( thisVCell{:} );
               
    thishBoxCH =  vertcat( thishCell{:} );
    
    %thisS = [ [thisSSingle   thisSSingle  thisSSingle];
    %          thisSBoxCH];
    thisS = thisSBoxCH;
               
    %thish = [ thishSingle;
    %          thishBoxCH];
    thish = thishBoxCH;
    
    thisq = size(thisS,1);
    
    
    

    
    
    % NOW PUT IN THE HARDCODED NOMINAL POWER - "thisri"
    thisri = { 0, 0, -150};
    
    % NOW PUT IN THE HARDCODED POLYGON - "thisS", "thish", "thisq"
    % The "harcoded" polygon was constructed above by setting \delta min
    % and max to fixed values.

    thishSingle = [50;50];
    
    thisS = sparse( thisS );
    thish = sparse( thish );
    
    
    
    % @TODO - where does this belong
    % For now the lifting is hard-coded for 4 sides
    thisLiftingOp = @(delta) [     min(delta,deltaSplitPoint(:,1));
                              max( min(delta,deltaSplitPoint(:,2)) -deltaSplitPoint(:,1) , 0 );
                              max( min(delta,deltaSplitPoint(:,3)) -deltaSplitPoint(:,2) , 0 );
                              max( min(delta,deltaSplitPoint(:,4)) -deltaSplitPoint(:,3) , 0 );
                              max( min(delta,deltaSplitPoint(:,5)) -deltaSplitPoint(:,4) , 0 );
                              max(     delta-deltaSplitPoint(:,5)                        , 0 )
                              ];
    thisSingle2part = kron( ones(1,NSides) , speye(thisNdT) );
    thisNumSides = NSides;
    thisNumDiElements = NSides*thisNdT2;
    thisSizeDiWidth = thisNdT*NSides;
    
    % IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
    % Find the max Delta for the +ve/-ve of each direction
    %deltaMaxMin     =  getElementwiseMaxAndMinForSet(thisSSingle, thishSingle);
    thisDeltaMin = deltaMin;
    thisDeltaMax = deltaMax;
    thisDeltaSplit = deltaSplitPoint;

    
    
    
    
    
% Handling an unrecognised policy
else
    disp(' ... ERROR: The policy requested is not recognise');
    disp('     THIS SHOULD NEVER HAVE OCCURRED, PLEASE INVESTIGATE THE AMMEND');
    error(' ... Terminating now :-( See previous messges an ammend');
end



%% COMPUTE THE DELTA TO BE APPLIED FOR THE RH SIMLUATION
thisDelta1 = thisq1 - thisEqSingle(1:Nd(1),:);


%% PUT ALL THE REQUIRED PROPERTIES INTO THE RETURN DISTURBANCE MODEL
clear disturbanceModelReturn;
disturbanceModelReturn.q0       = thisq0;
disturbanceModelReturn.q1       = thisq1;
disturbanceModelReturn.delta1   = thisDelta1;
disturbanceModelReturn.Nd       = thisNd;
disturbanceModelReturn.NdT      = thisNdT;
disturbanceModelReturn.NdT2     = thisNdT2;
disturbanceModelReturn.Eq       = thisEq;
disturbanceModelReturn.Ed       = thisEd;
disturbanceModelReturn.Edd      = thisEdd;
disturbanceModelReturn.ri       = thisri;
disturbanceModelReturn.Gi       = thisGi;
disturbanceModelReturn.S        = thisS;
disturbanceModelReturn.h        = thish;
disturbanceModelReturn.q        = thisq;
disturbanceModelReturn.UC       = thisUC;

disturbanceModelReturn.liftingOp        = thisLiftingOp;
disturbanceModelReturn.single2part      = thisSingle2part;
disturbanceModelReturn.numSides         = thisNumSides;
disturbanceModelReturn.numDiElements    = thisNumDiElements;
disturbanceModelReturn.sizeDiWidth      = thisSizeDiWidth;

disturbanceModelReturn.inelasticParticipants = inelasticParticipants;

disturbanceModelReturn.SSingle      = thisSSingle;
disturbanceModelReturn.hSingle      = thishSingle;
disturbanceModelReturn.qSingle      = thisqSingle;
disturbanceModelReturn.EdSingle     = thisEdSingle;
disturbanceModelReturn.EddSingle    = thisEddSingle;


% IF MORE THAN 3 SIDES THEN INCLUDE THE SPLIT POINTS ALSO
if (thisNumSides > 1 || thisNumSides == 1)
    disturbanceModelReturn.deltaMin = thisDeltaMin;
    disturbanceModelReturn.deltaMax = thisDeltaMax;
    disturbanceModelReturn.deltaSplit = thisDeltaSplit;
end


end  % <-- END OF FUNCTION


%% NOTE
% Get the definiton of the disturbance set Delta cannot be taken directly
% from the existing
%       S = thisDistStats.Single.S;
%       h = thisDistStats.Single.h;
% properties because it is time horizon dependent

%% ---------------------------------------------------------------------- %
%% STRUCTURE OF THE DISTURBANCE MODEL ACCESSED VIA "disturbanceModelStr" 
%disturbanceModelLocal = evalin('base',[disturbanceModelStr,'.property']);

% Properties (likely) available from the Disturbance Model
% disturbanceModel.timeHorizonMax;
% disturbanceModel.recedingHorizonMax;
% disturbanceModel.timeEnd;
% disturbanceModel.numTraces;
% disturbanceModel.Nd;
% disturbanceModel.NdT;
% disturbanceModel.UC;
% disturbanceModel.participants;      % Gives the inelastic particpants
% disturbanceModelFull.qTraces;
% disturbanceModelFull.stats{iTrace, iRHTimeStep}
%       .Single.meanq;
%              .mean;
%              .cov;
%              .ri{};
%              .S;
%              .h;
%              .Smin;
%              .hmin;
%              .Smax;
%              .hmax;
%       .SingleOff.meanq;
%                 .mean
%                 .cov;
%                 .ri{};
%                 .S;
%                 .h;
%                 .Smin;
%                 .hmin;
%                 .Smax;
%                 .hmax;
%       .Double.meanq;
%              .mean;
%              .cov;
%              .ri{};
%              .S;
%              .h;
%              .SAbs;
%              .hAbs;
%       .Tmax;
%       .Nd;
%       .NdT;
%       .UC;
%       .q0;
%       .inelaticParticipants{}.G;
%                              .n;


