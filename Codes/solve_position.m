function pos = solve_position(theta2, p)
%% solve_position.m
% Solve position with CORRECT configuration: C below B
% ==========================================================================

% Position of A (end of crank)
A = [p.l2 * cos(theta2); p.l2 * sin(theta2)];

%% Use four-bar OABE to find theta3
d_AE = norm(A - p.E);

% Check if four-bar can close
if d_AE > (p.l3 + p.l4) || d_AE < abs(p.l3 - p.l4)
    pos = struct();
    return;
end

% Law of cosines to find angle at A
cos_angle = (p.l3^2 + d_AE^2 - p.l4^2) / (2 * p.l3 * d_AE);
cos_angle = max(-1, min(1, cos_angle));

angle_offset = acos(cos_angle);
angle_AE = atan2(p.E(2) - A(2), p.E(1) - A(1));

% Two possible theta3 values
theta3_1 = angle_AE + angle_offset;
theta3_2 = angle_AE - angle_offset;

%% Test both configurations
best_config = [];
best_score = -inf;

for config = 1:2
    if config == 1
        theta3 = theta3_1;
    else
        theta3 = theta3_2;
    end
    
    % Calculate positions
    B_test = A + [p.l3 * cos(theta3); p.l3 * sin(theta3)];
    C_test = A + [p.AC * cos(theta3 + p.beta); p.AC * sin(theta3 + p.beta)];
    
    % Verify BE constraint
    dist_BE = norm(B_test - p.E);
    if abs(dist_BE - p.l4) > 1.0
        continue;  % Skip invalid configuration
    end
    
    % Find D position on slider
    dy = p.slider_y - C_test(2);
    disc = p.l5^2 - dy^2;
    
    if disc < 0
        continue;  % Cannot reach slider
    end
    
    dx = sqrt(disc);
    xD_right = C_test(1) + dx;  % D to the right
    xD_left = C_test(1) - dx;   % D to the left
    
    % Test both D positions
    for d_option = 1:2
        if d_option == 1
            xD = xD_right;
        else
            xD = xD_left;
        end
        
        D_test = [xD; p.slider_y];
        
        % Verify CD constraint
        dist_CD = norm(D_test - C_test);
        if abs(dist_CD - p.l5) > 1.0
            continue;
        end
        
        % Score this configuration based on CORRECT desired features
        score = 0;
        
        % CRITICAL: C should be BELOW B (main requirement from reference)
        if C_test(2) < B_test(2)
            score = score + 1000;  % Very high weight
        else
            score = score - 500;   % Penalize wrong orientation
        end
        
        % Preference: D to the right of E
        if xD > p.E(1)
            score = score + 100;
        end
        
        % Preference: B above A (from reference image)
        if B_test(2) > A(2)
            score = score + 50;
        end
        
        % Preference: C and A at similar height (relatively horizontal triangle)
        height_diff_CA = abs(C_test(2) - A(2));
        if height_diff_CA < 100
            score = score + 25;
        end
        
        % Preference: Reasonable positions
        if xD > 0 && xD < 1500 && C_test(2) > p.slider_y
            score = score + 10;
        end
        
        % Preference: B is the highest point of triangle
        if B_test(2) > A(2) && B_test(2) > C_test(2)
            score = score + 50;
        end
        
        % Keep track of best configuration
        if score > best_score
            best_score = score;
            best_config = struct('theta3', theta3, 'B', B_test, 'C', C_test, ...
                                 'D', D_test, 'xD', xD, 'score', score);
        end
    end
end

%% Use best configuration found
if isempty(best_config)
    % Fallback to numerical solver
    pos = solve_position_numerical(theta2, p);
    return;
end

%% Build complete position structure
pos.theta2 = theta2;
pos.theta3 = best_config.theta3;
pos.O = p.O;
pos.E = p.E;
pos.A = A;
pos.B = best_config.B;
pos.C = best_config.C;
pos.D = best_config.D;

% Calculate remaining angles
pos.theta4 = atan2(pos.B(2) - p.E(2), pos.B(1) - p.E(1));
pos.theta5 = atan2(pos.D(2) - pos.C(2), pos.D(1) - pos.C(1));

end

%% Fallback numerical solver
function pos = solve_position_numerical(theta2, p)
    A = [p.l2 * cos(theta2); p.l2 * sin(theta2)];
    
    % Constraint equations
    equations = @(vars) position_constraints(vars, A, p);
    
    % Multiple initial guesses
    initial_guesses = [
        theta2, p.E(1) + 200;
        theta2 + pi/4, p.E(1) + 150;
        theta2 - pi/4, p.E(1) + 250;
        atan2(p.E(2) - A(2), p.E(1) - A(1)) + pi/6, p.E(1) + 180;
    ];
    
    options = optimoptions('fsolve', 'Display', 'off', 'TolFun', 1e-9, 'MaxIter', 1000);
    
    for i = 1:size(initial_guesses, 1)
        x0 = initial_guesses(i, :)';
        
        [solution, fval, exitflag] = fsolve(equations, x0, options);
        
        if exitflag > 0 && norm(fval) < 1e-4
            theta3 = solution(1);
            xD = solution(2);
            
            % Build position structure
            B_temp = A + [p.l3 * cos(theta3); p.l3 * sin(theta3)];
            C_temp = A + [p.AC * cos(theta3 + p.beta); p.AC * sin(theta3 + p.beta)];
            
            % Check if C is below B (correct configuration)
            if C_temp(2) > B_temp(2)
                continue;  % Skip this solution, wrong configuration
            end
            
            pos.theta2 = theta2;
            pos.theta3 = theta3;
            pos.O = p.O;
            pos.E = p.E;
            pos.A = A;
            pos.B = B_temp;
            pos.C = C_temp;
            pos.D = [xD; p.slider_y];
            pos.theta4 = atan2(pos.B(2) - p.E(2), pos.B(1) - p.E(1));
            pos.theta5 = atan2(pos.D(2) - pos.C(2), pos.D(1) - pos.C(1));
            
            % Verify constraints
            dist_BE = norm(pos.B - p.E);
            dist_CD = norm(pos.D - pos.C);
            
            if abs(dist_BE - p.l4) < 2.0 && abs(dist_CD - p.l5) < 2.0
                return;
            end
        end
    end
    
    % Failed to find solution
    pos = struct();
end

function F = position_constraints(vars, A, p)
    theta3 = vars(1);
    xD = vars(2);
    
    B = A + [p.l3 * cos(theta3); p.l3 * sin(theta3)];
    C = A + [p.AC * cos(theta3 + p.beta); p.AC * sin(theta3 + p.beta)];
    
    F(1) = (B(1) - p.E(1))^2 + (B(2) - p.E(2))^2 - p.l4^2;
    F(2) = (xD - C(1))^2 + (p.slider_y - C(2))^2 - p.l5^2;
end