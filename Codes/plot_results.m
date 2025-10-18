function plot_results(theta2_array, velocities, accelerations, forces, balance, p)
%% plot_results.m
% Generate professional plots with robust error checking
% ==========================================================================

n = length(theta2_array);
theta2_deg = rad2deg(theta2_array);

%% Extract data arrays (with error checking)
vA = zeros(1, n);
vB = zeros(1, n);
vC = zeros(1, n);
vD = zeros(1, n);
omega3 = zeros(1, n);
omega4 = zeros(1, n);
omega5 = zeros(1, n);

aA = zeros(1, n);
aB = zeros(1, n);
aC = zeros(1, n);
aD = zeros(1, n);
alpha3 = zeros(1, n);
alpha4 = zeros(1, n);
alpha5 = zeros(1, n);

F12 = zeros(1, n);
F23 = zeros(1, n);
F34 = zeros(1, n);
F45 = zeros(1, n);
T2 = zeros(1, n);

valid_mask = false(1, n);

for i = 1:n
    % Check velocities
    if ~isempty(velocities{i}) && isfield(velocities{i}, 'vA_mag')
        vA(i) = velocities{i}.vA_mag;
        vB(i) = velocities{i}.vB_mag;
        vC(i) = velocities{i}.vC_mag;
        vD(i) = velocities{i}.vD_mag;
        omega3(i) = velocities{i}.omega3;
        omega4(i) = velocities{i}.omega4;
        omega5(i) = velocities{i}.omega5;
        valid_mask(i) = true;
    end
    
    % Check accelerations
    if ~isempty(accelerations{i}) && isfield(accelerations{i}, 'aA_mag')
        aA(i) = accelerations{i}.aA_mag;
        aB(i) = accelerations{i}.aB_mag;
        aC(i) = accelerations{i}.aC_mag;
        aD(i) = accelerations{i}.aD_mag;
        alpha3(i) = accelerations{i}.alpha3;
        alpha4(i) = accelerations{i}.alpha4;
        alpha5(i) = accelerations{i}.alpha5;
    end
    
    % Check forces
    if ~isempty(forces{i}) && isfield(forces{i}, 'F12_mag')
        F12(i) = forces{i}.F12_mag;
        F23(i) = forces{i}.F23_mag;
        F34(i) = forces{i}.F34_mag;
        F45(i) = forces{i}.F45_mag;
        T2(i) = forces{i}.T2;
    end
end

fprintf('Creating plots with %d/%d valid positions...\n', sum(valid_mask), n);

%% FIGURE 1: Velocities
fig1 = figure('Position', [100, 100, 1400, 900], 'Color', 'w');

% Linear velocities
subplot(2,1,1);
hold on; grid on;
plot(theta2_deg, vA, 'r-', 'LineWidth', 2, 'DisplayName', 'v_A');
plot(theta2_deg, vB, 'g-', 'LineWidth', 2, 'DisplayName', 'v_B');
plot(theta2_deg, vC, 'm-', 'LineWidth', 2, 'DisplayName', 'v_C');
plot(theta2_deg, vD, 'c-', 'LineWidth', 2, 'DisplayName', 'v_D');
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Linear Velocity (mm/s)', 'FontSize', 12, 'FontWeight', 'bold');
title('Linear Velocities of Key Points', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
xlim([0 360]);
set(gca, 'FontSize', 11);
hold off;

% Angular velocities
subplot(2,1,2);
hold on; grid on;
plot(theta2_deg, omega3, 'b-', 'LineWidth', 2, 'DisplayName', 'ω_3');
plot(theta2_deg, omega4, 'g-', 'LineWidth', 2, 'DisplayName', 'ω_4');
plot(theta2_deg, omega5, 'm-', 'LineWidth', 2, 'DisplayName', 'ω_5');
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Angular Velocity (rad/s)', 'FontSize', 12, 'FontWeight', 'bold');
title('Angular Velocities of Links', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
xlim([0 360]);
set(gca, 'FontSize', 11);
hold off;

%% FIGURE 2: Accelerations
fig2 = figure('Position', [150, 150, 1400, 900], 'Color', 'w');

% Linear accelerations
subplot(2,1,1);
hold on; grid on;
plot(theta2_deg, aA/1000, 'r-', 'LineWidth', 2, 'DisplayName', 'a_A');
plot(theta2_deg, aB/1000, 'g-', 'LineWidth', 2, 'DisplayName', 'a_B');
plot(theta2_deg, aC/1000, 'm-', 'LineWidth', 2, 'DisplayName', 'a_C');
plot(theta2_deg, aD/1000, 'c-', 'LineWidth', 2, 'DisplayName', 'a_D');
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Linear Acceleration (m/s²)', 'FontSize', 12, 'FontWeight', 'bold');
title('Linear Accelerations of Key Points', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
xlim([0 360]);
set(gca, 'FontSize', 11);
hold off;

% Angular accelerations
subplot(2,1,2);
hold on; grid on;
plot(theta2_deg, alpha3, 'b-', 'LineWidth', 2, 'DisplayName', 'α_3');
plot(theta2_deg, alpha4, 'g-', 'LineWidth', 2, 'DisplayName', 'α_4');
plot(theta2_deg, alpha5, 'm-', 'LineWidth', 2, 'DisplayName', 'α_5');
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Angular Acceleration (rad/s²)', 'FontSize', 12, 'FontWeight', 'bold');
title('Angular Accelerations of Links', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
xlim([0 360]);
set(gca, 'FontSize', 11);
hold off;

%% FIGURE 3: Dynamic Forces
fig3 = figure('Position', [200, 200, 1400, 900], 'Color', 'w');

% Joint forces
subplot(2,1,1);
hold on; grid on;
plot(theta2_deg, F12, 'k-', 'LineWidth', 2, 'DisplayName', 'F_{12} (at O)');
plot(theta2_deg, F23, 'r-', 'LineWidth', 2, 'DisplayName', 'F_{23} (at A)');
plot(theta2_deg, F34, 'b-', 'LineWidth', 2, 'DisplayName', 'F_{34} (at B)');
plot(theta2_deg, F45, 'm-', 'LineWidth', 2, 'DisplayName', 'F_{45} (at C)');
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Force Magnitude (N)', 'FontSize', 12, 'FontWeight', 'bold');
title('Joint Reaction Forces', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
xlim([0 360]);
set(gca, 'FontSize', 11);
hold off;

% Driving torque
subplot(2,1,2);
hold on; grid on;
plot(theta2_deg, T2, 'r-', 'LineWidth', 2.5);
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Driving Torque (N·m)', 'FontSize', 12, 'FontWeight', 'bold');
title('Required Driving Torque', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0 360]);
grid on;
set(gca, 'FontSize', 11);
hold off;

%% FIGURE 4: Balancing Analysis
fig4 = figure('Position', [250, 250, 1400, 900], 'Color', 'w');

% Get valid indices from balance structure
valid_idx = balance.valid_indices;

% Shaking force comparison
subplot(2,2,1);
hold on; grid on;
plot(theta2_deg, balance.shaking_F_mag, 'r-', 'LineWidth', 2, 'DisplayName', 'Unbalanced');
plot(theta2_deg, balance.shaking_F_mag_bal, 'b--', 'LineWidth', 2, 'DisplayName', 'Balanced');
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Shaking Force (N)', 'FontSize', 11, 'FontWeight', 'bold');
title('Shaking Force Magnitude', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
xlim([0 360]);
set(gca, 'FontSize', 10);
hold off;

% X and Y components
subplot(2,2,2);
hold on; grid on;
plot(theta2_deg, balance.shaking_F_x, 'r-', 'LineWidth', 2, 'DisplayName', 'F_x');
plot(theta2_deg, balance.shaking_F_y, 'b-', 'LineWidth', 2, 'DisplayName', 'F_y');
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Force Component (N)', 'FontSize', 11, 'FontWeight', 'bold');
title('Shaking Force Components', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
xlim([0 360]);
set(gca, 'FontSize', 10);
hold off;

% Shaking moment
subplot(2,2,3);
hold on; grid on;
plot(theta2_deg, balance.shaking_M, 'k-', 'LineWidth', 2);
xlabel('Crank Angle θ_2 (degrees)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Shaking Moment (N·m)', 'FontSize', 11, 'FontWeight', 'bold');
title('Shaking Moment about Origin', 'FontSize', 13, 'FontWeight', 'bold');
xlim([0 360]);
grid on;
set(gca, 'FontSize', 10);
hold off;

% Balancing summary
subplot(2,2,4);
axis off;

y_pos = 0.9;
text(0.1, y_pos, 'BALANCING SUMMARY', 'FontSize', 14, 'FontWeight', 'bold', 'Units', 'normalized');
y_pos = y_pos - 0.12;

text(0.1, y_pos, 'Unbalanced Mechanism:', 'FontSize', 11, 'FontWeight', 'bold', 'Units', 'normalized');
y_pos = y_pos - 0.08;
text(0.15, y_pos, sprintf('RMS Force: %.2f N', balance.F_rms), 'FontSize', 10, 'Units', 'normalized');
y_pos = y_pos - 0.06;
text(0.15, y_pos, sprintf('Peak Force: %.2f N', balance.F_peak), 'FontSize', 10, 'Units', 'normalized');
y_pos = y_pos - 0.06;
text(0.15, y_pos, sprintf('RMS Moment: %.2f N·m', balance.M_rms), 'FontSize', 10, 'Units', 'normalized');
y_pos = y_pos - 0.12;

text(0.1, y_pos, 'Balanced with Counterweight:', 'FontSize', 11, 'FontWeight', 'bold', 'Units', 'normalized');
y_pos = y_pos - 0.08;
text(0.15, y_pos, sprintf('Mass: %.3f kg', balance.m_cw), 'FontSize', 10, 'Units', 'normalized');
y_pos = y_pos - 0.06;
text(0.15, y_pos, sprintf('Radius: %.1f mm', balance.r_cw*1000), 'FontSize', 10, 'Units', 'normalized');
y_pos = y_pos - 0.06;
text(0.15, y_pos, sprintf('RMS Force: %.2f N', balance.F_rms_bal), 'FontSize', 10, 'Units', 'normalized');
y_pos = y_pos - 0.06;
text(0.15, y_pos, sprintf('Reduction: %.1f%%', balance.force_reduction), 'FontSize', 10, 'Units', 'normalized');
y_pos = y_pos - 0.12;

text(0.1, y_pos, 'Optimized Design:', 'FontSize', 11, 'FontWeight', 'bold', 'Units', 'normalized', 'Color', [0 0.6 0]);
y_pos = y_pos - 0.08;
text(0.15, y_pos, sprintf('Mass: %.3f kg', balance.m_cw_opt), 'FontSize', 10, 'Units', 'normalized', 'Color', [0 0.6 0]);
y_pos = y_pos - 0.06;
text(0.15, y_pos, sprintf('Radius: %.1f mm', balance.r_cw_opt*1000), 'FontSize', 10, 'Units', 'normalized', 'Color', [0 0.6 0]);
y_pos = y_pos - 0.06;
text(0.15, y_pos, sprintf('RMS Force: %.2f N', balance.F_rms_opt), 'FontSize', 10, 'Units', 'normalized', 'Color', [0 0.6 0]);
y_pos = y_pos - 0.06;
reduction_opt = (1 - balance.F_rms_opt/balance.F_rms) * 100;
text(0.15, y_pos, sprintf('Reduction: %.1f%%', reduction_opt), 'FontSize', 10, 'Units', 'normalized', 'Color', [0 0.6 0]);

%% FIGURE 5: Additional Shaking Force Analysis
fig5 = figure('Position', [300, 300, 1400, 700], 'Color', 'w');

% Polar plot of shaking force
subplot(1,2,1);
polarplot(theta2_array(valid_idx), balance.shaking_F_mag(valid_idx), 'r-', 'LineWidth', 2);
hold on;
polarplot(theta2_array(valid_idx), balance.shaking_F_mag_bal(valid_idx), 'b--', 'LineWidth', 2);
title('Shaking Force - Polar View', 'FontSize', 13, 'FontWeight', 'bold');
legend('Unbalanced', 'Balanced', 'Location', 'best');
hold off;

% Force hodograph (Fx vs Fy)
subplot(1,2,2);
hold on; grid on; axis equal;
plot(balance.shaking_F_x(valid_idx), balance.shaking_F_y(valid_idx), 'r-', 'LineWidth', 2, 'DisplayName', 'Unbalanced');
plot(balance.shaking_F_x_bal(valid_idx), balance.shaking_F_y_bal(valid_idx), 'b--', 'LineWidth', 2, 'DisplayName', 'Balanced');
xlabel('F_x (N)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('F_y (N)', 'FontSize', 12, 'FontWeight', 'bold');
title('Shaking Force Hodograph', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
plot(0, 0, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
set(gca, 'FontSize', 11);
hold off;

fprintf('✓ All 5 figures created successfully\n');

end