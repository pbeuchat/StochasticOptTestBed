classdef Visualisation < handle
% This class interfaces the disturbance and system with the controller
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > 
% ----------------------------------------------------------------------- %


    properties(Hidden,Constant)
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Visualisation';
    end
    
    properties(Constant)
        %colourArrayLength@double = 6;
        %colourArrayDefault@cell = {'-b','-r','-g','-c','-m','-k'};
        colourArrayLength@double = 8;
        colourArrayDefault@cell = {   [228, 26 , 28 ]/255      ;...     % RED
                                      [55 , 126, 184]/255      ;...     % BLUE
                                      [152, 78 , 163]/255      ;...     % PURPLE
                                      [255, 127, 0  ]/255      ;...
                                      [77 , 175, 74 ]/255      ;...
                                      [255, 255, 51 ]/255      ;...
                                      [166, 86 , 40 ]/255      ;...
                                      [247, 129, 191]/255       ...
                                   };
        markerArrayLength@double = 13;
        markerArrayDefault@cell = {'o','+','*','.','x','square','diamond','^','v','<','>','pentagram','hexagram'};
        markerNoneString@string = 'none';
        
        figure_backgroundColour@double = [0.75 , 0.75 , 0.75 ];
        
        lineWidthFeint@double      = 0.5;
        lineWidthThin@double       = 1.0;
        lineWidthDefault@double    = 1.5;
        lineWidthThick@double      = 2.5;
        
        fontWeightOptions = {'normal','bold'}
        interpretterOptions = {'tex','latex','none'};
        legendLocationOptions = {'north', 'south', 'east', 'west', 'northeast', 'northwest', 'southeast', 'southwest', ...
                    'northoutside', 'southoutside', 'eastoutside', 'westoutside', 'northeastoutside', 'northwestoutside',...
                    'southeastoutside', 'southwestoutside', 'best', 'bestoutside', 'none'};
        onOffOptions = {'on','off'};
        gridStyleOptions = {'-', '--', ':', '-.', 'none'};
        colourOptions = {'y', 'yellow', 'm', 'magenta', 'c', 'cyan', 'r', 'red', 'g', 'green', 'b', 'blue', 'w', 'white', 'k', 'black' };
        
        
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        
    end
    
    properties (Access = private)
        
    end
    
    
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Visualisation()
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
            end
            % END OF: "if nargin > 0"
        end
        % END OF: "function obj = ProgressModelEngine(inputModel,inputModelType)"
      
        % This allows the "DECONSTRUCTOR" method to be augmented
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    %methods (Static = false , Access = public)
    %end
    % END OF: "methods (Static = false , Access = public)"
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    methods (Static = true , Access = public)
        
        [ ] = visualise_singleController( inputControllerSpecs , inputDataStruct , inputPropertyNames );
        
        [ ] = visualise_multipleControllers( inputControllerSpecs , inputDataStruct , inputPropertyNames );
        
        [ ] = visualise_plotMultipleLines( hAxes , data_x , data_y , varargin )
        
        function returnColour = getDefaultColourForIndex( inputIndex )
            thisIndex = mod(inputIndex-1, Visualisation.colourArrayLength ) + 1;
            returnColour = Visualisation.colourArrayDefault{thisIndex,1};
        end
        
        
        
        function returnMarker = getDefaultMarkerForIndex( inputIndex )
            if inputIndex == 0
                returnMarker = Visualisation.markerNoneString;
            else
                thisIndex = mod(inputIndex-1, Visualisation.markerArrayLength ) + 1;
                returnMarker = Visualisation.markerArrayDefault{thisIndex};
            end
        end
        
    end
    % END OF: "methods (Static = true , Access = public)"
        
    %methods (Static = true , Access = private)
        
    %end
    % END OF: "methods (Static = true , Access = private)"
    
end

