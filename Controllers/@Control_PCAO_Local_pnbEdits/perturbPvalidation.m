function [ P_ij_best, Ecur_est_best ] = perturbPvalidation( X_buffer, Global_Cost_buffer, P_ij, ...
    theta, orders, bounds, e1, e2, a, perturb_num, w, GlobalCapBuffer, PerturbValidationMethod )

P_ij_best = P_ij;
E_best = +Inf;
Ecur_est_best = E_best;

fprintf('\nSearching for an improved perturbation...')
fprintf('\nPerturbation (total %d): ',perturb_num)
counter1 = 0;
counter2 = 0;
for i=1:perturb_num
    
    success_chars = 0;
    fprintf('%d',i)
	
    [ P_ij_cand ] = Control_PCAO_Local_pnbEdits.perturbPDMrandomly( P_ij, a, e1, e2 );
    P_ij_candidate = Control_PCAO_Local_pnbEdits.vectorise3Dmatrix( P_ij_cand );
    % STATIC CONTROLLER SIMULATIONS OF AIMSUN SHOULD BE PLUGGED HERE AND RETURN SUM(E) TO DECIDE THE BEST PERTURB
	E_candidate = 0;
    
	switch PerturbValidationMethod
        case 0
            for ii=1:size(X_buffer,2)
                [ x ] = Control_PCAO_Local_pnbEdits.createTRAININGdata(X_buffer, P_ij_candidate, Global_Cost_buffer, GlobalCapBuffer, ii);
%                 [ x ] = [ P_ij_candidate ];
                [ phi ] = Control_PCAO_Local_pnbEdits.calcPHI( x, orders );
                [ phi ] = Control_PCAO_Local_pnbEdits.vectorBOUNDnormalisation( phi, bounds, w );
                E_candidate = E_candidate + theta*phi';
            end
			Ecur_est = E_candidate;
        case 1
            [ x ] = Control_PCAO_Local_pnbEdits.createTRAININGdata(X_buffer, P_ij_candidate, Global_Cost_buffer, GlobalCapBuffer, size(X_buffer,2));
%             [ x ] = [ P_ij_candidate ];
            [ phi ] = Control_PCAO_Local_pnbEdits.calcPHI( x, orders );
            [ phi ] = Control_PCAO_Local_pnbEdits.vectorBOUNDnormalisation( phi, bounds, w );
            E_candidate = theta*phi';
            Ecur_est = E_candidate;
    end
% 	X(:,i) = x;
% 	E(i) = E_candidate;
% 	P(:,i) = P_ij_candidate;
	
    if isnan(E_candidate) || isempty(E_candidate)
        counter1 = counter1 + 1;
    end
	% DECIDING THE BEST PERTURBATION USING ONLY THE ERROR
    if abs(E_candidate)<E_best
        counter2 = counter2 + 1;
        fprintf(' - Successful!')
        P_ij_best = P_ij_cand;
        E_best = abs(E_candidate);
        Ecur_est_best = abs(Ecur_est);
        success_chars = length(char(' - Successful!'));
    end
    
    backspaces = length(char({num2str(i)})) + success_chars;
	if i<perturb_num
		for iii=1:backspaces
			fprintf('\b')
		end
	end
end
% FAULTS1 = {theta,bounds,orders,w,X};
% save FAULTS1.mat FAULTS1
% FAULTS2 = {X,E,P};
% save FAULTS2.mat FAULTS2

fprintf(' OK!')
% fprintf('\nNot A Number E_{cand} %d of %d detected!',counter1,perturb_num)
% fprintf('\nBetter E_{cand} %d of %d detected!',counter2,perturb_num)
% pause(3)

end