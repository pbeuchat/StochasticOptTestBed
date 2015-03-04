function [ fh_Jacobian_xbar, fh_Jacobian_SQRT_beta, fh_sigma ] = symbolic_calculations( n, m, num_of_dist, PredictDistHorizon, number_of_constraints, ...
    L, alpha, eta, GC_temp, GC_humid, temp_sigma, humid_sigma, U_min, U_max, lambda,current_folder,System )
    
   %JacobiansPath=[current_folder,'SymbolicFunctions\'];
   JacobiansPath=[current_folder,'SymbolicFunctions/'];
   mkdir( JacobiansPath);
   
	sym_flag = 1;
    fprintf('\nSymbolic function generation...')
    % symbolic creation of state
    chi = zeros(n,1); 
    chi = sym(chi);
    for i = 1:n
        chi(i) = sym(['chi',num2str(i)], 'real');
    end

    % symbolic creation of unconstrained control inputs
    u_bar = zeros(m,1); 
    u_bar = sym(u_bar);
    for i = 1:m
        u_bar(i) = sym(['u_bar',num2str(i)], 'real');
    end

    % symbolic creation of saturated control inputs
    [ u ] = Control_PCAO_Local_pnbEdits.sigmoid( u_bar, lambda, U_min, U_max, sym_flag );

    [ beta ] = Control_PCAO_Local_pnbEdits.timestep_calc_beta( L, chi, GC_temp, GC_humid, temp_sigma, humid_sigma, sym_flag );
    
	CONSTR = zeros(number_of_constraints,1); 
    CONSTR = sym(CONSTR);
	for i = 1:number_of_constraints
		CONSTR(i) = sym(['CONSTR',num2str(i)], 'real');
    end
	
    % symbolic creation of unconstrained control inputs
    d = zeros(num_of_dist,1); 
    d = sym(d);
    for i = 1:num_of_dist
        d(i) = sym(['d',num2str(i)], 'real');
    end
    
    % symbolic creation of unconstrained control inputs
    pd = zeros(PredictDistHorizon,1); 
    pd = sym(pd);
    for i = 1:PredictDistHorizon
        pd(i) = sym(['pd',num2str(i)], 'real');
    end
% 	%  --------------------------------------------
% 	%   User defined symbolic constraint forms
%	%	constraints (symbolic) of the form C(y) < 0
% 	%  --------------------------------------------
% 	if (number_of_constraints>0)
% 		CONSTR(1:n) = -chi;                    % 0 <= x_i
% 		CONSTR(n+1:2*n) = chi-X_max;           % x_i <= x_i,max
% 		CONSTR(2*n+1:3*n+m) = -u_bar-U_min;    % 0 <= G_i and g_i,min <= g_i
% 		for i=1:n
% 		   idx=find(Row(i,:)==-1);
% 		   CONSTR(225+i) = u_bar(i)-sum(u_bar(n+idx));  % G_i <= sum g_i (that receive r.o.w.)
% 
% 		end
% 		counter=1;
% 		for i=1:Nr_junctions
% 			%sum g <= C - L for every junction
% 		  CONSTR(270+Nr_junctions+i) = sum(u_bar(counter:counter+Stages(i)))-Cycle-Losttime(i);  
% 			%sum g >= C - L for every junction
% 		  CONSTR(286+Nr_junctions+i) = -sum(u_bar(counter:counter+Stages(i)))+Cycle+Losttime(i);   
% 		  counter=counter+Stages(i);
% 		end
% 	end
	
    % penality functions
    sigma = zeros(number_of_constraints,1); 
    sigma = sym(sigma);

    for i = 1:number_of_constraints
        sigma(i) = exp(alpha*CONSTR(i)-eta);
    end
    
    %augmented state vector x and augmented output vector y
    x_bar = [chi; 1; u; d; pd; sigma];
    x = [chi; u_bar];
    
    %  -------------------------------------------
    %  Transformation of dynamical system equation
    %  -------------------------------------------
    
%     Calculate M matrix symbolic parts
    addpath(JacobiansPath)
%     flag = 0;
%     while true
        string = [JacobiansPath,'ConstraintsL',num2str(L),num2str(System)];
        MM0 = matlabFunction(sigma,'file',string,'vars',{x}); %0
        fh_sigma = ['ConstraintsL',num2str(L),num2str(System)];
%         if number_of_constraints>0
%             flag = checkSymbolics(fh_sigma);
%         else
%             flag = 1;
%         end
%         if flag
%             break
%         end
%     end
    
%     flag = 0;
%     while true
        M = jacobian(x_bar,x); %1
        string = [JacobiansPath,'XbarJacobianL',num2str(L),num2str(System)];
        MM1 = matlabFunction(M,'file',string,'vars',{x}); %2
        fh_Jacobian_xbar = ['XbarJacobianL',num2str(L),num2str(System)];
%         flag = checkSymbolics(fh_Jacobian_xbar);
%         if flag
%             break
%         end
%     end
    
%     flag = 0;
%     while true
        for i=1:L
            M = jacobian(sqrt(beta(i)),x); %3
            string = [JacobiansPath,'BetaSQRTJacobian',num2str(i),num2str(L),num2str(System)];
            MM2 = matlabFunction(M,'file',string,'vars',{x}); %4
            fh_Jacobian_SQRT_beta(i,:) = ['BetaSQRTJacobian',num2str(i),num2str(L),num2str(System)];
        end
%         flag = checkSymbolics(fh_Jacobian_SQRT_beta);
%         if flag
%             break;
%         end
%     end

end