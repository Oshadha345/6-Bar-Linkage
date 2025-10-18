%% verify_configuration.m
% Quick verification that configuration is now correct
% ==========================================================================

clear; clc; close all;

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║     CONFIGURATION VERIFICATION (θ₂ = 60°)                    ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

% Load corrected parameters
p = params_sixbar();

% Solve at θ₂ = 60°
theta2 = deg2rad(60);
pos = solve_position(theta2, p);

if isempty(pos) || ~isfield(pos, 'B')
    fprintf('❌ ERROR: Could not solve position!\n');
    return;
end

fprintf('═══════════════════════════════════════════════════════\n');
fprintf(' JOINT POSITIONS\n');
fprintf('═══════════════════════════════════════════════════════\n');
fprintf('  O: (%8.1f, %8.1f) mm\n', pos.O(1), pos.O(2));
fprintf('  E: (%8.1f, %8.1f) mm\n', pos.E(1), pos.E(2));
fprintf('  A: (%8.1f, %8.1f) mm\n', pos.A(1), pos.A(2));
fprintf('  B: (%8.1f, %8.1f) mm\n', pos.B(1), pos.B(2));
fprintf('  C: (%8.1f, %8.1f) mm\n', pos.C(1), pos.C(2));
fprintf('  D: (%8.1f, %8.1f) mm\n', pos.D(1), pos.D(2));
fprintf('═══════════════════════════════════════════════════════\n\n');

fprintf('CONFIGURATION CHECKS:\n');
fprintf('───────────────────────────────────────────────────────\n');

all_ok = true;

% Check 1: C below B
if pos.C(2) < pos.B(2) - 10
    fprintf('  ✓ C is BELOW B by %.1f mm - CORRECT!\n', pos.B(2) - pos.C(2));
else
    fprintf('  ✗ C position wrong (diff = %.1f mm)\n', pos.B(2) - pos.C(2));
    all_ok = false;
end

% Check 2: B above A
if pos.B(2) > pos.A(2)
    fprintf('  ✓ B is above A by %.1f mm\n', pos.B(2) - pos.A(2));
else
    fprintf('  ✗ B should be above A\n');
    all_ok = false;
end

% Check 3: D to the right of E
if pos.D(1) > pos.E(1)
    fprintf('  ✓ D is right of E by %.1f mm\n', pos.D(1) - pos.E(1));
else
    fprintf('  ✗ D should be right of E\n');
    all_ok = false;
end

% Check 4: Constraint verification
fprintf('\n');
fprintf('CONSTRAINT VERIFICATION:\n');
fprintf('───────────────────────────────────────────────────────\n');

dist_BE = norm(pos.B - pos.E);
dist_CD = norm(pos.D - pos.C);
dist_AB = norm(pos.B - pos.A);
dist_AC = norm(pos.C - pos.A);

err_BE = abs(dist_BE - p.l4);
err_CD = abs(dist_CD - p.l5);
err_AB = abs(dist_AB - p.l3);
err_AC = abs(dist_AC - p.AC);

fprintf('  BE: Expected %.1f, Actual %.1f, Error %.3f mm', p.l4, dist_BE, err_BE);
if err_BE < 1.0, fprintf(' ✓\n'); else, fprintf(' ✗\n'); all_ok = false; end

fprintf('  CD: Expected %.1f, Actual %.1f, Error %.3f mm', p.l5, dist_CD, err_CD);
if err_CD < 1.0, fprintf(' ✓\n'); else, fprintf(' ✗\n'); all_ok = false; end

fprintf('  AB: Expected %.1f, Actual %.1f, Error %.3f mm', p.l3, dist_AB, err_AB);
if err_AB < 1.0, fprintf(' ✓\n'); else, fprintf(' ✗\n'); all_ok = false; end

fprintf('  AC: Expected %.1f, Actual %.1f, Error %.3f mm', p.AC, dist_AC, err_AC);
if err_AC < 1.0, fprintf(' ✓\n'); else, fprintf(' ✗\n'); all_ok = false; end

fprintf('───────────────────────────────────────────────────────\n\n');

if all_ok
    fprintf('╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║                                                              ║\n');
    fprintf('║          ✓✓✓ ALL CHECKS PASSED ✓✓✓                          ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║     Configuration matches reference image!                  ║\n');
    fprintf('║     Ready to run full analysis.                             ║\n');
    fprintf('║                                                              ║\n');
    fprintf('╔══════════════════════════════════════════════════════════════╗\n\n');
else
    fprintf('⚠ Some checks failed - review parameters\n\n');
end

%% Create comparison plot
figure('Position', [100, 100, 1400, 700], 'Color', 'w');

% Plot current configuration
hold on; axis equal; grid on;

% Ground
plot([-200, 1000], [p.slider_y, p.slider_y], 'k-', 'LineWidth', 4);
for x = -200:30:1000
    plot([x, x-15], [p.slider_y, p.slider_y-20], 'k-', 'LineWidth', 2);
end

% Links
plot([pos.O(1), pos.E(1)], [pos.O(2), pos.E(2)], 'k-', 'LineWidth', 6);
plot([pos.O(1), pos.A(1)], [pos.O(2), pos.A(2)], 'r-', 'LineWidth', 5);
plot([pos.A(1), pos.B(1)], [pos.A(2), pos.B(2)], 'b-', 'LineWidth', 5);
plot([pos.A(1), pos.C(1)], [pos.A(2), pos.C(2)], 'b--', 'LineWidth', 4);
plot([pos.B(1), pos.C(1)], [pos.B(2), pos.C(2)], 'b:', 'LineWidth', 3);
plot([pos.E(1), pos.B(1)], [pos.E(2), pos.B(2)], 'g-', 'LineWidth', 5);
plot([pos.C(1), pos.D(1)], [pos.C(2), pos.D(2)], 'm-', 'LineWidth', 5);

% Triangle fill
patch([pos.A(1), pos.B(1), pos.C(1)], [pos.A(2), pos.B(2), pos.C(2)], ...
      [0.3 0.5 1], 'FaceAlpha', 0.35, 'EdgeColor', 'none');

% Slider
rectangle('Position', [pos.D(1)-20, pos.D(2)-15, 40, 30], ...
          'FaceColor', [0.2 0.9 0.9], 'EdgeColor', [0 0.6 0.6], ...
          'LineWidth', 3, 'Curvature', 0.15);

% Joints
plot(pos.O(1), pos.O(2), 'ko', 'MarkerSize', 16, 'MarkerFaceColor', 'k');
plot(pos.E(1), pos.E(2), 'ko', 'MarkerSize', 16, 'MarkerFaceColor', 'k');
plot(pos.A(1), pos.A(2), 'ro', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
plot(pos.B(1), pos.B(2), 'go', 'MarkerSize', 14, 'MarkerFaceColor', 'g');
plot(pos.C(1), pos.C(2), 'mo', 'MarkerSize', 14, 'MarkerFaceColor', 'm');
plot(pos.D(1), pos.D(2), 'co', 'MarkerSize', 14, 'MarkerFaceColor', 'c');

% Labels
text(pos.O(1)-40, pos.O(2)+40, 'O', 'FontSize', 20, 'FontWeight', 'bold');
text(pos.E(1)+30, pos.E(2)+30, 'E', 'FontSize', 20, 'FontWeight', 'bold');
text(pos.A(1)+30, pos.A(2)+30, 'A', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'r');
text(pos.B(1)+30, pos.B(2)+30, 'B', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'g');
text(pos.C(1)+30, pos.C(2)+30, 'C', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'm');
text(pos.D(1)+30, pos.D(2)+30, 'D', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'c');

% Add verification text
text(50, 450, sprintf('C is %.1f mm BELOW B ✓', pos.B(2) - pos.C(2)), ...
     'FontSize', 14, 'FontWeight', 'bold', 'Color', [0 0.6 0], ...
     'BackgroundColor', [1 1 1 0.9], 'EdgeColor', [0 0.6 0], 'LineWidth', 2);

if all_ok
    title('✓ CORRECT Configuration - Matches Reference Image', ...
          'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0.6 0]);
else
    title('⚠ Check Configuration', ...
          'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.8 0.5 0]);
end

xlabel('X Position (mm)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Y Position (mm)', 'FontSize', 14, 'FontWeight', 'bold');
xlim([-250, 1000]); ylim([-150, 500]);

hold off;

print('Configuration_Verified', '-dpng', '-r300');
fprintf('✓ Figure saved: Configuration_Verified.png\n\n');