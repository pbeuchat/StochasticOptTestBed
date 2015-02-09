function [ orders ] = monomialRANDOMorders( monomial_number, X_elements, max_order )
% THIS FUNCTION GENERATES RANDOM ORDERS FOR THE RESPECTIVE X_ELEMENTS TO FORM THE MONOMIAL
% fprintf('\nGENERATING %d RANDOM MONOMIALS...', monomial_number)

orders = zeros(monomial_number, X_elements);

fprintf('\nGenerating monomial of order %d (total %d): ',max_order,monomial_number);
for j=1:monomial_number
    backspaces = length(char({num2str(j)}));
    while true
        % random choice of x elements that will participate in the monomial
        temp1(1,:) = randi([1,X_elements], [1,max_order]);
        
        for i=1:max_order
            if i==1
                temp1(2,i) = randi([0,max_order], [1,1]);
            else
                temp1(2,i) = randi([0,max_order-sum(temp1(2,1:i-1))], [1,1]);
            end
        end

        for i=1:max_order
            orders(j,temp1(1,i)) = temp1(2,i);
        end
        
        % if monomial order is totally zero do not break
        flag1 = 1;
        if orders(j,:) == 0
            flag1 = 0;
        end
        
        % if the randomly generated monomial is the same as one before do not break
        flag2 = 1;
        for k=1:j-1
            if orders(j,:) == orders(k,:)
                flag2 = 0;
            end
        end
        
        if j>1 && (flag1 && flag2)
            for ii=1:backspaces
                fprintf('\b')
            end
        end
        if (flag1 && flag2)             
            fprintf('%d',j)
            break
        end
        
    end
    
end

end