function [ ] = visualise_multipleControllers( inputControllerSpecs , inputDataCellArray , inputPropertyNames , plotOptions )
% Defined for the "Visualisation" class, this function plots the results
% for one controller
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



% Set the default interpretter for text to be latex
%   > This will apply to all figures created
set(0, 'defaultTextInterpreter', 'latex');


%% EXTRACT THE SELECTED PLOTTING OPTIONS FROM THE "plotOptions" INPUT VARIABLE
unitsForTimeAxis = plotOptions.unitsForTimeAxis;

% And hence specify the label to be used for the time axis
if strcmp( unitsForTimeAxis , 'steps' )
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    thisTimeLabel   = 'Time [hours]';
    % Need to put a few extra statements in here to detect the exact units
    % of "inputDataStruct.time.data(2,:);" and scale it appropriately
else
    disp( ' ... ERROR: The "unitsForTimeAxis" plotting option was not a recognised string');
    disp( '            Option requested is:');
    disp(unitsForTimeAxis);
end

% When comparing controllers is "only" makes sense to compare in absolute
% time in case that the data was stored at a different regularity
thisTimeLabel   = 'Time [hours]';


%% EXTRACT THE NUMBER OF CONTROLLERS TO BE COMPARED
numControllers = size(inputDataCellArray,1);

labelPerController = cell(numControllers,1);
for iController = 1:numControllers
    labelPerController{iController,1} = inputControllerSpecs{iController}.legend;
end


%% --------------------------------------------------------------------- %%
%% PLOT THE STATES (Those of importance and everything)
% Get the data
% @TODO - THERE IS A PARTIAL HACK HERE BECUSE "1:7" IS HARDCODED!!!
indiciesToPlot = (1:7)';
numStatesToCompare = length(indiciesToPlot);


% To allow for different lengths of the data, store both the horizontal and
% vertical axis data in a cell array
data = cell(numControllers,1);
timeForPlot = cell(numControllers,1);

% THIS FIGURE WILL HAVE ONE SUB-PLOT PER STATE-TO-COMPARE

% The "plotOptions" will mostly stay the same for each sub-plot
% Specify the plotting options
thisPlotOptions = { 'XLabelString'      ,  []                     ;...
                    'YLabelString'      ,  []                                ;...
                    'titleString'       ,  []                                ;...
                    'legendOnOff'       ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'LineColourIndex'   ,  1:numControllers                  ;...
                    'LineWidth'         ,  Visualisation.lineWidthDefault    ;...
                    %'maRkerIndex'       ,  ones(numLinesToPlot,1)            ;...
                    'legendStrings'     ,  labelPerController                ;...
                    'legendFontSize'    ,  12                                ;...
                    'legendFontWeight'  ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'legendLocation'    ,  'east'                    ;...    % OPTIONS: see below
                    'legendInterpreter' ,  'none'                            ;...    % OPTIONS: 'latex', 'tex', 'none'
                    'titleFontSize'     ,  24                                ;...
                    'titleFontWeight'   ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'titleColour'       ,  'black'                           ;...
                    'XLabelColour'      ,  'black'                           ;...
                    'YLabelColour'      ,  'black'                           ;...
                    'LabelFontSize'     ,  14                                ;...
                    'LabelFontWeight'   ,  'bold'                            ;...
                    'XGridOnOff'        ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'YGridOnOff'        ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'gridStyle'         ,  '--'                              ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                    'gridColour'        ,  [0.5 0.5 0.5]                     ;...
                    'XGridMinorOnOff'   ,  'off'                             ;...    % OPTIONS: 'off', 'on'
                    'YGridMinorOnOff'   ,  'off'                             ;...    % OPTIONS: 'off', 'on'
                    'gridMinorStyle'    ,  ':'                               ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                    'gridMinorColour'   ,  [0.5 0.5 0.5]                     ;...
                    %'XTickNumbersOnOff'
                    %'YTickNumbersOnOff'
                  };

% Create the figure
hFig = figure('position',[0 200 800 1200]);
set(hFig,'Color', Visualisation.figure_backgroundColour );

% Hence iterate through the number of states-to-compare
for iState = 1:numStatesToCompare
    % Get the index of this state
    thisStateIndex = indiciesToPlot(iState,1);


    % Construct the data to be plotted
    for iController = 1:numControllers
        thisProperty = inputPropertyNames{2};
        thisTimeProperty = inputPropertyNames{1};
        % Get the data for this controller and this state
        data{iController,1} = inputDataCellArray{iController,1}.(thisProperty).data(thisStateIndex,:,1);
        % When comparing controllers is "only" makes sense to compare
        % in absolute time in case that the data was stored at a different
        % regularity
        dimPerTime      = inputDataCellArray{iController,1}.(thisProperty).dimPerTime;
        timeLength      = size( data{iController,1} , dimPerTime+1 );
        timeForPlot{iController,1} = inputDataCellArray{iController,1}.(thisTimeProperty).data(2,1:timeLength);
    end
    
    % Put in the xLabel, yLabel and Title options as required
    if (iState == 1)
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisStateIndex};
        thisPlotOptions{3,2} = 'State, $x$ (Temperature [T]) vs. Time';
        thisPlotOptions{4,2} = 'on';
    elseif (iState == numStatesToCompare)
        thisPlotOptions{1,2} = thisTimeLabel;
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisStateIndex};
        thisPlotOptions{3,2} = [];
        thisPlotOptions{4,2} = 'off';
    else
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisStateIndex};
        thisPlotOptions{3,2} = [];
        thisPlotOptions{4,2} = 'off';
    end
    
    
    % Create the axes for ALL the states
    hAxes = subplot(numStatesToCompare,1,iState);
    % Now call the generic plotting function
    Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );
        
        
end


%% --------------------------------------------------------------------- %%
%% PLOT THE INPUTS (Those of importance and everything)
% Get the data
% @TODO - THERE IS A PARTIAL HACK HERE BECUSE "1:7" IS HARDCODED!!!
thisProperty = inputPropertyNames{3};
numInputsToCompare = size(inputDataCellArray{1,1}.(thisProperty).data,1);


% To allow for different lengths of the data, store both the horizontal and
% vertical axis data in a cell array
data = cell(numControllers,1);
timeForPlot = cell(numControllers,1);

% THIS FIGURE WILL HAVE ONE SUB-PLOT PER STATE-TO-COMPARE

% The "plotOptions" will mostly stay the same for each sub-plot
% Specify the plotting options
thisPlotOptions = { 'XLabelString'      ,  []                     ;...
                    'YLabelString'      ,  []                                ;...
                    'titleString'       ,  []                                ;...
                    'legendOnOff'       ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'LineColourIndex'   ,  1:numControllers                  ;...
                    'LineWidth'         ,  Visualisation.lineWidthDefault    ;...
                    %'maRkerIndex'       ,  ones(numLinesToPlot,1)            ;...
                    'legendStrings'     ,  labelPerController                ;...
                    'legendFontSize'    ,  12                                ;...
                    'legendFontWeight'  ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'legendLocation'    ,  'east'                    ;...    % OPTIONS: see below
                    'legendInterpreter' ,  'none'                            ;...    % OPTIONS: 'latex', 'tex', 'none'
                    'titleFontSize'     ,  24                                ;...
                    'titleFontWeight'   ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'titleColour'       ,  'black'                           ;...
                    'XLabelColour'      ,  'black'                           ;...
                    'YLabelColour'      ,  'black'                           ;...
                    'LabelFontSize'     ,  14                                ;...
                    'LabelFontWeight'   ,  'bold'                            ;...
                    'XGridOnOff'        ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'YGridOnOff'        ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'gridStyle'         ,  '--'                              ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                    'gridColour'        ,  [0.5 0.5 0.5]                     ;...
                    'XGridMinorOnOff'   ,  'off'                             ;...    % OPTIONS: 'off', 'on'
                    'YGridMinorOnOff'   ,  'off'                             ;...    % OPTIONS: 'off', 'on'
                    'gridMinorStyle'    ,  ':'                               ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                    'gridMinorColour'   ,  [0.5 0.5 0.5]                     ;...
                    %'XTickNumbersOnOff'
                    %'YTickNumbersOnOff'
                  };

% Create the figure
hFig = figure('position',[800 200 800 1200]);
set(hFig,'Color', Visualisation.figure_backgroundColour );

% Hence iterate through the number of states-to-compare
for iInput = 1:numInputsToCompare
    % Get the index of this state
    thisInputIndex = iInput;


    % Construct the data to be plotted
    for iController = 1:numControllers
        thisProperty = inputPropertyNames{3};
        thisTimeProperty = inputPropertyNames{1};
        % Get the data for this controller and this state
        data{iController,1} = inputDataCellArray{iController,1}.(thisProperty).data(thisInputIndex,:,1);
        % When comparing controllers is "only" makes sense to compare
        % in absolute time in case that the data was stored at a different
        % regularity
        dimPerTime      = inputDataCellArray{iController,1}.(thisProperty).dimPerTime;
        timeLength      = size( data{iController,1} , dimPerTime+1 );
        timeForPlot{iController,1} = inputDataCellArray{iController,1}.(thisTimeProperty).data(2,1:timeLength);
    end
    
    % Put in the xLabel, yLabel and Title options as required
    if (iInput == 1)
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisInputIndex};
        thisPlotOptions{3,2} = 'Input, $u$ vs. Time';
        thisPlotOptions{4,2} = 'on';
    elseif (iInput == numInputsToCompare)
        thisPlotOptions{1,2} = thisTimeLabel;
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisInputIndex};
        thisPlotOptions{3,2} = [];
        thisPlotOptions{4,2} = 'off';
    else
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisInputIndex};
        thisPlotOptions{3,2} = [];
        thisPlotOptions{4,2} = 'off';
    end
    
    
    % Create the axes for ALL the states
    hAxes = subplot(numInputsToCompare,1,iInput);
    % Now call the generic plotting function
    Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );
        
        
end


%% PLOT THE COSTS (Those of importance and everything)
% Get the data
% @TODO - THERE IS A PARTIAL HACK HERE BECUSE "1:7" IS HARDCODED!!!
thisProperty = inputPropertyNames{5};
numCostsToCompare = size(inputDataCellArray{1,1}.(thisProperty).data,1);
labelPerDim       = inputDataCellArray{1,1}.(thisProperty).labelPerDim;

% To allow for different lengths of the data, store both the horizontal and
% vertical axis data in a cell array
data = cell(numControllers,1);
timeForPlot = cell(numControllers,1);

%dataCumulativeCost = zeros(numControllers,1);

% THIS FIGURE WILL HAVE ONE SUB-PLOT PER STATE-TO-COMPARE

% The "plotOptions" will mostly stay the same for each sub-plot
% Specify the plotting options
thisPlotOptions = { 'XLabelString'      ,  []                     ;...
                    'YLabelString'      ,  []                                ;...
                    'titleString'       ,  []                                ;...
                    'legendOnOff'       ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'LineColourIndex'   ,  1:numControllers                  ;...
                    'LineWidth'         ,  Visualisation.lineWidthDefault    ;...
                    %'maRkerIndex'       ,  ones(numLinesToPlot,1)            ;...
                    'legendStrings'     ,  labelPerController                ;...
                    'legendFontSize'    ,  12                                ;...
                    'legendFontWeight'  ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'legendLocation'    ,  'east'                    ;...    % OPTIONS: see below
                    'legendInterpreter' ,  'none'                            ;...    % OPTIONS: 'latex', 'tex', 'none'
                    'titleFontSize'     ,  24                                ;...
                    'titleFontWeight'   ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'titleColour'       ,  'black'                           ;...
                    'XLabelColour'      ,  'black'                           ;...
                    'YLabelColour'      ,  'black'                           ;...
                    'LabelFontSize'     ,  14                                ;...
                    'LabelFontWeight'   ,  'bold'                            ;...
                    'XGridOnOff'        ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'YGridOnOff'        ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'gridStyle'         ,  '--'                              ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                    'gridColour'        ,  [0.5 0.5 0.5]                     ;...
                    'XGridMinorOnOff'   ,  'off'                             ;...    % OPTIONS: 'off', 'on'
                    'YGridMinorOnOff'   ,  'off'                             ;...    % OPTIONS: 'off', 'on'
                    'gridMinorStyle'    ,  ':'                               ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                    'gridMinorColour'   ,  [0.5 0.5 0.5]                     ;...
                    %'XTickNumbersOnOff'
                    %'YTickNumbersOnOff'
                  };

% Create the figure
hFig = figure('position',[1600 200 800 1200]);
set(hFig,'Color', Visualisation.figure_backgroundColour );

% Hence iterate through the number of states-to-compare
for iCost = 1:numCostsToCompare
    % Get the index of this state
    thisCostIndex = iCost;

    dataCumulativeCost = zeros(numControllers,1);

    % Construct the data to be plotted
    for iController = 1:numControllers
        thisProperty = inputPropertyNames{5};
        thisTimeProperty = inputPropertyNames{1};
        % Get the data for this controller and this state
        data{iController,1} = inputDataCellArray{iController,1}.(thisProperty).data(thisCostIndex,:,1);
        % When comparing controllers is "only" makes sense to compare
        % in absolute time in case that the data was stored at a different
        % regularity
        dimPerTime      = inputDataCellArray{iController,1}.(thisProperty).dimPerTime;
        timeLength      = size( data{iController,1} , dimPerTime+1 );
        timeForPlot{iController,1} = inputDataCellArray{iController,1}.(thisTimeProperty).data(2,1:timeLength);
        
        % Compute the cumulative
        dataCumulativeCost(iController,1) = sum( data{iController,1} );
    end
    
    % Put in the xLabel, yLabel and Title options as required
    if (iCost == 1)
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = [];
        thisPlotOptions{3,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisCostIndex};
        thisPlotOptions{4,2} = 'on';
    elseif (iCost == numCostsToCompare)
        thisPlotOptions{1,2} = thisTimeLabel;
        thisPlotOptions{2,2} = [];
        thisPlotOptions{3,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisCostIndex};
        thisPlotOptions{4,2} = 'off';
    else
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = [];
        thisPlotOptions{3,2} = inputDataCellArray{iController,1}.(thisProperty).labelPerDim{1}{thisCostIndex};
        thisPlotOptions{4,2} = 'off';
    end
    
    
    % Create the axes for ALL the states
    hAxes = subplot(numCostsToCompare,4, [4*(iCost-1)+1 , 4*iCost-1] );
    % Now call the generic plotting function
    Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );
        
    % Display the Cumulative cost
    
    for iController = 1:numControllers
        hAxes = subplot(numCostsToCompare,4,4*iCost);
        % @TODO: THIS IS A HACK BECAUSE THE COLOUR CODING IS NOT CONSISTENT
        % WITH THE OTHER GRAPHS
        scatter(1:numControllers,dataCumulativeCost);
    end
    
        
end



temp = 1;

%     if (dimPerTime == 1)
%         numLinesToPlot = size(data,1);
%     elseif (dimPerTime == 2)
%         numLinesToPlot = size(data,1) * size(data,2);
%     else
%         % We are not handling this case properly
%         numLinesToPlot = 0;
%     end


%% --------------------------------------------------------------------- %%
%% plot the CUMULATIVE COST
thisProperty = 'costCumulative';
if ismember( thisProperty , inputPropertyNames )

    %% Extract the data to be plotted for "thisProperty
    data                = inputDataCellArray{1,1}.(thisProperty).data;
    dimPerRealisation   = inputDataCellArray{1,1}.(thisProperty).dimPerRealisation;
    labelPerDim         = inputDataCellArray{1,1}.(thisProperty).labelPerDim;


    %% Extract the number of realisations
    % Actually this is not really needed
    %numRealisations = size( data , dimPerRealisation+1 );

    %% Get the number of lines to be plotted, and the legend text for each
    if (dimPerRealisation == 1)
        numCostsToCompare = size(data,1);
    elseif (dimPerRealisation == 2)
        numCostsToCompare = size(data,1) * size(data,2);
    else
        % We are not handling this case properly
        disp( ' ... ERROR: This function does NOT handle data with more' );
        disp( '            than 2 dimensions per time step' );
        numCostsToCompare = 0;
    end

    %% Prepare the plotting options
    legendFontSize_default = 12;
    xLabelInterpreter_default = 'none';
    yLabelInterpreter_default = 'none';
    labelFontSize_default = 12;

    % Specify the plotting options
    thisPlotOptions = { 'LineColourIndex'   ,  1:numControllers                  ;...    % 01
                        'LineWidth'         ,  Visualisation.lineWidthDefault    ;...    % 02
                        'maRkerIndex'       ,  1                                 ;...    % 03 % OPTIONS: '0' gives no marker, other options are: {'o','+','*','.','x','square','diamond','^','v','<','>','pentagram','hexagram'}
                        'legendOnOff'       ,  'on'                              ;...    % 04 % OPTIONS: 'off', 'on'
                        'legendStrings'     ,  labelPerController                ;...    % 05
                        'legendFontSize'    ,  legendFontSize_default            ;...    % 06
                        'legendFontWeight'  ,  'bold'                            ;...    % 07 % OPTIONS: 'normal', 'bold'
                        'legendLocation'    ,  'southOutside'                    ;...    % 08 % OPTIONS: see below
                        'legendInterpreter' ,  'none'                            ;...    % 09 % OPTIONS: 'latex', 'tex', 'none'
                        'titleString'       ,  []                                ;...    % 10
                        'titleFontSize'     ,  24                                ;...    % 11
                        'titleFontWeight'   ,  'bold'                            ;...    % 12 % OPTIONS: 'normal', 'bold'
                        'titleColour'       ,  'black'                           ;...    % 13
                        'XLabelString'      ,  []                                ;...    % 14
                        'YLabelString'      ,  []                                ;...    % 15
                        'XLabelInterpreter' ,  xLabelInterpreter_default         ;...    % 16 % OPTIONS: 'latex', 'tex', 'none'
                        'YLabelInterpreter' ,  yLabelInterpreter_default         ;...    % 17 % OPTIONS: 'latex', 'tex', 'none'
                        'XLabelColour'      ,  'black'                           ;...    % 18
                        'YLabelColour'      ,  'black'                           ;...    % 19
                        'LabelFontSize'     ,  labelFontSize_default             ;...    % 20
                        'LabelFontWeight'   ,  'bold'                            ;...    % 21
                        'XGridOnOff'        ,  'off'                             ;...    % 22 % OPTIONS: 'off', 'on'
                        'YGridOnOff'        ,  'on'                              ;...    % 23 % OPTIONS: 'off', 'on'
                        'gridStyle'         ,  '--'                              ;...    % 24 % OPTIONS: '-', '--', ':', '-.', 'none'
                        'gridColour'        ,  [0.5 0.5 0.5]                     ;...    % 25 % 
                        'XGridMinorOnOff'   ,  'off'                             ;...    % 26 % OPTIONS: 'off', 'on'
                        'YGridMinorOnOff'   ,  'off'                             ;...    % 27 % OPTIONS: 'off', 'on'
                        'gridMinorStyle'    ,  ':'                               ;...    % 28 % OPTIONS: '-', '--', ':', '-.', 'none'
                        'gridMinorColour'   ,  [0.5 0.5 0.5]                     ;...
                        %'XTickNumbersOnOff'
                        %'YTickNumbersOnOff'
                      };

    %% ----------------------------------------------------------------- %%
    %% Create the figure - FOR THE SCATTER PLOT OF COST PER REALISATION
    thisFigurePosition = Visualisation.getFigurePositionInFullScreenGrid( 2,2, [1,1] , 'rowandcolumn' );
    hFig = figure('position',thisFigurePosition);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Clear the data variable
    clear data;
        
    %% Iterate through the number of Cost Components to compare, making a sub-plot for each
    for iCost = 1:numCostsToCompare
        % Get the index of this state
        thisCostIndex = iCost;

        % Create a cell array for storing the data
        data = cell(numControllers,1);

        % Handle based on the data structure
        if (dimPerRealisation == 1)
            % Construct the data to be plotted
            for iController = 1:numControllers
                % Get the data for this controller and this state
                data{iController,1} = inputDataCellArray{iController,1}.(thisProperty).data(thisCostIndex,:);
            end
            
            % Put in the title string
            thisPlotOptions{10,2} = labelPerDim{1}{thisCostIndex};
            

        elseif (dimPerRealisation == 2)
            
            % ... NOT HANLDING THIS
            
        else
            % We are not handling this case properly
            disp( ' ... ERROR: This function does NOT handle data with more' );
            disp( '            than 2 dimensions per time step' );
            numCostsToCompare = 0;
        end


        % Create the axes for the subplot for this cost component
        hAxes = subplot(1, numCostsToCompare, iCost );
        
        % Now call the generic plotting function
        Visualisation.visualise_plotMultipleHistogramAsScatter( hAxes , data , thisPlotOptions  );
        
        
        % DISPLAY THE CUMULATIVE COST SUMMED OVER THE WHOLE TIME HORIZON
        disp([' ... NOTE: FOR COST COMPONENT: ',inputDataCellArray{1,1}.(thisProperty).labelPerDim{1}{thisCostIndex} ]);
        for iController = 1:numControllers
            disp(['  ',num2str(sum(data{iController,1}),'%10.1f'),'   for "',labelPerController{iController},'"' ]);
        end
        
    end

    
    
    %% ----------------------------------------------------------------- %%
    %% Create the figure - FOR THE HISTOGRAM PLOT COST DIFFERECNCE
    thisFigurePosition = Visualisation.getFigurePositionInFullScreenGrid( 2,2, [2,1] , 'rowandcolumn' );
    hFig = figure('position',thisFigurePosition);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Clear the data variable
    clear data;
        
    %% Iterate through the number of Cost Components to compare, making a sub-plot for each
    for iCost = 1:numCostsToCompare
        % Get the index of this state
        thisCostIndex = iCost;

        % Create a cell array for storing the data
        data = cell(numControllers-1,1);

        % For now we just compare with the last controller in the list
        
        
        % Handle based on the data structure
        if (dimPerRealisation == 1)
            % Construct the data to be plotted
            data_lastController = inputDataCellArray{numControllers,1}.(thisProperty).data(thisCostIndex,:);
            
            for iController = 1:numControllers-1
                % Get the data for this controller
                data_thisController = inputDataCellArray{iController,1}.(thisProperty).data(thisCostIndex,:);
                % Store the difference as the data to be plotted                
                data{iController,1} = data_thisController - data_lastController;
            end
            
            % Adjust the length of things to remove the last item
            % For the color index
            thisPlotOptions{1,2} = 1:(numControllers-1);
            % For the legnend strings
            thisPlotOptions{5,2} = labelPerController(1:(numControllers-1),1);
            
            
            % Put in the title string
            thisPlotOptions{10,2} = labelPerDim{1}{thisCostIndex};
            

        elseif (dimPerRealisation == 2)
            
            % ... NOT HANLDING THIS
            
        else
            % We are not handling this case properly
            disp( ' ... ERROR: This function does NOT handle data with more' );
            disp( '            than 2 dimensions per time step' );
            numCostsToCompare = 0;
        end


        % Create the axes for the subplot for this cost component
        hAxes = subplot(1, numCostsToCompare, iCost );
        
        % Now call the generic plotting function
        Visualisation.visualise_plotMultipleHistogram( hAxes , data , thisPlotOptions  );
    end
    
    
    
    
    
    %% ----------------------------------------------------------------- %%
    %% Create the figure - FOR THE PARETO FRONT
    thisFigurePosition = Visualisation.getFigurePositionInFullScreenGrid( 2,2, [1,2] , 'rowandcolumn' );
    hFig = figure('position',thisFigurePosition);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Clear the data variable
    clear data;
        
    %% Iterate through the number of Cost Components to compare, making a sub-plot for each
    if (numCostsToCompare-1) == 2

        % Create a cell array for storing the data
        data_x = cell(numControllers,1);
        data_y = cell(numControllers,1);
        
        % Handle based on the data structure
        if (dimPerRealisation == 1)
            
            for iController = 1:numControllers
                % Get the data for this controller
                data_thisController = inputDataCellArray{iController,1}.(thisProperty).data;
                % Store the difference as the data to be plotted                
                data_x{iController,1} = data_thisController(2,:);
                data_y{iController,1} = data_thisController(3,:);
            end
            
            % Adjust the length of things to remove the last item
            % For the color index
            thisPlotOptions{1,2} = 1:(numControllers);
            % For the legnend strings
            thisPlotOptions{5,2} = labelPerController(1:numControllers,1);
            
            % Put in the title string
            thisPlotOptions{10,2} = 'Pareto Front';
            
            % Put in the title string
            thisPlotOptions{14,2} = labelPerDim{1}{2,1};
            thisPlotOptions{15,2} = labelPerDim{1}{3,1};
            

        elseif (dimPerRealisation == 2)
            
            % ... NOT HANLDING THIS
            
        else
            % We are not handling this case properly
            disp( ' ... ERROR: This function does NOT handle data with more' );
            disp( '            than 2 dimensions per time step' );
            numCostsToCompare = 0;
        end


        % Create the axes for the subplot for this cost component
        %hAxes = subplot(1, numCostsToCompare, iCost );
        hAxes = subplot(1, 1, 1 );
        
        % Now call the generic plotting function
        Visualisation.visualise_plotParetoFrontAsScatter( hAxes , data_x , data_y , thisPlotOptions  );
    end
       
    
    
    %% ----------------------------------------------------------------- %%
    %% Create the figure - FOR THE ***IMPROVED*** PARETO FRONT
    thisFigurePosition = Visualisation.getFigurePositionInFullScreenGrid( 2,2, [2,2] , 'rowandcolumn' );
    hFig = figure('position',thisFigurePosition);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Clear the data variable
    clear data;
    clear data_x;
    clear data_y;
        
    
    % Fake the method ID
    %numControllers = length( inputControllerSpecs );
%     thisMethodID = 1;
%     tempMethodName = {'MPC','ADP - Dense P','ADP - Diag P','ADP - Ouput K','ADP - Ouput Decent K','LQR'};
%     iMethodName = 1;
%     for iControlMethod = 1:numControllers
%         inputControllerSpecs{iControlMethod}.methodID_forGroupPlotting = thisMethodID;
%         inputControllerSpecs{iControlMethod}.methodName_forGroupPlotting = tempMethodName{iMethodName};
%         if rem(iControlMethod+1,6) == 1
%             iMethodName = iMethodName + 1;
%             thisMethodID = thisMethodID + 1;
%         end
%     end
    
    
    % Re-specify the plotting options for this graph because it will be a
    % little tricker than the previous graphs
    legendFontSize_default = 12;
    xLabelInterpreter_default = 'none';
    yLabelInterpreter_default = 'none';
    labelFontSize_default = 12;

    % Specify the plotting options
    thisPlotOptions = { 'LineColourIndex'   ,  1                                 ;...    % 01
                        'LineWidth'         ,  Visualisation.lineWidthDefault    ;...    % 02
                        'maRkerIndex'       ,  1                                 ;...    % 03 % OPTIONS: '0' gives no marker, other options are: {'o','+','*','.','x','square','diamond','^','v','<','>','pentagram','hexagram'}
                        'legendOnOff'       ,  'on'                              ;...    % 04 % OPTIONS: 'off', 'on'
                        'legendStrings'     ,  ' '                               ;...    % 05
                        'legendFontSize'    ,  legendFontSize_default            ;...    % 06
                        'legendFontWeight'  ,  'bold'                            ;...    % 07 % OPTIONS: 'normal', 'bold'
                        'legendLocation'    ,  'southOutside'                    ;...    % 08 % OPTIONS: see below
                        'legendInterpreter' ,  'none'                            ;...    % 09 % OPTIONS: 'latex', 'tex', 'none'
                        'titleString'       ,  'Pareto Front'                    ;...    % 10
                        'titleFontSize'     ,  24                                ;...    % 11
                        'titleFontWeight'   ,  'bold'                            ;...    % 12 % OPTIONS: 'normal', 'bold'
                        'titleColour'       ,  'black'                           ;...    % 13
                        'XLabelString'      ,  []                                ;...    % 14
                        'YLabelString'      ,  []                                ;...    % 15
                        'XLabelInterpreter' ,  xLabelInterpreter_default         ;...    % 16 % OPTIONS: 'latex', 'tex', 'none'
                        'YLabelInterpreter' ,  yLabelInterpreter_default         ;...    % 17 % OPTIONS: 'latex', 'tex', 'none'
                        'XLabelColour'      ,  'black'                           ;...    % 18
                        'YLabelColour'      ,  'black'                           ;...    % 19
                        'LabelFontSize'     ,  labelFontSize_default             ;...    % 20
                        'LabelFontWeight'   ,  'bold'                            ;...    % 21
                        'XGridOnOff'        ,  'off'                             ;...    % 22 % OPTIONS: 'off', 'on'
                        'YGridOnOff'        ,  'on'                              ;...    % 23 % OPTIONS: 'off', 'on'
                        'gridStyle'         ,  '--'                              ;...    % 24 % OPTIONS: '-', '--', ':', '-.', 'none'
                        'gridColour'        ,  [0.5 0.5 0.5]                     ;...    % 25 % 
                        'XGridMinorOnOff'   ,  'off'                             ;...    % 26 % OPTIONS: 'off', 'on'
                        'YGridMinorOnOff'   ,  'off'                             ;...    % 27 % OPTIONS: 'off', 'on'
                        'gridMinorStyle'    ,  ':'                               ;...    % 28 % OPTIONS: '-', '--', ':', '-.', 'none'
                        'gridMinorColour'   ,  [0.5 0.5 0.5]                     ;...
                        %'XTickNumbersOnOff'
                        %'YTickNumbersOnOff'
                      };
    
    
    
    
    %% Iterate through the number of Cost Components to compare, making a sub-plot for each
    if (numCostsToCompare-1) == 2

        % Create a cell array for storing the data
        %data_x = cell(numControllers,1);
        %data_y = cell(numControllers,1);
        
        % Handle based on the data structure
        if (dimPerRealisation == 1)
            
            % FIRST: parse through all the Controller Methods and make a
            % list of the various methods
            clear methodIndex;
            % Initialise the methodindex to be bigger than required
            tempBlankSize = 20;
            tempID      = -999 * ones(tempBlankSize,1);
            tempIndex   = -999 * ones(tempBlankSize,1);
            tempName    = cell(tempBlankSize,1);
            tempControllerIndices = zeros(tempBlankSize,tempBlankSize);
            tempNumControllers = zeros(tempBlankSize,1);
            numGroups   = 0;
            
            %methodIndex = cell{20,1};
            %methodIndex.ID = zeros(0,1);
            %methodIndex.ID = zeros(0,1);
            
            % Iterate through the Controller methods
            for iControlMethod = 1:numControllers
                thisMethodID = inputControllerSpecs{iControlMethod}.methodID_forGroupPlotting;
                [thisIsMemberFlag , thisIsMemberIndex] = ismember(thisMethodID , tempID);
                if not( thisIsMemberFlag )
                    % Add the new group that we have found
                    numGroups = numGroups + 1;
                    tempID(numGroups,1) = thisMethodID;
                    tempIndex(numGroups,1) = numGroups;
                    tempName{numGroups,1} = inputControllerSpecs{iControlMethod}.methodName_forGroupPlotting;
                    tempNumControllers(numGroups,1) = tempNumControllers(numGroups,1) + 1;
                    tempControllerIndices(numGroups,tempNumControllers(numGroups,1)) = iControlMethod;                    
                else
                    % Add this controller to the existing group
                    tempNumControllers(thisIsMemberIndex,1) = tempNumControllers(thisIsMemberIndex,1) + 1;
                    tempControllerIndices(thisIsMemberIndex,tempNumControllers(thisIsMemberIndex,1)) = iControlMethod;                    
                end
            end
            % Put all this into a cell array
            methodIndex = cell(numGroups,1);
            for iGroup = 1:numGroups
                methodIndex{iGroup,1}.ID                = tempID(iGroup,1);
                methodIndex{iGroup,1}.index             = tempIndex(iGroup,1);
                methodIndex{iGroup,1}.name              = tempName{iGroup,1};
                methodIndex{iGroup,1}.numControllers    = tempNumControllers(iGroup,1);
                methodIndex{iGroup,1}.controllerIndices = (tempControllerIndices( iGroup, 1:tempNumControllers(iGroup,1) ))';
            end
            clear tempID;
            clear tempIndex;
            clear tempName;
            clear tempControllerIndices;
            clear tempNumControllers;
            
            
            
            % Create the axes for the subplot for this cost component
            %hAxes = subplot(1, numCostsToCompare, iCost );
            hAxes = subplot(1, 1, 1 );
            
            % Put in the title string
            %thisPlotOptions{10,2} = 'Pareto Front';
            
            % Put in the x and y label string
            thisPlotOptions{14,2} = labelPerDim{1}{2,1};
            thisPlotOptions{15,2} = labelPerDim{1}{3,1};
            
            % For the legnend strings
            %thisPlotOptions{5,2} = labelPerController(1:numControllers,1);
        
            % NOW - Step through the METHOD GROUPINGS
            % Plotting the Parato Front for that method at each step
            for iGroup = 1:numGroups
                % Get the controller indices for this group
                thisControllerIndices   = methodIndex{iGroup,1}.controllerIndices;
                thisNumControllers      = methodIndex{iGroup,1}.numControllers;
                
                % Clear the previous data
                clear data_x;
                clear data_y;
                
                % Step through the controllers for this methods and collect
                % the data
                for iController = 1:thisNumControllers
                    thisControllerIndex = thisControllerIndices(iController);
                    % Get the data for this controller
                    data_thisController = inputDataCellArray{thisControllerIndex,1}.(thisProperty).data;
                    % Store the difference as the data to be plotted                
                    data_x{iController,1} = data_thisController(2,:);
                    data_y{iController,1} = data_thisController(3,:);
                end
                
                % Set the "color index" plot option
                thisPlotOptions{1,2} = iGroup;
                
                thisPlotOptions{5,2} = {methodIndex{iGroup,1}.name};
                    
                % Now call the generic plotting function
                Visualisation.visualise_plotParetoFrontSummary( hAxes , data_x , data_y , thisPlotOptions  );
            end
            
            
            
            

        elseif (dimPerRealisation == 2)
            
            % ... NOT HANLDING THIS
            
        else
            % We are not handling this case properly
            disp( ' ... ERROR: This function does NOT handle data with more' );
            disp( '            than 2 dimensions per time step' );
            numCostsToCompare = 0;
        end


        % Create the axes for the subplot for this cost component
        %hAxes = subplot(1, numCostsToCompare, iCost );
        %hAxes = subplot(1, 1, 1 );
        
        % Now call the generic plotting function
        %Visualisation.visualise_plotParetoFrontAsScatter( hAxes , data_x , data_y , thisPlotOptions  );
    end



end   % END OF: "if isfield( inputPropertyNames , thisProperty )"



