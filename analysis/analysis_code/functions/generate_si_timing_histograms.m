function generate_si_timing_histograms(procFolder, good_subs, all_subs, out_fig_dir)
% GENERATE_SI_TIMING_HISTOGRAMS Generates timing distribution plots (Onset time,
% Movement Duration, and Overall Response Duration) for each participant (all 42),
% contrasting distributions with vs without time-sensitive exclusion criteria.
%
% Visualizations produced:
%   1. 42 individual participant figures (Sub_XX_timing_histograms.png / .pdf)
%      displayed as smoothed lines connecting the mid-top points of each bar
%      (no surface/bar display, minimal ink).
%   2. Consolidated group-level summary figure (Group_Summary_Timing_Histograms.png / .pdf)
%      with smoothed lines for pooled trials.
%   3. All-Participants Consolidated Distribution Figure (All_Participants_Timing_Distributions.png / .pdf)
%      broken into two columns (Valid Participants N=30 vs Excluded Participants N=12)
%      across all 3 timing measures, showing every participant's distribution as a thin
%      smoothed line plus the bold grand mean curve.
%   4. All-Participants 2-Column Small-Multiples Grid (All_Participants_2Column_Grid.png / .pdf)
%      arranging all 42 participants into 2 columns (21 rows x 2 cols) showing
%      individual participant timing profiles.

    if nargin < 1 || isempty(procFolder)
        procFolder = '../processed_data/nonStandardized_TrajNorm';
    end
    if nargin < 2 || isempty(good_subs)
        good_subs = [47, 49:51, 53:57, 59, 62, 65:67, 70:72, 75:85, 88, 90];
    end
    if nargin < 3 || isempty(all_subs)
        all_subs = [47, 49:85, 87:90];
    end
    if nargin < 4 || isempty(out_fig_dir)
        out_fig_dir = '../figures/SI_Participant_Time_Histograms';
    end

    if ~exist(out_fig_dir, 'dir')
        mkdir(out_fig_dir);
    end

    bt_file = fullfile(procFolder, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat');
    bt = load(bt_file);

    time_crit = ["early_res", "late_res", "slow_mvmnt", "very_slow_mvmnt"];

    % Colors for lines (Tufte-style minimal ink)
    col_wo = [0.85, 0.35, 0.35]; % Coral/crimson for Without Time Exclusions
    col_w  = [0.15, 0.45, 0.80]; % Steel blue for With Time Exclusions

    % Bin configurations
    edges_onset = 0:25:700;
    edges_mt    = 100:25:900;
    edges_rt    = 200:40:1500;

    x_fine_onset = linspace(0, 700, 300);
    x_fine_mt    = linspace(100, 900, 300);
    x_fine_rt    = linspace(200, 1500, 300);

    % Data structures for group and multi-participant plots
    group_onset_without = [];
    group_onset_with    = [];
    group_mt_without    = [];
    group_mt_with       = [];
    group_rt_without    = [];
    group_rt_with       = [];

    sub_data = struct();

    fprintf('Generating SI timing distribution figures (smoothed lines, minimal ink) for %d participants...\n', numel(all_subs));

    for s_idx = 1:numel(all_subs)
        s = all_subs(s_idx);
        is_valid_sub = ismember(s, good_subs);
        if is_valid_sub
            status_str = 'Valid Participant';
        else
            status_str = 'Excluded Participant';
        end

        r_file = fullfile(procFolder, sprintf('sub%dday2_reach_data_proc.mat', s));
        r_loaded = load(r_file);
        r_tbl = r_loaded.reach_data_table;
        r_tbl(r_tbl.practice >= 1, :) = [];
        r_bt = bt.reach_bad_trials{s};

        % Extract timing (in ms)
        onset_ms = r_tbl.onset * 1000;
        offset_ms = r_tbl.offset * 1000;
        mt_ms = (r_tbl.offset - r_tbl.onset) * 1000;

        % Technical non-time criteria
        nontime_reasons = setdiff(string(r_bt.Properties.VariableNames), ["any", "incorrect", "slow_mvmnt", "loop", time_crit]);
        bad_nontime = any(r_bt{:, cellstr(nontime_reasons)} > 0, 2);

        % Without time-sensitive exclusions (ignoring early_res, late_res, slow_mvmnt, very_slow_mvmnt)
        mask_without = ~bad_nontime & (r_tbl.pas == 1) & (r_tbl.target_correct == 1);

        % With time-sensitive exclusions (standard pre-registered)
        time_bad = (r_bt.early_res > 0) | (r_bt.late_res > 0) | (r_bt.very_slow_mvmnt > 0);
        mask_with = mask_without & ~time_bad;

        % Participant data
        p_onset_wo = onset_ms(mask_without);
        p_onset_w  = onset_ms(mask_with);

        p_mt_wo    = mt_ms(mask_without);
        p_mt_w     = mt_ms(mask_with);

        p_rt_wo    = offset_ms(mask_without);
        p_rt_w     = offset_ms(mask_with);

        % Store for group accumulation
        group_onset_without = [group_onset_without; p_onset_wo];
        group_onset_with    = [group_onset_with; p_onset_w];
        group_mt_without    = [group_mt_without; p_mt_wo];
        group_mt_with       = [group_mt_with; p_mt_w];
        group_rt_without    = [group_rt_without; p_rt_wo];
        group_rt_with       = [group_rt_with; p_rt_w];

        % Store for multi-participant combined plot
        sub_data(s_idx).sub = s;
        sub_data(s_idx).is_valid = is_valid_sub;
        sub_data(s_idx).onset_n_wo = numel(p_onset_wo); sub_data(s_idx).onset_n_w = numel(p_onset_w);
        sub_data(s_idx).onset_wo = get_smooth_line(p_onset_wo, edges_onset, x_fine_onset, true);
        sub_data(s_idx).onset_w  = get_smooth_line(p_onset_w,  edges_onset, x_fine_onset, true);
        sub_data(s_idx).mt_n_wo = numel(p_mt_wo);       sub_data(s_idx).mt_n_w = numel(p_mt_w);
        sub_data(s_idx).mt_wo = get_smooth_line(p_mt_wo, edges_mt, x_fine_mt, true);
        sub_data(s_idx).mt_w  = get_smooth_line(p_mt_w,  edges_mt, x_fine_mt, true);
        sub_data(s_idx).rt_n_wo = numel(p_rt_wo);       sub_data(s_idx).rt_n_w = numel(p_rt_w);
        sub_data(s_idx).rt_wo = get_smooth_line(p_rt_wo, edges_rt, x_fine_rt, true);
        sub_data(s_idx).rt_w  = get_smooth_line(p_rt_w,  edges_rt, x_fine_rt, true);

        % -------------------------------------------------------------
        % 1. Plot individual participant figure (Smoothed Lines, Minimal Ink)
        % -------------------------------------------------------------
        f = figure('Name', sprintf('Sub_%02d_Timing', s), 'Position', [100, 100, 1200, 380], 'Color', 'w', 'Visible', 'off');

        % Subplot 1: Onset Time (RT)
        subplot(1, 3, 1);
        hold on;
        y_onset_wo = get_smooth_line(p_onset_wo, edges_onset, x_fine_onset, false);
        y_onset_w  = get_smooth_line(p_onset_w,  edges_onset, x_fine_onset, false);
        plot(x_fine_onset, y_onset_wo, 'Color', col_wo, 'LineWidth', 1.8, 'DisplayName', sprintf('Without Time Excl (N=%d)', numel(p_onset_wo)));
        if ~isempty(p_onset_w)
            plot(x_fine_onset, y_onset_w, 'Color', col_w, 'LineWidth', 2.0, 'DisplayName', sprintf('With Time Excl (N=%d)', numel(p_onset_w)));
        end
        xline(100, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Early Cutoff (100 ms)');
        xlabel('Onset Time (ms)', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Trial Count', 'FontSize', 11, 'FontWeight', 'bold');
        title('Onset Time (RT)', 'FontSize', 12, 'FontWeight', 'bold');
        xlim([0, 700]);
        max_y1 = max([max(y_onset_wo), max(y_onset_w), 1]);
        ylim([0, max_y1 * 1.30]);
        box off; set(gca, 'TickDir', 'out', 'FontSize', 10);
        legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off');

        % Subplot 2: Movement Duration (MT)
        subplot(1, 3, 2);
        hold on;
        y_mt_wo = get_smooth_line(p_mt_wo, edges_mt, x_fine_mt, false);
        y_mt_w  = get_smooth_line(p_mt_w,  edges_mt, x_fine_mt, false);
        plot(x_fine_mt, y_mt_wo, 'Color', col_wo, 'LineWidth', 1.8, 'DisplayName', sprintf('Without Time Excl (N=%d)', numel(p_mt_wo)));
        if ~isempty(p_mt_w)
            plot(x_fine_mt, y_mt_w, 'Color', col_w, 'LineWidth', 2.0, 'DisplayName', sprintf('With Time Excl (N=%d)', numel(p_mt_w)));
        end
        xline(420, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Online Slow Cutoff (420 ms)');
        if ~isempty(p_mt_w)
            cutoff_3sd = mean(p_mt_w) + 3 * std(p_mt_w);
            xline(cutoff_3sd, 'm:', 'LineWidth', 1.5, 'DisplayName', sprintf('+3 SD Cutoff (%.0f ms)', cutoff_3sd));
        end
        xlabel('Movement Duration (ms)', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Trial Count', 'FontSize', 11, 'FontWeight', 'bold');
        title('Movement Duration (MT)', 'FontSize', 12, 'FontWeight', 'bold');
        xlim([100, 800]);
        max_y2 = max([max(y_mt_wo), max(y_mt_w), 1]);
        ylim([0, max_y2 * 1.30]);
        box off; set(gca, 'TickDir', 'out', 'FontSize', 10);
        legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off');

        % Subplot 3: Overall Response Duration (RT + MT)
        subplot(1, 3, 3);
        hold on;
        y_rt_wo = get_smooth_line(p_rt_wo, edges_rt, x_fine_rt, false);
        y_rt_w  = get_smooth_line(p_rt_w,  edges_rt, x_fine_rt, false);
        plot(x_fine_rt, y_rt_wo, 'Color', col_wo, 'LineWidth', 1.8, 'DisplayName', sprintf('Without Time Excl (N=%d)', numel(p_rt_wo)));
        if ~isempty(p_rt_w)
            plot(x_fine_rt, y_rt_w, 'Color', col_w, 'LineWidth', 2.0, 'DisplayName', sprintf('With Time Excl (N=%d)', numel(p_rt_w)));
        end
        xline(1000, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Late Cutoff (1000 ms)');
        xlabel('Overall Response Duration (ms)', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Trial Count', 'FontSize', 11, 'FontWeight', 'bold');
        title('Overall Response Duration (RT + MT)', 'FontSize', 12, 'FontWeight', 'bold');
        xlim([200, 1500]);
        max_y3 = max([max(y_rt_wo), max(y_rt_w), 1]);
        ylim([0, max_y3 * 1.30]);
        box off; set(gca, 'TickDir', 'out', 'FontSize', 10);
        legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off');

        sgtitle(sprintf('Participant %d (%s) - Timing Distributions', s, status_str), 'FontSize', 13, 'FontWeight', 'bold');

        % Save individual figures
        fig_base = fullfile(out_fig_dir, sprintf('Sub_%02d_timing_histograms', s));
        exportgraphics(f, [fig_base, '.png'], 'Resolution', 300);
        exportgraphics(f, [fig_base, '.pdf'], 'ContentType', 'image');
        close(f);
    end

    % -------------------------------------------------------------
    % 2. Consolidated Group-Level Summary Figure (Smoothed Lines)
    % -------------------------------------------------------------
    f_group = figure('Name', 'Group_Summary_Timing', 'Position', [100, 100, 1200, 400], 'Color', 'w', 'Visible', 'off');

    subplot(1, 3, 1);
    hold on;
    y_grp_onset_wo = get_smooth_line(group_onset_without, edges_onset, x_fine_onset, false);
    y_grp_onset_w  = get_smooth_line(group_onset_with,    edges_onset, x_fine_onset, false);
    plot(x_fine_onset, y_grp_onset_wo, 'Color', col_wo, 'LineWidth', 2.0, 'DisplayName', sprintf('Without Time Excl (N=%d)', numel(group_onset_without)));
    plot(x_fine_onset, y_grp_onset_w,  'Color', col_w,  'LineWidth', 2.2, 'DisplayName', sprintf('With Time Excl (N=%d)', numel(group_onset_with)));
    xline(100, 'k--', 'LineWidth', 1.8, 'DisplayName', 'Early Cutoff (100 ms)');
    xlabel('Onset Time (ms)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Total Trial Count', 'FontSize', 11, 'FontWeight', 'bold');
    title('Onset Time (RT) - Group', 'FontSize', 12, 'FontWeight', 'bold');
    xlim([0, 700]);
    ylim([0, max([max(y_grp_onset_wo), max(y_grp_onset_w)]) * 1.25]);
    box off; set(gca, 'TickDir', 'out', 'FontSize', 10);
    legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off');

    subplot(1, 3, 2);
    hold on;
    y_grp_mt_wo = get_smooth_line(group_mt_without, edges_mt, x_fine_mt, false);
    y_grp_mt_w  = get_smooth_line(group_mt_with,    edges_mt, x_fine_mt, false);
    plot(x_fine_mt, y_grp_mt_wo, 'Color', col_wo, 'LineWidth', 2.0, 'DisplayName', sprintf('Without Time Excl (N=%d)', numel(group_mt_without)));
    plot(x_fine_mt, y_grp_mt_w,  'Color', col_w,  'LineWidth', 2.2, 'DisplayName', sprintf('With Time Excl (N=%d)', numel(group_mt_with)));
    xline(420, 'k--', 'LineWidth', 1.8, 'DisplayName', 'Online Slow Cutoff (420 ms)');
    xlabel('Movement Duration (ms)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Total Trial Count', 'FontSize', 11, 'FontWeight', 'bold');
    title('Movement Duration (MT) - Group', 'FontSize', 12, 'FontWeight', 'bold');
    xlim([100, 800]);
    ylim([0, max([max(y_grp_mt_wo), max(y_grp_mt_w)]) * 1.25]);
    box off; set(gca, 'TickDir', 'out', 'FontSize', 10);
    legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off');

    subplot(1, 3, 3);
    hold on;
    y_grp_rt_wo = get_smooth_line(group_rt_without, edges_rt, x_fine_rt, false);
    y_grp_rt_w  = get_smooth_line(group_rt_with,    edges_rt, x_fine_rt, false);
    plot(x_fine_rt, y_grp_rt_wo, 'Color', col_wo, 'LineWidth', 2.0, 'DisplayName', sprintf('Without Time Excl (N=%d)', numel(group_rt_without)));
    plot(x_fine_rt, y_grp_rt_w,  'Color', col_w,  'LineWidth', 2.2, 'DisplayName', sprintf('With Time Excl (N=%d)', numel(group_rt_with)));
    xline(1000, 'k--', 'LineWidth', 1.8, 'DisplayName', 'Late Cutoff (1000 ms)');
    xlabel('Overall Response Duration (ms)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Total Trial Count', 'FontSize', 11, 'FontWeight', 'bold');
    title('Overall Response Duration (RT + MT) - Group', 'FontSize', 12, 'FontWeight', 'bold');
    xlim([200, 1500]);
    ylim([0, max([max(y_grp_rt_wo), max(y_grp_rt_w)]) * 1.25]);
    box off; set(gca, 'TickDir', 'out', 'FontSize', 10);
    legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off');

    sgtitle('Consolidated Group-Level Timing Distributions (N=42 Participants)', 'FontSize', 14, 'FontWeight', 'bold');

    group_base = fullfile(out_fig_dir, 'Group_Summary_Timing_Histograms');
    exportgraphics(f_group, [group_base, '.png'], 'Resolution', 300);
    exportgraphics(f_group, [group_base, '.pdf'], 'ContentType', 'image');
    close(f_group);

    % -------------------------------------------------------------
    % 3. All-Participants Combined Distribution Figure (3x2 Layout)
    %    Column 1: Valid Participants (N=30)
    %    Column 2: Excluded Participants (N=12)
    % -------------------------------------------------------------
    f_comb = figure('Name', 'All_Participants_Timing_Distributions', 'Position', [100, 100, 1100, 950], 'Color', 'w', 'Visible', 'off');
    tl = tiledlayout(f_comb, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    col_wo_sub = [0.90, 0.60, 0.60]; % Soft salmon for individual participant curves
    col_w_sub  = [0.60, 0.75, 0.90]; % Soft light blue for individual participant curves
    col_wo_grp = [0.80, 0.15, 0.15]; % Bold crimson for group mean
    col_w_grp  = [0.10, 0.35, 0.75]; % Bold navy for group mean

    valid_idx = find([sub_data.is_valid]);
    excl_idx  = find(~[sub_data.is_valid]);

    vars = {'onset', 'mt', 'rt'};
    var_titles = {'Onset Time (RT)', 'Movement Duration (MT)', 'Overall Response Duration (RT + MT)'};
    x_fines = {x_fine_onset, x_fine_mt, x_fine_rt};
    x_lims = {[0, 700], [100, 800], [200, 1500]};
    cutoffs = [100, 420, 1000];
    cutoff_labels = {'100 ms (Early)', '420 ms (Slow MT)', '1000 ms (Late)'};

    for v = 1:3
        var_name = vars{v};
        x_fine = x_fines{v};
        x_lim = x_lims{v};
        cutoff = cutoffs(v);
        cutoff_lbl = cutoff_labels{v};

        % Column 1: Valid Participants
        ax_val = nexttile(tl);
        hold(ax_val, 'on');

        lines_wo = []; lines_w = [];
        for i = valid_idx
            if sub_data(i).([var_name '_n_wo']) > 0
                plot(ax_val, x_fine, sub_data(i).([var_name '_wo']), 'Color', col_wo_sub, 'LineWidth', 0.9);
                lines_wo = [lines_wo; sub_data(i).([var_name '_wo'])];
            end
            if sub_data(i).([var_name '_n_w']) > 0
                plot(ax_val, x_fine, sub_data(i).([var_name '_w']), 'Color', col_w_sub, 'LineWidth', 0.9);
                lines_w = [lines_w; sub_data(i).([var_name '_w'])];
            end
        end

        h_wo = plot(ax_val, x_fine, mean(lines_wo, 1), 'Color', col_wo_grp, 'LineWidth', 2.5, 'DisplayName', 'Group Without Excl');
        h_w  = plot(ax_val, x_fine, mean(lines_w, 1),  'Color', col_w_grp,  'LineWidth', 2.5, 'DisplayName', 'Group With Excl');
        h_cut = xline(ax_val, cutoff, 'k--', 'LineWidth', 1.5, 'DisplayName', sprintf('Cutoff (%s)', cutoff_lbl));

        xlim(ax_val, x_lim);
        xlabel(ax_val, sprintf('%s (ms)', var_titles{v}), 'FontSize', 10, 'FontWeight', 'bold');
        ylabel(ax_val, 'Probability Density', 'FontSize', 10, 'FontWeight', 'bold');
        title(ax_val, sprintf('%s - Valid Participants (N=%d)', var_titles{v}, numel(valid_idx)), 'FontSize', 11, 'FontWeight', 'bold');
        box(ax_val, 'off');
        set(ax_val, 'TickDir', 'out', 'FontSize', 9);
        if v == 1
            legend(ax_val, [h_w, h_wo, h_cut], {'With Time Excl (Mean)', 'Without Time Excl (Mean)', 'Cutoff'}, 'Location', 'northeast', 'FontSize', 8, 'Box', 'off');
        end

        % Column 2: Excluded Participants
        ax_excl = nexttile(tl);
        hold(ax_excl, 'on');

        lines_wo_excl = []; lines_w_excl = [];
        for i = excl_idx
            if sub_data(i).([var_name '_n_wo']) > 0
                plot(ax_excl, x_fine, sub_data(i).([var_name '_wo']), 'Color', col_wo_sub, 'LineWidth', 0.9);
                lines_wo_excl = [lines_wo_excl; sub_data(i).([var_name '_wo'])];
            end
            if sub_data(i).([var_name '_n_w']) > 0
                plot(ax_excl, x_fine, sub_data(i).([var_name '_w']), 'Color', col_w_sub, 'LineWidth', 0.9);
                lines_w_excl = [lines_w_excl; sub_data(i).([var_name '_w'])];
            end
        end

        if ~isempty(lines_wo_excl)
            plot(ax_excl, x_fine, mean(lines_wo_excl, 1), 'Color', col_wo_grp, 'LineWidth', 2.5);
        end
        if ~isempty(lines_w_excl)
            plot(ax_excl, x_fine, mean(lines_w_excl, 1), 'Color', col_w_grp, 'LineWidth', 2.5);
        end
        xline(ax_excl, cutoff, 'k--', 'LineWidth', 1.5);

        xlim(ax_excl, x_lim);
        xlabel(ax_excl, sprintf('%s (ms)', var_titles{v}), 'FontSize', 10, 'FontWeight', 'bold');
        ylabel(ax_excl, 'Probability Density', 'FontSize', 10, 'FontWeight', 'bold');
        title(ax_excl, sprintf('%s - Excluded Participants (N=%d)', var_titles{v}, numel(excl_idx)), 'FontSize', 11, 'FontWeight', 'bold');
        box(ax_excl, 'off');
        set(ax_excl, 'TickDir', 'out', 'FontSize', 9);
    end

    title(tl, 'All Participants Timing Distributions (Smoothed Lines, Minimal Ink)', 'FontSize', 13, 'FontWeight', 'bold');

    fig_comb_base = fullfile(out_fig_dir, 'All_Participants_Timing_Distributions');
    exportgraphics(f_comb, [fig_comb_base, '.png'], 'Resolution', 300);
    exportgraphics(f_comb, [fig_comb_base, '.pdf'], 'ContentType', 'image');
    close(f_comb);

    % -------------------------------------------------------------
    % 4. All-Participants 2-Column Small-Multiples Grid (21 rows x 2 cols)
    % -------------------------------------------------------------
    f_grid = figure('Name', 'All_Participants_2Column_Grid', 'Position', [50, 50, 1200, 1800], 'Color', 'w', 'Visible', 'off');
    tl_grid = tiledlayout(f_grid, 21, 2, 'TileSpacing', 'tight', 'Padding', 'tight');

    col_onset = [0.15, 0.65, 0.35]; % Green for Onset
    col_mt    = [0.85, 0.45, 0.10]; % Amber/Orange for MT
    col_rt    = [0.20, 0.45, 0.85]; % Blue for Response Duration

    for s_idx = 1:numel(all_subs)
        s = all_subs(s_idx);
        is_valid = ismember(s, good_subs);

        ax = nexttile(tl_grid);
        hold(ax, 'on');

        % Extract curves for this sub
        y_onset = sub_data(s_idx).onset_w;
        y_mt    = sub_data(s_idx).mt_w;
        y_rt    = sub_data(s_idx).rt_w;

        if sub_data(s_idx).onset_n_w < 10
            y_onset = sub_data(s_idx).onset_wo;
            y_mt    = sub_data(s_idx).mt_wo;
            y_rt    = sub_data(s_idx).rt_wo;
            line_style = '--';
        else
            line_style = '-';
        end

        plot(ax, x_fine_onset, y_onset, 'Color', col_onset, 'LineWidth', 1.2, 'LineStyle', line_style);
        plot(ax, x_fine_mt,    y_mt,    'Color', col_mt,    'LineWidth', 1.2, 'LineStyle', line_style);
        plot(ax, x_fine_rt,    y_rt,    'Color', col_rt,    'LineWidth', 1.2, 'LineStyle', line_style);

        xline(ax, 100, ':', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 0.8);
        xline(ax, 420, ':', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 0.8);
        xline(ax, 1000, ':', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 0.8);

        xlim(ax, [0, 1400]);
        if is_valid
            lbl_str = sprintf('Sub %d (Valid, N=%d)', s, sub_data(s_idx).onset_n_w);
            lbl_col = [0.1, 0.4, 0.1];
        else
            lbl_str = sprintf('Sub %d (Excluded, N=%d)', s, sub_data(s_idx).onset_n_w);
            lbl_col = [0.7, 0.1, 0.1];
        end
        text(ax, 0.02, 0.82, lbl_str, 'Units', 'normalized', 'FontSize', 8, 'FontWeight', 'bold', 'Color', lbl_col);

        box(ax, 'off');
        set(ax, 'TickDir', 'out', 'FontSize', 7, 'YTick', []);
        if s_idx < 41
            set(ax, 'XTickLabel', []);
        else
            xlabel(ax, 'Time (ms)', 'FontSize', 8, 'FontWeight', 'bold');
        end
    end

    title(tl_grid, 'Participant-by-Participant Timing Distributions (Green: Onset, Orange: MT, Blue: Total RT)', 'FontSize', 12, 'FontWeight', 'bold');

    fig_grid_base = fullfile(out_fig_dir, 'All_Participants_2Column_Grid');
    exportgraphics(f_grid, [fig_grid_base, '.png'], 'Resolution', 300);
    exportgraphics(f_grid, [fig_grid_base, '.pdf'], 'ContentType', 'image');
    close(f_grid);

    fprintf('Saved all participant and group summary timing histograms to %s\n', out_fig_dir);
end

function y_smooth = get_smooth_line(data, edges, x_fine, do_normalize)
% GET_SMOOTH_LINE Fits an exact PCHIP spline connecting the mid-top points of histogram bins
    if isempty(data)
        y_smooth = zeros(size(x_fine));
        return;
    end
    c = histcounts(data, edges);
    if do_normalize
        bin_w = edges(2) - edges(1);
        y_val = c / (sum(c) * bin_w);
    else
        y_val = c;
    end
    mids = (edges(1:end-1) + edges(2:end)) / 2;
    x_pts = [edges(1), mids, edges(end)];
    y_pts = [0, y_val, 0];
    y_smooth = max(0, interp1(x_pts, y_pts, x_fine, 'pchip'));
end
