% Define key times for labeling
highlightTimes = [5, 10, 20, 100]; % Key times in years
timeTolerance = 1.92; % Tolerance for matching times (in years)

% Create the tiled layout for 1 and 2 std deviation plots
tiledlayout(1, 2, 'TileSpacing', 'Compact', 'Padding', 'Compact');

% Loop through for each subplot (1 and 2 std deviations)
for subplotIndex = 1:2
    % Create a subplot
    nexttile;
    hold on;

    % Display the shapefiles
    mapshow(shape1, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'k', 'DisplayType', 'polygon');
    mapshow(shape2, 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', 'none', 'DisplayType', 'polygon');

    % Loop through each pathway
    for i = 1:numPathways
        % Extract pathway data
        x_label = sprintf('x%dx', i);
        y_label = sprintf('x%dy', i);
        a_label = sprintf('x%da', i);
        b_label = sprintf('x%db', i);
        t_label = sprintf('t%d', i); % Time column (no 'x' prefix)

        x_data = data.(x_label);
        y_data = data.(y_label);
        a_data = data.(a_label);
        b_data = data.(b_label);
        t_data = data.(t_label); % Time data in years

        % Normalize ellipse areas for color mapping
        areas = pi * a_data .* b_data; % Area of ellipses
        norm_areas = (areas - min(areas)) / (max(areas) - min(areas)); % Normalize to [0, 1]

        % Connect the points with a curve
        plot(x_data, y_data, 'k-', 'LineWidth', 1, 'HandleVisibility', 'off');

        % Plot ellipses at each point
        for j = 1:(length(x_data) - 1)
            % Current and next point for rotation calculation
            x1 = x_data(j); y1 = y_data(j);
            x2 = x_data(j + 1); y2 = y_data(j + 1);

            % Calculate rotation angle
            A = atan2((y2 - y1), (x2 - x1)); % Angle in radians

            % Ellipse parameters
            h = x1; % Center x
            k = y1; % Center y
            a = a_data(j); % Semi-major axis
            b = b_data(j); % Semi-minor axis

            % Generate ellipse points
            theta = linspace(0, 2 * pi, 100);
            x_ellipse = a * cos(theta);
            y_ellipse = b * sin(theta);

            % Apply rotation matrix
            x_rot = x_ellipse * cos(A) - y_ellipse * sin(A);
            y_rot = x_ellipse * sin(A) + y_ellipse * cos(A);

            % Translate to ellipse center
            x_final = x_rot + h;
            y_final = y_rot + k;

            % Determine the color based on the area
            color1 = colorGradient(norm_areas(j));

            % Plot the ellipses
            if subplotIndex == 1
                % 1 std deviation
                fill(x_final, y_final, color1, 'EdgeColor', 'none', 'FaceAlpha', 0.8, 'HandleVisibility', 'off');
            else
                % 2 std deviation
                a2 = 2 * a; % Double semi-major axis
                b2 = 2 * b; % Double semi-minor axis
                x_ellipse2 = a2 * cos(theta);
                y_ellipse2 = b2 * sin(theta);

                % Apply rotation matrix for 2 std deviation
                x_rot2 = x_ellipse2 * cos(A) - y_ellipse2 * sin(A);
                y_rot2 = x_ellipse2 * sin(A) + y_ellipse2 * cos(A);

                % Translate to ellipse center
                x_final2 = x_rot2 + h;
                y_final2 = y_rot2 + k;

                % Determine the color for the larger ellipse
                color2 = colorGradient(norm_areas(j)); % Reuse same normalized area
                fill(x_final2, y_final2, color2, 'EdgeColor', 'none', 'FaceAlpha', 0.8, 'HandleVisibility', 'off');
            end
        end

        

        % Highlight key timestamps and the last time
        for timeIndex = 1:length(highlightTimes) + 1
            % If it's the last timestamp
            if timeIndex == length(highlightTimes) + 1
                idx = length(t_data); % Use the final point in the data
            else
                % Find the closest timestamp to the current highlight time
                [timeDiff, idx] = min(abs(t_data - highlightTimes(timeIndex)));
                if timeDiff > timeTolerance
                    continue; % Skip if no timestamp is within the tolerance
                end
            end

            % Highlighted ellipse parameters
            h = x_data(idx);
            k = y_data(idx);
            if subplotIndex == 1
                % 1 std deviation
                a = a_data(idx);
                b = b_data(idx);
            else
                % 2 std deviation
                a = 2 * a_data(idx);
                b = 2 * b_data(idx);
            end
            A = atan2((y_data(min(idx+1, end)) - y_data(max(idx-1, 1))), ...
                      (x_data(min(idx+1, end)) - x_data(max(idx-1, 1)))); % Use adjacent points

            % Generate ellipse points
            x_ellipse = a * cos(theta);
            y_ellipse = b * sin(theta);

            % Apply rotation and translation
            x_rot = x_ellipse * cos(A) - y_ellipse * sin(A);
            y_rot = x_ellipse * sin(A) + y_ellipse * cos(A);
            x_final = x_rot + h;
            y_final = y_rot + k;

            % Draw black outline for these key ellipses
            plot(x_final, y_final, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

            % Highlight the last timestamp in red
            if timeIndex == length(highlightTimes) + 1
                plot(x_final, y_final, 'r-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
            end

            % Add a label for the timestamp
            if timeIndex <= length(highlightTimes)
                label = sprintf('%d yr', highlightTimes(timeIndex));
            else
                label = sprintf('%d yr', round(t_data(idx)));
            end
            text(h, k, label, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 8, ...
                'FontWeight', 'bold');
        end
    end

    % Customize the subplot
    xlabel('UTM X Coordinate');
    ylabel('UTM Y Coordinate');
    grid off;
    if subplotIndex == 1
        title('1 Std Dev Ellipses');
    else
        title('2 Std Dev Ellipses');
    end

    hold off;
end

% Finalize the figure
sgtitle('French Island Contaminant Pathways with Highlighted Ellipses at Specific Times');

