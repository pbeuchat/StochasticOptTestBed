classdef ConstraintDef < handle
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


    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(15);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'StateDef';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        % The state definiton used to instantiate this object
        stateDef@StateDef;
        
        % The constraint definitions for the state vector
        x_box@double;
        x_rect_upper@double;
        x_rect_lower@double;
        x_poly_A@double;
        x_poly_b@double;
        x_poly_label@cell;
        x_poly_mask@logical;
        
        % The constraint definitions for the input vector
        u_box@double;
        u_rect_upper@double;
        u_rect_lower@double;
        u_poly_A@double;
        u_poly_b@double;
        u_poly_label@cell;
        u_poly_mask@logical;
        
        % Flags for which constraints are "included"
        flag_inc_x_box@logical   = false;
        flag_inc_x_rect@logical  = false;
        flag_inc_x_poly@logical  = false;
        
        flag_inc_u_box@logical   = false;
        flag_inc_u_rect@logical  = false;
        flag_inc_u_poly@logical  = false;
        
        % Having all the constraints together as one polytope is the
        % fastest for computation
        x_all_A@double;
        x_all_b@double;
        x_all_label@cell;
        
        u_all_A@double;
        u_all_b@double;
        u_all_label@cell;
        
        
        
    end
    
    properties (Access = private)
        % The State Def Object
        %stateDef@StateDef;
        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = ConstraintDef( inputStateDef , x_box , x_rect_upper , x_rect_lower , x_poly_A , x_poly_b , x_poly_label , x_poly_mask , u_box , u_rect_upper , u_rect_lower , u_poly_A , u_poly_b , u_poly_label , u_poly_mask )
            % Check if number of input arguments is correct
            if nargin ~= obj.n_properties
                %fprintf(' ... ERROR: The Constructor for the %s class requires %d argument/s for object creation.' , obj.thisClassName , obj.n_properties);
                disp([' ... ERROR: The Constructor for the "',obj.thisClassName,'" class requires ',num2str(obj.n_properties),' argument/s for object creation.']);
                error(bbConstants.errorMsg);
            end
            
            % ----------------------------------------------------- %
            % DO ALL THE CHECKS FOR THE "x" CONSTRAINTS
            % Check if the input State Definition object is of the
            % appropriate class
            if ~( isa( inputStateDef , 'StateDef' ) )
                disp( ' ... ERROR: the input State Definition object was not of class "StateDef".' );
                disp(['             Instead it was class(inputStateDef)  = ',class(inputStateDef)]);
                error(bbConstants.errorMsg);
            end

            % Check if the input is empty, and if not, check it is the
            % right type and the correct size
            if ~isempty(x_box)
                % Check the type
                if ~isfloat(x_box)
                    disp( ' ... ERROR: the input vector must be a double vector. It was input as:' );
                    disp(['             type of "x_box" = ',class(x_box)]);
                    error(bbConstants.errorMsg);
                else
                    % Now check they are the correct size
                    if ~( (size(x_box,1) == inputStateDef.n_x) && (size(x_box,2) == 1 ) )
                        disp( ' ... ERROR: the input vector is not the expected size' );
                        disp(['            the size of the input is: size(x_box) = ',num2str(size(x_box,1)),' -by- ',num2str(size(x_box,2)) ]);
                        disp(['            the expected size was:    size(x_box) = ',num2str(inputStateDef.n_x),' -by- 1' ]);
                        error(bbConstants.errorMsg);
                    else
                        % If we made it here then this constraint is
                        % valid and can be used
                        obj.flag_inc_x_box = true;
                    end
                end
            end
            
            % Check if the input is empty, and if not, check it is the
            % right type and the correct size
            if ( ~isempty(x_rect_lower) && ~isempty(x_rect_upper) )
                % Check the type
                if ( ~isfloat(x_rect_lower) || ~isfloat(x_rect_upper) )
                    disp( ' ... ERROR: the input vectors must be a double vectors. They were input as:' );
                    disp(['             type of "x_rect_lower" = ',class(x_rect_lower)]);
                    disp(['             type of "x_rect_upper" = ',class(x_rect_upper)]);
                    else
                    % Now check they are the correct size
                    if ~( (size(x_rect_lower,1) == inputStateDef.n_x) && (size(x_rect_lower,2) == 1 ) )
                        disp( ' ... ERROR: the input vector is not the expected size' );
                        disp(['            the size of the input is: size(x_rect_lower) = ',num2str(size(x_rect_lower,1)),' -by- ',num2str(size(x_rect_lower,2)) ]);
                        disp(['            the expected size was:    size(x_rect_lower) = ',num2str(inputStateDef.n_x),' -by- 1' ]);
                        error(bbConstants.errorMsg);
                    else
                        if ~( (size(x_rect_upper,1) == inputStateDef.n_x) && (size(x_rect_upper,2) == 1 ) )
                            disp( ' ... ERROR: the input vector is not the expected size' );
                            disp(['            the size of the input is: size(x_rect_upper) = ',num2str(size(x_rect_upper,1)),' -by- ',num2str(size(x_rect_upper,2)) ]);
                            disp(['            the expected size was:    size(x_rect_upper) = ',num2str(inputStateDef.n_x),' -by- 1' ]);
                            error(bbConstants.errorMsg);
                        else
                            % If we made it here then this constraint is
                            % valid and can be used
                            obj.flag_inc_x_rect = true;
                        end
                    end
                end
            else
                x_rect_lower = [];
                x_rect_upper = [];
            end
            
            
            % Check if the input is empty, and if not, check it is the
            % right type and the correct size
            if ( ~isempty(x_poly_A) && ~isempty(x_poly_b) && ~isempty(x_poly_mask) )
                % Check the type
                if ~isfloat(x_poly_A) || ~isfloat(x_poly_b) || ~islogical(x_poly_mask) || ~iscellstr(x_poly_label)
                    disp( ' ... ERROR: the input polytope matrix and vector must be doubles, the mask logical, and the labels a cell array of strings. It was input as:' );
                    disp(['             class of "x_poly_A"     = ',class(x_poly_A)]);
                    disp(['             class of "x_poly_b"     = ',class(x_poly_b)]);
                    disp(['             class of "x_poly_mask"  = ',class(x_poly_mask)]);
                    disp(['             class of "x_poly_label" = ',class(x_poly_label)]);
                    error(bbConstants.errorMsg);
                else
                    % Now check that the "x_poly_mask" only specifies the
                    % number of components equal to "n_x"
                    if ~( full(sum(x_poly_mask,1)) == inputStateDef.n_x )
                        disp( ' ... ERROR: the input mask for the "x" polytope selected more elements than the size "n_x"' );
                        disp(['            the sum of the mask:    sum(x_poly_mask,1) = ',num2str( sum(x_poly_mask,1) ) ]);
                        disp(['            the expected sum was:   inputStateDef.n_x  = ',num2str( inputStateDef.n_x  ) ]);
                        error(bbConstants.errorMsg);
                    else
                        % Now check that the "b" vector is compatible
                        if ~( (size(x_poly_A,1) == size(x_poly_b,1)) && (size(x_poly_b,2) == 1) )
                            disp( ' ... ERROR: the input "b" vector is not the expected size' );
                            disp(['            the size of the input is: size(x_poly_b) = ',num2str(size(x_poly_b,1)),' -by- ',num2str(size(x_poly_b,2)) ]);
                            disp(['            the expected size was:    size(x_poly_b) = ',num2str(size(x_poly_A,1)),' -by- 1' ]);
                            error(bbConstants.errorMsg);
                        else
                            % Check that the label is a compatible size
                            if ~( (size(x_poly_A,1) == size(x_poly_label,1)) && (size(x_poly_label,2) == 1) )
                                    disp( ' ... ERROR: the input cell array of labels is not the expected size' );
                                    disp(['            the size of the input is: size(x_poly_label) = ',num2str(size(x_poly_label,1)),' -by- ',num2str(size(x_poly_label,2)) ]);
                                    disp(['            the expected size was:    size(x_poly_label) = ',num2str(size(x_poly_A,1)),' -by- 1' ]);
                                    error(bbConstants.errorMsg);
                            else
                                % Check that the mask is a compatible size
                                if ~( (size(x_poly_A,2) == size(x_poly_mask,1)) && (size(x_poly_mask,2) == 1) )
                                    disp( ' ... ERROR: the input mask for the polytope is not the expected size' );
                                    disp(['            the size of the input is: size(x_poly_mask) = ',num2str(size(x_poly_mask,1)),' -by- ',num2str(size(x_poly_mask,2)) ]);
                                    disp(['            the expected size was:    size(x_poly_mask) = ',num2str(size(x_poly_A,2)),' -by- 1' ]);
                                    error(bbConstants.errorMsg);
                                else
                                    % If we made it here then this constraint is
                                    % valid and can be used
                                    obj.flag_inc_x_poly = true;
                                end
                            end
                        end
                    end
                end
            else
                x_poly_A        = [];
                x_poly_b        = [];
                x_poly_label    = cell(0,1);
                x_poly_mask     = false(0,0);
            end
            
            
            % ----------------------------------------------------- %
            % NOW ALL THE SAME CHECKS FOR THE "u" CONSTRAINTS
            % Check if the input is empty, and if not, check it is the
            % right type and the correct size
            if ~isempty(u_box)
                % Check the type
                if ~isfloat(u_box)
                    disp( ' ... ERROR: the input vector must be a double vector. It was input as:' );
                    disp(['             type of "u_box" = ',class(u_box)]);
                    error(bbConstants.errorMsg);
                else
                    % Now check they are the correct size
                    if ~( (size(u_box,1) == inputStateDef.n_u) && (size(u_box,2) == 1 ) )
                        disp( ' ... ERROR: the input vector is not the expected size' );
                        disp(['            the size of the input is: size(u_box) = ',num2str(size(u_box,1)),' -by- ',num2str(size(u_box,2)) ]);
                        disp(['            the expected size was:    size(u_box) = ',num2str(inputStateDef.n_u),' -by- 1' ]);
                        error(bbConstants.errorMsg);
                    else
                        % If we made it here then this constraint is
                        % valid and can be used
                        obj.flag_inc_u_box = true;
                    end
                end
            end
            
            % Check if the input is empty, and if not, check it is the
            % right type and the correct size
            if ( ~isempty(u_rect_lower) && ~isempty(u_rect_upper) )
                % Check the type
                if ( ~isfloat(u_rect_lower) || ~isfloat(u_rect_upper) )
                    disp( ' ... ERROR: the input vectors must be a double vectors. They were input as:' );
                    disp(['             type of "u_rect_lower" = ',class(u_rect_lower)]);
                    disp(['             type of "u_rect_upper" = ',class(u_rect_upper)]);
                    else
                    % Now check they are the correct size
                    if ~( (size(u_rect_lower,1) == inputStateDef.n_u) && (size(u_rect_lower,2) == 1 ) )
                        disp( ' ... ERROR: the input vector is not the expected size' );
                        disp(['            the size of the input is: size(u_rect_lower) = ',num2str(size(u_rect_lower,1)),' -by- ',num2str(size(u_rect_lower,2)) ]);
                        disp(['            the expected size was:    size(u_rect_lower) = ',num2str(inputStateDef.n_u),' -by- 1' ]);
                        error(bbConstants.errorMsg);
                    else
                        if ~( (size(u_rect_upper,1) == inputStateDef.n_u) && (size(u_rect_upper,2) == 1 ) )
                            disp( ' ... ERROR: the input vector is not the expected size' );
                            disp(['            the size of the input is: size(u_rect_upper) = ',num2str(size(u_rect_upper,1)),' -by- ',num2str(size(u_rect_upper,2)) ]);
                            disp(['            the expected size was:    size(u_rect_upper) = ',num2str(inputStateDef.n_u),' -by- 1' ]);
                            error(bbConstants.errorMsg);
                        else
                            % If we made it here then this constraint is
                            % valid and can be used
                            obj.flag_inc_u_rect = true;
                        end
                    end
                end
            else
                u_rect_lower = [];
                u_rect_upper = [];
            end
            
            
            % Check if the input is empty, and if not, check it is the
            % right type and the correct size
            if ( ~isempty(u_poly_A) && ~isempty(u_poly_b) && ~isempty(u_poly_mask) )
                % Check the type
                if ~isfloat(u_poly_A) || ~isfloat(u_poly_b) || ~islogical(u_poly_mask) || ~iscellstr(u_poly_label)
                    disp( ' ... ERROR: the input polytope matrix and vector must be doubles, the mask logical, and the labels a cell array of strings. It was input as:' );
                    disp(['             class of "u_poly_A"     = ',class(u_poly_A)]);
                    disp(['             class of "u_poly_b"     = ',class(u_poly_b)]);
                    disp(['             class of "u_poly_mask"  = ',class(u_poly_mask)]);
                    disp(['             class of "u_poly_label" = ',class(u_poly_label)]);
                    error(bbConstants.errorMsg);
                else
                    % Now check that the "u_poly_mask" only specifies the
                    % number of components equal to "n_u"
                    if ~( full(sum(u_poly_mask,1)) == inputStateDef.n_u )
                        disp( ' ... ERROR: the input mask for the "u" polytope selected more elements than the size "n_u"' );
                        disp(['            the sum of the mask:    sum(u_poly_mask,1) = ',num2str( sum(u_poly_mask,1) ) ]);
                        disp(['            the expected sum was:   inputStateDef.n_u  = ',num2str( inputStateDef.n_u  ) ]);
                        error(bbConstants.errorMsg);
                    else
                        % Now check that the "b" vector is compatible
                        if ~( (size(u_poly_A,1) == size(u_poly_b,1)) && (size(u_poly_b,2) == 1) )
                            disp( ' ... ERROR: the input "b" vector is not the expected size' );
                            disp(['            the size of the input is: size(u_poly_b) = ',num2str(size(u_poly_b,1)),' -by- ',num2str(size(u_poly_b,2)) ]);
                            disp(['            the expected size was:    size(u_poly_b) = ',num2str(size(u_poly_A,1)),' -by- 1' ]);
                            error(bbConstants.errorMsg);
                        else
                            % Check that the label is a compatible size
                            if ~( (size(u_poly_A,1) == size(u_poly_label,1)) && (size(u_poly_label,2) == 1) )
                                    disp( ' ... ERROR: the input cell array of labels is not the expected size' );
                                    disp(['            the size of the input is: size(u_poly_label) = ',num2str(size(u_poly_label,1)),' -by- ',num2str(size(u_poly_label,2)) ]);
                                    disp(['            the expected size was:    size(u_poly_label) = ',num2str(size(u_poly_A,1)),' -by- 1' ]);
                                    error(bbConstants.errorMsg);
                            else
                                % Check that the mask is a compatible size
                                if ~( (size(u_poly_A,2) == size(u_poly_mask,1)) && (size(u_poly_mask,2) == 1) )
                                    disp( ' ... ERROR: the input mask for the polytope is not the expected size' );
                                    disp(['            the size of the input is: size(u_poly_mask) = ',num2str(size(u_poly_mask,1)),' -by- ',num2str(size(u_poly_mask,2)) ]);
                                    disp(['            the expected size was:    size(u_poly_mask) = ',num2str(size(u_poly_A,2)),' -by- 1' ]);
                                    error(bbConstants.errorMsg);
                                else
                                    % If we made it here then this constraint is
                                    % valid and can be used
                                    obj.flag_inc_u_poly = true;
                                end
                            end
                        end
                    end
                end
            else
                u_poly_A        = [];
                u_poly_b        = [];
                u_poly_label    = cell(0,1);
                u_poly_mask     = false(0,0);
            end
            
            
            % ---------------------------------------------------- %
            % NOW PUT ALL THE INPUT INTO THE APPROPRIATE VARIABLES OF THIS
            % OBJECT
            obj.stateDef        = inputStateDef;
            
            obj.x_box           = x_box;
            obj.x_rect_lower    = x_rect_lower;
            obj.x_rect_upper    = x_rect_upper;
            obj.x_poly_A        = x_poly_A;
            obj.x_poly_b        = x_poly_b;
            obj.x_poly_label    = x_poly_label;
            obj.x_poly_mask     = x_poly_mask;
            
            obj.u_box           = u_box;
            obj.u_rect_lower    = u_rect_lower;
            obj.u_rect_upper    = u_rect_upper;
            obj.u_poly_A        = u_poly_A;
            obj.u_poly_b        = u_poly_b;
            obj.u_poly_label    = u_poly_label;
            obj.u_poly_mask     = u_poly_mask;
            
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
        % FUNCTION:
        function returnConstraintDef = requestPartialConstraintDefForGivenSubSystem( obj , inputStateDefPartial , inputStateDefFull , i_ss )
            
            % Get the mask for this sub-system from the State Definiton
            % masks
            mask_x = inputStateDefFull.mask_x_ss( : , i_ss );
            mask_u = inputStateDefFull.mask_u_ss( : , i_ss );
            
            % Works through each constraint type, applying the mask as
            % appropriate to the constraint type
            
            % --------------------- FOR X ------------------------- %
            % For the "x" box
            if obj.flag_inc_x_box
                new_x_box = obj.x_box(mask_x,1);
            else
                new_x_box = [];
            end
            
            % For the "x" hyper-rectangle
            if obj.flag_inc_x_rect
                new_x_rect_lower = obj.x_rect_lower(mask_x,1);
                new_x_rect_upper = obj.x_rect_upper(mask_x,1);
            else
                new_x_rect_lower = [];
                new_x_rect_upper = [];
            end
            
            % For the "x" polytope
            % Only tell the sub-system about constraints in which it is
            % involved
            if obj.flag_inc_x_poly
                % Collect a list of indicies in which this subsystem is
                % involved
                old_x_poly_A_partial = obj.x_poly_A(:,mask_x');
                mask_x_poly = ( sum( abs(old_x_poly_A_partial) ,2) > 0 );
                
                new_x_poly_A      = obj.x_poly_A(mask_x_poly,:);
                new_x_poly_b      = obj.x_poly_b(mask_x_poly,1);
                new_x_poly_label  = obj.x_poly_label(mask_x_poly,1);
            else
                new_x_poly_A = [];
                new_x_poly_b = [];
                new_x_poly_label = cell(0,1);
            end
            
            
            % --------------------- FOR U ------------------------- %
            % For the "u" box
            if obj.flag_inc_u_box
                new_u_box = obj.u_box(mask_u,1);
            else
                new_u_box = [];
            end
            
            % For the "u" hyper-rectangle
            if obj.flag_inc_u_rect
                new_u_rect_lower = obj.u_rect_lower(mask_u,1);
                new_u_rect_upper = obj.u_rect_upper(mask_u,1);
            else
                new_u_rect_lower = [];
                new_u_rect_upper = [];
            end
            
            % For the "u" polytope
            % Only tell the sub-system about constraints in which it is
            % involved
            if obj.flag_inc_u_poly
                % Collect a list of indicies in which this subsystem is
                % involved
                old_u_poly_A_partial = obj.u_poly_A(:,mask_u');
                mask_u_poly = ( sum( abs(old_u_poly_A_partial) ,2) > 0 );
                
                new_u_poly_A      = obj.u_poly_A(mask_u_poly,:);
                new_u_poly_b      = obj.u_poly_b(mask_u_poly,1);
                new_u_poly_label  = obj.u_poly_label(mask_u_poly,1);
            else
                new_u_poly_A = [];
                new_u_poly_b = [];
                new_u_poly_label = cell(0,1);
            end
            
            % Create the return object
            returnConstraintDef = ConstraintDef( inputStateDefPartial , new_x_box , new_x_rect_upper , new_x_rect_lower , new_x_poly_A , new_x_poly_b , new_x_poly_label , mask_x , new_u_box , new_u_rect_upper , new_u_rect_lower , new_u_poly_A , new_u_poly_b , new_u_poly_label , mask_u );
        end
        % END OF: "function [...] = xxx(...)"
        
 
        % FUNCTION: to construct a single polytope that describes all the
        % constraints
        function createCombinedConstraintDescription( obj )
            
            % Get the state and input size from the State Definition object
            n_x = double( obj.stateDef.n_x );
            n_u = double( obj.stateDef.n_u );
            
            % The polytope should not be included if this is a partial
            % constraint defintion. This can be identified by checking if
            % the "A" matrix is the same width as "n_x" or "n_u"
            % respectively
            if obj.flag_inc_x_poly
                flag_compatible_x_poly = ( n_x == size(obj.x_poly_A,2) );
            else
                flag_compatible_x_poly = false;
            end
            
            if obj.flag_inc_u_poly
                flag_compatible_u_poly = ( n_u == size(obj.u_poly_A,2) );
            else
                flag_compatible_u_poly = false;
            end
           
            
            % Start with the x-only constraints
            if obj.flag_inc_x_box
                A_x_box = [ speye(n_x) ; -speye(n_x)  ];
                b_x_box = [ obj.x_box  ; -obj.x_box   ];
                x_box_label = cell(2*n_x,1);
                for i_x = 1:n_x
                    x_box_label{i_x,1}      = [ 'Box on "x" element ',num2str(i_x),', with identifier ',obj.stateDef.label_x{i_x},', [x]_',num2str(i_x),' <= ',num2str(obj.x_box(i_x,1)) ];
                end
                for i_x = 1:n_x
                    x_box_label{n_x+i_x,1}  = [ 'Box on "x" element ',num2str(i_x),', with identifier ',obj.stateDef.label_x{i_x},', [x]_',num2str(i_x),' >= -',num2str(obj.x_box(i_x,1)) ];
                end
            else
                A_x_box = sparse( [],[],[], 0 , n_x , 0 );
                b_x_box = zeros(0,1);
                x_box_label = cell(0,1);
            end
            
            if obj.flag_inc_x_rect
                A_x_rect = [ speye(n_x)       ; -speye(n_x)  ];
                b_x_rect = [ obj.x_rect_upper  ; -obj.x_rect_lower   ];
                x_rect_label = cell(2*n_x,1);
                for i_x = 1:n_x
                    x_rect_label{i_x,1}         = [ 'Hyper-rectanlge on "x" element ',num2str(i_x),', with identifier ',obj.stateDef.label_x{i_x},', [x]_',num2str(i_x),' <= ',num2str(obj.x_rect_upper(i_x,1)) ];
                end
                for i_x = 1:n_x
                    x_rect_label{n_x+i_x,1}     = [ 'Hyper-rectangle on "x" element ',num2str(i_x),', with identifier ',obj.stateDef.label_x{i_x},', [x]_',num2str(i_x),' >= ',num2str(obj.x_rect_lower(i_x,1)) ];
                end
            else
                A_x_rect = sparse( [],[],[], 0 , n_x , 0 );
                b_x_rect = zeros(0,1);
                x_rect_label = cell(0,1);
            end
            
            if flag_compatible_x_poly
                A_x_poly = obj.x_poly_A;
                b_x_poly = obj.x_poly_b;
                x_poly_label_copy = obj.x_poly_label;
            else
                A_x_poly = sparse( [],[],[], 0 , n_x , 0 );
                b_x_poly = zeros(0,1);
                x_poly_label_copy = cell(0,1);
            end
            
            % Now put them together
            obj.x_all_A = [ A_x_box ; A_x_rect ; A_x_poly ];
            obj.x_all_b = [ b_x_box ; b_x_rect ; b_x_poly ];
            obj.x_all_label = [x_box_label ; x_rect_label ; x_poly_label_copy];
            
            
            % Start with the u-only constraints
            if obj.flag_inc_u_box
                A_u_box = [ speye(n_u) ; -speye(n_u)  ];
                b_u_box = [ obj.u_box  ; -obj.u_box   ];
                u_box_label = cell(2*n_u,1);
                for i_u = 1:n_u
                    u_box_label{i_u,1}      = [ 'Box on "u" element ',num2str(i_u),', with identifier ',obj.stateDef.label_u{i_u},', [u]_',num2str(i_u),' <= ',num2str(obj.u_box(i_u,1)) ];
                end
                for i_u = 1:n_u
                    u_box_label{n_u+i_u,1}  = [ 'Box on "u" element ',num2str(i_u),', with identifier ',obj.stateDef.label_u{i_u},', [u]_',num2str(i_u),' >= -',num2str(obj.u_box(i_u,1)) ];
                end
            else
                A_u_box = sparse( [],[],[], 0 , n_u , 0 );
                b_u_box = zeros(0,1);
                u_box_label = cell(0,1);
            end
            
            if obj.flag_inc_u_rect
                A_u_rect = [ speye(n_u)       ; -speye(n_u)  ];
                b_u_rect = [ obj.u_rect_upper  ; -obj.u_rect_lower   ];
                u_rect_label = cell(2*n_u,1);
                for i_u = 1:n_u
                    u_rect_label{i_u,1}         = [ 'Hyper-rectanlge on "u" element ',num2str(i_u),', with identifier ',obj.stateDef.label_u{i_u},', [u]_',num2str(i_u),' <= ',num2str(obj.u_rect_upper(i_u,1)) ];
                end
                for i_u = 1:n_u
                    u_rect_label{n_u+i_u,1}     = [ 'Hyper-rectangle on "u" element ',num2str(i_u),', with identifier ',obj.stateDef.label_u{i_u},', [u]_',num2str(i_u),' >= ',num2str(obj.u_rect_lower(i_u,1)) ];
                end
            else
                A_u_rect = sparse( [],[],[], 0 , n_u , 0 );
                b_u_rect = zeros(0,1);
                u_rect_label = cell(0,1);
            end
            
            if flag_compatible_u_poly
                A_u_poly = obj.u_poly_A;
                b_u_poly = obj.u_poly_b;
                u_poly_label_copy = obj.u_poly_label;
            else
                A_u_poly = sparse( [],[],[], 0 , n_u , 0 );
                b_u_poly = zeros(0,1);
                u_poly_label_copy = cell(0,1);
            end
            
            % Now put them together
            obj.u_all_A = [ A_u_box ; A_u_rect ; A_u_poly ];
            obj.u_all_b = [ b_u_box ; b_u_rect ; b_u_poly ];
            obj.u_all_label = [u_box_label ; u_rect_label ; u_poly_label_copy];
            
            
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

