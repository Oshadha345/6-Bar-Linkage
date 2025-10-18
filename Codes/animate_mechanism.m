function animate_mechanism(positions, p, options)
%% animate_mechanism.m
% Create high-quality animation with automatic format detection
% Tries MP4 first, falls back to AVI if needed
% ==========================================================================

if nargin < 3
    options.save_video = false;
    options.video_name = 'sixbar_animation.mp4';
    options.frame_rate = 30;
    options.show_trails = true;
end

n_frames = length(positions);

% Count valid frames
valid_count = 0;
valid_indices = [];
for i = 1:n_frames
    if ~isempty(positions{i}) && isfield(positions{i}, 'A') && isfield(positions{i}, 'B')
        valid_count = valid_count + 1;
        valid_indices = [valid_indices, i];
    end
end

fprintf('Animation: %d/%d valid frames (%.1f%%)\n', valid_count, n_frames, 100*valid_count/n_frames);

if valid_count < 10
    fprintf('⚠ Warning: Too few valid frames for animation (need at least 10)\n');
    return;
end

%% Calculate dynamic axis limits to fit all motion
fprintf('Calculating optimal viewport...\n');

x_min = inf; x_max = -inf;
y_min = inf; y_max = -inf;

for i = valid_indices
    pos = positions{i};
    
    % Check all points
    all_x = [p.O(1), p.E(1), pos.A(1), pos.B(1), pos.C(1), pos.D(1)];
    all_y = [p.O(2), p.E(2), pos.A(2), pos.B(2), pos.C(2), pos.D(2)];
    
    x_min = min(x_min, min(all_x));
    x_max = max(x_max, max(all_x));
    y_min = min(y_min, min(all_y));
    y_max = max(y_max, max(all_y));
end

% Add padding (20% extra space)
x_range = x_max - x_min;
y_range = y_max - y_min;

x_padding = 0.2 * x_range;
y_padding = 0.25 * y_range;

x_limits = [x_min - x_padding, x_max + x_padding];
y_limits = [y_min - y_padding, y_max + y_padding];

% Make sure ground is visible
y_limits(1) = min(y_limits(1), p.slider_y - 50);

fprintf('  Viewport: X [%.1f, %.1f] mm, Y [%.1f, %.1f] mm\n', ...
        x_limits(1), x_limits(2), y_limits(1), y_limits(2));

%% Create figure with white background
fig = figure('Position', [50, 50, 1600, 1000], 'Color', 'w');

%% Initialize video writer with format fallback
if options.save_video
    [filepath, name, ext] = fileparts(options.video_name);
    
    % Determine desired format
    if strcmpi(ext, '.mp4')
        desired_format = 'mp4';
    else
        desired_format = 'avi';
    end
    
    video_created = false;
    format_used = '';
    
    % Try different formats in order of preference
    if strcmpi(desired_format, 'mp4')
        % Try MP4 formats
        formats_to_try = {
            'MPEG-4',           [name '.mp4'];
            'Motion JPEG AVI',  [name '.avi'];
            'Uncompressed AVI', [name '.avi']
        };
    else
        % Try AVI formats
        formats_to_try = {
            'Motion JPEG AVI',  [name '.avi'];
            'Uncompressed AVI', [name '.avi']
        };
    end
    
    for fmt_idx = 1:size(formats_to_try, 1)
        profile = formats_to_try{fmt_idx, 1};
        filename = fullfile(filepath, formats_to_try{fmt_idx, 2});
        
        try
            fprintf('  Trying format: %s...\n', profile);
            v = VideoWriter(filename, profile);
            v.FrameRate = options.frame_rate;
            
            % Set quality if supported
            if isprop(v, 'Quality')
                v.Quality = 95;
            end
            
            open(v);
            
            % Success!
            video_created = true;
            format_used = profile;
            options.video_name = filename;
            fprintf('  ✓ Using format: %s\n', profile);
            fprintf('  Recording to: %s\n', filename);
            break;
            
        catch ME
            fprintf('  ✗ Format not available: %s\n', profile);
            if exist('v', 'var')
                try
                    delete(v);
                catch
                end
            end
        end
    end
    
    if ~video_created
        fprintf('⚠ Warning: Could not create video file with any format!\n');
        fprintf('  Animation will play without saving.\n');
        options.save_video = false;
    end
end

% Trail storage
if options.show_trails
    trail_A = nan(2, n_frames);
    trail_B = nan(2, n_frames);
    trail_C = nan(2, n_frames);
    trail_D = nan(2, n_frames);
end

fprintf('Generating animation frames...\n');
progress_step = max(1, floor(n_frames / 20));

%% Animation Loop
frames_rendered = 0;

for frame = 1:n_frames
    % Check if this frame is valid
    if isempty(positions{frame}) || ~isfield(positions{frame}, 'A') || ~isfield(positions{frame}, 'B')
        continue;
    end
    
    clf;
    hold on;
    axis equal;
    grid on;
    set(gca, 'FontSize', 12, 'LineWidth', 1.5);
    
    pos = positions{frame};
    
    % Store trail points
    if options.show_trails
        trail_A(:, frame) = pos.A;
        trail_B(:, frame) = pos.B;
        trail_C(:, frame) = pos.C;
        trail_D(:, frame) = pos.D;
    end
    
    % Set axis limits
    xlim(x_limits);
    ylim(y_limits);
    
    %% Draw Ground
    ground_x = [x_limits(1), x_limits(2)];
    ground_y = [p.slider_y, p.slider_y];
    plot(ground_x, ground_y, 'k-', 'LineWidth', 4);
    
    % Ground hatching
    hatch_spacing = 25;
    for x = ground_x(1):hatch_spacing:ground_x(2)
        plot([x, x-12], [p.slider_y, p.slider_y-15], 'k-', 'LineWidth', 1.5);
    end
    
    % Ground fill
    patch([ground_x, fliplr(ground_x)], ...
          [ground_y, [p.slider_y-20, p.slider_y-20]], ...
          [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    
    %% Draw Fixed Ground Link OE
    plot([p.O(1), p.E(1)], [p.O(2), p.E(2)], 'k-', 'LineWidth', 6);
    
    %% Draw Links
    % Link 2 (Crank OA) - RED
    plot([p.O(1), pos.A(1)], [p.O(2), pos.A(2)], '-', ...
         'Color', [0.9 0.1 0.1], 'LineWidth', 8);
    
    % Link 3 (Triangular Coupler ABC) - BLUE
    patch([pos.A(1), pos.B(1), pos.C(1)], ...
          [pos.A(2), pos.B(2), pos.C(2)], ...
          [0.2 0.4 0.9], 'FaceAlpha', 0.35, 'EdgeColor', 'none');
    
    plot([pos.A(1), pos.B(1)], [pos.A(2), pos.B(2)], '-', ...
         'Color', [0.1 0.2 0.8], 'LineWidth', 7);
    plot([pos.A(1), pos.C(1)], [pos.A(2), pos.C(2)], '--', ...
         'Color', [0.1 0.2 0.8], 'LineWidth', 5);
    plot([pos.B(1), pos.C(1)], [pos.B(2), pos.C(2)], ':', ...
         'Color', [0.1 0.2 0.8], 'LineWidth', 4);
    
    % Link 4 (EB) - GREEN
    plot([p.E(1), pos.B(1)], [p.E(2), pos.B(2)], '-', ...
         'Color', [0.1 0.7 0.1], 'LineWidth', 7);
    
    % Link 5 (CD) - MAGENTA
    plot([pos.C(1), pos.D(1)], [pos.C(2), pos.D(2)], '-', ...
         'Color', [0.8 0.1 0.6], 'LineWidth', 7);
    
    % Slider (Link 6) - CYAN
    slider_w = 25;
    slider_h = 20;
    rectangle('Position', [pos.D(1)-slider_w/2, pos.D(2)-slider_h/2, slider_w, slider_h], ...
              'FaceColor', [0.2 0.9 0.9], 'EdgeColor', [0 0.6 0.6], ...
              'LineWidth', 3, 'Curvature', 0.15);
    
    %% Draw Trails
    if options.show_trails && frame > 1
        valid_trail = ~isnan(trail_A(1, 1:frame));
        
        if sum(valid_trail) > 1
            plot(trail_A(1, valid_trail), trail_A(2, valid_trail), 'r-', ...
                 'LineWidth', 1.8, 'Color', [1 0.4 0.4 0.5]);
            plot(trail_B(1, valid_trail), trail_B(2, valid_trail), 'g-', ...
                 'LineWidth', 1.8, 'Color', [0.4 1 0.4 0.5]);
            plot(trail_C(1, valid_trail), trail_C(2, valid_trail), 'm-', ...
                 'LineWidth', 1.8, 'Color', [1 0.4 1 0.5]);
            plot(trail_D(1, valid_trail), trail_D(2, valid_trail), 'c-', ...
                 'LineWidth', 2.2, 'Color', [0.4 1 1 0.7]);
        end
    end
    
    %% Draw Joints
    joint_radius = 7;
    shadow_offset = 2.5;
    
    % Fixed pivots
    viscircles([p.O(1)+shadow_offset, p.O(2)-shadow_offset], joint_radius+1, ...
               'Color', [0.3 0.3 0.3], 'LineWidth', 2, 'EnhanceVisibility', false);
    viscircles([p.O(1), p.O(2)], joint_radius, 'Color', 'k', 'LineWidth', 3);
    plot(p.O(1), p.O(2), 'ko', 'MarkerSize', 14, 'MarkerFaceColor', 'k');
    
    viscircles([p.E(1)+shadow_offset, p.E(2)-shadow_offset], joint_radius+1, ...
               'Color', [0.3 0.3 0.3], 'LineWidth', 2, 'EnhanceVisibility', false);
    viscircles([p.E(1), p.E(2)], joint_radius, 'Color', 'k', 'LineWidth', 3);
    plot(p.E(1), p.E(2), 'ko', 'MarkerSize', 14, 'MarkerFaceColor', 'k');
    
    % Moving joints
    viscircles([pos.A(1), pos.A(2)], joint_radius, 'Color', [0.7 0 0], 'LineWidth', 2.5);
    plot(pos.A(1), pos.A(2), 'o', 'MarkerSize', 12, 'MarkerFaceColor', [1 0.3 0.3], ...
         'MarkerEdgeColor', [0.7 0 0], 'LineWidth', 2.5);
    
    viscircles([pos.B(1), pos.B(2)], joint_radius, 'Color', [0 0.5 0], 'LineWidth', 2.5);
    plot(pos.B(1), pos.B(2), 'o', 'MarkerSize', 12, 'MarkerFaceColor', [0.3 1 0.3], ...
         'MarkerEdgeColor', [0 0.5 0], 'LineWidth', 2.5);
    
    viscircles([pos.C(1), pos.C(2)], joint_radius, 'Color', [0.6 0 0.4], 'LineWidth', 2.5);
    plot(pos.C(1), pos.C(2), 'o', 'MarkerSize', 12, 'MarkerFaceColor', [1 0.3 0.8], ...
         'MarkerEdgeColor', [0.6 0 0.4], 'LineWidth', 2.5);
    
    viscircles([pos.D(1), pos.D(2)], joint_radius, 'Color', [0 0.5 0.5], 'LineWidth', 2.5);
    plot(pos.D(1), pos.D(2), 'o', 'MarkerSize', 12, 'MarkerFaceColor', [0.3 1 1], ...
         'MarkerEdgeColor', [0 0.5 0.5], 'LineWidth', 2.5);
    
    %% Labels
    label_offset = 15;
    
    text(p.O(1)-25, p.O(2)+20, 'O', 'FontSize', 22, 'FontWeight', 'bold', ...
         'Color', 'k', 'BackgroundColor', [1 1 1 0.9], 'EdgeColor', 'k', 'LineWidth', 2, 'Margin', 3);
    
    text(p.E(1)+label_offset, p.E(2)+label_offset, 'E', 'FontSize', 22, 'FontWeight', 'bold', ...
         'Color', 'k', 'BackgroundColor', [1 1 1 0.9], 'EdgeColor', 'k', 'LineWidth', 2, 'Margin', 3);
    
    text(pos.A(1)+label_offset, pos.A(2)+label_offset, 'A', 'FontSize', 22, 'FontWeight', 'bold', ...
         'Color', [0.8 0 0], 'BackgroundColor', [1 0.9 0.9 0.95], ...
         'EdgeColor', [0.8 0 0], 'LineWidth', 2, 'Margin', 3);
    
    text(pos.B(1)+label_offset, pos.B(2)+label_offset, 'B', 'FontSize', 22, 'FontWeight', 'bold', ...
         'Color', [0 0.6 0], 'BackgroundColor', [0.9 1 0.9 0.95], ...
         'EdgeColor', [0 0.6 0], 'LineWidth', 2, 'Margin', 3);
    
    text(pos.C(1)+label_offset, pos.C(2)+label_offset, 'C', 'FontSize', 22, 'FontWeight', 'bold', ...
         'Color', [0.7 0 0.5], 'BackgroundColor', [1 0.9 1 0.95], ...
         'EdgeColor', [0.7 0 0.5], 'LineWidth', 2, 'Margin', 3);
    
    text(pos.D(1), pos.D(2)+30, 'D', 'FontSize', 22, 'FontWeight', 'bold', ...
         'Color', [0 0.7 0.7], 'BackgroundColor', [0.9 1 1 0.95], ...
         'EdgeColor', [0 0.7 0.7], 'LineWidth', 2, 'Margin', 3);
    
    centroid_ABC = [(pos.A(1) + pos.B(1) + pos.C(1))/3, (pos.A(2) + pos.B(2) + pos.C(2))/3];
    text(centroid_ABC(1), centroid_ABC(2), 'Link 3', 'FontSize', 14, 'FontWeight', 'bold', ...
         'Color', [0.1 0.2 0.8], 'HorizontalAlignment', 'center', ...
         'BackgroundColor', [1 1 1 0.7], 'EdgeColor', [0.1 0.2 0.8], 'LineWidth', 2, 'Margin', 4);
    
    %% Title and Info
    theta2_deg = rad2deg(pos.theta2);
    title(sprintf('Six-Bar Linkage Mechanism  |  Crank Angle θ₂ = %.1f°  |  Frame %d/%d', ...
                  theta2_deg, frame, n_frames), ...
          'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.5]);
    
    xlabel('X Position (mm)', 'FontSize', 15, 'FontWeight', 'bold');
    ylabel('Y Position (mm)', 'FontSize', 15, 'FontWeight', 'bold');
    
    info_text = sprintf('ω₂ = %.1f rad/s\nl₂ = %.0f mm\nl₃ = %.0f mm\nβ = %.1f°', ...
                        p.omega2, p.l2, p.l3, p.beta_deg);
    annotation('textbox', [0.02, 0.82, 0.13, 0.13], 'String', info_text, ...
               'FontSize', 12, 'FontWeight', 'bold', ...
               'BackgroundColor', [0.95 0.95 1 0.95], ...
               'EdgeColor', [0.2 0.2 0.8], 'LineWidth', 2, ...
               'FitBoxToText', 'on', 'Margin', 6);
    
    annotation('textbox', [0.78, 0.02, 0.2, 0.05], ...
               'String', sprintf('Oshadha345\n2025-01-16'), ...
               'FontSize', 10, 'FontWeight', 'bold', ...
               'BackgroundColor', [1 1 1 0.8], 'EdgeColor', 'k', ...
               'LineWidth', 1.5, 'HorizontalAlignment', 'right', 'Margin', 4);
    
    hold off;
    
    % Capture frame
    drawnow;
    
    if options.save_video
        try
            frame_img = getframe(fig);
            writeVideo(v, frame_img);
            frames_rendered = frames_rendered + 1;
        catch ME
            fprintf('  Warning: Failed to capture frame %d: %s\n', frame, ME.message);
        end
    else
        pause(0.03);
    end
    
    % Progress
    if mod(frame, progress_step) == 0 || frame == n_frames
        fprintf('  Progress: %3.0f%% (%d/%d frames)\n', 100*frame/n_frames, frame, n_frames);
    end
end

%% Close video
if options.save_video
    close(v);
    
    [~, ~, ext] = fileparts(options.video_name);
    fprintf('\n✓ Animation saved: %s\n', options.video_name);
    fprintf('  Format: %s\n', format_used);
    fprintf('  Extension: %s\n', upper(ext(2:end)));
    fprintf('  Frames rendered: %d\n', frames_rendered);
    fprintf('  Frame rate: %d fps\n', options.frame_rate);
    
    if exist(options.video_name, 'file')
        file_info = dir(options.video_name);
        fprintf('  File size: %.2f MB\n', file_info.bytes / 1024^2);
    end
end

close(fig);

fprintf('✓ Animation complete!\n');

end