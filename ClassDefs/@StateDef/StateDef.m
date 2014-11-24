classdef StateDef < matlab.mixin.Copyable
% This class keeps track of the state, input and disturbance defintions for
% a pariticular porblem instance
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
%               
% ----------------------------------------------------------------------- %
% This class inherits from the super-class "matlab.mixin.Copyable" meaning
% that it is a handle class with a copy method. So we can call "copy()" on
% a "StateDef" object and get a new copy that can be altered without
% alterring the orignal object that we copied from.
% This is necessary so that each "Control_Coordinator" can take a copy of
% the "StateDef" object and alter the "mask_..." and "n_ss" properties if a
% new control structure is defined



    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(11);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'StateDef';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        % State, Input and Disturbance Vector Size
        n_x@uint32  = uint32(0);
        n_u@uint32  = uint32(0);
        n_xi@uint32 = uint32(0);
        
        % Labels for the above
        label_x@cell    = cell(0,0);
        label_u@cell    = cell(0,0);
        label_xi@cell   = cell(0,0);
        
        % The number of sub-systems
        n_ss@uint32 = uint32(0);
        
        % The masks for which sub-system has access to which state and
        % disturbance information, and controls which inputs
        mask_x_ss@logical   = false(0,0);
        mask_u_ss@logical   = false(0,0);
        mask_xi_ss@logical  = false(0,0);
        
        % The Initial State
        x0@double;
        
        
    end
    
    properties (Access = private)
        % Nothing here yet for the "StateDef" class
        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = StateDef( n_x , n_u , n_xi , label_x , label_u , label_xi , n_ss , mask_x_ss , mask_u_ss , mask_xi_ss , x0 )
            % Check if number of input arguments is correct
            if nargin ~= obj.n_properties
                %fprintf(' ... ERROR: The Constructor for the %s class requires %d argument/s for object creation.' , obj.thisClassName , obj.n_properties);
                disp([' ... ERROR: The Constructor for the "',obj.thisClassName,'" class requires ',num2str(obj.n_properties),' argument/s for object creation.']);
                error(bbConstants.errorMsg);
            end

            % Check if the input vector sizes are integers
            if ( ~isinteger(n_x) || ~isinteger(n_u) || ~isinteger(n_xi) )
                disp( ' ... ERROR: the input vector sizes (n_x, n_u, n_xi) must be integers. They were input as:' );
                disp(['             type of "n_x"  = ',class(n_x)]);
                disp(['             type of "n_u"  = ',class(n_u)]);
                disp(['             type of "n_xi" = ',class(n_xi)]);
                error(bbConstants.errorMsg);
            end

            % Check if the labels are input as cell arrays of string
            if ( ~iscellstr(label_x) || ~iscellstr(label_u) || ~iscellstr(label_xi) )
                disp( ' ... ERROR: The labels must be input as a cell array of strings' );
                disp(['              iscellstr(label_x)  = ',num2str( iscellstr(label_x) )]);
                disp(['              iscellstr(label_u)  = ',num2str( iscellstr(label_u) )]);
                disp(['              iscellstr(label_xi) = ',num2str( iscellstr(label_xi) )]);
                error(bbConstants.errorMsg);
            end

            % Check that the number of sub-systems (n_ss) is an integer
            if ~isinteger(n_ss)
                disp( ' ... ERROR: the number of sub-system must be input as an integer' );
                disp(['             type of "n_ss"  = ',class(n_ss)]);
                error(bbConstants.errorMsg);
            end
            
            % Check that the masks are "logicals"
            if ~islogical(mask_x_ss)
                disp(' ... ERROR: the matrix for the state -by- subsystem mask is not of type "logical"');
                disp(['             type of "mask_x_ss"  = ',class(mask_x_ss)]);
                error(bbConstants.errorMsg);
            end
            if ~islogical(mask_u_ss)
                disp(' ... ERROR: the matrix for the input -by- subsystem mask is not of type "logical"');
                disp(['             type of "mask_u_ss"  = ',class(mask_u_ss)]);
                error(bbConstants.errorMsg);
            end
            if ~islogical(mask_xi_ss)
                disp(' ... ERROR: the matrix for the disturbance -by- subsystem mask is not of type "logical"');
                disp(['             type of "mask_xi_ss"  = ',class(mask_xi_ss)]);
                error(bbConstants.errorMsg);
            end
            
            % And, Check thst the masks are of the requied size
            if ~( (size(mask_x_ss,1) == n_x) || (size(mask_x_ss,2) == n_ss) )
                disp(' ... ERROR: the matrix for the state -by- subsystem mask is not the expected size');
                disp(['            size(mask_x_ss)  = ',size(mask_x_ss,1),'-by-',size(mask_x_ss,2),' , but was expected to be of size = ',num2str(n_x),'-by-',num2str(n_ss)]);
                error(bbConstants.errorMsg);
            end
            if ~( (size(mask_u_ss,1) == n_u) || (size(mask_u_ss,2) == n_ss) )
                disp(' ... ERROR: the matrix for the input -by- subsystem mask is not the expected size');
                disp(['            size(mask_u_ss)  = ',size(mask_u_ss,1),'-by-',size(mask_u_ss,2),' , but was expected to be of size = ',num2str(n_u),'-by-',num2str(n_ss)]);
                error(bbConstants.errorMsg);
            end
            if ~( (size(mask_xi_ss,1) == n_xi) || (size(mask_xi_ss,2) == n_ss) )
                disp(' ... ERROR: the matrix for the disturbance -by- subsystem mask is not the expected size');
                disp(['            size(mask_xi_ss)  = ',size(mask_xi_ss,1),'-by-',size(mask_xi_ss,2),' , but was expected to be of size = ',num2str(n_xi),'-by-',num2str(n_ss)]);
                error(bbConstants.errorMsg);
            end
            
            
            % Check that the initial condition is of type "double" and the
            % correct size
            if ~isfloat(x0)
                disp(' ... ERROR: the initial condition is not of type "dobule"');
                disp(['             type of "x0"  = ',class(x0)]);
                error(bbConstants.errorMsg);
            end
            if ~( (size(x0,1) == n_x) || (size(x0,2) == 1) )
                disp(' ... ERROR: the initial condition is not the expected size');
                disp(['            size(x0)  = ',size(x0,1),'-by-',size(x0,2),' , but was expected to be of size = ',num2str(n_x),'-by- 1']);
                error(bbConstants.errorMsg);
            end
            
            
            
            % Create a mask for how each element of the "n_u" inputs can
            % depend on the state and disturbance measurements
            % ... or don't :-(
            
            % Now put all the input into this "StateDef" object
            obj.n_x         = n_x;
            obj.n_u         = n_u;
            obj.n_xi        = n_xi;
            obj.label_x     = label_x;
            obj.label_u     = label_u;
            obj.label_xi    = label_xi;
            obj.n_ss        = n_ss;
            obj.mask_x_ss   = mask_x_ss;
            obj.mask_u_ss   = mask_u_ss;
            obj.mask_xi_ss  = mask_xi_ss;
            obj.x0          = x0;

        end
        % END OF: "function [..] = ProgressModelEngine(...)"
      
        % Augment the deconstructor method
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    
    
    methods (Static = false , Access = public)
        % Define functions implemented in other files:
        % -----------------------------------------------
        
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: to convert the masks to a list of variable labels
        function [] = createLabelOfDependencies()
            % Get the masks
            mask_x_ss = obj.mask_x_ss;
            mask_u_ss = obj.mask_u_ss;
            mask_xi_ss = obj.mask_xi_ss;
            % Get the labels
            label_x = obj.label_x;
            label_u = obj.label_u;
            label_xi = obj.label_xi;
            % Iterate through each sub-system
            for i_ss = 1 : obj.n_ss
                disp('For sub-system 1:');
                disp('   - it can access the following states:');
                thisLogical = mask_x_ss(:,i_ss);
                thisList = label_x;
                for iList = 1:length(thisList)
                    disp(['      ',thisList{iList}]);
                end
                
                disp('   - it can access the following disturbances:');
                thisLogical = mask_xi_ss(:,i_ss);
                thisList = label_xi;
                for iList = 1:length(thisList)
                    disp(['      ',thisList{iList}]);
                end
                
                disp('   - it can control the following inputs:');
                thisLogical = mask_u_ss(:,i_ss);
                thisList = label_u;
                for iList = 1:length(thisList)
                    disp(['      ',thisList{iList}]);
                end
            end
        end
        % END OF: "function [...] = performStateUpdate(...)"
        

        function returnStateDef = requestPartialStateDefForGivenSubSystem( obj , i_ss )
            % Get the size from the number of non-zero elements in the rows
            % of the approriate mask
            this_n_x    = uint32( nnz( obj.mask_x_ss(  :,i_ss ) ) );
            this_n_u    = uint32( nnz( obj.mask_u_ss(  :,i_ss ) ) );
            this_n_xi   = uint32( nnz( obj.mask_xi_ss( :,i_ss ) ) );
            % Get the labels for the state (where the logical type of the
            % masks making logical indexing into the label cell arrays very
            % quick and easy)
            this_label_x    = obj.label_x(  obj.mask_x_ss(  :,i_ss ) );
            this_label_u    = obj.label_u(  obj.mask_u_ss(  :,i_ss ) );
            this_label_xi   = obj.label_xi( obj.mask_xi_ss( :,i_ss ) );

            % By definition the new state definition has only one
            % sub-system
            this_n_ss = uint32(1);

            % ... and the masks are trivally all true
            this_mask_x_ss  = true( this_n_x  , 1);
            this_mask_u_ss  = true( this_n_u  , 1);
            this_mask_xi_ss = true( this_n_xi , 1);
            
            % The the portion of the initial state variable
            this_x0 = obj.x0( obj.mask_x_ss(  : , i_ss ) );
            
            % Create the return object
            returnStateDef = StateDef( this_n_x , this_n_u , this_n_xi , this_label_x , this_label_u , this_label_xi , this_n_ss , this_mask_x_ss , this_mask_u_ss , this_mask_xi_ss , this_x0);
        end
        
        
        function returnIsValid = checkMasksAreValid( obj , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss )
            % Initialise the return variable
            returnIsValid = true;
            
            % First check that the number of sub-systems is positive
            if ( isempty(new_n_ss) || ~isa(new_n_ss,'uint32') || (new_n_ss <= 0) )
                returnIsValid = false;
                disp(' ... ERROR: The input "new_n_ss" variable is either empty, not a "uint32" or not positive...');
                disp(new_n_ss);
                error(bbConstants.errorMsg);
            end
            
            % Second, check that the masks are all of class logical
            if ( ~islogical(new_mask_x_ss) || ~islogical(new_mask_u_ss) || ~islogical(new_mask_xi_ss) )
                returnIsValid = false;
                disp( ' ... ERROR: one or more the the new masks are not of class "logical"');
                disp(['            class(new_mask_x_ss)   = ', class(new_mask_x_ss)  ]);
                disp(['            class(new_mask_u_ss)   = ', class(new_mask_u_ss)  ]);
                disp(['            class(new_mask_xi_ss)  = ', class(new_mask_xi_ss) ]);
            end
            
            % Third, check that each mask has the correct size
            if ~( (size(new_mask_x_ss,1) == obj.n_x) || (size(new_mask_x_ss,2) == new_n_ss) )
                returnIsValid = false;
                disp(' ... ERROR: the matrix for the state -by- subsystem mask is not the expected size');
                disp(['            size(mask_x_ss)  = ',size(new_mask_x_ss,1),'-by-',size(new_mask_x_ss,2),' , but was expected to be of size = ',num2str(obj.n_x),'-by-',num2str(new_n_ss)]);
                error(bbConstants.errorMsg);
            end
            if ~( (size(new_mask_u_ss,1) == obj.n_u) || (size(new_mask_u_ss,2) == new_n_ss) )
                returnIsValid = false;
                disp(' ... ERROR: the matrix for the input -by- subsystem mask is not the expected size');
                disp(['            size(mask_u_ss)  = ',size(new_mask_u_ss,1),'-by-',size(new_mask_u_ss,2),' , but was expected to be of size = ',num2str(obj.n_u),'-by-',num2str(new_n_ss)]);
                error(bbConstants.errorMsg);
            end
            if ~( (size(new_mask_xi_ss,1) == obj.n_xi) || (size(new_mask_xi_ss,2) == new_n_ss) )
                returnIsValid = false;
                disp(' ... ERROR: the matrix for the disturbance -by- subsystem mask is not the expected size');
                disp(['            size(mask_xi_ss)  = ',size(new_mask_xi_ss,1),'-by-',size(new_mask_xi_ss,2),' , but was expected to be of size = ',num2str(obj.n_xi),'-by-',num2str(new_n_ss)]);
                error(bbConstants.errorMsg);
            end
            
            % All the checks are complete and the return variable should
            % already be set to reflect the outcome of the checks
        end
        
        function updateMasks( obj , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss )
            % Put the input objects directly into the variables assuming
            % they have been checked via the "checkMasksAreValid" function
            obj.n_ss        = new_n_ss;
            obj.mask_x_ss   = new_mask_x_ss;
            obj.mask_u_ss   = new_mask_u_ss;
            obj.mask_xi_ss  = new_mask_xi_ss;
            
        end
        
        

        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    
    
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    %methods (Static = true , Access = public)
    %end
    % END OF: "methods (Static = true , Access = public)"
        
    %methods (Static = true , Access = private)
        
    %end
    % END OF: "methods (Static = true , Access = private)"
    
end

