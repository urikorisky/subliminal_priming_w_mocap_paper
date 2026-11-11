function plot_and_save_effect_sizes(effects_tbl, within_tbl)
    %% Generate Horizontal Whisker Plots and Save Scoped Bootstrap Effect Size Tables
    % Ordered in manuscript presentation order:
    %   1. TrajNorm_noStandardization (Plain vanilla / pre-registered preprocessing)
    %   2. TrajNorm_Standardization   (Within-participant standardization robustness)
    %   3. noTrajNorm_noStandardization (Post-hoc time-domain full trajectory analysis)

    out_dir_stats = '../statistics/';
    out_dir_figs  = fullfile('../figures/', 'Effect_Sizes');
    if ~exist(out_dir_stats, 'dir'), mkdir(out_dir_stats); end
    if ~exist(out_dir_figs, 'dir'), mkdir(out_dir_figs); end

    readable_names = containers.Map(...
        {'react', 'mt', 'mad', 'com', 'tot_dist', 'auc', 'ra', 'kb_rt', 'head_angle', 'iep', 'traj', 'x_std'}, ...
        {'Reaching Onset', 'Reaching Duration', 'Maximum Absolute Deviation (MAD)', 'Num of COM', ...
         'Total Distance Traveled', 'Area Under Curve (AUC)', 'Reach Area', 'Keyboard RT', ...
         'Heading Angle', 'Implied End Point (IEP)', 'Deviation From Center', 'Movement Variance (X-STD)'});

    % Canonical manuscript order of flavors
    manuscript_flavors = ["TrajNorm_noStandardization", "TrajNorm_Standardization", "noTrajNorm_noStandardization"];
    avail_flavors = unique(string(effects_tbl.Flavor), 'stable');
    flavors = intersect(manuscript_flavors, avail_flavors, 'stable');

    %% Plot 1: Standardized Effect Sizes per Flavor
    for iF = 1:length(flavors)
        f = flavors(iF);
        idx = string(effects_tbl.Flavor) == f;
        sub_tbl = effects_tbl(idx, :);
        if isempty(sub_tbl), continue; end

        fig = figure('Name', sprintf('Effect Sizes - %s', f), 'Color', 'w', 'Position', [80 80 1120 660]);
        ax = axes('Parent', fig);
        hold(ax, 'on');

        n_rows = height(sub_tbl);
        % Order top-to-bottom matching manuscript & comparison plot order
        y = n_rows : -1 : 1;
        vars = sub_tbl.Effect;

        readable_vars = strings(length(vars), 1);
        for v = 1:length(vars)
            if isKey(readable_names, char(vars(v)))
                readable_vars(v) = readable_names(char(vars(v)));
            else
                readable_vars(v) = strrep(char(vars(v)), '_', ' ');
            end
        end

        err_neg = sub_tbl.Reported_Effect_Size - sub_tbl.CI_Lower;
        err_pos = sub_tbl.CI_Upper - sub_tbl.Reported_Effect_Size;

        errorbar(ax, sub_tbl.Reported_Effect_Size, y, err_neg, err_pos, 'horizontal', 'o', ...
            'LineWidth', 1.6, 'MarkerSize', 8, 'MarkerFaceColor', [0.05 0.35 0.85], ...
            'Color', [0.00 0.45 0.74], 'CapSize', 10);

        [sorted_y, s_idx] = sort(y);
        set(ax, 'YTick', sorted_y, 'YTickLabel', readable_vars(s_idx), 'FontSize', 11.5);
        ylim(ax, [0.4, n_rows + 0.65]);
        min_x = min(0, min(sub_tbl.CI_Lower) - 0.1);
        max_x = max(sub_tbl.CI_Upper) + 0.65;
        xlim(ax, [min_x, max_x]);
        xlabel(ax, 'Standardized Effect Size (d_z / Dependent AKP)', 'FontSize', 13.5);

        desc_lines = get_descriptive_flavor_title(f, true);
        title(ax, desc_lines, 'FontSize', 12.5, 'FontWeight', 'bold', 'Interpreter', 'none');

        for j = 1:length(y)
            val_str = format_no_leading_zero(sub_tbl.Reported_Effect_Size(j));
            low_str = format_no_leading_zero(sub_tbl.CI_Lower(j));
            up_str  = format_no_leading_zero(sub_tbl.CI_Upper(j));

            txt = sprintf('%s [%s, %s]', val_str, low_str, up_str);
            text(ax, sub_tbl.CI_Upper(j) + 0.04, y(j), txt, 'VerticalAlignment', 'middle', 'FontSize', 10.5);
        end
        grid(ax, 'on');

        saveas(fig, fullfile(out_dir_figs, sprintf('Effect_Sizes_%s.fig', f)));
        exportgraphics(fig, fullfile(out_dir_figs, sprintf('Effect_Sizes_%s.png', f)), 'Resolution', 300);
        saveas(fig, fullfile(out_dir_figs, sprintf('Effect_Sizes_%s.svg', f)));
    end

    %% Plot 2: Effect Size Differences Compared to KB RT (Ordered Flavor 1 -> Flavor 2 -> Flavor 3, Top to Bottom)
    kb_idx = contains(within_tbl.Comparison, 'kb_rt');
    kb_tbl = within_tbl(kb_idx, :);

    fig2 = figure('Name', 'Effect Size Differences vs KB_RT', 'Color', 'w', 'Position', [60 40 1380 940]);
    ax2 = axes('Parent', fig2);
    hold(ax2, 'on');

    avail_kb_flavors = unique(string(kb_tbl.Flavor), 'stable');
    flavors_kb = intersect(manuscript_flavors, avail_kb_flavors, 'stable');

    actual_diff_array = zeros(height(kb_tbl), 1);
    ci_lower_array    = zeros(height(kb_tbl), 1);
    ci_upper_array    = zeros(height(kb_tbl), 1);
    y_positions       = zeros(height(kb_tbl), 1);
    y_labels          = cell(height(kb_tbl), 1);
    p_values_array    = zeros(height(kb_tbl), 1);

    for j = 1:height(kb_tbl)
        comp_parts = split(kb_tbl.Comparison(j), '_minus_');
        if strcmp(comp_parts{1}, 'kb_rt')
            var_name = comp_parts{2};
            actual_diff_array(j) = -kb_tbl.Effect_Size_Diff(j);
            ci_lower_array(j)    = -kb_tbl.CI_Upper(j);
            ci_upper_array(j)    = -kb_tbl.CI_Lower(j);
        else
            var_name = comp_parts{1};
            actual_diff_array(j) = kb_tbl.Effect_Size_Diff(j);
            ci_lower_array(j)    = kb_tbl.CI_Lower(j);
            ci_upper_array(j)    = kb_tbl.CI_Upper(j);
        end
        p_values_array(j) = kb_tbl.P_Value(j);

        if isKey(readable_names, char(var_name))
            var_clean = readable_names(char(var_name));
        else
            var_clean = strrep(char(var_name), '_', ' ');
        end
        y_labels{j} = char(var_clean);
    end

    min_x = min(ci_lower_array, [], 'omitnan') - 0.25;
    max_x = max(ci_upper_array, [], 'omitnan') + 1.45;
    x_banner_center = mean([min_x, max_x]);

    % Soft distinct background tints per flavor (1: blue tint, 2: green tint, 3: warm grey tint)
    flavor_bg_map = containers.Map( ...
        {'TrajNorm_noStandardization', 'TrajNorm_Standardization', 'noTrajNorm_noStandardization'}, ...
        {[0.90 0.95 1.00],             [0.93 0.99 0.93],           [0.95 0.95 0.95]});

    y_current = 0;
    header_specs = struct('y', {}, 'lines', {});

    % Build bottom-up so flavors_kb(1) = Flavor 1 sits at the TOP of the figure
    for iF = length(flavors_kb) : -1 : 1
        f = flavors_kb(iF);
        idx = find(string(kb_tbl.Flavor) == f);

        y_current = y_current + 1;
        y_bottom  = y_current - 0.55;

        y_positions(idx) = (y_current + length(idx) - 1) : -1 : y_current;
        y_current = y_current + length(idx) - 1;
        y_top     = y_current + 0.55;

        if isKey(flavor_bg_map, char(f))
            bg_col = flavor_bg_map(char(f));
        else
            bg_col = [0.95 0.95 0.95];
        end
        patch(ax2, [-10 10 10 -10], [y_bottom y_bottom y_top y_top], bg_col, 'EdgeColor', 'none', 'FaceAlpha', 0.55);
        plot(ax2, [0 0], [y_bottom y_top], 'k--', 'LineWidth', 1.5);

        desc_lines = get_descriptive_flavor_title(f, false);
        n_hdr_lines = numel(desc_lines);
        if n_hdr_lines >= 2
            y_current = y_current + 1.35;
            header_specs(end+1) = struct('y', y_current, 'lines', {desc_lines}); %#ok<AGROW>
            y_current = y_current + 0.95;
        else
            y_current = y_current + 1.10;
            header_specs(end+1) = struct('y', y_current, 'lines', {desc_lines}); %#ok<AGROW>
            y_current = y_current + 0.65;
        end
    end

    err_neg = actual_diff_array - ci_lower_array;
    err_pos = ci_upper_array - actual_diff_array;

    errorbar(ax2, actual_diff_array, y_positions, err_neg, err_pos, 'horizontal', 'o', ...
        'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'Color', 'r', 'CapSize', 10);

    % Draw section titles cleanly in the header bands between sections
    for h_i = 1:numel(header_specs)
        text(ax2, x_banner_center, header_specs(h_i).y, header_specs(h_i).lines, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontWeight', 'bold', 'FontSize', 11, 'Interpreter', 'none');
    end

    [sorted_y, sort_idx] = sort(y_positions);
    sorted_labels = y_labels(sort_idx);
    set(ax2, 'YTick', sorted_y, 'YTickLabel', sorted_labels, 'FontSize', 10.5);
    ylim(ax2, [0.1, y_current + 0.25]);
    xlim(ax2, [min_x, max_x]);
    xlabel(ax2, '\Delta Standardized Effect Size (Variable - KB RT)', 'FontSize', 14);
    title(ax2, 'Effect Size Differences Compared to KB RT', 'FontSize', 16, 'FontWeight', 'bold');

    for j = 1:height(kb_tbl)
        val_str = format_no_leading_zero(actual_diff_array(j));
        low_str = format_no_leading_zero(ci_lower_array(j));
        up_str  = format_no_leading_zero(ci_upper_array(j));

        p_val_str = sprintf('p=%.3f', p_values_array(j));
        p_val_str = strrep(p_val_str, 'p=0.', 'p=.');

        txt = sprintf('%s [%s, %s], %s', val_str, low_str, up_str, p_val_str);
        text(ax2, ci_upper_array(j) + 0.05, y_positions(j), txt, 'VerticalAlignment', 'middle', 'FontSize', 10);
    end
    grid(ax2, 'on');

    saveas(fig2, fullfile(out_dir_figs, 'dz_Differences_vs_KB_RT.fig'));
    exportgraphics(fig2, fullfile(out_dir_figs, 'dz_Differences_vs_KB_RT.png'), 'Resolution', 300);
    saveas(fig2, fullfile(out_dir_figs, 'dz_Differences_vs_KB_RT.svg'));

    %% Save Scoped Tables (Ordered Flavor 1 -> Flavor 2 -> Flavor 3)
    writetable(effects_tbl, fullfile(out_dir_stats, 'Effect_Sizes_Table.csv'));
    writetable(within_tbl,  fullfile(out_dir_stats, 'Within_Flavor_Comparisons.csv'));
    writetable(effects_tbl, fullfile(out_dir_stats, 'Effect_Sizes_Table.xlsx'));
    writetable(within_tbl,  fullfile(out_dir_stats, 'Within_Flavor_Comparisons.xlsx'));

    save(fullfile(out_dir_stats, 'Bootstrap_Stats_Tables.mat'), 'effects_tbl', 'within_tbl');
    disp('All effect size plots and tables successfully saved!');
end

function lines_out = get_descriptive_flavor_title(flavor_str, is_single_flavor_fig)
    switch char(flavor_str)
        case 'TrajNorm_noStandardization'
            lines_out = { ...
                'Main results section pre-registered and post-hoc variables, under pre-registered preprocessing procedure'; ...
                '(Trajectories normalized to %path, no within-participant standardization of discrete variables)' ...
            };
        case 'TrajNorm_Standardization'
            if is_single_flavor_fig
                lines_out = { ...
                    'Robustness analysis: Pre-registered trajectory normalization to %path,'; ...
                    'within-participant standardization of discrete variables' ...
                };
            else
                lines_out = {'Robustness analysis: Pre-registered trajectory normalization to %path, within-participant standardization of discrete variables'};
            end
        case 'noTrajNorm_noStandardization'
            lines_out = {'Post-hoc full trajectory time-domain analysis: Trajectories not normalized to %path'};
        otherwise
            lines_out = {strrep(char(flavor_str), '_', ' ')};
    end
end

function s = format_no_leading_zero(val)
    s = sprintf('%.2f', val);
    if startsWith(s, '0.')
        s = extractAfter(s, 1);
    elseif startsWith(s, '-0.')
        s = ['-' char(extractAfter(s, 2))];
    end
end
