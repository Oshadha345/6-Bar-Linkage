function acc = solve_acceleration(pos, vel, p)
%% solve_acceleration.m
% Compute accelerations using analytical differentiation
% ==========================================================================

theta2 = pos.theta2;
theta3 = pos.theta3;
theta4 = pos.theta4;
theta5 = pos.theta5;

omega2 = vel.omega2;
omega3 = vel.omega3;
omega4 = vel.omega4;
omega5 = vel.omega5;

alpha2 = p.alpha2;  % Crank angular acceleration (usually 0 for constant speed)

%% Acceleration of point A
acc.aA_tangential = alpha2 * p.l2 * [-sin(theta2); cos(theta2)];
acc.aA_normal = -omega2^2 * p.l2 * [cos(theta2); sin(theta2)];
acc.aA = acc.aA_tangential + acc.aA_normal;

%% Angular accelerations of links 3 and 4
% From acceleration constraint equations

% Normal acceleration components
aA_B_normal = -omega3^2 * p.l3 * [cos(theta3); sin(theta3)];
aE_B_normal = -omega4^2 * p.l4 * [cos(theta4); sin(theta4)];

% Coefficient matrix for [alpha3; alpha4]
A_mat = [-p.l3*sin(theta3),  p.l4*sin(theta4);
          p.l3*cos(theta3), -p.l4*cos(theta4)];

b_vec = acc.aA + aA_B_normal - aE_B_normal;

% Solve for alpha3 and alpha4
alpha_sol = A_mat \ b_vec;
acc.alpha3 = alpha_sol(1);
acc.alpha4 = alpha_sol(2);

%% Acceleration of point B
aB_tangential = acc.alpha3 * [-p.l3*sin(theta3); p.l3*cos(theta3)];
acc.aB = acc.aA + aB_tangential + aA_B_normal;

%% Acceleration of point C
aC_tangential = acc.alpha3 * [-p.AC*sin(theta3+p.beta); p.AC*cos(theta3+p.beta)];
aC_normal = -omega3^2 * p.AC * [cos(theta3+p.beta); sin(theta3+p.beta)];
acc.aC = acc.aA + aC_tangential + aC_normal;

%% Angular acceleration of link 5 and acceleration of D
% D constrained to horizontal motion: aD_y = 0

% Normal acceleration component
aC_D_normal = -omega5^2 * p.l5 * [cos(theta5); sin(theta5)];

% From constraint: aD_y = 0
% 0 = aC_y + alpha5*l5*cos(theta5) - omega5²*l5*sin(theta5)
acc.alpha5 = (omega5^2 * p.l5 * sin(theta5) - acc.aC(2)) / (p.l5 * cos(theta5));

% Acceleration of D (horizontal only)
aD_x = acc.aC(1) - acc.alpha5 * p.l5 * sin(theta5) + aC_D_normal(1);
acc.aD = [aD_x; 0];

%% Store angular accelerations
acc.alpha2 = alpha2;

%% Acceleration magnitudes
acc.aA_mag = norm(acc.aA);
acc.aB_mag = norm(acc.aB);
acc.aC_mag = norm(acc.aC);
acc.aD_mag = abs(aD_x);

end