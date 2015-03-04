function u = computeControlAction( obj , x , xi_prev , stageCost_prev , predictions )
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    % Implement the ADP computation just for the sake of testing
    
    tic;
    
%% --------------------------------------------------------------------- %%
%% EXTRACT THE DETAILS FROM THE INPUTS AND PROPERTIES OF THIS OBJECT
    myBuilding      = obj.model.building;
    myCosts         = obj.model.costDef;
    myConstraints   = obj.model.constraintDef;
    
    A       = sparse( myBuilding.building_model.discrete_time_model.A   );
    Bu      = sparse( myBuilding.building_model.discrete_time_model.Bu  );
    Bxi     = sparse( myBuilding.building_model.discrete_time_model.Bv  );
    Bxu     = myBuilding.building_model.discrete_time_model.Bxu;
    Bxiu    = myBuilding.building_model.discrete_time_model.Bvu;
    
    n_x = size(A,1);
    n_u = size(Bu,2);
    n_xi = size(Bxi,2);
    
    Exi     = predictions.mean(1:n_xi);
    Exixi   = predictions.cov(1:n_xi,1:n_xi);
    
    
%% --------------------------------------------------------------------- %%
%% COMPUTE THE SIZE OF THE PROBLEM

    %n_z = 1/factorial(n_x+n_u-1) * 3^(n_x+n_u-1);
    % See: http://murphmath.wordpress.com/2012/08/22/counting-monomials/
    n_z = nchoosek( (n_x+n_u) + 2 , 2);

    n_zhat = 1 + n_x + n_u + n_x*n_u;
    
%% --------------------------------------------------------------------- %%
%% DECLARE THE OPTIMISATION VARIABLES FOR THE VALUE FUNCTION
    tic;
    P = sdpvar(n_x,n_x,'symmetric');        % Symmetric nxn matrix
    p = sdpvar(n_x,1,'full');        % Symmetric nxn matrix
    s = sdpvar(1,1,'full');        % Symmetric nxn matrix
    toc
    tic;
%% --------------------------------------------------------------------- %%
%% DEFINE THE DISCOUNT FACTOR
    
    disFactor = 0.9;


%% --------------------------------------------------------------------- %%
%% BUILD THE MATRIX FOR "V(f(x,u,xi))"

    % Some preliminary objects required
    Bxiu_Exi_cell = cell(n_u,1);
    for iControl = 1:n_u
        Bxiu_Exi_cell{iControl,1} = sparse(Bxiu(:,:,iControl)) * Exi;
    end
    Bxiu_Exi = horzcat(Bxiu_Exi_cell{:,1});
    
    
    trBxiuPBxi = zeros(n_u,1);
    for iControl = 1:n_u
        trBxiuPBxi(iControl,1) = trace( sparse(Bxiu(:,:,iControl))'*P*Bxi*Exixi);
    end
    trBxiuPBxi = sparse(trBxiuPBxi);
    
    
    trBxiuPBxiu = zeros(n_u,n_u);
    for iControl = 1:n_u
        for jControl = 1:iControl
            if iControl == jControl
                trBxiuPBxiu(iControl,jControl) = 0.5 * trace( sparse(Bxiu(:,:,iControl))' *P* sparse(Bxiu(:,:,jControl))*Exixi);
            else
                trBxiuPBxiu(iControl,jControl) =       trace( sparse(Bxiu(:,:,iControl))' *P* sparse(Bxiu(:,:,jControl))*Exixi);
            end
        end
    end
    trBxiuPBxiu = sparse(trBxiuPBxiu+trBxiuPBxiu');
    
    BPB = Bu'*P*Bu +...
          Bu'*P*Bxiu_Exi + ...
          Bxiu_Exi'*P*Bu + ...
          trBxiuPBxiu;
    
    Bxu_reshape = sparse( reshape(Bxu,n_x,n_x*n_u,1) );
      
    
    EpAhat = p' * [ Bxi * Exi  ,  A  ,  (Bu + Bxiu_Exi)  ,  Bxu_reshape ];
    
    EAPA_topL ...
         = [  0.5*trace(Bxi'*P*Bxi*Exixi)   ,   sparse([],[],[],1,n_x,0)   ,   sparse([],[],[],1,n_u,0)   ;...
              A'*P*Bxi*Exi                  ,   0.5*A'*P*A                 ,   sparse([],[],[],n_x,n_u,0)   ;...
              Bu'*P*Bxi*Exi + trBxiuPBxi    ,   (Bu+Bxiu_Exi)'*P*A         ,   0.5*BPB                     ...
           ];
    
    EAPA_botL = Bxu_reshape' * P * [  Bxi*Exi   ,   A   ,   Bu+Bxiu_Exi   ];
    
    EAPA_botR = Bxu_reshape' * P * Bxu_reshape;
    
    EAPA = [   EAPA_topL+EAPA_topL'   ,   EAPA_botL'   ;...
               EAPA_botL              ,   EAPA_botR     ...
           ];
    
    
    Fhat =   EAPA ...
           + [ EpAhat   ; sparse([],[],[],n_zhat-1,n_zhat,0) ]; ...
           + [ EpAhat'  , sparse([],[],[],n_zhat,n_zhat-1,0) ]; ...
           + sparse(1,1,s,n_zhat,n_zhat,1);
       

%% --------------------------------------------------------------------- %%
%% BUILD THE COST MATRIX
    Lhat_part =  [  myCosts.c   ,   myCosts.q'   ,   myCosts.r'   ;...
                    myCosts.q   ,   myCosts.Q    ,   myCosts.S'   ;...
                    myCosts.r   ,   myCosts.S    ,   myCosts.R     ...
                 ];
    Lhat = blkdiag( Lhat_part , sparse([],[],[],n_x*n_u,n_x*n_u,0) );
    
    
    
%% --------------------------------------------------------------------- %%
%% GET THE NUMBER OF CONSTRAINTS

    numCons = 0;

    % 
    if myConstraints.flag_inc_x_rect
        numCons = numCons + n_x;
    end
    
    if myConstraints.flag_inc_u_rect
        numCons = numCons + n_u;
    end
    
    if myConstraints.flag_inc_u_poly
        numCons = numCons + size(myConstraints.u_poly_b,1);
    end
    
%% --------------------------------------------------------------------- %%
%% DECLARE THE OPTIMISATION VARIABLES FOR THE CONSTRAINT S-PROCEDURE

    toc
    tic;
    numCons = 2;
    lmul = cell(numCons,1);
    for iCon = 1:numCons
        lmul{iCon,1} = sdpvar(1+n_x+n_u,1+n_x+n_u,'symmetric');
    end
    toc

    numVariables = 0.5*(1+n_x)*(1+n_x+1) + 0.5*(1+n_x+n_u)*(1+n_x+n_u+1)*numCons;
    time_toBuild = toc;
    disp([' ... INFO: > It took ',num2str(time_toBuild),' seconds to build the APD formulation']);
    disp( '           > The optimisation problem involves:');
    disp(['                  ',num2str(numVariables,'%12d'),'   variables']);
    disp(['                  ',num2str(0,'%12d'),'   inequality constraints']);
    disp(['                  ',num2str(0,'%12d'),'   equality constraints']);
   

%% --------------------------------------------------------------------- %%
%% BUILD THE CONSTRAINT MATRICIES
    



    
    
end
% END OF FUNCTION