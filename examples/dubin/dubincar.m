% This example computes the worst possible disturbance of a Dubin's car
% with the following dynamics:
%
%     x' = cos(theta)
%     y' = sin(theta)
%     theta' = U(t) + u(t)
%
% where (x, y, theta)' is the state, U(t) is a one-dimensional nominal input 
% signal and u(t) is a one-dimensional disturbance of norm 2. The system's
% output is the full state: (x, y, theta)'. 



clear; clc; close all;


model_name = 'dubin';

disturbance_specs = [1 2];

ti_val = 0; 
tf_val = 10;

output_dim = 3;

error_tol = .01;

nominal_input = linspace(10,0,100)';
nominal_time = linspace(0,10,100)';


output_struct = ...
    worst(model_name, output_dim, 'ti', ti_val, 'tf', tf_val, ...
          'disturbance_specs', disturbance_specs, 'error_tol', error_tol, ...
          'nominal_input', nominal_input, 'nominal_time', nominal_time, ...
          'plot_cost', 1, 'plot_d', 1, 'plot_error', 1);
      
% Plot the distribution of worst values
figure
hist(output_struct.costs)