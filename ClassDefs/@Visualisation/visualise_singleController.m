function [ ] = visualise_singleController( inputControllerSpecs , inputDataStruct , inputPropertyNames , plotOptions )
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


%% SPECIFY THE DATA THAT THIS FUNCTION CAN PLOT

plotableDataPerTime = {'state','input','disturbance','cost'};

plotableDataPerRealisation = {'costCumulative'};


%% SPECIFY A FEW DEFAULTS

legendFontSize_default = 12;
labelFontSize_default = 16;
xLabelInterpreter_default = 'latex';
yLabelInterpreter_default = 'none';

%% --------------------------------------------------------------------- %%
%% PLOT ALL THE PLOTABLE DATA FROM THE "inputPropertyNames"

% This is a standardised plotting function that should have nothing
% hard-coded and ideally enough flexiblity to plot "anything"

% Get the number of properties
numInputProperties = length(inputPropertyNames);

% Iterate through each property
for iProperty = 1 : numInputProperties
    % Get the name of this property
    thisProperty = inputPropertyNames{iProperty};
    
    % Get the name of the data represented by the property
    if isfield( inputDataStruct , thisProperty );
        thisDataRepresents = inputDataStruct.(thisProperty).dataRepresents;
    else
        thisDataRepresents = '';
    end
    
    % Check that the data represented by this property is:
    %% PLOTABLE PER TIME
    if ismember( thisDataRepresents , plotableDataPerTime )
        
        
        %% Deduce the title and y-axis label to use
        switch lower(thisDataRepresents)
            % ------------------------------- %
            case 'state'
                thisTitleString  = 'States';
                thisYLabelString = 'State, $x$ (Temperature [T])';
                thisFigIndex = 1;
                
            % ------------------------------- %
            case 'input'
                thisTitleString  = 'Inputs';
                thisYLabelString = 'Input, $u$';
                thisFigIndex = 2;
                
            % ------------------------------- %
            case 'disturbance'
                thisTitleString  = 'Disturbances';
                thisYLabelString = 'Disturbance, $\xi$';
                thisFigIndex = 3;
            
            % ------------------------------- %
            case 'cost'
                thisTitleString  = 'Cost Components and Total';
                thisYLabelString = '';
                thisFigIndex = 4;
                
            % ------------------------------- %
            otherwise
                thisTitleString  = 'Placeholder';
                thisYLabelString = 'Placeholder';
        end
                
            
        %% CHECK THE "to plot" MASK
        mask_toPlot     = inputDataStruct.(thisProperty).toPlotMask;
        
        numSubPlots = 1;
        if ~all(mask_toPlot)
            numSubPlots = 2;
        end
        
        if strcmp( thisDataRepresents , 'cost')
            numSubPlots = 3;
        end
        
        
        
        %% Extract the data to be plotted for "thisProperty
        if numSubPlots == 1
            data            = inputDataStruct.(thisProperty).data(:,:,1);
        elseif numSubPlots == 2
            data            = inputDataStruct.(thisProperty).data(mask_toPlot,:,1);
        else
            % numSubPlots == 3
            data            = inputDataStruct.(thisProperty).data(:,:,1);
        end
        dimPerTime      = inputDataStruct.(thisProperty).dimPerTime;
        labelPerDim     = inputDataStruct.(thisProperty).labelPerDim;
        
        %% Extract the time vector to plot the data against
        thisTimePropertyName = inputDataStruct.(thisProperty).timePropertyName;
        timeLength      = size( data , dimPerTime+1 );
        if strcmp( unitsForTimeAxis , 'steps' )
            timeForPlot     = inputDataStruct.(thisTimePropertyName).data(1,1:timeLength);
            thisTimeLabel   = 'Time [index]';
        elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
            timeForPlot     = inputDataStruct.(thisTimePropertyName).data(2,1:timeLength);
            thisTimeLabel   = 'Time [hours]';
            % Need to put a few extra statements in here to detect the exact units
            % of "inputDataStruct.time.data(2,:);" and scale it appropriately
        else
            disp( ' ... ERROR: The "unitsForTimeAxis" plotting option was not a recognised string');
            disp( '            Option requested is:');
            disp(unitsForTimeAxis);
        end

        
        %% Get the number of lines to be plotted, and the legend text for each
        if (dimPerTime == 1)
            numLinesToPlot = size(data,1);
            if numSubPlots == 1
                legendStrings = labelPerDim{1}(:);
            elseif numSubPlots == 2
                legendStrings = labelPerDim{1}(mask_toPlot);
            else
                % numSubPlots == 3
                legendStrings = [];
            end
        elseif (dimPerTime == 2)
            numLinesToPlot = size(data,1) * size(data,2);
            legendStrings = labelPerDim{1}(:);
        else
            % We are not handling this case properly
            disp( ' ... ERROR: This function does NOT handle data with more' );
            disp( '            than 2 dimensions per time step' );
            numLinesToPlot = 0;
            legendStrings = [];
        end

        % Specify the plotting options
        thisPlotOptions = { 'LineColourIndex'   ,  1:numLinesToPlot                  ;...    % 01
                            'LineWidth'         ,  Visualisation.lineWidthDefault    ;...    % 02
                            'maRkerIndex'       ,  0                                 ;...    % 03 % OPTIONS: '0' gives no marker, other options are: {'o','+','*','.','x','square','diamond','^','v','<','>','pentagram','hexagram'}
                            'legendOnOff'       ,  'on'                              ;...    % 04 % OPTIONS: 'off', 'on'
                            'legendStrings'     ,  legendStrings                     ;...    % 05
                            'legendFontSize'    ,  legendFontSize_default            ;...    % 06
                            'legendFontWeight'  ,  'bold'                            ;...    % 07 % OPTIONS: 'normal', 'bold'
                            'legendLocation'    ,  'eastOutside'                     ;...    % 08 % OPTIONS: see below
                            'legendInterpreter' ,  'none'                            ;...    % 09 % OPTIONS: 'latex', 'tex', 'none'
                            'titleString'       ,  thisTitleString                   ;...    % 10
                            'titleFontSize'     ,  24                                ;...    % 11
                            'titleFontWeight'   ,  'bold'                            ;...    % 12 % OPTIONS: 'normal', 'bold'
                            'titleColour'       ,  'black'                           ;...
                            'XLabelString'      ,  thisTimeLabel                     ;...
                            'YLabelString'      ,  thisYLabelString                  ;...
                            'XLabelInterpreter' ,  xLabelInterpreter_default         ;...    % OPTIONS: 'latex', 'tex', 'none'
                            'YLabelInterpreter' ,  yLabelInterpreter_default         ;...    % OPTIONS: 'latex', 'tex', 'none'
                            'XLabelColour'      ,  'black'                           ;...
                            'YLabelColour'      ,  'black'                           ;...
                            'LabelFontSize'     ,  labelFontSize_default             ;...
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
        thisFigurePosition = Visualisation.getFigurePositionInFullScreenGrid( 2,2, thisFigIndex , 'columnwise' );
        hFig = figure('OuterPosition',thisFigurePosition);
        set(hFig,'Color', Visualisation.figure_backgroundColour );

        if numSubPlots == 1
            % Create the axes
            thisPosition = [0.15 0.15 0.8 0.75];
            hAxes = axes('Position', thisPosition);

            % Now call the generic plotting function
            Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );
        elseif numSubPlots == 2
            % ------------------------------ %
            % Create the first subplot
            hAxes = subplot(2,1,1);
            % Now call the generic plotting function
            Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );
            
            % ------------------------------ %
            % Now get the second set of data
            data            = inputDataStruct.(thisProperty).data(~mask_toPlot,:,1);
            % Update the legend strings and "numLinesToPlot" plotting option
            legendStrings = labelPerDim{1}(~mask_toPlot);
            numLinesToPlot = size(data,1);
            % Put these into the "thisPlotOptions" cell array in the
            % appropriate location
            thisPlotOptions{1,2} = 1:numLinesToPlot;
            thisPlotOptions{5,2} = legendStrings;
            
            % Create the swcond subplot
            hAxes = subplot(2,1,2);
            % Now call the generic plotting function
            Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );
        else
            % numSubPlots == 3
            % Step through each of the line
            for iLine = 1:numLinesToPlot
                hAxes = subplot(numLinesToPlot,1,iLine);

                % Updates the title string
                thisPlotOptions{1,2} = 1;   % This is for: 'LineColourIndex'
                thisPlotOptions{5,2} = [];  % This is for: 'legendStrings'
                thisPlotOptions{10,2} = ['Cost Component: ', labelPerDim{1}{iLine}];     % This is for: 'titleString'
                
        
                % Now call the generic plotting function
                Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data(iLine,:) , thisPlotOptions  );
            end
        end % END OF: "numSubPlots == 1"
        

    % Check that the data represented by this property is:
    %% PLOTABLE PER REALISATION
    elseif ismember( thisDataRepresents , plotableDataPerRealisation )
        
        %% Extract the data to be plotted for "thisProperty
        data                = inputDataStruct.(thisProperty).data;
        dimPerRealisation   = inputDataStruct.(thisProperty).dimPerRealisation;
        labelPerDim         = inputDataStruct.(thisProperty).labelPerDim;
        
        
        
        %% Extract the time vector to plot the data against
        
        numRealisations = size( data , dimPerRealisation+1 );
        
        thisTimeLabel   = 'Time [index]';
%         thisTimePropertyName = inputDataStruct.(thisProperty).timePropertyName;
%         timeLength      = size( data , dimPerRealisation+1 );
%         if strcmp( unitsForTimeAxis , 'steps' )
%             timeForPlot     = inputDataStruct.(thisTimePropertyName).data(1,1:timeLength);
%             thisTimeLabel   = 'Time [index]';
%         elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
%             timeForPlot     = inputDataStruct.(thisTimePropertyName).data(2,1:timeLength);
%             thisTimeLabel   = 'Time [hours]';
%             % Need to put a few extra statements in here to detect the exact units
%             % of "inputDataStruct.time.data(2,:);" and scale it appropriately
%         else
%             disp( ' ... ERROR: The "unitsForTimeAxis" plotting option was not a recognised string');
%             disp( '            Option requested is:');
%             disp(unitsForTimeAxis);
%         end

        %% Get the number of lines to be plotted, and the legend text for each
        if (dimPerRealisation == 1)
            numLinesToPlot = size(data,1);
            legendStrings = labelPerDim{1}(:);
        elseif (dimPerRealisation == 2)
            numLinesToPlot = size(data,1) * size(data,2);
            legendStrings = labelPerDim{1}(:);
        else
            % We are not handling this case properly
            disp( ' ... ERROR: This function does NOT handle data with more' );
            disp( '            than 2 dimensions per time step' );
            numLinesToPlot = 0;
            legendStrings = [];
        end

        % Specify the plotting options
        thisPlotOptions = { 'LineColourIndex'   ,  1                                 ;...    % 01
                            'LineWidth'         ,  Visualisation.lineWidthDefault    ;...    % 02
                            'maRkerIndex'       ,  1                                 ;...    % 03 % OPTIONS: '0' gives no marker, other options are: {'o','+','*','.','x','square','diamond','^','v','<','>','pentagram','hexagram'}
                            'legendOnOff'       ,  'off'                             ;...    % 04 % OPTIONS: 'off', 'on'
                            'legendStrings'     ,  []                                ;...    % 05
                            'legendFontSize'    ,  legendFontSize_default            ;...    % 06
                            'legendFontWeight'  ,  'bold'                            ;...    % 07 % OPTIONS: 'normal', 'bold'
                            'legendLocation'    ,  'eastOutside'                     ;...    % 08 % OPTIONS: see below
                            'legendInterpreter' ,  'none'                            ;...    % 09 % OPTIONS: 'latex', 'tex', 'none'
                            'titleString'       ,  []                                ;...    % 10
                            'titleFontSize'     ,  24                                ;...    % 11
                            'titleFontWeight'   ,  'bold'                            ;...    % 12 % OPTIONS: 'normal', 'bold'
                            'titleColour'       ,  'black'                           ;...    % 13
                            'XLabelString'      ,  thisTimeLabel                     ;...    % 14
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

        % Create the figure
        hFig = figure('position',[50 40 1200 600]);
        set(hFig,'Color', Visualisation.figure_backgroundColour );

        for iData = 1 : numLinesToPlot
            hAxes = subplot(1,numLinesToPlot,iData);
            %scatter( hAxes , ones(numRealisations,1) , data(iData,:) );
            
            thisPlotOptions{15,2} = ['Cost Component: ', labelPerDim{1}{iData}];     % This is for: 'YLabelString'
            
            % Now call the generic plotting function
            Visualisation.visualise_plotMultipleHistogramAsScatter( hAxes , data(iData,:) , thisPlotOptions  );
            
        end
        
        hSupTitle = suptitle('Cumulative Cost Distibution over Realisations');
        set(hSupTitle,'FontSize',16,'FontWeight','normal');
        
        
        % Create the axes
        %thisPosition = [0.15 0.15 0.8 0.75];
        %hAxes = axes('Position', thisPosition);

        % Now call the generic plotting function
        %Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );

        
        
    else
        disp([' ... NOTE: the result with property name "',thisProperty,'" that represents "',thisDataRepresents,'" could not be plotted' ]);
        disp( '           because it has not been programmed how to plot this type of data' );
    end
end   % END OF: "for iProperty = 1 : numInputProperties"


%% --------------------------------------------------------------------- %%
%% PLOT THE STATES (Those of importance and everything)
if false
% Get the data
% @TODO - THERE IS A PARTIAL HACK HERE BECUSE "1:7" IS HARDCODED!!!
data            = inputDataStruct.x_worker_0001.data(1:7,:);
dimPerTime      = inputDataStruct.x_worker_0001.dimPerTime;
labelPerDim     = inputDataStruct.x_worker_0001.labelPerDim;

timeLength      = size( data , dimPerTime+1 );
if strcmp( unitsForTimeAxis , 'steps' )
    timeForPlot     = inputDataStruct.time_worker_0001.data(1,1:timeLength);
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    timeForPlot     = inputDataStruct.time_worker_0001.data(2,1:timeLength);
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
thisPlotOptions = { 'legendStrings'     ,  labelPerDim{1}(1:7)                 ;...
                    'LineColourIndex'   ,  1:numLinesToPlot                  ;...
                    'LineWidth'         ,  Visualisation.lineWidthDefault    ;...
                    %'maRkerIndex'       ,  ones(numLinesToPlot,1)            ;...
                    'legendOnOff'       ,  'on'                              ;...    % OPTIONS: 'off', 'on'
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
%thisPosition = [0.15 0.15 0.8 0.75];
%hAxes = axes('Position', thisPosition);

% Create the axes for the states of "importance"
hAxes = subplot(2,1,1);

% Now call the generic plotting function
Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );


% NOW FOR ALL THE STATES
% Update the data to be all states
data = inputDataStruct.x_worker_0001.data(:,:);
% Update the legend labels respectively
thisPlotOptions{1,2} = labelPerDim{1}(:);
% Update the "numLinesToPlot"
numLinesToPlot = size(data,1);
thisPlotOptions{2,2} = 1:numLinesToPlot;


% Create the axes for ALL the states
hAxes = subplot(2,1,2);
% Now call the generic plotting function
Visualisation.visualise_plotMultipleLines( hAxes , timeForPlot, data , thisPlotOptions  );



%% --------------------------------------------------------------------- %%
%% PLOT THE INPUTS
% Get the data
data            = inputDataStruct.u_worker_0001.data;
dimPerTime      = inputDataStruct.u_worker_0001.dimPerTime;
labelPerDim     = inputDataStruct.u_worker_0001.labelPerDim;

timeLength      = size( data , dimPerTime+1 );
if strcmp( unitsForTimeAxis , 'steps' )
    timeForPlot     = inputDataStruct.time_worker_0001.data(1,1:timeLength);
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    timeForPlot     = inputDataStruct.time_worker_0001.data(2,1:timeLength);
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
data            = inputDataStruct.xi_worker_0001.data;
dimPerTime      = inputDataStruct.xi_worker_0001.dimPerTime;
labelPerDim     = inputDataStruct.xi_worker_0001.labelPerDim;


timeLength      = size( data , dimPerTime+1 );
if strcmp( unitsForTimeAxis , 'steps' )
    timeForPlot     = inputDataStruct.time_worker_0001.data(1,1:timeLength);
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    timeForPlot     = inputDataStruct.time_worker_0001.data(2,1:timeLength);
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
data            = inputDataStruct.cost_worker_0001.data;
dimPerTime      = inputDataStruct.cost_worker_0001.dimPerTime;
labelPerDim     = inputDataStruct.cost_worker_0001.labelPerDim;


timeLength      = size( data , dimPerTime+1 );
if strcmp( unitsForTimeAxis , 'steps' )
    timeForPlot     = inputDataStruct.time_worker_0001.data(1,1:timeLength);
    thisTimeLabel   = 'Time [index]';
elseif ismember( unitsForTimeAxis , {'days', 'hours', 'minutes', 'seconds'} )
    timeForPlot     = inputDataStruct.time_worker_0001.data(2,1:timeLength);
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
    
    
end % END OF: "if false"
    
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