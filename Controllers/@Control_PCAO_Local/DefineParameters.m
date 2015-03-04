function [Param]=DefineParameters(obj,current_folder,predictions)

%=========================================================================
%This function defines and saves useful parameters for PCAO implementation
%=========================================================================


fprintf('\nDefining experiment and system parameters...');

%struct creation for all the information
Param=struct;
                           %PCAO parameters%
%=================================================================================%

Param.e1 = 5*10^(-6);%0.00001     % lower bounds of P matrix elements 
Param.e2 = 4*Param.e1;        % upper bounds of P matrix elements
Param.maxMONOMorder = 3;      % maximum order of random monomials in the estimator
Param.NoMonomials = 150;      % number of monomials forming the polynomial
Param.NoPerturbations = 250;  % number of random perturbations - tests
Param.CapBuffer = 30;         % time window capacity for estimator training
Param.pole = 0.03;            % stabilization slow pole in fictitious control integration
Param.GlobalCapBuffer = 4;    % global performance history points to be incorporated in the estimator's regressor vector
Param.w_norm = 10;            % normalisation bound i.e. [ - w_norm, + w_norm ] for estimator training data
Param.PerturbStep = 0.04;     % Perturbation searching step
Param.alpha = 0.1;            % constraints are incorporated in the cost as:
Param.eta = 1;                % exp(-alpha*(CONST(i) - eta) functions
Param.PerturbValidation = 1;  % perturbation validation method using the estimator
Param.PerturbCenter = 4;      % switch changing the perturbation center decision  


                           %System parameters%
%===================================================================================%

Param.NoSystems=7;
Param.L = 1;                                                        % number of controller mixing functions
Param.NoStates = obj.stateDef.n_x;                                  % state variables number
Param.NoActions = obj.stateDef.n_u;                                 % control variables number
Param.NoDisturbances = obj.stateDef.n_xi;                           % disturbance measurements % Temperature, humidity, solar radiation
Param.PredictDistHorizon =  length(predictions.mean);               % distrurbance prediction horizon hours
Param.NoConstraints = 0;
Param.dt=15*60;

               % maximum/minimum values of control/state variables %
%===================================================================================%

Param.U_MIN =  obj.constraintDef.u_rect_lower*ones(1,Param.NoActions) ;  % respective minimum values of control variables    
Param.U_MAX =  obj.constraintDef.u_rect_upper*ones(1,Param.NoActions) ;  % respective maximum values of control variables         

Param.CHI_MIN = obj.constraintDef.x_rect_lower*ones(1,Param.NoStates);   % respective minimum values of state variables [ Temperatures and Humidities ]    
Param.CHI_MAX = obj.constraintDef.x_rect_upper*ones(1,Param.NoStates);   % respective maximum values of state variables [ Temperatures and Humidities ]  


Param.lambda = 1*ones(1,Param.NoActions);        % saturation function slope factor

save([current_folder,'Simulation_Parameters.mat'],'Param');
