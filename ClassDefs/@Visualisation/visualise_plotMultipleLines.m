function [ ] = visualise_plotMultipleLines( hAxes , data_x , data_y , varargin )
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %


    %% REFERENCES:
    % See this Matlab page for all the possible properties that can be set
    % for the "Axes Properties";
    % http://ch.mathworks.com/help/matlab/ref/axes-properties.html
    

    %% ----------------------------------------------------------------- %%
    %% PRELIMINARY CHECKS AND SETTINGS
    

    %% Set the default interpretter for text to be latex
    %   > This will apply to all figures created
    set(0, 'defaultTextInterpreter', 'latex');
    
    %% Check the x and y data are compatible with eachother
    if ~( (size(data_x,1) == 1) || (size(data_x,2) == 1) )
        disp( ' ... ERROR: the input "x" data was not a vector');
        disp(['            size(data_x) = ',num2str(size(data_x,1)),' -by- ',num2str(size(data_x,2)) ]);
        disp( ' ... Returning from function now without plotting anything');
        return;
    end
    
    if ~( length(data_x) == size(data_y,2) )
        disp( ' ... ERROR: the input "y" data should have the same width as the length of the "x" data');
        disp(['            size(data_y)    = ',num2str(size(data_y,1)),' -by- ',num2str(size(data_y,2)) ]);
        disp(['            length(data_x)  = ',num2str(length(data_y)),' -by- ',num2str(size(data_y,2)) ]);
        disp( ' ... Returning from function now without plotting anything');
        return;
    end
    
    
    %% GET THE NUMBER OF LINE TO PLOT - directly from the "y" data
    numLinesToPlot = size(data_y,1);
    
    
    %% ----------------------------------------------------------------- %%
    %% NOW PARSE THE "varargin" TO EXTRACT THE SETTINGS FROM IT
    % The following need to be set for the plotting to be performed
    % We declare them all as empty here, parse through the "varargin", and
    % then set those that are still empty to their default
    
    % Line details
    lineColourIndex         = [];
    lineWidth               = [];
    markerIndex             = [];
    
    % Legend details
    legendStrings           = [];
    legendFontSize          = [];
    legendFontWeight        = [];
    legendLocation          = [];
    legendInterpreter       = [];
    
    % Title details
    titleString             = [];
    titleFontSize           = [];
	titleFontWeight         = [];
	titleColour             = [];

    % Axis label details
    xLabelString            = [];
	yLabelString            = [];
	xLabelColour            = [];
	yLabelColour            = [];
	labelFontSize           = [];
	labelFontWeight         = [];
    
    % Grid details
	xGridOnOff              = [];
	yGridOnOff              = [];
	xGridStyle              = [];
	yGridStyle              = [];
	xGridMinorOnOff         = [];
	yGridMinorOnOff         = [];
	xGridMinorStyle         = [];
	yGridMinorStyle         = [];
    
    % Specify also in one place the defaults for each of the above
    % Line defaults
    default_lineColourIndex = ones( numLinesToPlot , 1 );
    default_lineWidth = Visualisation.lineWidthDefault * ones( numLinesToPlot , 1 );
    default_markerIndex = zeros( numLinesToPlot , 1 );
    
    % Legend defaults
    default_legendStrings           = [];
    default_legendFontSize          = 10;
    default_legendFontWeight        = 'normal';
    default_legendLocation          = 'bestOutside';
    default_legendInterpreter       = 'none';
    
    % Title defaults
    default_titleString             = [];
    default_titleFontSize           = 16;
	default_titleFontWeight         = 'bold';
	default_titleColour             = 'k';

    % Axis label defaults
    default_xLabelString            = [];
	default_yLabelString            = [];
	default_xLabelColour            = 'k';
	default_yLabelColour            = 'k';
	default_labelFontSize           = 12;
	default_labelFontWeight         = 'normal';
    
    % Grid defaults
	default_xGridOnOff              = 'on';
	default_yGridOnOff              = 'on';
	default_xGridStyle              = '--';
	default_yGridStyle              = '--';
	default_xGridMinorOnOff         = 'off';
	default_yGridMinorOnOff         = 'off';
	default_xGridMinorStyle         = ':';
	default_yGridMinorStyle         = ':';
    
    % Now parse through the "VARiable ARGuments IN" cell array (i.e.
    % "varargin")
    if (~isempty(varargin))
        % Check if the number of extra arguments is more than expected
        if length(varargin) > 1
            disp(' ... ERROR: inputs after the 4th are not used');
        end
        inputSettings = varargin{1};
        for iTemp = 1:size(inputSettings,1)
            switch lower(inputSettings{iTemp,1})
                % ------------------------------- %
                case 'linecolourindex'
                    lineColourIndex = inputSettings{iTemp,2};
                    % If entered as a singleton, increase it to a vector
                    if ( size(lineColourIndex,1) == 1 && size(lineColourIndex,2) == 1 && ndims(lineColourIndex) == 2 )
                        lineColourIndex = repmat(lineColourIndex,numLinesToPlot,1);
                    end
                    % Check it is the right size
                    if ~( length(lineColourIndex) == numLinesToPlot && min(size(lineColourIndex)) == 1 && ndims(lineColourIndex) == 2 )
                        disp(' ... ERROR: the "LineColourIndex" option input was not a compatible size, using the default instead');
                        lineColourIndex = [];
                    end
                    
                % ------------------------------- %
                case 'linewidth'
                    lineWidth = inputSettings{iTemp,2};
                    % If entered as a singleton, increase it to a vector
                    if ( size(lineWidth,1) == 1 && size(lineWidth,2) == 1 && ndims(lineWidth) == 2 )
                        lineWidth = repmat(lineWidth,numLinesToPlot,1);
                    end
                    % Check it is the right size
                    if ~( length(lineWidth) == numLinesToPlot && min(size(lineWidth)) == 1 && ndims(lineWidth) == 2 )
                        disp(' ... ERROR: the "lineWidth" option input was not a compatible size, using the default instead');
                        lineWidth = [];
                    end
                    
                % ------------------------------- %
                case 'markerindex'
                    markerIndex = inputSettings{iTemp,2};
                    % If entered as a singleton, increase it to a vector
                    if ( size(markerIndex,1) == 1 && size(markerIndex,2) == 1 && ndims(markerIndex) == 2 )
                        markerIndex = repmat(markerIndex,numLinesToPlot,1);
                    end
                    % Check it is the right size
                    if ~( length(markerIndex) == numLinesToPlot && min(size(markerIndex)) == 1 && ndims(markerIndex) == 2 )
                        disp(' ... ERROR: the "markerIndex" option input was not a compatible size, using the default instead');
                        markerIndex = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendstrings'
                    legendStrings = inputSettings{iTemp,2};
                    % If is is not a cell array of strings then ignore
                    if ~iscellstr( legendStrings )
                        disp(' ... ERROR: the "legendstrings" option input was not a cell array of strings and can not be used');
                        disp('            No legend will be displayed');
                        legendStrings = [];
                    end
                    % Check it is the right size
                    if ~( length(legendstrings) == numLinesToPlot && min(size(legendstrings)) == 1 && ndims(legendstrings) == 2 )
                        disp(' ... ERROR: the "legendstrings" option input was not a compatible size');
                        disp('            No legend will be displayed');
                        legendStrings = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendfontsize'
                    legendFontSize = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~( size(legendFontSize,1) == 1 && size(legendFontSize,2) == 1 && ndims(legendFontSize) == 2 && isfloat(legendFontSize) )
                        disp(' ... ERROR: the "legendFontSize" option input was not valid, using default instead');
                        legendFontSize = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendfontweight'
                    legendFontWeight = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~ismember( legendFontWeight , Visualisation.fontWeightOptions )
                        disp(' ... ERROR: the "legendFontWeight" option input was not valid, using default instead');
                        legendFontWeight = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendlocation'
                    legendLocation = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~ismember( legendLocation , Visualisation.legendLocationOptions )
                        disp(' ... ERROR: the "legendLocation" option input was not valid, using default instead');
                        legendLocation = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendinterpreter'
                    legendInterpreter = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~ismember( legendInterpreter , Visualisation.legendInterpretterOptions )
                        disp(' ... ERROR: the "legendInterpreter" option input was not valid, using default instead');
                        legendInterpreter = [];
                    end
                    
                    
                % ------------------------------- %
                case 'titlestring'
                    
                    
                    
                % ------------------------------- %
                case 'titlefontsize'
                    titleFontSize = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~( size(titleFontSize,1) == 1 && size(titleFontSize,2) == 1 && ndims(titleFontSize) == 2 && isfloat(titleFontSize) )
                        disp(' ... ERROR: the "titleFontSize" option input was not valid, using default instead');
                        titleFontSize = [];
                    end
                    
                    
                % ------------------------------- %
                case 'titlefontweight'
                    titleFontWeight = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~ismember( titleFontWeight , Visualisation.fontWeightOptions )
                        disp(' ... ERROR: the "titleFontWeight" option input was not valid, using default instead');
                        titleFontWeight = [];
                    end
                    
                    
                    
                    
                % ------------------------------- %
                case 'titlecolour'
                    
                    
                    
                % ------------------------------- %
                case 'xlabel'
                    
                    
                    
                % ------------------------------- %
                case 'ylabel'
                    
                    
                    
                    
                % ------------------------------- %
                case 'xlabelcolour'
                    
                    
                    
                % ------------------------------- %
                case 'ylabelcolour'
                    
                    
                    
                % ------------------------------- %
                case 'labelfontsize'
                    labelFontSize = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~( size(labelFontSize,1) == 1 && size(labelFontSize,2) == 1 && ndims(labelFontSize) == 2 && isfloat(labelFontSize) )
                        disp(' ... ERROR: the "labelFontSize" option input was not valid, using default instead');
                        labelFontSize = [];
                    end
                    
                    
                % ------------------------------- %
                case 'labelfontweight'
                    labelFontWeight = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~ismember( labelFontWeight , Visualisation.fontWeightOptions )
                        disp(' ... ERROR: the "labelFontWeight" option input was not valid, using default instead');
                        labelFontWeight = [];
                    end
                    
                    
                % ------------------------------- %
                case 'xgrid'
                    
                    
                    
                % ------------------------------- %
                case 'ygrid'
                    
                    
                    
                % ------------------------------- %
                case 'xgridstyle'
                    
                    
                    
                % ------------------------------- %
                case 'ygridstyle'
                    
                    
                    
                % ------------------------------- %
                case 'xgridminor'
                    
                    
                    
                % ------------------------------- %
                case 'ygridminor'
                    
                    
                    
                % ------------------------------- %
                case 'xgridminorstyle'
                    
                    
                    
                % ------------------------------- %
                case 'ygridminorstyle'
                    
                    
            
            otherwise         
                disp([' ... ERROR: Invalid optional argument, "',inputSettings{iTemp},'"' ]);
                disp( '            This argument is skipped and the default used instead' );  
            end
            % END OF: switch varargin{c}
        end
        % END OF: for c=1:length(varargin)
    end
    % END OF: if (~isempty(varargin))
    
    if isempty(lineColourIndex)
        lineColourIndex = default_lineColourIndex;
    end
    if isempty(lineWidth)
        lineWidth = default_lineWidth;
    end
    if isempty(markerIndex)
        markerIndex = default_markerIndex;
    end
    
    
    
    %% ----------------------------------------------------------------- %%
    %% PLOT THE DATA
    % Pre-allocate a vector for the handle to each line
    hLine = zeros(numLinesToPlot,1);
    
    % Plot the data
    hold on;
    for iLine = 1:numLinesToPlot
        % Get the colour for this line
        thisColour = Visualisation.getDefaultColourForIndex( lineColourIndex(iLine) );
        % Specify the line width
        thisLineWidth = lineWidth( iLine );
        % Specify the mark
        thisMarker = Visualisation.getDefaultMarkerForIndex( markerIndex(iLine) );
        
        % Plot the line
        hLine(iLine) = plot( hAxes, data_x, data_y(iLine,:) , 'color' , thisColour , 'LineWidth' , thisLineWidth , 'marker' , thisMarker);
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
    %title( inputControllerSpecs.label );
    xlabel('Time [index]');
    ylabel('State, $x$');
    % LEGEND
    %hLegend1 = legend(hAxes, hLine, labelPerDim{1}(1:7), 'Location', 'SouthOutside');
    %newPosition = [0.125 0.02 0.25 0.07];
    %newUnits = 'normalized';
    %set(hLegend1,'Position', newPosition,'Units', newUnits, 'interpreter','latex');
    %set(hLegend1,'interpreter','none');
    
    
    
    
    
    
	
end
% END OF FUNCTION