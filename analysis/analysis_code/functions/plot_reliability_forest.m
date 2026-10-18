function fig_handle = plot_reliability_forest(Reliability_Table, out_dir)
%PLOT_RELIABILITY_FOREST Generates a publication-quality forest plot of
% Spearman-Brown corrected split-half reliability (5,000 random splits)
% for the 8 discrete manuscript metrics.
%
% Panel (a): Reliability of Congruency Difference Scores (Pearson r_SB & Spearman rho_SB)
% Panel (b): Reliability of Condition Means (Congruent vs. Incongruent, Pearson r_SB & Spearman rho_SB)

    if nargin < 2 || isempty(out_dir)
        out_dir = '../figures';
    end
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    % Filter tables by score type (keeping original metric order top-to-bottom)
    T_diff  = Reliability_Table(Reliability_Table.Score_Type == "Congruency_Diff", :);
    T_con   = Reliability_Table(Reliability_Table.Score_Type == "Congruent_Mean", :);
    T_incon = Reliability_Table(Reliability_Table.Score_Type == "Incongruent_Mean", :);

    n_metrics = height(T_diff);
    % Y-positions with extra breathing room above each category header:
    % Confirmatory: y = 8.8, 7.8 (header at 9.35, divider at 7.15)
    % Pre-Reg Exploratory: y = 6.2, 5.2, 4.2, 3.2 (header at 6.78, divider at 2.55)
    % Post-Hoc Exploratory: y = 1.6, 0.6 (header at 2.18)
    y_pos = [8.8; 7.8; 6.2; 5.2; 4.2; 3.2; 1.6; 0.6];
    sep_y = [7.15, 2.55];
    dy    = 0.16; % vertical offset between paired series

    fig_handle = figure('Name', 'Split-Half Reliability (Spearman-Brown, 5,000 Splits)', ...
        'Color', 'w', 'Position', [50, 60, 1500, 720], 'MenuBar', 'figure');
    try
        theme(fig_handle, 'light');
    catch
    end

    % Colors
    col_pearson  = [0.00, 0.35, 0.71]; % Deep blue
    col_spearman = [0.85, 0.33, 0.10]; % Warm orange-red
    col_con      = [0.00, 0.35, 0.71]; % Congruent blue
    col_incon    = [0.86, 0.20, 0.13]; % Incongruent red
    col_zero     = [0.45, 0.45, 0.45];
    col_div      = [0.75, 0.75, 0.75];

    %% ====================================================================
    %  PANEL A: Congruency Difference Score Reliability (Delta)
    %  ====================================================================
    ax1 = axes(fig_handle, 'Position', [0.155, 0.11, 0.405, 0.73]);
    hold(ax1, 'on');

    % Shaded category bands
    patch(ax1, [-0.50 1.68 1.68 -0.50], [7.15 7.15 9.65 9.65], [0.96 0.98 1.00], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    patch(ax1, [-0.50 1.68 1.68 -0.50], [0.05 0.05 2.55 2.55], [0.98 0.97 0.95], 'EdgeColor', 'none', 'HandleVisibility', 'off');

    % Reference vertical lines
    xline(ax1, 0, '--', 'Color', col_zero, 'LineWidth', 1.3, 'HandleVisibility', 'off');
    xline(ax1, 0.5, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    xline(ax1, 0.7, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    xline(ax1, 0.9, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    xline(ax1, 1.0, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 1.0, 'HandleVisibility', 'off');

    % Horizontal category dividers
    for s = 1:numel(sep_y)
        yline(ax1, sep_y(s), '-', 'Color', col_div, 'LineWidth', 1.3, 'HandleVisibility', 'off');
    end

    % Plot error bars for each metric
    for i = 1:n_metrics
        yk_p = y_pos(i) + dy;
        yk_s = y_pos(i) - dy;

        plot(ax1, [T_diff.Pearson_CI_Lower(i), T_diff.Pearson_CI_Upper(i)], [yk_p, yk_p], ...
            '-', 'Color', col_pearson, 'LineWidth', 2.2, 'HandleVisibility', 'off');
        plot(ax1, [T_diff.Spearman_CI_Lower(i), T_diff.Spearman_CI_Upper(i)], [yk_s, yk_s], ...
            '-', 'Color', col_spearman, 'LineWidth', 2.2, 'HandleVisibility', 'off');
    end

    h_p = plot(ax1, T_diff.Pearson_r_SB_Mean, y_pos + dy, 'o', ...
        'MarkerSize', 7.5, 'MarkerFaceColor', col_pearson, 'MarkerEdgeColor', 'w', 'LineWidth', 1.0, ...
        'DisplayName', 'Pearson r_{SB} (Mean \pm 95% CI)');
    h_s = plot(ax1, T_diff.Spearman_rho_SB_Mean, y_pos - dy, 'd', ...
        'MarkerSize', 7.5, 'MarkerFaceColor', col_spearman, 'MarkerEdgeColor', 'w', 'LineWidth', 1.0, ...
        'DisplayName', 'Spearman \rho_{SB} (Mean \pm 95% CI)');

    % Annotate numerical values in a clean right-hand column inside Panel A
    for i = 1:n_metrics
        txt_str = sprintf('r = %.2f [%.2f, %.2f]  |  \\rho = %.2f', ...
            T_diff.Pearson_r_SB_Mean(i), T_diff.Pearson_CI_Lower(i), T_diff.Pearson_CI_Upper(i), ...
            T_diff.Spearman_rho_SB_Mean(i));
        text(ax1, 1.03, y_pos(i), txt_str, 'FontSize', 9.5, 'FontName', 'Calibri', ...
            'Color', [0.15 0.15 0.15], 'VerticalAlignment', 'middle');
    end

    % Category headers in dedicated whitespace rows above each group
    text(ax1, -0.47, 9.38, 'Pre-Registered Confirmatory', 'FontSize', 10, 'FontName', 'Calibri', ...
        'FontWeight', 'bold', 'FontAngle', 'italic', 'Color', [0.18 0.32 0.52]);
    text(ax1, -0.47, 6.82, 'Pre-Registered Exploratory', 'FontSize', 10, 'FontName', 'Calibri', ...
        'FontWeight', 'bold', 'FontAngle', 'italic', 'Color', [0.30 0.30 0.30]);
    text(ax1, -0.47, 2.22, 'Post-Hoc Exploratory', 'FontSize', 10, 'FontName', 'Calibri', ...
        'FontWeight', 'bold', 'FontAngle', 'italic', 'Color', [0.48 0.32 0.18]);

    [y_ticks_sorted, sort_order] = sort(y_pos, 'ascend');
    set(ax1, 'YTick', y_ticks_sorted, 'YTickLabel', T_diff.Metric_Label(sort_order), ...
        'FontSize', 12, 'FontName', 'Calibri', 'LineWidth', 1.5, 'TickDir', 'out', 'Box', 'off');
    ylim(ax1, [0.05, 9.65]);
    xlim(ax1, [-0.50, 1.68]);
    xticks(ax1, -0.5:0.25:1.0);
    xlabel(ax1, 'Spearman–Brown Reliability (r_{SB} / \rho_{SB})', 'FontSize', 13, 'FontWeight', 'bold');

    t1 = title(ax1, '(a) Congruency Difference Score (\Delta = Incon - Con)', 'FontSize', 14, 'FontWeight', 'bold');
    t1.Units = 'normalized';
    t1.Position(2) = 1.11;

    lg1 = legend(ax1, [h_p, h_s], 'Orientation', 'horizontal', 'FontSize', 10.5, 'Box', 'off');
    lg1.Position = [0.18, 0.855, 0.35, 0.035];

    %% ====================================================================
    %  PANEL B: Condition Mean Reliability (Congruent vs. Incongruent)
    %  ====================================================================
    ax2 = axes(fig_handle, 'Position', [0.585, 0.11, 0.385, 0.73]);
    hold(ax2, 'on');

    patch(ax2, [0.42 1.34 1.34 0.42], [7.15 7.15 9.65 9.65], [0.96 0.98 1.00], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    patch(ax2, [0.42 1.34 1.34 0.42], [0.05 0.05 2.55 2.55], [0.98 0.97 0.95], 'EdgeColor', 'none', 'HandleVisibility', 'off');

    xline(ax2, 0.5, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    xline(ax2, 0.7, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    xline(ax2, 0.8, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    xline(ax2, 0.9, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    xline(ax2, 1.0, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 1.0, 'HandleVisibility', 'off');

    for s = 1:numel(sep_y)
        yline(ax2, sep_y(s), '-', 'Color', col_div, 'LineWidth', 1.3, 'HandleVisibility', 'off');
    end

    for i = 1:n_metrics
        yk_c = y_pos(i) + dy;
        yk_i = y_pos(i) - dy;

        plot(ax2, [T_con.Pearson_CI_Lower(i), T_con.Pearson_CI_Upper(i)], [yk_c, yk_c], ...
            '-', 'Color', col_con, 'LineWidth', 2.2, 'HandleVisibility', 'off');
        plot(ax2, [T_incon.Pearson_CI_Lower(i), T_incon.Pearson_CI_Upper(i)], [yk_i, yk_i], ...
            '-', 'Color', col_incon, 'LineWidth', 2.2, 'HandleVisibility', 'off');
    end

    h_c_p = plot(ax2, T_con.Pearson_r_SB_Mean, y_pos + dy, 'o', ...
        'MarkerSize', 7.5, 'MarkerFaceColor', col_con, 'MarkerEdgeColor', 'w', 'LineWidth', 1.0, ...
        'DisplayName', 'Congruent (Pearson r_{SB})');
    h_c_s = plot(ax2, T_con.Spearman_rho_SB_Mean, y_pos + dy, 'd', ...
        'MarkerSize', 6.0, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_con, 'LineWidth', 1.3, ...
        'DisplayName', 'Congruent (Spearman \rho_{SB})');

    h_i_p = plot(ax2, T_incon.Pearson_r_SB_Mean, y_pos - dy, 'o', ...
        'MarkerSize', 7.5, 'MarkerFaceColor', col_incon, 'MarkerEdgeColor', 'w', 'LineWidth', 1.0, ...
        'DisplayName', 'Incongruent (Pearson r_{SB})');
    h_i_s = plot(ax2, T_incon.Spearman_rho_SB_Mean, y_pos - dy, 'd', ...
        'MarkerSize', 6.0, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_incon, 'LineWidth', 1.3, ...
        'DisplayName', 'Incongruent (Spearman \rho_{SB})');

    for i = 1:n_metrics
        txt_str = sprintf('Con: r=%.2f (\\rho=%.2f) | Incon: r=%.2f (\\rho=%.2f)', ...
            T_con.Pearson_r_SB_Mean(i), T_con.Spearman_rho_SB_Mean(i), ...
            T_incon.Pearson_r_SB_Mean(i), T_incon.Spearman_rho_SB_Mean(i));
        text(ax2, 1.015, y_pos(i), txt_str, 'FontSize', 9.0, 'FontName', 'Calibri', ...
            'Color', [0.15 0.15 0.15], 'VerticalAlignment', 'middle');
    end

    set(ax2, 'YTick', y_ticks_sorted, 'YTickLabel', {}, ...
        'FontSize', 12, 'FontName', 'Calibri', 'LineWidth', 1.5, 'TickDir', 'out', 'Box', 'off');
    ylim(ax2, [0.05, 9.65]);
    xlim(ax2, [0.42, 1.34]);
    xticks(ax2, 0.5:0.1:1.0);
    xlabel(ax2, 'Spearman–Brown Reliability (r_{SB} / \rho_{SB})', 'FontSize', 13, 'FontWeight', 'bold');

    t2 = title(ax2, '(b) Condition Means (Congruent & Incongruent)', 'FontSize', 14, 'FontWeight', 'bold');
    t2.Units = 'normalized';
    t2.Position(2) = 1.11;

    lg2 = legend(ax2, [h_c_p, h_c_s, h_i_p, h_i_s], 'NumColumns', 2, 'FontSize', 10, 'Box', 'off');
    lg2.Position = [0.60, 0.848, 0.35, 0.050];

    % Save outputs
    base_fn = fullfile(out_dir, 'Fig_Split_Half_Reliability');
    saveas(fig_handle, [base_fn '.fig']);
    exportgraphics(fig_handle, [base_fn '.png'], 'Resolution', 300);
    try
        saveas(fig_handle, [base_fn '.svg']);
    catch
    end
    fprintf('Saved reliability forest plot to: %s (.fig, .png, .svg)\n', base_fn);
end
