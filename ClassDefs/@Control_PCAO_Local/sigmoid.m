function [ u ] = sigmoid( u_bar, lambda, min_value, max_value, sym_flag)
%SIGMOID Compute sigmoid function

m = length(u_bar);
u = zeros(m,1);

if sym_flag == 1
	u = sym(u);
end

for i=1:m
    a2 = (max_value(i) + min_value(i))/2;
    b2 = (max_value(i) - min_value(i))/2;
    u(i) = a2 + b2*tanh(lambda(i)*(u_bar(i)-a2)/b2);
end

end
