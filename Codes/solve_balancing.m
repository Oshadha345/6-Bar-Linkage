function balance = solve_balancing(positions, velocities, accelerations, p)
%% solve_balancing.m
% Perform balancing analysis with robust error checking
% ==========================================================================

fprintf('Computing shaking forces and moments...\n');

n = length(positions);
g = p.g / 1000;  % Convert to m/s²

% Initialize arrays
shaking_F_x = zeros(1, n);
shaking_F_y = zeros(1, n);
shaking_F_mag = zeros(1, n);
shaking_M = zeros(1, n);

valid_count = 0;
valid_indices = [];

%% Calculate shaking forces for each position
for i = 1:n
    % Check if position data is valid
    if isempty(positions{i}) || ~isfield(positions{i}, 'A') || ...
       isempty(accelerations{i}) || ~isfield(accelerations{i}, 'aA')
        continue;  % Skip invalid positions
    end
    
    pos = positions{i};
    acc = accelerations{i};
    vel = velocities{i};
    
    valid_count = valid_count + 1;
    valid_indices = [valid_indices, i];
    
    % Centers of gravity
    rG2 = (p.O + pos.A) / 2;
    rG3 = (pos.A + pos.B + pos.C) / 3;
    rG4 = (p.E + pos.B) / 2;
    rG5 = (pos.C + pos.D) / 2;
    rG6 = pos.D;
    
    % CG accelerations (convert to m/s²)
    aG2 = acc.aA / 2000;  % mm/s² to m/s²
    
    % Link 3 CG acceleration
    r_AG3 = rG3 - pos.A;
    r_AG3_mag = norm(r_AG3) / 1000;  % Convert to meters
    if r_AG3_mag < 1e-9
        angle_AG3 = 0;
    else
        angle_AG3 = atan2(r_AG3(2), r_AG3(1));
    end
    aG3_tang = acc.alpha3 * r_AG3_mag * [-sin(angle_AG3); cos(angle_AG3)];
    aG3_norm = -vel.omega3^2 * r_AG3_mag * [cos(angle_AG3); sin(angle_AG3)];
    aG3 = (acc.aA / 1000) + aG3_tang + aG3_norm;  % m/s²
    
    aG4 = acc.aB / 2000;  % m/s²
    aG5 = (acc.aC + acc.aD) / 2000;  % m/s²
    aG6 = acc.aD / 1000;  % m/s²
    
    % Total shaking force = sum of all inertia forces + weights
    F_shaking = p.m2 * aG2 + p.m3 * aG3 + p.m4 * aG4 + p.m5 * aG5 + p.m6 * aG6;
    F_shaking(2) = F_shaking(2) + (p.m2 + p.m3 + p.m4 + p.m5 + p.m6) * g;
    
    shaking_F_x(i) = F_shaking(1);
    shaking_F_y(i) = F_shaking(2);
    shaking_F_mag(i) = norm(F_shaking);
    
    % Shaking moment about origin (convert positions to meters)
    M_shaking = 0;
    M_shaking = M_shaking + cross2d((rG2/1000), p.m2 * aG2);
    M_shaking = M_shaking + cross2d((rG3/1000), p.m3 * aG3);
    M_shaking = M_shaking + cross2d((rG4/1000), p.m4 * aG4);
    M_shaking = M_shaking + cross2d((rG5/1000), p.m5 * aG5);
    M_shaking = M_shaking + cross2d((rG6/1000), p.m6 * aG6);
    
    % Add inertia moments
    M_shaking = M_shaking + p.I2 * acc.alpha2 + p.I3 * acc.alpha3 + ...
                p.I4 * acc.alpha4 + p.I5 * acc.alpha5;
    
    shaking_M(i) = M_shaking;
end

fprintf('  Valid positions for balancing: %d/%d (%.1f%%)\n', ...
        valid_count, n, 100*valid_count/n);

if valid_count == 0
    error('No valid positions found for balancing analysis!');
end

%% Calculate RMS and peak values (only over valid positions)
valid_F_mag = shaking_F_mag(valid_indices);
valid_M = shaking_M(valid_indices);

balance.F_rms = sqrt(mean(valid_F_mag.^2));
balance.F_peak = max(valid_F_mag);
balance.M_rms = sqrt(mean(valid_M.^2));
balance.M_peak = max(abs(valid_M));

%% Design counterweight on crank (link 2)
% Place counterweight opposite to crank direction
m_cw = 0.5;  % Initial guess (kg)
r_cw = 0.05;  % Radius from O (m)

balance.m_cw = m_cw;
balance.r_cw = r_cw;

%% Recalculate with counterweight
shaking_F_x_bal = zeros(1, n);
shaking_F_y_bal = zeros(1, n);
shaking_F_mag_bal = zeros(1, n);

for i = valid_indices
    pos = positions{i};
    acc = accelerations{i};
    
    % Counterweight position (opposite to crank)
    theta_cw = pos.theta2 + pi;
    r_cw_pos = [r_cw * cos(theta_cw); r_cw * sin(theta_cw)];
    
    % Counterweight acceleration
    a_cw = -p.omega2^2 * r_cw_pos;
    
    % Add counterweight effect
    F_cw = m_cw * a_cw;
    
    % Original shaking force + counterweight
    F_total = [shaking_F_x(i); shaking_F_y(i)] + F_cw;
    
    shaking_F_x_bal(i) = F_total(1);
    shaking_F_y_bal(i) = F_total(2);
    shaking_F_mag_bal(i) = norm(F_total);
end

valid_F_mag_bal = shaking_F_mag_bal(valid_indices);
balance.F_rms_bal = sqrt(mean(valid_F_mag_bal.^2));
balance.force_reduction = (1 - balance.F_rms_bal / balance.F_rms) * 100;

%% Optimize counterweight mass
fprintf('  Optimizing counterweight...\n');

% Objective function: minimize RMS shaking force
obj_func = @(m) calculate_rms_with_counterweight(m, r_cw, positions, ...
                accelerations, shaking_F_x, shaking_F_y, p, valid_indices);

% Optimize
options = optimset('Display', 'off', 'TolX', 1e-6);
m_cw_opt = fminbnd(obj_func, 0, 2, options);

balance.m_cw_opt = m_cw_opt;
balance.r_cw_opt = r_cw;
balance.F_rms_opt = obj_func(m_cw_opt);

%% 2D optimization (mass and radius)
obj_func_2d = @(x) calculate_rms_with_counterweight(x(1), x(2), positions, ...
                   accelerations, shaking_F_x, shaking_F_y, p, valid_indices);

x0 = [m_cw_opt; r_cw];
lb = [0; 0.01];  % Lower bounds
ub = [2; 0.15];  % Upper bounds

options = optimoptions('fmincon', 'Display', 'off', 'Algorithm', 'sqp');
x_opt = fmincon(obj_func_2d, x0, [], [], [], [], lb, ub, [], options);

balance.m_cw_opt_2d = x_opt(1);
balance.r_cw_opt_2d = x_opt(2);
balance.F_rms_opt_2d = obj_func_2d(x_opt);

%% Store arrays
balance.shaking_F_x = shaking_F_x;
balance.shaking_F_y = shaking_F_y;
balance.shaking_F_mag = shaking_F_mag;
balance.shaking_M = shaking_M;
balance.shaking_F_x_bal = shaking_F_x_bal;
balance.shaking_F_y_bal = shaking_F_y_bal;
balance.shaking_F_mag_bal = shaking_F_mag_bal;
balance.valid_indices = valid_indices;
balance.valid_count = valid_count;

fprintf('  ✓ Balancing analysis complete\n');

end

%% Helper function: Calculate RMS with given counterweight
function rms_val = calculate_rms_with_counterweight(m_cw, r_cw, positions, ...
                   accelerations, F_x_orig, F_y_orig, p, valid_indices)
    
    n = length(valid_indices);
    F_mag_squared = 0;
    
    for idx = 1:n
        i = valid_indices(idx);
        
        pos = positions{i};
        
        % Counterweight position
        theta_cw = pos.theta2 + pi;
        r_cw_pos = [r_cw * cos(theta_cw); r_cw * sin(theta_cw)];
        
        % Counterweight acceleration
        a_cw = -p.omega2^2 * r_cw_pos;
        
        % Add counterweight effect
        F_cw = m_cw * a_cw;
        F_total = [F_x_orig(i); F_y_orig(i)] + F_cw;
        
        F_mag_squared = F_mag_squared + norm(F_total)^2;
    end
    
    rms_val = sqrt(F_mag_squared / n);
end

%% Helper function: 2D cross product
function c = cross2d(a, b)
    c = a(1)*b(2) - a(2)*b(1);
end