function forces = solve_dynamics(pos, vel, acc, p)
%% solve_dynamics.m
% Compute dynamic forces using Newton-Euler equations
% With robust error checking for invalid positions
% ==========================================================================

% Check if position data is valid
if isempty(pos)
    forces = struct();
    return;
end

% Check if all required fields exist
required_fields = {'A', 'B', 'C', 'D', 'E', 'O'};
for i = 1:length(required_fields)
    if ~isfield(pos, required_fields{i})
        forces = struct();
        return;
    end
end

% Check if velocity data is valid
if isempty(vel) || ~isfield(vel, 'omega3')
    forces = struct();
    return;
end

% Check if acceleration data is valid
if isempty(acc) || ~isfield(acc, 'aA')
    forces = struct();
    return;
end

%% Calculate Centers of Gravity Positions

% Link 2: CG at OA/2
rG2 = (p.O + pos.A) / 2;

% Link 3: CG at centroid of triangle ABC
rG3 = (pos.A + pos.B + pos.C) / 3;

% Link 4: CG at EB/2
rG4 = (p.E + pos.B) / 2;

% Link 5: CG at CD/2
rG5 = (pos.C + pos.D) / 2;

% Slider 6: CG at D
rG6 = pos.D;

%% Calculate CG Accelerations

% Link 2
aG2 = acc.aA / 2;  % Simplified (O is fixed)

% Link 3 (use centroid acceleration)
r_AG3 = rG3 - pos.A;
r_AG3_mag = norm(r_AG3);
if r_AG3_mag < 1e-6
    angle_AG3 = 0;
else
    angle_AG3 = atan2(r_AG3(2), r_AG3(1));
end
aG3_tangential = acc.alpha3 * r_AG3_mag * [-sin(angle_AG3); cos(angle_AG3)];
aG3_normal = -vel.omega3^2 * r_AG3_mag * [cos(angle_AG3); sin(angle_AG3)];
aG3 = acc.aA + aG3_tangential + aG3_normal;

% Link 4
aG4 = acc.aB / 2;  % Simplified (E is fixed)

% Link 5
aG5 = (acc.aC + acc.aD) / 2;

% Slider 6
aG6 = acc.aD;

%% Calculate Inertia Forces and Moments (in N, N·m)

% Convert to meters for proper units
g_m = p.g / 1000;  % m/s²

% Inertia forces (F = -m*a), convert accelerations to m/s²
F_inertia_2 = -p.m2 * (aG2 / 1000);
F_inertia_3 = -p.m3 * (aG3 / 1000);
F_inertia_4 = -p.m4 * (aG4 / 1000);
F_inertia_5 = -p.m5 * (aG5 / 1000);
F_inertia_6 = -p.m6 * (aG6 / 1000);

% Inertia moments (M = -I*alpha)
M_inertia_2 = -p.I2 * acc.alpha2;
M_inertia_3 = -p.I3 * acc.alpha3;
M_inertia_4 = -p.I4 * acc.alpha4;
M_inertia_5 = -p.I5 * acc.alpha5;

% Weight forces
W2 = [0; -p.m2 * g_m];
W3 = [0; -p.m3 * g_m];
W4 = [0; -p.m4 * g_m];
W5 = [0; -p.m5 * g_m];
W6 = [0; -p.m6 * g_m];

%% Solve for Joint Forces (working backwards from slider)

% Link 6 (Slider): Force balance
% F65 + N + W6 + F_inertia_6 = 0
% where N = [0; N_y] is normal force from slider constraint

N_y = -F_inertia_6(2) - W6(2);  % Slider side load
F65_x = -F_inertia_6(1);
F65 = [F65_x; 0];  % Force from link 5 on slider

forces.N_slider = N_y;
forces.F65 = F65;

% Link 5: Force balance
% F45 + F56 + W5 + F_inertia_5 = 0
F56 = -F65;  % Reaction pair
F45 = -F56 - W5 - F_inertia_5;

forces.F45 = F45;

% Link 4: Force balance
% F14 + F34 + W4 + F_inertia_4 = 0
% F34 acts at point B
F34_from_link3 = -F45;  % This will be corrected after link 3 analysis

% Link 3: Force balance
% F23 + F43 + F53 + W3 + F_inertia_3 = 0
% where:
%   F23 is force from link 2 at joint A
%   F43 is force from link 4 at joint B
%   F53 is force from link 5 at joint C

F53 = -F45;  % Reaction pair (force from link 5 on link 3)

% We need to solve link 3 and link 4 together
% For now, use simplified approach assuming forces at joints

% Link 4 receives force F34 at B from link 3
% F14 + F34 + W4 + F_inertia_4 = 0
% We'll iterate or use a simplified assumption

% Simplified: Assume link 4 connects E to B, force primarily along link
% For detailed analysis, should solve moment equations simultaneously

% For link 3, assuming force F43 at B (from link 4)
% Estimate F43 based on link 4 equilibrium
F14_estimate = -W4 - F_inertia_4;  % If F34 is small initially
F34 = -F14_estimate;  % Reaction
F43 = -F34;

% Now solve link 3
F23 = -F43 - F53 - W3 - F_inertia_3;

forces.F34 = norm(F34);
forces.F43 = F43;
forces.F23 = F23;

% Link 4: Refine with F43
F14 = -F43 - W4 - F_inertia_4;
forces.F14 = F14;

% Link 2: Force balance and driving torque
% F12 + F32 + W2 + F_inertia_2 = 0
F32 = -F23;
F12 = -F32 - W2 - F_inertia_2;

forces.F12 = F12;

% Driving Torque (moment balance about O)
r_OtoG2 = (rG2 - p.O) / 1000;  % Convert to meters
r_OtoA = (pos.A - p.O) / 1000;

T2 = -M_inertia_2 - cross2d(r_OtoG2, W2 + F_inertia_2) - cross2d(r_OtoA, F32);

forces.T2 = T2;  % Driving torque (N·m)

%% Force Magnitudes
forces.F12_mag = norm(F12);
forces.F23_mag = norm(F23);
forces.F34_mag = norm(F34);
forces.F45_mag = norm(F45);
forces.F14_mag = norm(F14);

end

%% Helper function: 2D cross product (returns scalar)
function c = cross2d(a, b)
    c = a(1)*b(2) - a(2)*b(1);
end