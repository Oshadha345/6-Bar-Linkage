%% main_computational_analysis.m
% ══════════════════════════════════════════════════════════════════════════
% SIX-BAR LINKAGE MECHANISM - COMPLETE COMPUTATIONAL ANALYSIS
% ══════════════════════════════════════════════════════════════════════════
% Author: 
% Date: 2025-10-15
% 
% This script performs complete computational analysis including:
%   1. Position, Velocity & Acceleration Analysis
%   2. Dynamic Forces Analysis
%   3. Balancing Strategy Development
% 
% All outputs saved to: /MATLAB Drive/Sixbar_assignment/media/
% ══════════════════════════════════════════════════════════════════════════

clear; clc; close all;

fprintf('\n');
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║                                                              ║\n');
fprintf('║    SIX-BAR LINKAGE MECHANISM COMPUTATIONAL ANALYSIS          ║\n');
fprintf('║                                                              ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

%% ═══════════════════════════════════════════════════════════════════════
%  SETUP OUTPUT DIRECTORIES
%  ═══════════════════════════════════════════════════════════════════════

base_dir = '/MATLAB Drive/Sixbar_assignment';
media_dir = fullfile(base_dir, 'media');
figures_dir = fullfile(media_dir, 'figures');
data_dir = fullfile(media_dir, 'data');
videos_dir = fullfile(media_dir, 'videos');

% Create directories if they don't exist
if ~exist(base_dir, 'dir'), mkdir(base_dir); end
if ~exist(media_dir, 'dir'), mkdir(media_dir); end
if ~exist(figures_dir, 'dir'), mkdir(figures_dir); end
if ~exist(data_dir, 'dir'), mkdir(data_dir); end
if ~exist(videos_dir, 'dir'), mkdir(videos_dir); end

fprintf('Output directories created:\n');
fprintf('  Media:   %s\n', media_dir);
fprintf('  Figures: %s\n', figures_dir);
fprintf('  Data:    %s\n', data_dir);
fprintf('  Videos:  %s\n\n', videos_dir);

%% ═══════════════════════════════════════════════════════════════════════
%  PHASE 1: LOAD PARAMETERS
%  ═══════════════════════════════════════════════════════════════════════

p = params_sixbar();

% Save parameters to CSV
params_table = table();
params_table.Parameter = {'l1 (mm)'; 'l2 (mm)'; 'l3 (mm)'; 'l4 (mm)'; 'l5 (mm)'; 
                          'AC (mm)'; 'H (mm)'; 'S (mm)'; 'beta (deg)'; 'theta1 (deg)'; 
                          'omega2 (rad/s)'; 'm2 (kg)'; 'm3 (kg)'; 'm4 (kg)'; 
                          'm5 (kg)'; 'm6 (kg)'; 'I2 (kg·m²)'; 'I3 (kg·m²)'; 
                          'I4 (kg·m²)'; 'I5 (kg·m²)'};
params_table.Value = [p.l1; p.l2; p.l3; p.l4; p.l5; p.AC; p.H; p.S; 
                      p.beta_deg; p.theta1_deg; p.omega2; p.m2; p.m3; p.m4; 
                      p.m5; p.m6; p.I2; p.I3; p.I4; p.I5];

writetable(params_table, fullfile(data_dir, 'mechanism_parameters.csv'));
fprintf('✓ Parameters saved to: %s\n\n', fullfile(data_dir, 'mechanism_parameters.csv'));

%% ═══════════════════════════════════════════════════════════════════════
%  PHASE 2: POSITION, VELOCITY & ACCELERATION ANALYSIS
%  ═══════════════════════════════════════════════════════════════════════

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║  PART 1: KINEMATICS ANALYSIS (Position, Velocity, Accel)    ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

% Number of positions for one complete revolution
n_positions = 72;  % 5-degree increments
theta2_array = linspace(0, 2*pi, n_positions);

% Storage
positions = cell(1, n_positions);
velocities = cell(1, n_positions);
accelerations = cell(1, n_positions);

fprintf('Computing kinematics for %d crank positions...\n', n_positions);

tic;
for i = 1:n_positions
    % Position analysis
    positions{i} = solve_position(theta2_array(i), p);
    
    if ~isempty(fieldnames(positions{i}))
        % Velocity analysis
        velocities{i} = solve_velocity(positions{i}, p);
        
        % Acceleration analysis
        accelerations{i} = solve_acceleration(positions{i}, velocities{i}, p);
    end
    
    % Progress indicator
    if mod(i, 12) == 0
        fprintf('  Progress: %3.0f%% (%d/%d)\n', 100*i/n_positions, i, n_positions);
    end
end
elapsed_time = toc;

fprintf('\n✓ Kinematics analysis complete (%.2f seconds)\n\n', elapsed_time);

%% ═══════════════════════════════════════════════════════════════════════
%  PHASE 3: DYNAMIC FORCES ANALYSIS
%  ═══════════════════════════════════════════════════════════════════════

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║  PART 2: DYNAMIC FORCES ANALYSIS                             ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

forces = cell(1, n_positions);

fprintf('Computing dynamic forces...\n');

tic;
success_count = 0;
failed_indices = [];

for i = 1:n_positions
    % Check if position, velocity, and acceleration are valid
    if ~isempty(positions{i}) && isfield(positions{i}, 'A') && ...
       ~isempty(velocities{i}) && isfield(velocities{i}, 'omega3') && ...
       ~isempty(accelerations{i}) && isfield(accelerations{i}, 'aA')
        
        try
            forces{i} = solve_dynamics(positions{i}, velocities{i}, accelerations{i}, p);
            
            if ~isempty(forces{i}) && isfield(forces{i}, 'F12_mag')
                success_count = success_count + 1;
            else
                forces{i} = struct();
                failed_indices = [failed_indices, i];
            end
        catch ME
            fprintf('  Warning: Force calculation failed at position %d: %s\n', i, ME.message);
            forces{i} = struct();
            failed_indices = [failed_indices, i];
        end
    else
        forces{i} = struct();
        failed_indices = [failed_indices, i];
    end
    
    if mod(i, 12) == 0
        fprintf('  Progress: %3.0f%% (%d/%d)\n', 100*i/n_positions, i, n_positions);
    end
end
elapsed_time = toc;

fprintf('\n✓ Dynamic forces analysis complete (%.2f seconds)\n', elapsed_time);
fprintf('  Successfully analyzed: %d/%d positions (%.1f%%)\n', ...
        success_count, n_positions, 100*success_count/n_positions);

if ~isempty(failed_indices)
    fprintf('  Failed positions: %d total\n', length(failed_indices));
    if length(failed_indices) <= 10
        fprintf('    Indices: ');
        fprintf('%d ', failed_indices);
        fprintf('\n');
    end
end

fprintf('\n');

%% ═══════════════════════════════════════════════════════════════════════
%  PHASE 4: BALANCING STRATEGY DEVELOPMENT
%  ═══════════════════════════════════════════════════════════════════════

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║  PART 3: BALANCING STRATEGY DEVELOPMENT                      ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

balance = solve_balancing(positions, velocities, accelerations, p);

fprintf('✓ Balancing analysis complete\n\n');

%% ═══════════════════════════════════════════════════════════════════════
%  PHASE 5: RESULTS AT θ₂ = 60° (FOR COMPARISON WITH GRAPHICAL METHOD)
%  ═══════════════════════════════════════════════════════════════════════

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║  RESULTS AT θ₂ = 60° (For Graphical Method Comparison)      ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

theta2_deg = rad2deg(theta2_array);
[~, idx_60] = min(abs(theta2_deg - 60));

fprintf('POSITIONS:\n');
fprintf('──────────────────────────────────────────────────────────────\n');
fprintf('  A: (%7.2f, %7.2f) mm\n', positions{idx_60}.A(1), positions{idx_60}.A(2));
fprintf('  B: (%7.2f, %7.2f) mm\n', positions{idx_60}.B(1), positions{idx_60}.B(2));
fprintf('  C: (%7.2f, %7.2f) mm\n', positions{idx_60}.C(1), positions{idx_60}.C(2));
fprintf('  D: (%7.2f, %7.2f) mm\n\n', positions{idx_60}.D(1), positions{idx_60}.D(2));

fprintf('VELOCITIES:\n');
fprintf('──────────────────────────────────────────────────────────────\n');
fprintf('  v_A = %7.2f mm/s\n', velocities{idx_60}.vA_mag);
fprintf('  v_B = %7.2f mm/s\n', velocities{idx_60}.vB_mag);
fprintf('  v_C = %7.2f mm/s\n', velocities{idx_60}.vC_mag);
fprintf('  v_D = %7.2f mm/s\n\n', velocities{idx_60}.vD_mag);

fprintf('  ω_3 = %7.3f rad/s\n', velocities{idx_60}.omega3);
fprintf('  ω_4 = %7.3f rad/s\n', velocities{idx_60}.omega4);
fprintf('  ω_5 = %7.3f rad/s\n\n', velocities{idx_60}.omega5);

fprintf('ACCELERATIONS:\n');
fprintf('──────────────────────────────────────────────────────────────\n');
fprintf('  a_A = %7.2f mm/s²\n', accelerations{idx_60}.aA_mag);
fprintf('  a_B = %7.2f mm/s²\n', accelerations{idx_60}.aB_mag);
fprintf('  a_C = %7.2f mm/s²\n', accelerations{idx_60}.aC_mag);
fprintf('  a_D = %7.2f mm/s²\n\n', accelerations{idx_60}.aD_mag);

fprintf('  α_3 = %7.3f rad/s²\n', accelerations{idx_60}.alpha3);
fprintf('  α_4 = %7.3f rad/s²\n', accelerations{idx_60}.alpha4);
fprintf('  α_5 = %7.3f rad/s²\n\n', accelerations{idx_60}.alpha5);

fprintf('DYNAMIC FORCES:\n');
fprintf('──────────────────────────────────────────────────────────────\n');
fprintf('  F_12 (at O) = %7.3f N\n', forces{idx_60}.F12_mag);
fprintf('  F_23 (at A) = %7.3f N\n', forces{idx_60}.F23_mag);
fprintf('  F_34 (at B) = %7.3f N\n', forces{idx_60}.F34_mag);
fprintf('  F_45 (at C) = %7.3f N\n\n', forces{idx_60}.F45_mag);

fprintf('  Driving Torque T_2 = %7.4f N·m\n', forces{idx_60}.T2);
fprintf('  Slider Side Load N = %7.3f N\n\n', forces{idx_60}.N_slider);

fprintf('BALANCING PERFORMANCE:\n');
fprintf('──────────────────────────────────────────────────────────────\n');
fprintf('  Unbalanced RMS Shaking Force:  %7.3f N\n', balance.F_rms);
fprintf('  Balanced RMS Shaking Force:    %7.3f N\n', balance.F_rms_bal);
fprintf('  Force Reduction:               %7.1f%%\n\n', balance.force_reduction);

fprintf('  Optimized Counterweight:\n');
fprintf('    Mass:   %.3f kg\n', balance.m_cw_opt);
fprintf('    Radius: %.1f mm\n', balance.r_cw_opt*1000);
fprintf('    Force Reduction: %.1f%%\n\n', (1-balance.F_rms_opt/balance.F_rms)*100);

%% Save Results Table at θ₂ = 60°
results_table = table();
results_table.Parameter = {
    'Crank Angle θ₂ (deg)'; '';
    '--- POSITIONS ---';
    'Point A - X (mm)'; 'Point A - Y (mm)';
    'Point B - X (mm)'; 'Point B - Y (mm)';
    'Point C - X (mm)'; 'Point C - Y (mm)';
    'Point D - X (mm)'; 'Point D - Y (mm)'; '';
    '--- VELOCITIES ---';
    'v_A (mm/s)'; 'v_B (mm/s)'; 'v_C (mm/s)'; 'v_D (mm/s)';
    'ω_3 (rad/s)'; 'ω_4 (rad/s)'; 'ω_5 (rad/s)'; '';
    '--- ACCELERATIONS ---';
    'a_A (mm/s²)'; 'a_B (mm/s²)'; 'a_C (mm/s²)'; 'a_D (mm/s²)';
    'α_3 (rad/s²)'; 'α_4 (rad/s²)'; 'α_5 (rad/s²)'; '';
    '--- FORCES ---';
    'F_12 at O (N)'; 'F_23 at A (N)'; 'F_34 at B (N)'; 'F_45 at C (N)';
    'Driving Torque T_2 (N·m)'; 'Slider Side Load N (N)';
};

results_table.Value = [
    theta2_deg(idx_60); NaN; NaN;
    positions{idx_60}.A(1); positions{idx_60}.A(2);
    positions{idx_60}.B(1); positions{idx_60}.B(2);
    positions{idx_60}.C(1); positions{idx_60}.C(2);
    positions{idx_60}.D(1); positions{idx_60}.D(2); NaN; NaN;
    velocities{idx_60}.vA_mag; velocities{idx_60}.vB_mag;
    velocities{idx_60}.vC_mag; velocities{idx_60}.vD_mag;
    velocities{idx_60}.omega3; velocities{idx_60}.omega4;
    velocities{idx_60}.omega5; NaN; NaN;
    accelerations{idx_60}.aA_mag; accelerations{idx_60}.aB_mag;
    accelerations{idx_60}.aC_mag; accelerations{idx_60}.aD_mag;
    accelerations{idx_60}.alpha3; accelerations{idx_60}.alpha4;
    accelerations{idx_60}.alpha5; NaN; NaN;
    forces{idx_60}.F12_mag; forces{idx_60}.F23_mag;
    forces{idx_60}.F34_mag; forces{idx_60}.F45_mag;
    forces{idx_60}.T2; forces{idx_60}.N_slider;
];

writetable(results_table, fullfile(data_dir, 'results_at_60deg.csv'));
fprintf('✓ Results table saved to: %s\n\n', fullfile(data_dir, 'results_at_60deg.csv'));

%% ═══════════════════════════════════════════════════════════════════════
%  PHASE 6: GENERATE AND SAVE PLOTS
%  ═══════════════════════════════════════════════════════════════════════

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║  GENERATING PROFESSIONAL PLOTS                               ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

plot_results(theta2_array, velocities, accelerations, forces, balance, p);

% Save all figures as high-res PNG
fprintf('Saving figures to: %s\n', figures_dir);

figure(1);
saveas(gcf, fullfile(figures_dir, 'Fig1_Velocities.png'));
print(gcf, fullfile(figures_dir, 'Fig1_Velocities_HighRes'), '-dpng', '-r300');
fprintf('  ✓ Figure 1: Velocities saved\n');

figure(2);
saveas(gcf, fullfile(figures_dir, 'Fig2_Accelerations.png'));
print(gcf, fullfile(figures_dir, 'Fig2_Accelerations_HighRes'), '-dpng', '-r300');
fprintf('  ✓ Figure 2: Accelerations saved\n');

figure(3);
saveas(gcf, fullfile(figures_dir, 'Fig3_DynamicForces.png'));
print(gcf, fullfile(figures_dir, 'Fig3_DynamicForces_HighRes'), '-dpng', '-r300');
fprintf('  ✓ Figure 3: Dynamic Forces saved\n');

figure(4);
saveas(gcf, fullfile(figures_dir, 'Fig4_BalancingAnalysis.png'));
print(gcf, fullfile(figures_dir, 'Fig4_BalancingAnalysis_HighRes'), '-dpng', '-r300');
fprintf('  ✓ Figure 4: Balancing Analysis saved\n');

figure(5);
saveas(gcf, fullfile(figures_dir, 'Fig5_ShakingMoment.png'));
print(gcf, fullfile(figures_dir, 'Fig5_ShakingMoment_HighRes'), '-dpng', '-r300');
fprintf('  ✓ Figure 5: Shaking Moment saved\n\n');

%% Create single position diagram at θ₂ = 60°
fprintf('Creating mechanism diagram at θ₂ = 60°...\n');
pos_60 = positions{idx_60};

fig_mech = figure('Position', [100, 100, 1200, 900], 'Color', 'w');
hold on; axis equal; grid on;

% Ground
plot([-60, 360], [p.slider_y, p.slider_y], 'k-', 'LineWidth', 4);
hatch_x = -60:15:360;
for x = hatch_x
    plot([x, x-8], [p.slider_y, p.slider_y-10], 'k-', 'LineWidth', 1.5);
end

% Links
plot([p.O(1), p.E(1)], [p.O(2), p.E(2)], 'k-', 'LineWidth', 6);
plot([p.O(1), pos_60.A(1)], [p.O(2), pos_60.A(2)], 'r-', 'LineWidth', 7);
plot([pos_60.A(1), pos_60.B(1)], [pos_60.A(2), pos_60.B(2)], 'b-', 'LineWidth', 7);
plot([pos_60.A(1), pos_60.C(1)], [pos_60.A(2), pos_60.C(2)], 'b--', 'LineWidth', 5);
plot([p.E(1), pos_60.B(1)], [p.E(2), pos_60.B(2)], 'g-', 'LineWidth', 7);
plot([pos_60.C(1), pos_60.D(1)], [pos_60.C(2), pos_60.D(2)], 'm-', 'LineWidth', 7);

% Slider
rectangle('Position', [pos_60.D(1)-11, pos_60.D(2)-9, 22, 18], ...
          'FaceColor', [0.2 0.9 0.9], 'EdgeColor', 'c', 'LineWidth', 3);

% Joints
viscircles(p.O', 7, 'Color', 'k', 'LineWidth', 3);
viscircles(p.E', 7, 'Color', 'k', 'LineWidth', 3);
viscircles(pos_60.A', 7, 'Color', 'r', 'LineWidth', 3);
viscircles(pos_60.B', 7, 'Color', 'g', 'LineWidth', 3);
viscircles(pos_60.C', 7, 'Color', 'm', 'LineWidth', 3);
viscircles(pos_60.D', 7, 'Color', 'c', 'LineWidth', 3);

% Labels
text(p.O(1)-15, p.O(2)+15, 'O', 'FontSize', 20, 'FontWeight', 'bold');
text(p.E(1)+10, p.E(2)+10, 'E', 'FontSize', 20, 'FontWeight', 'bold');
text(pos_60.A(1)+10, pos_60.A(2)+10, 'A', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'r');
text(pos_60.B(1)+10, pos_60.B(2)+10, 'B', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'g');
text(pos_60.C(1)+10, pos_60.C(2)+10, 'C', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'm');
text(pos_60.D(1), pos_60.D(2)+25, 'D', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'c');

title('Six-Bar Linkage Mechanism at θ₂ = 60°', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('X Position (mm)', 'FontSize', 14);
ylabel('Y Position (mm)', 'FontSize', 14);
xlim([-80, 380]); ylim([-100, 180]);
set(gca, 'FontSize', 12, 'LineWidth', 1.5);

hold off;

saveas(fig_mech, fullfile(figures_dir, 'Mechanism_Position_60deg.png'));
print(fig_mech, fullfile(figures_dir, 'Mechanism_Position_60deg_HighRes'), '-dpng', '-r300');
fprintf('  ✓ Mechanism diagram at 60° saved\n\n');

close(fig_mech);

%% ═══════════════════════════════════════════════════════════════════════
%  PHASE 7: GENERATE AND SAVE ANIMATION
%  ═══════════════════════════════════════════════════════════════════════

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║  GENERATING HIGH-END ANIMATION VIDEO                         ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

anim_options.save_video = true;
anim_options.video_name = fullfile(videos_dir, 'SixBar_Mechanism_Animation.mp4');
anim_options.frame_rate = 30;
anim_options.show_trails = true;

fprintf('Creating animation (this may take 1-2 minutes)...\n');
animate_mechanism(positions, p, anim_options);

fprintf('\n✓ Animation video saved to: %s\n\n', anim_options.video_name);

%% ═══════════════════════════════════════════════════════════════════════
%  PHASE 8: SAVE COMPLETE DATASET
%  ═══════════════════════════════════════════════════════════════════════

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║  SAVING COMPLETE DATASET                                     ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

% Save .mat file for future use
mat_file = fullfile(data_dir, 'complete_results.mat');
save(mat_file, 'positions', 'velocities', 'accelerations', ...
     'forces', 'balance', 'p', 'theta2_array');
fprintf('✓ MATLAB data saved to: %s\n', mat_file);

% Save balancing results
balance_table = table();
balance_table.Parameter = {
    'Unbalanced RMS Force (N)';
    'Unbalanced Peak Force (N)';
    'Unbalanced RMS Moment (N·m)';
    '';
    'Initial Counterweight Mass (kg)';
    'Initial Counterweight Radius (mm)';
    'Balanced RMS Force (N)';
    'Force Reduction (%)';
    '';
    'Optimized CW Mass (kg)';
    'Optimized CW Radius (mm)';
    'Optimized RMS Force (N)';
    'Optimized Reduction (%)';
};

balance_table.Value = [
    balance.F_rms;
    balance.F_peak;
    balance.M_rms;
    NaN;
    balance.m_cw;
    balance.r_cw * 1000;
    balance.F_rms_bal;
    balance.force_reduction;
    NaN;
    balance.m_cw_opt;
    balance.r_cw_opt * 1000;
    balance.F_rms_opt;
    (1 - balance.F_rms_opt/balance.F_rms) * 100;
];

writetable(balance_table, fullfile(data_dir, 'balancing_results.csv'));
fprintf('✓ Balancing results saved to: %s\n', fullfile(data_dir, 'balancing_results.csv'));

% Create README file
readme_file = fullfile(media_dir, 'README.txt');
fid = fopen(readme_file, 'w');
fprintf(fid, '══════════════════════════════════════════════════════════════\n');
fprintf(fid, '  SIX-BAR LINKAGE MECHANISM - COMPUTATIONAL ANALYSIS RESULTS\n');
fprintf(fid, '══════════════════════════════════════════════════════════════\n');
fprintf(fid, 'Author: Osha\n');
fprintf(fid, 'Date: %s\n\n', datestr(now));
fprintf(fid, 'DIRECTORY STRUCTURE:\n');
fprintf(fid, '------------------------------------------------------------\n');
fprintf(fid, 'media/\n');
fprintf(fid, '  ├── figures/           [6 high-resolution PNG images]\n');
fprintf(fid, '  │   ├── Fig1_Velocities.png\n');
fprintf(fid, '  │   ├── Fig2_Accelerations.png\n');
fprintf(fid, '  │   ├── Fig3_DynamicForces.png\n');
fprintf(fid, '  │   ├── Fig4_BalancingAnalysis.png\n');
fprintf(fid, '  │   ├── Fig5_ShakingMoment.png\n');
fprintf(fid, '  │   └── Mechanism_Position_60deg.png\n');
fprintf(fid, '  │\n');
fprintf(fid, '  ├── videos/            [1 MP4 animation]\n');
fprintf(fid, '  │   └── SixBar_Mechanism_Animation.mp4\n');
fprintf(fid, '  │\n');
fprintf(fid, '  ├── data/              [CSV tables and MAT file]\n');
fprintf(fid, '  │   ├── mechanism_parameters.csv\n');
fprintf(fid, '  │   ├── results_at_60deg.csv\n');
fprintf(fid, '  │   ├── balancing_results.csv\n');
fprintf(fid, '  │   └── complete_results.mat\n');
fprintf(fid, '  │\n');
fprintf(fid, '  └── README.txt         [This file]\n\n');
fprintf(fid, 'USAGE:\n');
fprintf(fid, '------------------------------------------------------------\n');
fprintf(fid, '1. View figures: Open PNG files in figures/ folder\n');
fprintf(fid, '2. Watch animation: Open MP4 file in videos/ folder\n');
fprintf(fid, '3. Access data: Open CSV files in Excel/Google Sheets\n');
fprintf(fid, '4. Load in MATLAB: load(''data/complete_results.mat'')\n\n');
fprintf(fid, 'FOR REPORT:\n');
fprintf(fid, '------------------------------------------------------------\n');
fprintf(fid, '• Include all 6 figures from figures/ folder\n');
fprintf(fid, '• Embed animation or screenshots\n');
fprintf(fid, '• Copy tables from CSV files\n');
fprintf(fid, '• Compare computational vs. handwritten results\n\n');
fclose(fid);

fprintf('✓ README file created: %s\n\n', readme_file);

%% ═══════════════════════════════════════════════════════════════════════
%  COMPLETE
%  ═══════════════════════════════════════════════════════════════════════

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║                                                              ║\n');
fprintf('║              ✓✓✓ ANALYSIS COMPLETE! ✓✓✓                     ║\n');
fprintf('║                                                              ║\n');
fprintf('║  All outputs saved to:                                       ║\n');
fprintf('║  %s  ║\n', media_dir);
fprintf('║                                                              ║\n');
fprintf('║  Generated Files:                                            ║\n');
fprintf('║    • 6 High-Resolution Figures (PNG)                         ║\n');
fprintf('║    • 1 HD Animation Video (MP4)                              ║\n');
fprintf('║    • 4 Data Tables (CSV)                                     ║\n');
fprintf('║    • 1 Complete Dataset (MAT)                                ║\n');
fprintf('║    • 1 README Documentation (TXT)                            ║\n');
fprintf('║                                                              ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

fprintf('📁 OUTPUT SUMMARY:\n');
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('Figures:  %s\n', figures_dir);
fprintf('Videos:   %s\n', videos_dir);
fprintf('Data:     %s\n', data_dir);
fprintf('═══════════════════════════════════════════════════════════════\n\n');

fprintf('📝 FOR YOUR REPORT:\n');
fprintf('  1. Download all files from: %s\n', media_dir);
fprintf('  2. Include all 6 figures in report\n');
fprintf('  3. Embed or link to animation video\n');
fprintf('  4. Copy tables from CSV files\n');
fprintf('  5. Compare with handwritten calculations\n\n');

fprintf('✅ Ready for submission!\n\n');