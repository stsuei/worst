function output_struct = worst_simulink_backward(model_name, t, x,...
    nu, has_U, has_u, has_v, has_del, input_struct)


% Get some useful variables
state_dim = size(x,2);
N = length(t);
output_dim = size(nu,2);

if has_U
    U = input_struct.U;
    Ut = input_struct.Ut;
    total_Udim = size(U,2);
else
    U = [];
    Ut = [];
    total_Udim = 0;
end
if has_u
    u = input_struct.u;
    total_udim = size(u,2);
else
    u = [];
    total_udim = 0;
end
if has_v
    v = input_struct.v;
    total_vdim = size(v,2);
    xi = input_struct.xi;
else
    v = [];
    total_vdim = 0;
    xi = [];
end
if has_del
    params = input_struct.params;
    num_params = length(params);
else
    params = [];
    num_params = 0;
end




% Integrate over time - this automatically handles the fact that the system
% is a final value problem.
[time, soln] = ode45(@back_deriv, [t(N), t(1)], zeros(state_dim+num_params,1));

% Interpolate signals
soln = interp1(time, soln, t);


% Compute the output
output = zeros(N, total_udim+total_vdim);
for i = 1:N
    Ui = interp1(Ut, U, t(i))';
    if has_u, now_u = u(i,:)'; else now_u = []; end;
    if has_v, now_v = v(i,:)'; else now_v = []; end;
    [~,B,~,D] = linmod(model_name, x(i,:)', [Ui; now_u; now_v; params]);
    
    if has_u
        dfdu = B(:,total_Udim+1:total_Udim+total_udim);
        dgdu = D(1:output_dim, total_Udim+1:total_Udim+total_udim);
        dhdu = D(output_dim+1:end, total_Udim+1:total_Udim+total_udim);
    else
        dfdu = [];
        dgdu = [];
        dhdu = [];
    end
    if has_v
        dfdv = B(:,total_Udim+total_udim+1:total_Udim+total_udim+total_vdim);
        dgdv = D(1:output_dim, ...
                 total_Udim+total_udim+1:total_Udim+total_udim+total_vdim);
        dhdv = D(output_dim+1:end, ...
                 total_Udim+total_udim+1:total_Udim+total_udim+total_vdim);
    else
        dfdv = [];
        dgdv = [];
        dhdv = [];
    end
    
    if (has_u || has_v)
        Cdyn = [dfdu', zeros(total_udim, num_params); ...
                dfdv', zeros(total_vdim, num_params)];
        Ddyn = [dgdu', dhdu'; dgdv', dhdv];
    end
    
    if has_u, now_nu = nu(i,:)'; else now_nu = []; end;
    if has_v, now_xi = xi(i,:)'; else now_xi = []; end;
    
    if (has_u || has_v)
        output(i,:) = Cdyn*soln(i,:)' + Ddyn*[now_nu; now_xi];
    end
end
if has_u
    output_struct.gamma = -output(:, 1:total_udim);
end
if has_v
    output_struct.kappa = output(:, total_udim+1:end);
end
if has_del
    lambdad = soln(:, state_dim+1:end);
    output_struct.lambdad0 = lambdad(1,:)';
end


% Nested derivative function. Uses linmod to take jacobians
function deriv = back_deriv(time, lambda)

    cur_x = interp1(t, x, time)';
    cur_nu = interp1(t, nu, time)';
    cur_u = []; cur_v = []; cur_xi = []; cur_U = [];
    if has_u, cur_u = interp1(t, u, time)'; end
    if has_v, cur_v = interp1(t, v, time)'; end
    if has_v, cur_xi = interp1(t, xi, time)'; end
    if has_U, cur_U = interp1(Ut, U, time)'; end
    
    [Ai,Bi,Ci,Di] = linmod(model_name, cur_x, [cur_U; cur_u; cur_v; params]);
    
    dfdx = Ai;
    dgdx = Ci(1:output_dim, :);
    dhdx = Ci(output_dim+1:end, :);
    
    if has_del
        dfdd = Bi(:, total_Udim+total_udim+total_vdim+1:end);
        dgdd = Di(1:output_dim, total_Udim+total_udim+total_vdim+1:end);
        dhdd = Di(output_dim+1:end, total_Udim+total_udim+total_vdim+1:end);
    else
        dfdd = [];
        dgdd = [];
        dhdd = [];
    end

    Adyn = [dfdx', zeros(state_dim, num_params); ...
            dfdd', zeros(num_params, num_params)];
    Bdyn = [dgdx', dhdx'; dgdd', dhdd'];
    
    deriv = Adyn*lambda + Bdyn*[cur_nu; cur_xi];
    deriv = -deriv;
end


end