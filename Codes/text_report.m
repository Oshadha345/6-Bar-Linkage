%% export_results_to_txt.m
% Export complete results from .mat file to comprehensive .txt report
% Author: 
% Date: 2025-10-16
% ==========================================================================

clear; clc;

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║     EXPORTING RESULTS TO TEXT FILE                           ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

%% Load results
mat_file = '/MATLAB Drive/Sixbar_assignment/media/data/complete_results.mat';
output_file = '/MATLAB Drive/Sixbar_assignment/media/data/complete_results_report.txt';

fprintf('Loading data from: %s\n', mat_file);
load(mat_file);

fprintf('Creating text report...\n\n');

%% Open file for writing
fid = fopen(output_file, 'w');

if fid == -1
    error('Could not create output file!');
end

%% Write header
fprintf(fid, '╔══════════════════════════════════════════════════════════════════════════════╗\n');
fprintf(fid, '║                                                                              ║\n');
fprintf(fid, '║           SIX-BAR LINKAGE MECHANISM - COMPLETE ANALYSIS REPORT               ║\n');
fprintf(fid, '║                                                                              ║\n');
fprintf(fid, '╚══════════════════════════════════════════════════════════════════════════════╝\n\n');

fprintf(fid, 'Author: Oshadha345\n');
fprintf(fid, 'Date Generated: %s UTC\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, 'Analysis Type: Computational Method\n');
fprintf(fid, 'Software: MATLAB R2024a\n\n');

fprintf(fid, '════════════════════════════════════════════════════════════════════════════════\n\n');

%% SECTION 1: Mechanism Parameters
fprintf(fid, '1. MECHANISM PARAMETERS\n');
fprintf(fid, '═══════════════════════════════════════════════════════════════════════════════\n\n');

fprintf(fid, '1.1 Geometric Parameters (mm)\n');
fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
fprintf(fid, '  l1 (OE) - Ground Link:        %8.2f mm\n', p.l1);
fprintf(fid, '  l2 (OA) - Crank:               %8.2f mm\n', p.l2);
fprintf(fid, '  l3 (AB) - Coupler Side 1:      %8.2f mm\n', p.l3);
fprintf(fid, '  l4 (BE) - Rocker:              %8.2f mm\n', p.l4);
fprintf(fid, '  l5 (CD) - To Slider:           %8.2f mm\n', p.l5);
fprintf(fid, '  AC - Coupler Side 2:           %8.2f mm\n', p.AC);
fprintf(fid, '  H - Slider Vertical Offset:    %8.2f mm\n', p.H);
fprintf(fid, '  S - Reference Distance:        %8.2f mm\n\n', p.S);

fprintf(fid, '1.2 Angles\n');
fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
fprintf(fid, '  θ1 - Ground Link Angle:        %8.2f°\n', p.theta1_deg);
fprintf(fid, '  β - Coupler Internal Angle:    %8.2f° (negative for correct configuration)\n\n', p.beta_deg);

fprintf(fid, '1.3 Kinematics\n');
fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
fprintf(fid, '  ω2 - Crank Angular Velocity:   %8.2f rad/s (constant)\n', p.omega2);
fprintf(fid, '  α2 - Crank Angular Accel.:     %8.2f rad/s² (zero - constant speed)\n\n', p.alpha2);

fprintf(fid, '1.4 Mass Properties\n');
fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
fprintf(fid, '  Link 2 (Crank):      m2 = %.1f kg,  I2 = %.4f kg·m²\n', p.m2, p.I2);
fprintf(fid, '  Link 3 (Coupler):    m3 = %.1f kg,  I3 = %.4f kg·m²\n', p.m3, p.I3);
fprintf(fid, '  Link 4 (Rocker):     m4 = %.1f kg,  I4 = %.4f kg·m²\n', p.m4, p.I4);
fprintf(fid, '  Link 5 (To Slider):  m5 = %.1f kg,  I5 = %.4f kg·m²\n', p.m5, p.I5);
fprintf(fid, '  Link 6 (Slider):     m6 = %.1f kg\n\n', p.m6);

fprintf(fid, '1.5 Fixed Pivot Positions\n');
fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
fprintf(fid, '  O (Origin):          (%.2f, %.2f) mm\n', p.O(1), p.O(2));
fprintf(fid, '  E (Fixed Pivot):     (%.2f, %.2f) mm\n', p.E(1), p.E(2));
fprintf(fid, '  Slider Path Y:       %.2f mm\n\n', p.slider_y);

%% SECTION 2: Analysis Summary
fprintf(fid, '\n════════════════════════════════════════════════════════════════════════════════\n\n');
fprintf(fid, '2. ANALYSIS SUMMARY\n');
fprintf(fid, '═══════════════════════════════════════════════════════════════════════════════\n\n');

n_total = length(positions);
n_valid = 0;
for i = 1:n_total
    if ~isempty(positions{i}) && isfield(positions{i}, 'A')
        n_valid = n_valid + 1;
    end
end

fprintf(fid, '  Total Crank Positions Analyzed:     %d\n', n_total);
fprintf(fid, '  Valid Solutions Found:               %d (%.1f%%)\n', n_valid, 100*n_valid/n_total);
fprintf(fid, '  Crank Angle Increment:               %.1f°\n', 360/n_total);
fprintf(fid, '  Analysis Method:                     Loop-Closure Equations\n');
fprintf(fid, '  Configuration:                       Open-Loop (C below B)\n\n');

%% SECTION 3: Results at θ₂ = 60°
fprintf(fid, '\n════════════════════════════════════════════════════════════════════════════════\n\n');
fprintf(fid, '3. DETAILED RESULTS AT θ₂ = 60°\n');
fprintf(fid, '═══════════════════════════════════════════════════════════════════════════════\n\n');

% Find index closest to 60°
theta2_array = linspace(0, 2*pi, n_total);
theta2_deg = rad2deg(theta2_array);
[~, idx_60] = min(abs(theta2_deg - 60));

% Find nearest valid position if needed
while (isempty(positions{idx_60}) || ~isfield(positions{idx_60}, 'A')) && idx_60 < n_total
    idx_60 = idx_60 + 1;
end

if ~isempty(positions{idx_60}) && isfield(positions{idx_60}, 'A')
    fprintf(fid, '3.1 Position Analysis\n');
    fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
    fprintf(fid, '  Actual θ2 analyzed:          %.2f°\n\n', rad2deg(positions{idx_60}.theta2));
    fprintf(fid, '  Joint Coordinates:\n');
    fprintf(fid, '    Point A:  (%8.2f, %8.2f) mm\n', positions{idx_60}.A(1), positions{idx_60}.A(2));
    fprintf(fid, '    Point B:  (%8.2f, %8.2f) mm\n', positions{idx_60}.B(1), positions{idx_60}.B(2));
    fprintf(fid, '    Point C:  (%8.2f, %8.2f) mm\n', positions{idx_60}.C(1), positions{idx_60}.C(2));
    fprintf(fid, '    Point D:  (%8.2f, %8.2f) mm\n\n', positions{idx_60}.D(1), positions{idx_60}.D(2));
    
    fprintf(fid, '  Link Angles:\n');
    fprintf(fid, '    θ3 (Link 3):     %8.2f°\n', rad2deg(positions{idx_60}.theta3));
    fprintf(fid, '    θ4 (Link 4):     %8.2f°\n', rad2deg(positions{idx_60}.theta4));
    fprintf(fid, '    θ5 (Link 5):     %8.2f°\n\n', rad2deg(positions{idx_60}.theta5));
    
    if ~isempty(velocities{idx_60}) && isfield(velocities{idx_60}, 'vA_mag')
        fprintf(fid, '3.2 Velocity Analysis\n');
        fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
        fprintf(fid, '  Linear Velocities:\n');
        fprintf(fid, '    v_A:             %8.2f mm/s\n', velocities{idx_60}.vA_mag);
        fprintf(fid, '    v_B:             %8.2f mm/s\n', velocities{idx_60}.vB_mag);
        fprintf(fid, '    v_C:             %8.2f mm/s\n', velocities{idx_60}.vC_mag);
        fprintf(fid, '    v_D:             %8.2f mm/s\n\n', velocities{idx_60}.vD_mag);
        
        fprintf(fid, '  Angular Velocities:\n');
        fprintf(fid, '    ω3:              %8.3f rad/s\n', velocities{idx_60}.omega3);
        fprintf(fid, '    ω4:              %8.3f rad/s\n', velocities{idx_60}.omega4);
        fprintf(fid, '    ω5:              %8.3f rad/s\n\n', velocities{idx_60}.omega5);
    end
    
    if ~isempty(accelerations{idx_60}) && isfield(accelerations{idx_60}, 'aA_mag')
        fprintf(fid, '3.3 Acceleration Analysis\n');
        fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
        fprintf(fid, '  Linear Accelerations:\n');
        fprintf(fid, '    a_A:             %8.2f mm/s²\n', accelerations{idx_60}.aA_mag);
        fprintf(fid, '    a_B:             %8.2f mm/s²\n', accelerations{idx_60}.aB_mag);
        fprintf(fid, '    a_C:             %8.2f mm/s²\n', accelerations{idx_60}.aC_mag);
        fprintf(fid, '    a_D:             %8.2f mm/s²\n\n', accelerations{idx_60}.aD_mag);
        
        fprintf(fid, '  Angular Accelerations:\n');
        fprintf(fid, '    α3:              %8.3f rad/s²\n', accelerations{idx_60}.alpha3);
        fprintf(fid, '    α4:              %8.3f rad/s²\n', accelerations{idx_60}.alpha4);
        fprintf(fid, '    α5:              %8.3f rad/s²\n\n', accelerations{idx_60}.alpha5);
    end
    
    if ~isempty(forces{idx_60}) && isfield(forces{idx_60}, 'F12_mag')
        fprintf(fid, '3.4 Dynamic Force Analysis\n');
        fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
        fprintf(fid, '  Joint Reaction Forces:\n');
        fprintf(fid, '    F12 (at O):      %8.3f N\n', forces{idx_60}.F12_mag);
        fprintf(fid, '    F23 (at A):      %8.3f N\n', forces{idx_60}.F23_mag);
        fprintf(fid, '    F34 (at B):      %8.3f N\n', forces{idx_60}.F34_mag);
        fprintf(fid, '    F45 (at C):      %8.3f N\n\n', forces{idx_60}.F45_mag);
        
        fprintf(fid, '  Driving Torque and Loads:\n');
        fprintf(fid, '    T2 (Driving):    %8.4f N·m\n', forces{idx_60}.T2);
        fprintf(fid, '    N (Slider):      %8.3f N\n\n', forces{idx_60}.N_slider);
    end
end

%% SECTION 4: Statistical Summary
fprintf(fid, '\n════════════════════════════════════════════════════════════════════════════════\n\n');
fprintf(fid, '4. STATISTICAL SUMMARY (Complete Cycle)\n');
fprintf(fid, '═══════════════════════════════════════════════════════════════════════════════\n\n');

% Extract valid data
valid_indices = [];
for i = 1:n_total
    if ~isempty(positions{i}) && isfield(positions{i}, 'A')
        valid_indices = [valid_indices, i];
    end
end

if ~isempty(valid_indices)
    % Velocities
    vA_all = zeros(1, length(valid_indices));
    vD_all = zeros(1, length(valid_indices));
    omega3_all = zeros(1, length(valid_indices));
    
    % Accelerations
    aA_all = zeros(1, length(valid_indices));
    aD_all = zeros(1, length(valid_indices));
    alpha3_all = zeros(1, length(valid_indices));
    
    % Forces
    F12_all = zeros(1, length(valid_indices));
    T2_all = zeros(1, length(valid_indices));
    
    for idx = 1:length(valid_indices)
        i = valid_indices(idx);
        
        if ~isempty(velocities{i}) && isfield(velocities{i}, 'vA_mag')
            vA_all(idx) = velocities{i}.vA_mag;
            vD_all(idx) = velocities{i}.vD_mag;
            omega3_all(idx) = velocities{i}.omega3;
        end
        
        if ~isempty(accelerations{i}) && isfield(accelerations{i}, 'aA_mag')
            aA_all(idx) = accelerations{i}.aA_mag;
            aD_all(idx) = accelerations{i}.aD_mag;
            alpha3_all(idx) = accelerations{i}.alpha3;
        end
        
        if ~isempty(forces{i}) && isfield(forces{i}, 'F12_mag')
            F12_all(idx) = forces{i}.F12_mag;
            T2_all(idx) = forces{i}.T2;
        end
    end
    
    fprintf(fid, '4.1 Velocity Statistics\n');
    fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
    fprintf(fid, '  v_A:  Min = %8.2f mm/s,  Max = %8.2f mm/s,  Mean = %8.2f mm/s\n', ...
            min(vA_all), max(vA_all), mean(vA_all));
    fprintf(fid, '  v_D:  Min = %8.2f mm/s,  Max = %8.2f mm/s,  Mean = %8.2f mm/s\n', ...
            min(vD_all), max(vD_all), mean(vD_all));
    fprintf(fid, '  ω3:   Min = %8.3f rad/s,  Max = %8.3f rad/s,  Mean = %8.3f rad/s\n\n', ...
            min(omega3_all), max(omega3_all), mean(omega3_all));
    
    fprintf(fid, '4.2 Acceleration Statistics\n');
    fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
    fprintf(fid, '  a_A:  Min = %8.2f mm/s²,  Max = %8.2f mm/s²,  Mean = %8.2f mm/s²\n', ...
            min(aA_all), max(aA_all), mean(aA_all));
    fprintf(fid, '  a_D:  Min = %8.2f mm/s²,  Max = %8.2f mm/s²,  Mean = %8.2f mm/s²\n', ...
            min(aD_all), max(aD_all), mean(aD_all));
    fprintf(fid, '  α3:   Min = %8.3f rad/s²,  Max = %8.3f rad/s²,  Mean = %8.3f rad/s²\n\n', ...
            min(alpha3_all), max(alpha3_all), mean(alpha3_all));
    
    fprintf(fid, '4.3 Force Statistics\n');
    fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
    fprintf(fid, '  F12:  Min = %8.3f N,  Max = %8.3f N,  Mean = %8.3f N\n', ...
            min(F12_all), max(F12_all), mean(F12_all));
    fprintf(fid, '  T2:   Min = %8.4f N·m,  Max = %8.4f N·m,  Mean = %8.4f N·m\n\n', ...
            min(T2_all), max(T2_all), mean(T2_all));
end

%% SECTION 5: Balancing Analysis
if exist('balance', 'var')
    fprintf(fid, '\n════════════════════════════════════════════════════════════════════════════════\n\n');
    fprintf(fid, '5. BALANCING ANALYSIS\n');
    fprintf(fid, '═══════════════════════════════════════════════════════════════════════════════\n\n');
    
    fprintf(fid, '5.1 Unbalanced Mechanism\n');
    fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
    fprintf(fid, '  RMS Shaking Force:           %8.3f N\n', balance.F_rms);
    fprintf(fid, '  Peak Shaking Force:          %8.3f N\n', balance.F_peak);
    fprintf(fid, '  RMS Shaking Moment:          %8.3f N·m\n', balance.M_rms);
    fprintf(fid, '  Peak Shaking Moment:         %8.3f N·m\n\n', balance.M_peak);
    
    fprintf(fid, '5.2 Counterweight Design (Basic)\n');
    fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
    fprintf(fid, '  Mass:                        %8.3f kg\n', balance.m_cw);
    fprintf(fid, '  Radius from O:               %8.1f mm\n', balance.r_cw * 1000);
    fprintf(fid, '  Balanced RMS Force:          %8.3f N\n', balance.F_rms_bal);
    fprintf(fid, '  Force Reduction:             %8.1f%%\n\n', balance.force_reduction);
    
    fprintf(fid, '5.3 Optimized Counterweight Design\n');
    fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
    fprintf(fid, '  Optimized Mass:              %8.3f kg\n', balance.m_cw_opt);
    fprintf(fid, '  Optimized Radius:            %8.1f mm\n', balance.r_cw_opt * 1000);
    fprintf(fid, '  Optimized RMS Force:         %8.3f N\n', balance.F_rms_opt);
    reduction_opt = (1 - balance.F_rms_opt/balance.F_rms) * 100;
    fprintf(fid, '  Force Reduction:             %8.1f%%\n\n', reduction_opt);
    
    fprintf(fid, '5.4 2D Optimization (Mass + Radius)\n');
    fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
    fprintf(fid, '  Optimal Mass:                %8.3f kg\n', balance.m_cw_opt_2d);
    fprintf(fid, '  Optimal Radius:              %8.1f mm\n', balance.r_cw_opt_2d * 1000);
    fprintf(fid, '  Optimized RMS Force:         %8.3f N\n', balance.F_rms_opt_2d);
    reduction_2d = (1 - balance.F_rms_opt_2d/balance.F_rms) * 100;
    fprintf(fid, '  Force Reduction:             %8.1f%%\n\n', reduction_2d);
end

%% SECTION 6: Data Tables
fprintf(fid, '\n════════════════════════════════════════════════════════════════════════════════\n\n');
fprintf(fid, '6. COMPLETE DATA TABLES\n');
fprintf(fid, '═══════════════════════════════════════════════════════════════════════════════\n\n');

fprintf(fid, '6.1 Position Data (Selected Points)\n');
fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');
fprintf(fid, 'θ2(°)   |   A_x(mm)   A_y(mm) |   B_x(mm)   B_y(mm) |   C_x(mm)   C_y(mm) |   D_x(mm)   D_y(mm)\n');
fprintf(fid, '────────────────────────────────────────────────────────────────────────────────\n');

for i = 1:6:n_total  % Print every 6th position
    if ~isempty(positions{i}) && isfield(positions{i}, 'A')
        fprintf(fid, '%6.1f  | %8.2f %8.2f | %8.2f %8.2f | %8.2f %8.2f | %8.2f %8.2f\n', ...
                rad2deg(positions{i}.theta2), ...
                positions{i}.A(1), positions{i}.A(2), ...
                positions{i}.B(1), positions{i}.B(2), ...
                positions{i}.C(1), positions{i}.C(2), ...
                positions{i}.D(1), positions{i}.D(2));
    end
end

%% Footer
fprintf(fid, '\n\n════════════════════════════════════════════════════════════════════════════════\n');
fprintf(fid, '                              END OF REPORT\n');
fprintf(fid, '════════════════════════════════════════════════════════════════════════════════\n\n');

fprintf(fid, 'Report generated from: %s\n', mat_file);
fprintf(fid, 'Generated by: \n');
fprintf(fid, 'Date: %s UTC\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '\nFor detailed plots and animation, see:\n');
fprintf(fid, '  - Figures: /MATLAB Drive/Sixbar_assignment/media/figures/\n');
fprintf(fid, '  - Video:   /MATLAB Drive/Sixbar_assignment/media/videos/\n\n');

%% Close file
fclose(fid);

fprintf('✓ Report created successfully!\n\n');
fprintf('Output file: %s\n', output_file);

% Display file info
file_info = dir(output_file);
fprintf('File size: %.2f KB\n\n', file_info.bytes / 1024);

fprintf('You can now download this file from MATLAB Online:\n');
fprintf('  1. Navigate to: /MATLAB Drive/Sixbar_assignment/media/data/\n');
fprintf('  2. Right-click on: complete_results_report.txt\n');
fprintf('  3. Select "Download"\n\n');

fprintf('✓ Done!\n');