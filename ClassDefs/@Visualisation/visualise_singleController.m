function [ ] = visualise_singleController( inputControllerSpecs , inputDataStruct , inputPropertyNames , plotOptions )
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
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


%% --------------------------------------------------------------------- %%
%% PLOT THE STATES
% Get the data
data            = inputDataStruct.x.data(1:42,:);
dimPerTime      = inputDataStruct.x.dimPerTime;
labelPerDim     = inputDataStruct.x.labelPerDim;

timeLength      = size( data , dimPerTime+1 );
if strcmp( unitsForTimeAxis , 'steps' )
    timeForPlot     = inputDataStruct.time.data(1,1:timeLength);
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    timeForPlot     = inputDataStruct.time.data(2,1:timeLength);
    thisTimeLabel   = 'Time [hours]';
    % Need to put a few extra statements in here to detect the exact units
    % of "inputDataStruct.time.data(2,:);" and scale it appropriately
else
    disp( ' ... ERROR: The "unitsForTimeAxis" plotting option was not a recognised string');
    disp( '            Option requested is:');
    disp(unitsForTimeAxis);
end
    
if (dimPerTime == 1)
    numLinesToPlot = size(data,1);
elseif (dimPerTime == 2)
    numLinesToPlot = size(data,1) * size(data,2);
else
    % We are not handling this case properly
    numLinesToPlot = 0;
end

% Specify the plotting options
thisPlotOptions = { 'LineColourIndex'   ,  1:numLinesToPlot                  ;...
                    'LineWidth'         ,  Visualisation.lineWidthDefault    ;...
                    %'maRkerIndex'       ,  ones(numLinesToPlot,1)            ;...
                    'legendOnOff'       ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'legendStrings'     ,  labelPerDim{1}(:)                 ;...
                    'legendFontSize'    ,  12                                ;...
                    'legendFontWeight'  ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'legendLocation'    ,  'eastOutside'                     ;...    % OPTIONS: see below
                    'legendInterpreter' ,  'none'                            ;...    % OPTIONS: 'latex', 'tex', 'none'
                    'titleString'       ,  'States'                          ;...
                    'titleFontSize'     ,  24                                ;...
                    'titleFontWeight'   ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'titleColour'       ,  'black'                           ;...
                    'XLabelString'      ,  thisTimeLabel                     ;...
                    'YLabelString'      ,  'State, $x$ (Temperature [T])'    ;...
                    'XLabelColour'      ,  'black'                           ;...
                    'YLabelColour'      ,  'black'                           ;...
                    'LabelFontSize'     ,  18                                ;...
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
hFig = figure('position',[50 680 1200 600]);
set(hFig,'Color', Visualisation.figure_backgroundColour );

% Create the axes
thisPosition = [0.15 0.15 0.8 0.75];
hAxes = axes('Position', thisPosition);

% Now call the generic plotting function
Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );



%% --------------------------------------------------------------------- %%
%% PLOT THE INPUTS
% Get the data
data            = inputDataStruct.u.data;
dimPerTime      = inputDataStruct.u.dimPerTime;
labelPerDim     = inputDataStruct.u.labelPerDim;

timeLength      = size( data , dimPerTime+1 );
if strcmp( unitsForTimeAxis , 'steps' )
    timeForPlot     = inputDataStruct.time.data(1,1:timeLength);
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    timeForPlot     = inputDataStruct.time.data(2,1:timeLength);
    thisTimeLabel   = 'Time [hours]';
    % Need to put a few extra statements in here to detect the exact units
    % of "inputDataStruct.time.data(2,:);" and scale it appropriately
else
    disp( ' ... ERROR: The "unitsForTimeAxis" plotting option was not a recognised string');
    disp( '            Option requested is:');
    disp(unitsForTimeAxis);
end

if (dimPerTime == 1)
    numLinesToPlot = size(data,1);
elseif (dimPerTime == 2)
    numLinesToPlot = size(data,1) * size(data,2);
else
    % We are not handling this case properly
    numLinesToPlot = 0;
end

% Specify the plotting options
thisPlotOptions = { 'LineColourIndex'   ,  1:numLinesToPlot                  ;...
                    'LineWidth'         ,  Visualisation.lineWidthDefault    ;...
                    %'maRkerIndex'       ,  ones(numLinesToPlot,1)            ;...
                    'legendOnOff'       ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'legendStrings'     ,  labelPerDim{1}(:)                 ;...
                    'legendFontSize'    ,  12                                ;...
                    'legendFontWeight'  ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'legendLocation'    ,  'eastOutside'                     ;...    % OPTIONS: see below
                    'legendInterpreter' ,  'none'                            ;...    % OPTIONS: 'latex', 'tex', 'none'
                    'titleString'       ,  'Inputs'                          ;...
                    'titleFontSize'     ,  24                                ;...
                    'titleFontWeight'   ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'titleColour'       ,  'black'                           ;...
                    'XLabelString'      ,  thisTimeLabel                     ;...
                    'YLabelString'      ,  'Input, $u$'                      ;...
                    'XLabelColour'      ,  'black'                           ;...
                    'YLabelColour'      ,  'black'                           ;...
                    'LabelFontSize'     ,  18                                ;...
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
hFig = figure('position',[50 40 1200 600]);
set(hFig,'Color', Visualisation.figure_backgroundColour );

% Create the axes
thisPosition = [0.15 0.15 0.8 0.75];
hAxes = axes('Position', thisPosition);

% Now call the generic plotting function
Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );







%% --------------------------------------------------------------------- %%
%% PLOT THE DISTURBANCES
% Get the data
data            = inputDataStruct.xi.data;
dimPerTime      = inputDataStruct.xi.dimPerTime;
labelPerDim     = inputDataStruct.xi.labelPerDim;


timeLength      = size( data , dimPerTime+1 );
if strcmp( unitsForTimeAxis , 'steps' )
    timeForPlot     = inputDataStruct.time.data(1,1:timeLength);
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    timeForPlot     = inputDataStruct.time.data(2,1:timeLength);
    thisTimeLabel   = 'Time [hours]';
    % Need to put a few extra statements in here to detect the exact units
    % of "inputDataStruct.time.data(2,:);" and scale it appropriately
else
    disp( ' ... ERROR: The "unitsForTimeAxis" plotting option was not a recognised string');
    disp( '            Option requested is:');
    disp(unitsForTimeAxis);
end


if (dimPerTime == 1)
    numLinesToPlot = size(data,1);
elseif (dimPerTime == 2)
    numLinesToPlot = size(data,1) * size(data,2);
else
    % We are not handling this case properly
    numLinesToPlot = 0;
end


% Specify the plotting options
thisPlotOptions = { 'LineColourIndex'   ,  1:numLinesToPlot                  ;...
                    'LineWidth'         ,  Visualisation.lineWidthDefault    ;...
                    %'maRkerIndex'       ,  ones(numLinesToPlot,1)            ;...
                    'legendOnOff'       ,  'on'                              ;...    % OPTIONS: 'off', 'on'
                    'legendStrings'     ,  labelPerDim{1}(:)                 ;...
                    'legendFontSize'    ,  12                                ;...
                    'legendFontWeight'  ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'legendLocation'    ,  'eastOutside'                     ;...    % OPTIONS: see below
                    'legendInterpreter' ,  'none'                            ;...    % OPTIONS: 'latex', 'tex', 'none'
                    'titleString'       ,  'Disturbances'                    ;...
                    'titleFontSize'     ,  24                                ;...
                    'titleFontWeight'   ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'titleColour'       ,  'black'                           ;...
                    'XLabelString'      ,  thisTimeLabel                     ;...
                    'YLabelString'      ,  'Disturbance, $\xi$'              ;...
                    'XLabelColour'      ,  'black'                           ;...
                    'YLabelColour'      ,  'black'                           ;...
                    'LabelFontSize'     ,  18                                ;...
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
hFig = figure('position',[1250 680 1200 600]);
set(hFig,'Color', Visualisation.figure_backgroundColour );

% Create the axes
thisPosition = [0.15 0.15 0.8 0.75];
hAxes = axes('Position', thisPosition);

% Now call the generic plotting function
Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );



%% --------------------------------------------------------------------- %%
%% PLOT THE COST
% Get the data
data            = inputDataStruct.cost.data;
dimPerTime      = inputDataStruct.cost.dimPerTime;
labelPerDim     = inputDataStruct.cost.labelPerDim;


timeLength      = size( data , dimPerTime+1 );
if strcmp( unitsForTimeAxis , 'steps' )
    timeForPlot     = inputDataStruct.time.data(1,1:timeLength);
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    timeForPlot     = inputDataStruct.time.data(2,1:timeLength);
    thisTimeLabel   = 'Time [hours]';
    % Need to put a few extra statements in here to detect the exact units
    % of "inputDataStruct.time.data(2,:);" and scale it appropriately
else
    disp( ' ... ERROR: The "unitsForTimeAxis" plotting option was not a recognised string');
    disp( '            Option requested is:');
    disp(unitsForTimeAxis);
end


if (dimPerTime == 1)
    numLinesToPlot = size(data,1);
elseif (dimPerTime == 2)
    numLinesToPlot = size(data,1) * size(data,2);
else
    % We are not handling this case properly
    numLinesToPlot = 0;
end

% Specify the plotting options
thisPlotOptions = { 'titleString'       ,  'Costs'                           ;...
                    'LineColourIndex'   ,  1:numLinesToPlot                  ;...
                    'LineWidth'         ,  Visualisation.lineWidthDefault    ;...
                    %'maRkerIndex'       ,  ones(numLinesToPlot,1)            ;...
                    'legendOnOff'       ,  'off'                              ;...    % OPTIONS: 'off', 'on'
                    'legendStrings'     ,  []                                ;...
                    'legendFontSize'    ,  12                                ;...
                    'legendFontWeight'  ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'legendLocation'    ,  'eastOutside'                     ;...    % OPTIONS: see below
                    'legendInterpreter' ,  'none'                            ;...    % OPTIONS: 'latex', 'tex', 'none'                    
                    'titleFontSize'     ,  24                                ;...
                    'titleFontWeight'   ,  'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                    'titleColour'       ,  'black'                           ;...
                    'XLabelString'      ,  thisTimeLabel                     ;...
                    'YLabelString'      ,  'Cost'                            ;...
                    'XLabelColour'      ,  'black'                           ;...
                    'YLabelColour'      ,  'black'                           ;...
                    'LabelFontSize'     ,  18                                ;...
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
hFig = figure('position',[1250 40 1200 600]);
set(hFig,'Color', Visualisation.figure_backgroundColour );

% Assuming that the cost is not made up from too many componets, then it
% is not clear that the should exist on the same scale
% Hence plot each component on a seaprate sub-plot

if (dimPerTime == 1)

    % Step through each of the line
    for iLine = 1:numLinesToPlot
        hAxes = subplot(numLinesToPlot,1,iLine);
        
        % Updates the title string
        thisPlotOptions{1,2} = ['Cost Component: ', labelPerDim{1}{iLine}];
        thisPlotOptions{2,2} = 1;
        
        % Now call the generic plotting function
        Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data(iLine,:) , thisPlotOptions  );
    end
    
else
    % Create the axes
    thisPosition = [0.15 0.15 0.8 0.75];
    hAxes = axes('Position', thisPosition);

    % Now call the generic plotting function
    Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );
end    
    
    
    
% %% --------------------------------------------------------------------- %%
% %% PLOT THE COST per sub-system
% % Get the data
% data            = inputDataStruct.cost_per_ss.data;
% dimPerTime      = inputDataStruct.cost_per_ss.dimPerTime;
% labelPerDim     = inputDataStruct.cost_per_ss.labelPerDim;
% 
% timeLength      = size( data , dimPerTime+1 );
% 
% if (dimPerTime == 1)
%     numLinesToPlot = size(data,1);
% elseif (dimPerTime == 2)
%     numLinesToPlot = size(data,1) * size(data,2);
% else
%     % We are not handling this case properly
%     numLinesToPlot = 0;
% end
% 
% numLinesToPlot = size(data,2);
% 
% 
% % Create the figure
% hFig = figure('position',[1250 20 1200 600]);
% set(hFig,'Color', Visualisation.figure_backgroundColour );
% 
% % Create the axes
% thisPosition = [0.15 0.15 0.8 0.75];
% hAxes = axes('Position', thisPosition);
% 
% % Pre-allocate a vector for the handle to each line
% hLine = zeros(numLinesToPlot,1);
% 
% % Plot the data
% hold on;
% for iLine = 1:numLinesToPlot
%     % Get the colour for this line
%     thisColour = Visualisation.getDefaultColourForIndex( iLine );
%     % Specify the line width
%     thisLineWidth = Visualisation.lineWidthThin;
% 
%     % Plot the line
%     hLine(iLine) = plot( hAxes, (1:timeLength), reshape(data(1,iLine,:),timeLength,1) , 'color' , thisColour , 'LineWidth' , thisLineWidth );
% end
% hold off;
% 
% % Label a few things
% % Set some properties of the axes
% set(hAxes,'XGrid','on');
% set(hAxes,'YGrid','on');
% set(hAxes,'FontSize',16);
% % Make it only integer ticks
% %if (display_xTickLabel)     set(hAxFObj,'XTick',(1:numCases)');
% %else                        set(hAxFObj,'XTickLabel','');       end;
% % Add the title and axis label
% title( inputControllerSpecs.label );
% xlabel('Time [index]');
% ylabel('Cost');
% % LEGEND
% hLegend1 = legend(hAxes, hLine, labelPerDim{2}, 'Location', 'SouthOutside');
% %newPosition = [0.125 0.02 0.25 0.07];
% %newUnits = 'normalized';
% %set(hLegend1,'Position', newPosition,'Units', newUnits, 'interpreter','latex');
% set(hLegend1,'interpreter','none');
    
    
	
end
% END OF FUNCTION