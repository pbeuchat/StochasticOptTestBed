function [ ] = visualise_singleController( inputControllerSpecs , inputDataStruct , inputPropertyNames )
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
    
    
    
    
    % --------------------------------------------- %
    % PLOT THE STATES
    % Get the data
    data            = inputDataStruct.x.data(1:7,:);
    dimPerTime      = inputDataStruct.x.dimPerTime;
    labelPerDim     = inputDataStruct.x.labelPerDim;
    
    timeLength      = size( data , dimPerTime+1 );
    
    if (dimPerTime == 1)
        numLinesToPlot = size(data,1);
    elseif (dimPerTime == 2)
        numLinesToPlot = size(data,1) * size(data,2);
    else
        % We are not handling this case properly
        numLinesToPlot = 0;
    end
    
    % Specify the plotting options
    thisPlotOptions = { 'LineColourIndex'   ,   1:numLinesToPlot                ;...
                        'LineWidth'         ,   Visualisation.lineWidthThick    ;...
                        %'maRkerIndex'       ,   ones(numLinesToPlot,1)         ;...
                        %'legendStrings'     , labelPerDim{1}(:)                 ;...
                        %'legendFontSize'    , 10                                ;...
                        %'legendFontWeight'  , 'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                        %'legendLocation'    , 'eastOutside'                     ;...    % OPTIONS: see below
                        %'legendInterpreter' , 'latex'                           ;...    % OPTIONS: 'latex', 'tex', 'none'
                        %'titleString'       , 'Something'                       ;...
                        %'titleFontSize'     , 20                                ;...
                        %'titleFontWeight'   , 'bold'                            ;...    % OPTIONS: 'normal', 'bold'
                        %'titleColour'       , 'red'                             ;...
                        %'XLabelString'      , 'Time'                            ;...
                        %'YLabelString'      , 'Value'                           ;...
                        %'XLabelColour'      , 'blue'                            ;...
                        %'YLabelColour'      , 'green'                           ;...
                        %'LabelFontSize'     , 12                                ;...
                        %'LabelFontWeight'   , 12                                ;...
                        %'XGrid'             , 'on'                              ;...    % OPTIONS: 'off', 'on'
                        %'YGrid'             , 'on'                              ;...    % OPTIONS: 'off', 'on'
                        %'XGridStyle'        , '--'                              ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                        %'YGridStyle'        , '--'                              ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                        %'XGridMinor'        , 'on'                              ;...    % OPTIONS: 'off', 'on'
                        %'YGridMinor'        , 'on'                              ;...    % OPTIONS: 'off', 'on'
                        %'XGridMinorStyle'   , '--'                              ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                        %'YGridMinorStyle'   , '--'                              ;...    % OPTIONS: '-', '--', ':', '-.', 'none'
                      };


% Legend Location Options:
% 'north', 'south', 'east', 'west', 'northeast', 'northwest', 'southeast',
% 'southwest', 'northoutside', 'southoutside', 'eastoutside', 'westoutside',
% 'northeastoutside', 'northwestoutside', 'southeastoutside', 'southwestoutside',
% 'best', 'bestoutside', 'none'
                  
    
    % Create the figure
    hFig = figure('position',[50 50 1200 800]);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Create the axes
    thisPosition = [0.15 0.15 0.8 0.75];
    hAxes = axes('Position', thisPosition);
    
    Visualisation.visualise_plotMultipleLines( hAxes , (1:timeLength), data , thisPlotOptions  );
    
    
    
    % --------------------------------------------- %
    % PLOT THE INPUTS
    % Get the data
    data            = inputDataStruct.u.data;
    dimPerTime      = inputDataStruct.u.dimPerTime;
    labelPerDim     = inputDataStruct.u.labelPerDim;
    
    timeLength      = size( data , dimPerTime+1 );
    
    if (dimPerTime == 1)
        numLinesToPlot = size(data,1);
    elseif (dimPerTime == 2)
        numLinesToPlot = size(data,1) * size(data,2);
    else
        % We are not handling this case properly
        numLinesToPlot = 0;
    end
    
    
    % Create the figure
    hFig = figure('position',[50 50 1200 800]);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Create the axes
    thisPosition = [0.15 0.15 0.8 0.75];
    hAxes = axes('Position', thisPosition);
    
    % Pre-allocate a vector for the handle to each line
    hLine = zeros(numLinesToPlot,1);
    
    % Plot the data
    hold on;
    for iLine = 1:numLinesToPlot
        % Get the colour for this line
        thisColour = Visualisation.getDefaultColourForIndex( iLine );
        % Specify the line width
        thisLineWidth = Visualisation.lineWidthThin;
        
        % Plot the line
        hLine(iLine) = plot( hAxes, (1:timeLength), data(iLine,:) , 'color' , thisColour , 'LineWidth' , thisLineWidth );
    end
    hold off;
    
    % Label a few things
    % Set some properties of the axes
    set(hAxes,'XGrid','on');
    set(hAxes,'YGrid','on');
    set(hAxes,'FontSize',16);
    % Make it only integer ticks
    %if (display_xTickLabel)     set(hAxFObj,'XTick',(1:numCases)');
    %else                        set(hAxFObj,'XTickLabel','');       end;
    % Add the title and axis label
    title( inputControllerSpecs.label );
    xlabel('Time [index]');
    ylabel('Input, $u$');
    % LEGEND
    hLegend1 = legend(hAxes, hLine, labelPerDim{1}(:), 'Location', 'SouthOutside');
    %newPosition = [0.125 0.02 0.25 0.07];
    %newUnits = 'normalized';
    %set(hLegend1,'Position', newPosition,'Units', newUnits, 'interpreter','latex');
    set(hLegend1,'interpreter','none');
    
    
    
    
    
    % --------------------------------------------- %
    % PLOT THE DISTURBANCES
    % Get the data
    data            = inputDataStruct.xi.data;
    dimPerTime      = inputDataStruct.xi.dimPerTime;
    labelPerDim     = inputDataStruct.xi.labelPerDim;
    
    timeLength      = size( data , dimPerTime+1 );
    
    if (dimPerTime == 1)
        numLinesToPlot = size(data,1);
    elseif (dimPerTime == 2)
        numLinesToPlot = size(data,1) * size(data,2);
    else
        % We are not handling this case properly
        numLinesToPlot = 0;
    end
    
    
    % Create the figure
    hFig = figure('position',[50 50 1200 800]);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Create the axes
    thisPosition = [0.15 0.15 0.8 0.75];
    hAxes = axes('Position', thisPosition);
    
    % Pre-allocate a vector for the handle to each line
    hLine = zeros(numLinesToPlot,1);
    
    % Plot the data
    hold on;
    for iLine = 1:numLinesToPlot
        % Get the colour for this line
        thisColour = Visualisation.getDefaultColourForIndex( iLine );
        % Specify the line width
        thisLineWidth = Visualisation.lineWidthThin;
        
        % Plot the line
        hLine(iLine) = plot( hAxes, (1:timeLength), data(iLine,:) , 'color' , thisColour , 'LineWidth' , thisLineWidth );
    end
    hold off;
    
    % Label a few things
    % Set some properties of the axes
    set(hAxes,'XGrid','on');
    set(hAxes,'YGrid','on');
    set(hAxes,'FontSize',16);
    % Make it only integer ticks
    %if (display_xTickLabel)     set(hAxFObj,'XTick',(1:numCases)');
    %else                        set(hAxFObj,'XTickLabel','');       end;
    % Add the title and axis label
    title( inputControllerSpecs.label );
    xlabel('Time [index]');
    ylabel('Disturbance, $\xi$');
    % LEGEND
    hLegend1 = legend(hAxes, hLine, labelPerDim{1}, 'Location', 'SouthOutside');
    %newPosition = [0.125 0.02 0.25 0.07];
    %newUnits = 'normalized';
    %set(hLegend1,'Position', newPosition,'Units', newUnits, 'interpreter','latex');
    set(hLegend1,'interpreter','none');
    
    
    
    % --------------------------------------------- %
    % PLOT THE COST
    % Get the data
    data            = inputDataStruct.cost.data;
    dimPerTime      = inputDataStruct.cost.dimPerTime;
    labelPerDim     = inputDataStruct.cost.labelPerDim;
    
    timeLength      = size( data , dimPerTime+1 );
    
    if (dimPerTime == 1)
        numLinesToPlot = size(data,1);
    elseif (dimPerTime == 2)
        numLinesToPlot = size(data,1) * size(data,2);
    else
        % We are not handling this case properly
        numLinesToPlot = 0;
    end
    
    
    % Create the figure
    hFig = figure('position',[50 50 1200 800]);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Create the axes
    thisPosition = [0.15 0.15 0.8 0.75];
    hAxes = axes('Position', thisPosition);
    
    % Pre-allocate a vector for the handle to each line
    hLine = zeros(numLinesToPlot,1);
    
    % Plot the data
    hold on;
    for iLine = 1:numLinesToPlot
        % Get the colour for this line
        thisColour = Visualisation.getDefaultColourForIndex( iLine );
        % Specify the line width
        thisLineWidth = Visualisation.lineWidthThin;
        
        % Plot the line
        hLine(iLine) = plot( hAxes, (1:timeLength), data(iLine,:) , 'color' , thisColour , 'LineWidth' , thisLineWidth );
    end
    hold off;
    
    % Label a few things
    % Set some properties of the axes
    set(hAxes,'XGrid','on');
    set(hAxes,'YGrid','on');
    set(hAxes,'FontSize',16);
    % Make it only integer ticks
    %if (display_xTickLabel)     set(hAxFObj,'XTick',(1:numCases)');
    %else                        set(hAxFObj,'XTickLabel','');       end;
    % Add the title and axis label
    title( inputControllerSpecs.label );
    xlabel('Time [index]');
    ylabel('Cost');
    % LEGEND
    hLegend1 = legend(hAxes, hLine, labelPerDim{1}, 'Location', 'SouthOutside');
    %newPosition = [0.125 0.02 0.25 0.07];
    %newUnits = 'normalized';
    %set(hLegend1,'Position', newPosition,'Units', newUnits, 'interpreter','latex');
    set(hLegend1,'interpreter','none');
    
    
    
    
    % --------------------------------------------- %
    % PLOT THE COST per sub-system
    % Get the data
    data            = inputDataStruct.cost_per_ss.data;
    dimPerTime      = inputDataStruct.cost_per_ss.dimPerTime;
    labelPerDim     = inputDataStruct.cost_per_ss.labelPerDim;
    
    timeLength      = size( data , dimPerTime+1 );
    
    if (dimPerTime == 1)
        numLinesToPlot = size(data,1);
    elseif (dimPerTime == 2)
        numLinesToPlot = size(data,1) * size(data,2);
    else
        % We are not handling this case properly
        numLinesToPlot = 0;
    end
    
    numLinesToPlot = size(data,2);
    
    
    % Create the figure
    hFig = figure('position',[50 50 1200 800]);
    set(hFig,'Color', Visualisation.figure_backgroundColour );
    
    % Create the axes
    thisPosition = [0.15 0.15 0.8 0.75];
    hAxes = axes('Position', thisPosition);
    
    % Pre-allocate a vector for the handle to each line
    hLine = zeros(numLinesToPlot,1);
    
    % Plot the data
    hold on;
    for iLine = 1:numLinesToPlot
        % Get the colour for this line
        thisColour = Visualisation.getDefaultColourForIndex( iLine );
        % Specify the line width
        thisLineWidth = Visualisation.lineWidthThin;
        
        % Plot the line
        hLine(iLine) = plot( hAxes, (1:timeLength), reshape(data(1,iLine,:),timeLength,1) , 'color' , thisColour , 'LineWidth' , thisLineWidth );
    end
    hold off;
    
    % Label a few things
    % Set some properties of the axes
    set(hAxes,'XGrid','on');
    set(hAxes,'YGrid','on');
    set(hAxes,'FontSize',16);
    % Make it only integer ticks
    %if (display_xTickLabel)     set(hAxFObj,'XTick',(1:numCases)');
    %else                        set(hAxFObj,'XTickLabel','');       end;
    % Add the title and axis label
    title( inputControllerSpecs.label );
    xlabel('Time [index]');
    ylabel('Cost');
    % LEGEND
    hLegend1 = legend(hAxes, hLine, labelPerDim{2}, 'Location', 'SouthOutside');
    %newPosition = [0.125 0.02 0.25 0.07];
    %newUnits = 'normalized';
    %set(hLegend1,'Position', newPosition,'Units', newUnits, 'interpreter','latex');
    set(hLegend1,'interpreter','none');
    
    
	
end
% END OF FUNCTION