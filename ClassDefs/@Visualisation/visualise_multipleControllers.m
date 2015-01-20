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
        % Get the data for this controller and this state
        data{iController,1} = inputDataCellArray{iController,1}.x.data(thisStateIndex,:);
        % When comparing controllers is "only" makes sense to compare
        % in absolute time in case that the data was stored at a different
        % regularity
        dimPerTime      = inputDataCellArray{iController,1}.x.dimPerTime;
        timeLength      = size( data{iController,1} , dimPerTime+1 );
        timeForPlot{iController,1} = inputDataCellArray{iController,1}.time.data(1,1:timeLength);
    end
    
    % Put in the xLabel, yLabel and Title options as required
    if (iState == 1)
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.x.labelPerDim{1}{thisStateIndex};
        thisPlotOptions{3,2} = 'State, $x$ (Temperature [T]) vs. Time';
        thisPlotOptions{4,2} = 'on';
    elseif (iState == numStatesToCompare)
        thisPlotOptions{1,2} = thisTimeLabel;
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.x.labelPerDim{1}{thisStateIndex};
        thisPlotOptions{3,2} = [];
        thisPlotOptions{4,2} = 'off';
    else
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.x.labelPerDim{1}{thisStateIndex};
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
numInputsToCompare = size(inputDataCellArray{1,1}.u.data,1);


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
        % Get the data for this controller and this state
        data{iController,1} = inputDataCellArray{iController,1}.u.data(thisInputIndex,:);
        % When comparing controllers is "only" makes sense to compare
        % in absolute time in case that the data was stored at a different
        % regularity
        dimPerTime      = inputDataCellArray{iController,1}.u.dimPerTime;
        timeLength      = size( data{iController,1} , dimPerTime+1 );
        timeForPlot{iController,1} = inputDataCellArray{iController,1}.time.data(1,1:timeLength);
    end
    
    % Put in the xLabel, yLabel and Title options as required
    if (iInput == 1)
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.u.labelPerDim{1}{thisInputIndex};
        thisPlotOptions{3,2} = 'Input, $u$ vs. Time';
        thisPlotOptions{4,2} = 'on';
    elseif (iInput == numInputsToCompare)
        thisPlotOptions{1,2} = thisTimeLabel;
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.u.labelPerDim{1}{thisInputIndex};
        thisPlotOptions{3,2} = [];
        thisPlotOptions{4,2} = 'off';
    else
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = inputDataCellArray{iController,1}.u.labelPerDim{1}{thisInputIndex};
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
numCostsToCompare = size(inputDataCellArray{1,1}.cost.data,1);
labelPerDim       = inputDataCellArray{1,1}.cost.labelPerDim;

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
hFig = figure('position',[1600 200 800 1200]);
set(hFig,'Color', Visualisation.figure_backgroundColour );

% Hence iterate through the number of states-to-compare
for iCost = 1:numCostsToCompare
    % Get the index of this state
    thisCostIndex = iCost;


    % Construct the data to be plotted
    for iController = 1:numControllers
        % Get the data for this controller and this state
        data{iController,1} = inputDataCellArray{iController,1}.cost.data(thisCostIndex,:);
        % When comparing controllers is "only" makes sense to compare
        % in absolute time in case that the data was stored at a different
        % regularity
        dimPerTime      = inputDataCellArray{iController,1}.cost.dimPerTime;
        timeLength      = size( data{iController,1} , dimPerTime+1 );
        timeForPlot{iController,1} = inputDataCellArray{iController,1}.time.data(1,1:timeLength);
    end
    
    % Put in the xLabel, yLabel and Title options as required
    if (iCost == 1)
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = [];
        thisPlotOptions{3,2} = inputDataCellArray{iController,1}.cost.labelPerDim{1}{thisCostIndex};
        thisPlotOptions{4,2} = 'on';
    elseif (iCost == numCostsToCompare)
        thisPlotOptions{1,2} = thisTimeLabel;
        thisPlotOptions{2,2} = [];
        thisPlotOptions{3,2} = inputDataCellArray{iController,1}.cost.labelPerDim{1}{thisCostIndex};
        thisPlotOptions{4,2} = 'off';
    else
        thisPlotOptions{1,2} = [];
        thisPlotOptions{2,2} = [];
        thisPlotOptions{3,2} = inputDataCellArray{iController,1}.cost.labelPerDim{1}{thisCostIndex};
        thisPlotOptions{4,2} = 'off';
    end
    
    
    % Create the axes for ALL the states
    hAxes = subplot(numCostsToCompare,1,iCost);
    % Now call the generic plotting function
    Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );
        
        
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



