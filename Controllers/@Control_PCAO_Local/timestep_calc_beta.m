function [ beta ] = timestep_calc_beta( L, chi, GC_temp, GC_humid, temp_sigma, humid_sigma, sym_flag )
% THIS FUNCTION CALCULATES BETA VALUES FOR ONE TIMESTEP - FOR A SINGLE GIVEN chi
    global mFileErrorCode
    tilde_beta = zeros(1,L);
    temp_norms = 0;
    humid_norms = 0;
    A = 0;
    B = 0;
    s = 0;
    beta = zeros(1,L);
    NoZones = length(chi);
    mFileErrorCode = 'timestep_beta';
    if sym_flag == 1
        tilde_beta = sym(tilde_beta);
        temp_norms = sym(temp_norms);
        humid_norms = sym(humid_norms);
        A = sym(A);
        B = sym(B);
        s = sym(s);
        beta = sym(beta);
    end
    
    temp_norms = sqrt(chi(1:NoZones)'*chi(1:NoZones));
    
    
    for i = 1:L

        % Gaussian values for every time instance of state vector
        A = exp(-((temp_norms-GC_temp(i))^2)/(2*temp_sigma^2));
        B = exp(-((humid_norms-GC_humid(i))^2)/(2*humid_sigma^2));
        tilde_beta(i)= A*B;

    end

    s = sum(tilde_beta);
    beta = tilde_beta/s;
    
end

