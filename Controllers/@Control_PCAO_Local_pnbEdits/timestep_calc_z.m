function [ z ] = timestep_calc_z( L, beta_multi, x_bar, sym_flag )
% THIS FUNCTION CALCULATES z VALUES FOR ONE TIMESTEP - FOR A SINGLE GIVEN x_bar

    dim_sub = length(x_bar);
    
    z = zeros(dim_sub*L,1);
    if sym_flag == 1
        z = sym(z);
    end
    for i=1:L
        
        z((i-1)*dim_sub+1:i*dim_sub,1) = sqrt(beta_multi(i))*x_bar;
        
    end

end

