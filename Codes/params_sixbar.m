function p = params_sixbar()
%% params_sixbar.m
% Six-Bar Linkage Mechanism Parameters
% Edit these values to match YOUR mechanism
% ==========================================================================

%% Geometric Parameters (mm)
% scaling factor 1:10 -> real = parameters/10
p.l1 = 575.28;              % Length OE (ground link)
p.l2 = 246.30;               % Length OA (crank)
p.l3 = 484.62;              % Length AB (coupler side)
p.l4 = 324.74;              % Length BE
p.l5 = 572.72;              % Length CD
p.AC = 325.64;              % Length AC (coupler side)
p.H = 78.91;                % Vertical offset (O is H above slider path)
p.S = 846.41;               % Horizontal distance reference

%% Angles (degrees -> convert to radians)
p.beta_deg = -14.978;         % Internal angle β between AB and AC
p.theta1_deg = 9.6;       % Angle of ground link OE with horizontal

p.beta = p.beta_deg * pi/180;
p.theta1 = p.theta1_deg * pi/180;

%% Kinematics
p.omega2 = 10;           % rad/s - Angular velocity of crank (input)
p.alpha2 = 0;            % rad/s² - Angular acceleration of crank (constant speed)

%% Mass Properties (from assignment)
% Link 2 (Crank)
p.m2 = 1.0;              % kg
p.I2 = 0.002;            % kg·m²
p.rG2_ratio = 0.5;       % CG at OA/2

% Link 3 (Triangular Coupler)
p.m3 = 2.5;              % kg
p.I3 = 0.008;            % kg·m²
% CG at centroid of triangle (approximation)

% Link 4 (EB)
p.m4 = 1.5;              % kg
p.I4 = 0.005;            % kg·m²
p.rG4_ratio = 0.5;       % CG at EB/2

% Link 5 (CD)
p.m5 = 1.8;              % kg
p.I5 = 0.006;            % kg·m²
p.rG5_ratio = 0.5;       % CG at CD/2

% Slider 6
p.m6 = 0.9;              % kg
% CG at D (slider center)

%% Physical Constants
p.g = 9810;              % mm/s² (gravity)

%% Fixed Pivot Positions
p.O = [0; 0];            % Origin at O
p.E = [p.l1 * cos(p.theta1); p.l1 * sin(p.theta1)];  % Fixed pivot E
p.slider_y = -p.H;       % Slider path at y = -H

%% Display Parameters
fprintf('\n╔════════════════════════════════════════════════════╗\n');
fprintf('║     SIX-BAR LINKAGE MECHANISM PARAMETERS           ║\n');
fprintf('╚════════════════════════════════════════════════════╝\n\n');
fprintf('Geometric Parameters:\n');
fprintf('  l1 (OE)  = %6.1f mm\n', p.l1);
fprintf('  l2 (OA)  = %6.1f mm\n', p.l2);
fprintf('  l3 (AB)  = %6.1f mm\n', p.l3);
fprintf('  l4 (BE)  = %6.1f mm\n', p.l4);
fprintf('  l5 (CD)  = %6.1f mm\n', p.l5);
fprintf('  AC       = %6.1f mm\n', p.AC);
fprintf('  H        = %6.1f mm\n', p.H);
fprintf('  S        = %6.1f mm\n', p.S);
fprintf('\nAngles:\n');
fprintf('  β        = %6.1f°\n', p.beta_deg);
fprintf('  θ1       = %6.1f°\n', p.theta1_deg);
fprintf('\nKinematics:\n');
fprintf('  ω2       = %6.2f rad/s\n', p.omega2);
fprintf('\nMass Properties:\n');
fprintf('  m2=%0.1f kg, I2=%0.4f kg·m²\n', p.m2, p.I2);
fprintf('  m3=%0.1f kg, I3=%0.4f kg·m²\n', p.m3, p.I3);
fprintf('  m4=%0.1f kg, I4=%0.4f kg·m²\n', p.m4, p.I4);
fprintf('  m5=%0.1f kg, I5=%0.4f kg·m²\n', p.m5, p.I5);
fprintf('  m6=%0.1f kg (slider)\n', p.m6);
fprintf('\n');

end