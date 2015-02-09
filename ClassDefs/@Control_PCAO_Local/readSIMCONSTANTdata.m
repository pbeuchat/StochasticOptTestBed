function [ L, n, m, num_of_dist, e1, e2, max_order, monomial_number, perturb_num, ...
    T_buffer, pole, w_norm, PredictDistHorizon, number_of_constraints, alpha, eta,  ...
    U_MIN, U_MAX, CHI_MIN, CHI_MAX, lambda,...
     PerturbValidationMethod, PerturbCenter, ...
     GlobalCapBuffer,NoSystems,dt,Astep] = readSIMCONSTANTdata(SIMULparam)
    
    % load([FilePath,'SIMULparam.mat'],'SIMULparam')

    L = SIMULparam.L;
    n = SIMULparam.NoStates;
    m = SIMULparam.NoActions;
    num_of_dist = SIMULparam.NoDisturbances;
    e1 = SIMULparam.e1;
    e2 = SIMULparam.e2;
    max_order = SIMULparam.maxMONOMorder;
    monomial_number = SIMULparam.NoMonomials;
    perturb_num = SIMULparam.NoPerturbations;
    T_buffer = SIMULparam.CapBuffer;
    pole = SIMULparam.pole;
    w_norm = SIMULparam.w_norm;
    PredictDistHorizon = SIMULparam.PredictDistHorizon;
    number_of_constraints = SIMULparam.NoConstraints;
    alpha = SIMULparam.alpha;
    eta = SIMULparam.eta;
    U_MIN = SIMULparam.U_MIN;
    U_MAX = SIMULparam.U_MAX;
    CHI_MIN = SIMULparam.CHI_MIN;
    CHI_MAX = SIMULparam.CHI_MAX;
    lambda = SIMULparam.lambda;
    PerturbValidationMethod = SIMULparam.PerturbValidation;
    PerturbCenter = SIMULparam.PerturbCenter;
    GlobalCapBuffer = SIMULparam.GlobalCapBuffer;
    NoSystems = SIMULparam.NoSystems;
    dt=SIMULparam.dt;
    Astep=SIMULparam.PerturbStep;
end