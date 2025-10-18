function vel = solve_velocity(pos, p)
%% solve_velocity.m
% Compute velocities using analytical differentiation
% ==========================================================================

theta2 = pos.theta2;
theta3 = pos.theta3;
theta4 = pos.theta4;
theta5 = pos.theta5;

omega2 = p.omega2;

%% Velocity of point A
vel.vA = omega2 * p.l2 * [-sin(theta2); cos(theta2)];

%% Angular velocities of links 3 and 4
% Using velocity constraint equations:
% vB = vA + omega3 × rAB = omega4 × rEB

% Coefficient matrix for [omega3; omega4]
A_mat = [-p.l3*sin(theta3),  p.l4*sin(theta4);
          p.l3*cos(theta3), -p.l4*cos(theta4)];

b_vec = vel.vA;

% Solve for omega3 and omega4
omega_sol = A_mat \ b_vec;
vel.omega3 = omega_sol(1);
vel.omega4 = omega_sol(2);

%% Velocity of point B
vel.vB = vel.vA + vel.omega3 * [-p.l3*sin(theta3); p.l3*cos(theta3)];

%% Velocity of point C
vel.vC = vel.vA + vel.omega3 * [-p.AC*sin(theta3+p.beta); p.AC*cos(theta3+p.beta)];

%% Angular velocity of link 5 and velocity of D
% D moves horizontally only: vD = [vD_x; 0]
% From constraint: 0 = vC_y + omega5 * l5 * cos(theta5)
vel.omega5 = -vel.vC(2) / (p.l5 * cos(theta5));

% Velocity of D (horizontal only)
vD_x = vel.vC(1) - vel.omega5 * p.l5 * sin(theta5);
vel.vD = [vD_x; 0];

%% Store angular velocities
vel.omega2 = omega2;

%% Velocity magnitudes
vel.vA_mag = norm(vel.vA);
vel.vB_mag = norm(vel.vB);
vel.vC_mag = norm(vel.vC);
vel.vD_mag = abs(vD_x);

end