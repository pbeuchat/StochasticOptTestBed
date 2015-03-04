function [ phi ] = calcPHI( x, orders )
% THIS FUNCTION CALCULATES APPROXIMATORS KERNEL phi VECTOR FOR A GIVEN x
X_elements = size(x,1);    
monomial_number = size(orders,1);
temp = zeros(X_elements,monomial_number);

for i=1:monomial_number
    for ii=1:X_elements
        temp(ii,i) = x(ii)^orders(i,ii);
    end
end
phi = prod(temp);
if size(temp,1) == 1
    phi = temp;
end

end

