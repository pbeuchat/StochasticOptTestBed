function [ Mx ] = timestep_calc_Mx( L, x_bar, x_bar_des, x, beta_multi, fh_Jacobian_xbar, fh_Jacobian_SQRT_beta,current_folder,Symbolic_folder)
% THIS FUNCTION CALCULATES THE NUMERIC VALUES OF THE JACOBIAN MATRIX

    load([Symbolic_folder,'Symbolic_function'],'fh_Jacobian_xbar','fh_Jacobian_SQRT_beta','fh_SIGMA');
    dim_x = length(x);
    dim_sub = length(x_bar);
    
    fh1 = str2func(char(fh_Jacobian_xbar));
    Mx = zeros(dim_sub*L,dim_x);    
    
    for i=1:L
        if L>1
            fh2 = str2func(char(fh_Jacobian_SQRT_beta(i,:)));
            Mx((i-1)*dim_sub+1:i*dim_sub,:) = (x_bar-x_bar_des)*fh2(x) + sqrt(beta_multi(i))*fh1(x);
        else
           
            Mx((i-1)*dim_sub+1:i*dim_sub,:) = sqrt(beta_multi(i))*fh1(x);
        end
    end

end