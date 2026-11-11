function [Stats_Table, fig_handles] = plot_supplementary_com_analysis(save_dir, data_dir, stats_dir)
%PLOT_SUPPLEMENTARY_COM_ANALYSIS Produces the Supplementary Information (SI)
% figures and statistics for the Change of Mind (COM) dwell time and debouncing threshold analysis.
%
% This function performs:
% 1. Subject-adjusted dwell time distribution analysis (physical milliseconds per participant),
%    showing the sharp noise component (< 80 ms) vs. sustained motor corrections (>= 80 ms).
% 2. Parameter sweep across normalized sample thresholds (1 to 20 samples, 0.5% to 10% reach),
%    including the pre-registered raw COM baseline for reference,
%    AND reporting both Correct and Incorrect trials across the sweep.
% 3. Neuro-motor physical millisecond thresholds (10 ms, 25 ms, 50 ms, and 80 ms motor correction minimum),
%    reporting simple effects / p-values of Incongruent vs. Congruent split by Correctness.
%
% Outputs:
% - SuppFig_COM_1_Dwell_Distributions (.png, .fig, .pdf)
% - SuppFig_COM_2_Threshold_Sweep (.png, .fig, .pdf)
% - SuppFig_COM_3_Physical_Thresholds (.png, .fig, .pdf)
% - Supplementary_COM_Threshold_Stats.xlsx & .csv
%
% Author: Antigravity / Uri

    func_dir = fileparts(mfilename('fullpath'));
    repo_root = fullfile(func_dir, '..', '..');
    if nargin < 1 || isempty(save_dir)
        save_dir = fullfile(repo_root, 'figures', 'Supplementary_COM');
    end
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end

    % Locate latest acceleration-corrected processed TrajNorm data
    if nargin < 2 || isempty(data_dir)
        data_dir = fullfile(repo_root, 'processed_data', 'nonStandardized_TrajNorm');
        if ~exist(data_dir, 'dir')
            data_dir = fullfile(repo_root, 'processed_data', 'standardized_TrajNorm');
        end
    end

    if nargin < 3 || isempty(stats_dir)
        stats_dir = fullfile(repo_root, 'statistics');
    end
    if ~exist(stats_dir, 'dir')
        mkdir(stats_dir);
    end

    good_subs_file = dir(fullfile(data_dir, 'good_subs_*.mat'));
    good_subs = load(fullfile(data_dir, good_subs_file(1).name));
    good_subs = good_subs.good_subs;

    bad_trials_file = dir(fullfile(data_dir, 'bad_trials_*.mat'));
    bad_trials = load(fullfile(data_dir, bad_trials_file(1).name));
    reach_bad_trials = bad_trials.reach_bad_trials;

    trim_len = load(fullfile(data_dir, 'trim_len.mat'));
    trim_len = trim_len.trim_len; % 200

    n_subs = length(good_subs);
    fprintf('=== Running Supplementary COM Analysis across %d subjects ===\n', n_subs);

    % Color palette matching manuscript
    c_blue   = [0.12, 0.47, 0.71]; % Congruent
    c_red    = [0.84, 0.15, 0.16]; % Incongruent
    c_purple = [0.49, 0.18, 0.56]; % Effect size
    c_orange = [0.85, 0.33, 0.10]; % Dwell noise / p-values
    c_gray   = [0.40, 0.40, 0.40];

    %% ---------------------------------------------------------------------
    %% 1. EXTRACT DATA & INDIVIDUAL TRIAL DURATIONS
    %% ---------------------------------------------------------------------
    trial_data = [];
    all_dwell_events = [];

    for s_idx = 1:n_subs
        iSub = good_subs(s_idx);
        traj_d = load(fullfile(data_dir, sprintf('sub%dday2_reach_traj_proc.mat', iSub)));
        data_d = load(fullfile(data_dir, sprintf('sub%dday2_reach_data_proc.mat', iSub)));

        traj_tab = traj_d.reach_traj_table;
        data_tab = data_d.reach_data_table;

        reasons = string(reach_bad_trials{iSub}.Properties.VariableNames);
        reasons(reasons == "any" | reasons == "slow_mvmnt" | reasons == "loop" | reasons == "incorrect") = [];
        bad = any(reach_bad_trials{iSub}{:, reasons} > 0, 2);
        pas = ismember(data_tab.pas, 1);

        valid_timing = ~bad & pas;
        iep = traj_tab.iep;
        iep_mat = reshape(iep, trim_len, height(data_tab));

        valid_idx = find(valid_timing);

        for v_i = 1:length(valid_idx)
            tr = valid_idx(v_i);
            is_con = data_tab.con(tr);
            is_correct = data_tab.target_correct(tr);
            md_ms = (data_tab.offset(tr) - data_tab.onset(tr)) * 1000; % Movement duration in ms

            iep_tr = iep_mat(:, tr);
            neg_angle = iep_tr < 0;
            neg_angle(1) = neg_angle(2);

            crossings = find(diff(neg_angle));
            n_com = length(crossings);

            % Collect dwells
            for k = 1:n_com
                c_curr = crossings(k);
                if k < n_com
                    c_next = crossings(k+1);
                    dw_samp = c_next - c_curr;
                else
                    dw_samp = trim_len - c_curr + 1;
                end
                dw_ms = (dw_samp / trim_len) * md_ms;

                ev.sub = iSub;
                ev.trial = tr;
                ev.is_con = is_con;
                ev.is_correct = is_correct;
                ev.com_order = k;
                ev.crossing_sample = c_curr;
                ev.crossing_pct = (c_curr / trim_len) * 100;
                ev.dwell_samples = dw_samp;
                ev.dwell_ms = dw_ms;
                ev.dwell_pct = (dw_samp / trim_len) * 100;

                if isempty(all_dwell_events)
                    all_dwell_events = ev;
                else
                    all_dwell_events(end+1) = ev;
                end
            end

            t_item.sub = iSub;
            t_item.trial = tr;
            t_item.is_con = is_con;
            t_item.is_correct = is_correct;
            t_item.md_ms = md_ms;
            t_item.neg_angle = neg_angle;
            t_item.raw_com = n_com;

            if isempty(trial_data)
                trial_data = t_item;
            else
                trial_data(end+1) = t_item;
            end
        end
    end

    dwell_tbl = struct2table(all_dwell_events);
    fprintf('Extracted %d total COM events across %d valid trials.\n', height(dwell_tbl), length(trial_data));

    %% =====================================================================
    %% FIGURE S1: SUBJECT-ADJUSTED DWELL TIME DISTRIBUTION (PHYSICAL MS)
    %% =====================================================================
    fig1 = figure('Name', 'SuppFig COM 1 - Dwell Time Distribution', 'Position', [100, 100, 1100, 500], 'Color', 'w');
    
    % Panel A: Millisecond dwell histogram with zoom-in
    ax1 = subplot(1, 2, 1);
    hold(ax1, 'on');
    h_all = histogram(ax1, dwell_tbl.dwell_ms, 0:15:500, 'FaceColor', c_blue, 'EdgeColor', 'w', 'FaceAlpha', 0.85);
    xline(ax1, 80, '--r', '80 ms (Neuro-motor Limit)', 'LineWidth', 2, 'FontSize', 10, 'LabelVerticalAlignment', 'top');
    xline(ax1, 50, ':k', '50 ms', 'LineWidth', 1.5, 'FontSize', 9);
    xlabel(ax1, 'Dwell Time per COM (Milliseconds)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel(ax1, 'Number of COM Events', 'FontSize', 11, 'FontWeight', 'bold');
    title(ax1, 'A. Overall Dwell Distribution (Adjusted by Subject MD)', 'FontSize', 12, 'FontWeight', 'bold');
    grid(ax1, 'on');
    set(ax1, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off');

    % Inset on sub-100 ms region
    ax_ins = axes('Position', [0.27, 0.45, 0.18, 0.42]);
    hold(ax_ins, 'on');
    histogram(ax_ins, dwell_tbl.dwell_ms, 0:5:100, 'FaceColor', c_orange, 'EdgeColor', 'w', 'FaceAlpha', 0.85);
    xline(ax_ins, 80, '--r', '80 ms', 'LineWidth', 1.8, 'FontSize', 9);
    xline(ax_ins, 50, ':k', '50 ms', 'LineWidth', 1.3, 'FontSize', 8);
    xlabel(ax_ins, 'Dwell (ms)', 'FontSize', 9, 'FontWeight', 'bold');
    ylabel(ax_ins, 'Count', 'FontSize', 9, 'FontWeight', 'bold');
    title(ax_ins, 'Sub-100 ms Noise Band', 'FontSize', 9, 'FontWeight', 'bold');
    grid(ax_ins, 'on');
    set(ax_ins, 'FontSize', 8, 'TickDir', 'out', 'Box', 'off');

    % Panel B: Cumulative distribution & percentiles
    ax2 = subplot(1, 2, 2);
    hold(ax2, 'on');
    [f_cdf, x_cdf] = ecdf(dwell_tbl.dwell_ms);
    plot(ax2, x_cdf, f_cdf * 100, 'Color', c_blue, 'LineWidth', 2.5);
    xline(ax2, 80, '--r', sprintf('80 ms (%.1f%% of COMs)', 100*mean(dwell_tbl.dwell_ms < 80)), 'LineWidth', 2, 'FontSize', 10);
    xline(ax2, 50, ':k', sprintf('50 ms (%.1f%%)', 100*mean(dwell_tbl.dwell_ms < 50)), 'LineWidth', 1.5, 'FontSize', 9);
    xline(ax2, 25, '-.g', sprintf('25 ms (%.1f%%)', 100*mean(dwell_tbl.dwell_ms < 25)), 'LineWidth', 1.5, 'FontSize', 9);
    xlabel(ax2, 'Dwell Time Threshold (Milliseconds)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel(ax2, 'Cumulative % of COMs Filtered Out', 'FontSize', 11, 'FontWeight', 'bold');
    title(ax2, 'B. Cumulative Noise Elimination Curve', 'FontSize', 12, 'FontWeight', 'bold');
    grid(ax2, 'on');
    set(ax2, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'XLim', [0, 450], 'YLim', [0, 100]);

    % Save Figure COM 1
    exportgraphics(fig1, fullfile(save_dir, 'SuppFig_COM_1_Dwell_Distributions.png'), 'Resolution', 300);
    exportgraphics(fig1, fullfile(save_dir, 'SuppFig_COM_1_Dwell_Distributions.pdf'));
    try, exportgraphics(fig1, fullfile(save_dir, 'SuppFig_COM_1_Dwell_Distributions.svg'), 'ContentType', 'vector'); catch, end
    savefig(fig1, fullfile(save_dir, 'SuppFig_COM_1_Dwell_Distributions.fig'));

    %% =====================================================================
    %% 2. PARAMETER SWEEP ACROSS SAMPLES (CORRECT & INCORRECT SEPARATELY)
    %% =====================================================================
    sample_thresholds = 1:20;
    n_thresh = length(sample_thresholds);

    sweep_corr_con_m   = zeros(n_thresh, 1);
    sweep_corr_con_sd  = zeros(n_thresh, 1);
    sweep_corr_incon_m = zeros(n_thresh, 1);
    sweep_corr_incon_sd = zeros(n_thresh, 1);
    sweep_corr_diff    = zeros(n_thresh, 1);
    sweep_corr_tstat   = zeros(n_thresh, 1);
    sweep_corr_pval    = zeros(n_thresh, 1);
    sweep_corr_dz      = zeros(n_thresh, 1);

    sweep_err_con_m    = zeros(n_thresh, 1);
    sweep_err_con_sd   = zeros(n_thresh, 1);
    sweep_err_incon_m  = zeros(n_thresh, 1);
    sweep_err_incon_sd = zeros(n_thresh, 1);
    sweep_err_diff     = zeros(n_thresh, 1);
    sweep_err_tstat    = zeros(n_thresh, 1);
    sweep_err_df       = zeros(n_thresh, 1);
    sweep_err_pval     = zeros(n_thresh, 1);
    sweep_err_dz       = zeros(n_thresh, 1);

    for th_idx = 1:n_thresh
        min_dw = sample_thresholds(th_idx);

        sub_corr_con = zeros(n_subs, 1);
        sub_corr_incon = zeros(n_subs, 1);
        sub_err_con = NaN(n_subs, 1);
        sub_err_incon = NaN(n_subs, 1);

        for s_i = 1:n_subs
            sub_id = good_subs(s_i);

            % Trials for this subject
            idx_c_con = find([trial_data.sub] == sub_id & [trial_data.is_correct] == 1 & [trial_data.is_con] == 1);
            idx_c_inc = find([trial_data.sub] == sub_id & [trial_data.is_correct] == 1 & [trial_data.is_con] == 0);
            idx_e_con = find([trial_data.sub] == sub_id & [trial_data.is_correct] == 0 & [trial_data.is_con] == 1);
            idx_e_inc = find([trial_data.sub] == sub_id & [trial_data.is_correct] == 0 & [trial_data.is_con] == 0);

            % Helper to compute com count
            sub_corr_con(s_i) = mean(compute_debounced_counts(trial_data, idx_c_con, min_dw, trim_len));
            sub_corr_incon(s_i) = mean(compute_debounced_counts(trial_data, idx_c_inc, min_dw, trim_len));

            if ~isempty(idx_e_con)
                sub_err_con(s_i) = mean(compute_debounced_counts(trial_data, idx_e_con, min_dw, trim_len));
            end
            if ~isempty(idx_e_inc)
                sub_err_incon(s_i) = mean(compute_debounced_counts(trial_data, idx_e_inc, min_dw, trim_len));
            end
        end

        % Correct trials t-test
        [~, p_c, ~, stats_c] = ttest(sub_corr_incon, sub_corr_con);
        diff_c = mean(sub_corr_incon - sub_corr_con);
        dz_c = diff_c / std(sub_corr_incon - sub_corr_con);

        sweep_corr_con_m(th_idx)   = mean(sub_corr_con);
        sweep_corr_con_sd(th_idx)  = std(sub_corr_con);
        sweep_corr_incon_m(th_idx) = mean(sub_corr_incon);
        sweep_corr_incon_sd(th_idx) = std(sub_corr_incon);
        sweep_corr_diff(th_idx)    = diff_c;
        sweep_corr_tstat(th_idx)   = stats_c.tstat;
        sweep_corr_pval(th_idx)    = p_c;
        sweep_corr_dz(th_idx)      = dz_c;

        % Incorrect trials t-test (paired where subject has both)
        diff_err = sub_err_incon - sub_err_con;
        v_err = ~isnan(diff_err);
        [~, p_e, ~, stats_e] = ttest(diff_err(v_err));
        diff_e = mean(diff_err(v_err));
        dz_e = diff_e / std(diff_err(v_err));

        sweep_err_con_m(th_idx)   = nanmean(sub_err_con);
        sweep_err_con_sd(th_idx)  = nanstd(sub_err_con);
        sweep_err_incon_m(th_idx) = nanmean(sub_err_incon);
        sweep_err_incon_sd(th_idx) = nanstd(sub_err_incon);
        sweep_err_diff(th_idx)    = diff_e;
        sweep_err_tstat(th_idx)   = stats_e.tstat;
        sweep_err_df(th_idx)      = stats_e.df;
        sweep_err_pval(th_idx)    = p_e;
        sweep_err_dz(th_idx)      = dz_e;
    end

    % Pre-registered baseline values (Threshold = 1 sample, raw):
    prereg_con   = sweep_corr_con_m(1);
    prereg_incon = sweep_corr_incon_m(1);
    prereg_dz    = sweep_corr_dz(1);
    prereg_pval  = sweep_corr_pval(1);

    fig2 = figure('Name', 'SuppFig COM 2 - Threshold Parameter Sweep', 'Position', [100, 100, 1300, 520], 'Color', 'w');

    % Subplot 1: COM Count vs Threshold with Pre-Reg highlighted
    ax2_1 = subplot(1, 3, 1);
    hold(ax2_1, 'on');
    p_c = plot(ax2_1, sample_thresholds, sweep_corr_con_m, '-o', 'Color', c_blue, 'LineWidth', 2.2, 'MarkerSize', 6, 'MarkerFaceColor', c_blue);
    p_i = plot(ax2_1, sample_thresholds, sweep_corr_incon_m, '-s', 'Color', c_red, 'LineWidth', 2.2, 'MarkerSize', 6, 'MarkerFaceColor', c_red);
    % Highlight pre-registered reference points
    plot(ax2_1, 1, prereg_con, 'o', 'Color', [0.0, 0.2, 0.6], 'MarkerSize', 11, 'LineWidth', 2.5);
    plot(ax2_1, 1, prereg_incon, 's', 'Color', [0.6, 0.0, 0.0], 'MarkerSize', 11, 'LineWidth', 2.5);
    text(ax2_1, 2.1, prereg_incon - 0.02, sprintf('Pre-registered Raw\n(%.2f vs %.2f)', prereg_con, prereg_incon), ...
        'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2], 'VerticalAlignment', 'top');

    xlabel(ax2_1, 'Minimal Dwell Threshold (Samples)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel(ax2_1, 'Mean Number of COMs per Trial', 'FontSize', 11, 'FontWeight', 'bold');
    title(ax2_1, 'A. COM Count vs. Threshold (Correct Trials)', 'FontSize', 12, 'FontWeight', 'bold');
    legend(ax2_1, [p_c, p_i], {'Congruent', 'Incongruent'}, 'Location', 'northeast', 'Box', 'off');
    grid(ax2_1, 'on');
    set(ax2_1, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'XLim', [0.5, 20.5], 'YLim', [1.05, 2.08]);

    % Subplot 2: Effect Size vs Threshold (split by Correctness)
    ax2_2 = subplot(1, 3, 2);
    hold(ax2_2, 'on');
    p_dz_c = plot(ax2_2, sample_thresholds, sweep_corr_dz, '-o', 'Color', c_purple, 'LineWidth', 2.4, 'MarkerSize', 6, 'MarkerFaceColor', c_purple);
    p_dz_e = plot(ax2_2, sample_thresholds, sweep_err_dz, '--s', 'Color', c_gray, 'LineWidth', 1.8, 'MarkerSize', 6, 'MarkerFaceColor', c_gray);
    % Reference line for pre-registered effect size
    yline(ax2_2, prereg_dz, '--', 'Color', c_purple, 'LineWidth', 1.2);
    text(ax2_2, 10, prereg_dz - 0.035, sprintf('Pre-reg d_z = %.2f', prereg_dz), 'FontSize', 9, 'FontWeight', 'bold', 'Color', c_purple);
    yline(ax2_2, 0.5, ':k', 'LineWidth', 1.0);
    text(ax2_2, 4.5, 0.512, 'Medium (d_z = 0.50)', 'FontSize', 9, 'Color', [0.15 0.15 0.15], 'VerticalAlignment', 'bottom');
    yline(ax2_2, 0.0, '-k', 'LineWidth', 0.8, 'Color', [0.7 0.7 0.7]);
    xlabel(ax2_2, 'Minimal Dwell Threshold (Samples)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel(ax2_2, 'Priming Effect Size (Cohen''s d_z)', 'FontSize', 11, 'FontWeight', 'bold');
    title(ax2_2, 'B. Effect Size Split by Correctness', 'FontSize', 12, 'FontWeight', 'bold');
    legend(ax2_2, [p_dz_c, p_dz_e], {'Correct Trials', 'Incorrect Trials'}, 'Location', 'southeast', 'Box', 'off');
    grid(ax2_2, 'on');
    set(ax2_2, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'XLim', [0.5, 20.5], 'YLim', [-0.25, 0.58]);

    % Subplot 3: p-value curve (split by Correctness, true logarithmic Y-axis)
    ax2_3 = subplot(1, 3, 3);
    p_pv_c = semilogy(ax2_3, sample_thresholds, sweep_corr_pval, '-o', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 2.4, 'MarkerSize', 6, 'MarkerFaceColor', [0.85, 0.33, 0.10]);
    hold(ax2_3, 'on');
    p_pv_e = semilogy(ax2_3, sample_thresholds, sweep_err_pval, '--s', 'Color', c_gray, 'LineWidth', 1.8, 'MarkerSize', 6, 'MarkerFaceColor', c_gray);
    set(ax2_3, 'YScale', 'log');
    yline(ax2_3, 0.05, '--r', '\alpha = 0.05', 'LineWidth', 1.8, 'FontSize', 9, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom');
    yline(ax2_3, prereg_pval, ':', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.3);
    text(ax2_3, 1.3, prereg_pval * 1.22, sprintf('Pre-reg p = %.3f', prereg_pval), 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.85, 0.33, 0.10], 'VerticalAlignment', 'bottom');
    xlabel(ax2_3, 'Minimal Dwell Threshold (Samples)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel(ax2_3, 'p-value (Log Scale)', 'FontSize', 11, 'FontWeight', 'bold');
    title(ax2_3, 'C. p-values Split by Correctness', 'FontSize', 12, 'FontWeight', 'bold');
    max_p_corr = max(sweep_corr_pval);
    if max_p_corr < 0.05
        corr_leg_lbl = sprintf('Correct Trials (all p <= %.3f)', max_p_corr);
    else
        corr_leg_lbl = 'Correct Trials';
    end
    set(ax2_3, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'XLim', [0.5, 20.5], 'YLim', [0.003, 1.3], ...
        'YTick', [0.005, 0.01, 0.05, 0.1, 0.5, 1], 'YTickLabel', {'0.005', '0.01', '0.05', '0.1', '0.5', '1'});
    lgd3 = legend(ax2_3, [p_pv_c, p_pv_e], {corr_leg_lbl, 'Incorrect Trials (n.s.)'}, 'Location', 'east', 'Box', 'off', 'FontSize', 9);
    drawnow;
    lgd3.Position(2) = lgd3.Position(2) + 0.08;
    grid(ax2_3, 'on');

    % Save Figure COM 2
    exportgraphics(fig2, fullfile(save_dir, 'SuppFig_COM_2_Threshold_Sweep.png'), 'Resolution', 300);
    exportgraphics(fig2, fullfile(save_dir, 'SuppFig_COM_2_Threshold_Sweep.pdf'));
    try, exportgraphics(fig2, fullfile(save_dir, 'SuppFig_COM_2_Threshold_Sweep.svg'), 'ContentType', 'vector'); catch, end
    savefig(fig2, fullfile(save_dir, 'SuppFig_COM_2_Threshold_Sweep.fig'));

    %% =====================================================================
    %% 3. PHYSICAL MILLISECOND THRESHOLDS (10 ms, 25 ms, 50 ms, 80 ms)
    %% =====================================================================
    ms_targets = [10, 25, 50, 80];
    n_ms = length(ms_targets);

    fig3 = figure('Name', 'SuppFig COM 3 - Physical Millisecond Thresholds', 'Position', [100, 100, 1350, 500], 'Color', 'w');

    ms_stats_rows = [];

    for m_i = 1:n_ms
        target_ms = ms_targets(m_i);

        sub_con_c = zeros(n_subs, 1);
        sub_inc_c = zeros(n_subs, 1);
        sub_con_e = NaN(n_subs, 1);
        sub_inc_e = NaN(n_subs, 1);

        for s_i = 1:n_subs
            sub_id = good_subs(s_i);

            idx_corr_con   = find([trial_data.sub] == sub_id & [trial_data.is_correct] == 1 & [trial_data.is_con] == 1);
            idx_corr_incon = find([trial_data.sub] == sub_id & [trial_data.is_correct] == 1 & [trial_data.is_con] == 0);
            idx_err_con    = find([trial_data.sub] == sub_id & [trial_data.is_correct] == 0 & [trial_data.is_con] == 1);
            idx_err_incon  = find([trial_data.sub] == sub_id & [trial_data.is_correct] == 0 & [trial_data.is_con] == 0);

            cells = {idx_corr_con, idx_corr_incon, idx_err_con, idx_err_incon};
            cell_m = zeros(4, 1);

            for c = 1:4
                trs = cells{c};
                if isempty(trs)
                    cell_m(c) = NaN;
                    continue;
                end
                c_coms = zeros(length(trs), 1);
                for k = 1:length(trs)
                    t_obj = trial_data(trs(k));
                    neg = t_obj.neg_angle;
                    md = t_obj.md_ms;
                    trial_dwell_samples = max(1, round((target_ms / md) * trim_len));

                    if trial_dwell_samples <= 1
                        c_coms(k) = length(find(diff(neg)));
                    else
                        curr_state = neg(1);
                        deb = neg;
                        t = 2;
                        while t <= trim_len
                            if neg(t) ~= curr_state
                                cand = neg(t);
                                end_t = min(trim_len, t + trial_dwell_samples - 1);
                                if all(neg(t:end_t) == cand) && (end_t - t + 1 >= trial_dwell_samples || end_t == trim_len)
                                    curr_state = cand;
                                end
                            end
                            deb(t) = curr_state;
                            t = t + 1;
                        end
                        c_coms(k) = length(find(diff(deb)));
                    end
                end
                cell_m(c) = mean(c_coms);
            end

            sub_con_c(s_i) = cell_m(1);
            sub_inc_c(s_i) = cell_m(2);
            sub_con_e(s_i) = cell_m(3);
            sub_inc_e(s_i) = cell_m(4);
        end

        % Correct trials t-test
        [~, p_ms_c, ~, stats_ms_c] = ttest(sub_inc_c, sub_con_c);
        diff_ms_c = mean(sub_inc_c - sub_con_c);
        dz_ms_c = diff_ms_c / std(sub_inc_c - sub_con_c);

        % Incorrect trials t-test
        diff_ms_err = sub_inc_e - sub_con_e;
        v_ms_e = ~isnan(diff_ms_err);
        [~, p_ms_e, ~, stats_ms_e] = ttest(diff_ms_err(v_ms_e));
        diff_ms_e = mean(diff_ms_err(v_ms_e));
        dz_ms_e = diff_ms_e / std(diff_ms_err(v_ms_e));

        % Record row for Correct trials
        rc.Threshold = sprintf('%d ms Physical Duration', target_ms);
        rc.Correctness = 'Correct';
        rc.Congruent_Mean = mean(sub_con_c);
        rc.Congruent_SD   = std(sub_con_c);
        rc.Incongruent_Mean = mean(sub_inc_c);
        rc.Incongruent_SD   = std(sub_inc_c);
        rc.Difference_Incon_minus_Con = diff_ms_c;
        rc.t_statistic = stats_ms_c.tstat;
        rc.df = stats_ms_c.df;
        rc.p_value_uncorrected = p_ms_c;
        rc.Cohens_dz = dz_ms_c;

        % Record row for Incorrect trials
        re.Threshold = sprintf('%d ms Physical Duration', target_ms);
        re.Correctness = 'Incorrect';
        re.Congruent_Mean = nanmean(sub_con_e);
        re.Congruent_SD   = nanstd(sub_con_e);
        re.Incongruent_Mean = nanmean(sub_inc_e);
        re.Incongruent_SD   = nanstd(sub_inc_e);
        re.Difference_Incon_minus_Con = diff_ms_e;
        re.t_statistic = stats_ms_e.tstat;
        re.df = stats_ms_e.df;
        re.p_value_uncorrected = p_ms_e;
        re.Cohens_dz = dz_ms_e;

        ms_stats_rows = [ms_stats_rows; rc; re];

        % Plot subplot for this physical threshold with clear p-values split by correctness
        ax_m = subplot(1, 4, m_i);
        hold(ax_m, 'on');

        m_con_corr = mean(sub_con_c);
        m_inc_corr = mean(sub_inc_c);
        m_con_err  = nanmean(sub_con_e);
        m_inc_err  = nanmean(sub_inc_e);

        sem_con_corr = std(sub_con_c) / sqrt(n_subs);
        sem_inc_corr = std(sub_inc_c) / sqrt(n_subs);
        sem_con_err  = nanstd(sub_con_e) / sqrt(sum(~isnan(sub_con_e)));
        sem_inc_err  = nanstd(sub_inc_e) / sqrt(sum(~isnan(sub_inc_e)));

        x_pts = [1, 2];
        p_c_m = plot(ax_m, x_pts, [m_con_corr, m_con_err], '-o', 'Color', c_blue, 'LineWidth', 2.2, 'MarkerSize', 7, 'MarkerFaceColor', c_blue);
        p_i_m = plot(ax_m, x_pts, [m_inc_corr, m_inc_err], '-s', 'Color', c_red, 'LineWidth', 2.2, 'MarkerSize', 7, 'MarkerFaceColor', c_red);

        errorbar(ax_m, x_pts, [m_con_corr, m_con_err], [sem_con_corr, sem_con_err], 'LineStyle', 'none', 'Color', c_blue, 'LineWidth', 1.4, 'CapSize', 6);
        errorbar(ax_m, x_pts, [m_inc_corr, m_inc_err], [sem_inc_corr, sem_inc_err], 'LineStyle', 'none', 'Color', c_red, 'LineWidth', 1.4, 'CapSize', 6);

        % Annotate simple effects directly above data points
        text(ax_m, 1, max(m_con_corr, m_inc_corr) + 0.16, ...
            sprintf('Correct:\n\\Delta = +%.2f\np = %.3f*', diff_ms_c, p_ms_c), ...
            'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);

        text(ax_m, 2, max(m_con_err, m_inc_err) + 0.16, ...
            sprintf('Incorrect:\n\\Delta = %+.2f\np = %.3f (n.s.)', diff_ms_e, p_ms_e), ...
            'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'normal', 'Color', [0.35 0.35 0.35]);

        set(ax_m, 'XTick', [1, 2], 'XTickLabel', {'Correct', 'Incorrect'}, 'XLim', [0.55, 2.45], 'YLim', [0.65, 2.15]);
        ylabel(ax_m, 'Mean COMs (±SEM)', 'FontSize', 10, 'FontWeight', 'bold');
        title(ax_m, sprintf('%d ms Cutoff', target_ms), 'FontSize', 11, 'FontWeight', 'bold');
        grid(ax_m, 'on');
        set(ax_m, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off');
        if m_i == 1
            legend(ax_m, [p_c_m, p_i_m], {'Congruent', 'Incongruent'}, 'Location', 'northeast', 'Box', 'off', 'FontSize', 9);
        end
    end

    % Save Figure COM 3
    exportgraphics(fig3, fullfile(save_dir, 'SuppFig_COM_3_Physical_Thresholds.png'), 'Resolution', 300);
    exportgraphics(fig3, fullfile(save_dir, 'SuppFig_COM_3_Physical_Thresholds.pdf'));
    try, exportgraphics(fig3, fullfile(save_dir, 'SuppFig_COM_3_Physical_Thresholds.svg'), 'ContentType', 'vector'); catch, end
    savefig(fig3, fullfile(save_dir, 'SuppFig_COM_3_Physical_Thresholds.fig'));

    %% ---------------------------------------------------------------------
    %% 4. EXPORT STATISTICAL SUMMARY TABLE (SPLIT BY CORRECTNESS)
    %% ---------------------------------------------------------------------
    sample_rows = [];
    key_samples = [1, 2, 5, 10, 15, 20];
    for ks = key_samples
        if ks == 1
            lbl = 'Pre-registered Raw (1 sample / 0.5% reach)';
        else
            lbl = sprintf('%d samples (%.1f%% reach)', ks, (ks/trim_len)*100);
        end

        % Row for Correct
        r_sc.Threshold = lbl;
        r_sc.Correctness = 'Correct';
        r_sc.Congruent_Mean = sweep_corr_con_m(ks);
        r_sc.Congruent_SD   = sweep_corr_con_sd(ks);
        r_sc.Incongruent_Mean = sweep_corr_incon_m(ks);
        r_sc.Incongruent_SD   = sweep_corr_incon_sd(ks);
        r_sc.Difference_Incon_minus_Con = sweep_corr_diff(ks);
        r_sc.t_statistic = sweep_corr_tstat(ks);
        r_sc.df = 29;
        r_sc.p_value_uncorrected = sweep_corr_pval(ks);
        r_sc.Cohens_dz = sweep_corr_dz(ks);

        % Row for Incorrect
        r_se.Threshold = lbl;
        r_se.Correctness = 'Incorrect';
        r_se.Congruent_Mean = sweep_err_con_m(ks);
        r_se.Congruent_SD   = sweep_err_con_sd(ks);
        r_se.Incongruent_Mean = sweep_err_incon_m(ks);
        r_se.Incongruent_SD   = sweep_err_incon_sd(ks);
        r_se.Difference_Incon_minus_Con = sweep_err_diff(ks);
        r_se.t_statistic = sweep_err_tstat(ks);
        r_se.df = sweep_err_df(ks);
        r_se.p_value_uncorrected = sweep_err_pval(ks);
        r_se.Cohens_dz = sweep_err_dz(ks);

        sample_rows = [sample_rows; r_sc; r_se];
    end

    Stats_Table = struct2table([sample_rows; ms_stats_rows]);
    writetable(Stats_Table, fullfile(save_dir, 'Supplementary_COM_Threshold_Stats.csv'));
    writetable(Stats_Table, fullfile(stats_dir, 'Supplementary_COM_Threshold_Stats.csv'));
    try
        writetable(Stats_Table, fullfile(save_dir, 'Supplementary_COM_Threshold_Stats.xlsx'));
        writetable(Stats_Table, fullfile(stats_dir, 'Supplementary_COM_Threshold_Stats.xlsx'));
    catch
    end

    fig_handles = [fig1, fig2, fig3];
    fprintf('=== Successfully saved all Supplementary COM figures and tables to %s ===\n', save_dir);
end

%% Helper function for debouncing
function counts = compute_debounced_counts(trial_data, trial_indices, min_dw, trim_len)
    counts = zeros(length(trial_indices), 1);
    for k = 1:length(trial_indices)
        neg = trial_data(trial_indices(k)).neg_angle;
        if min_dw <= 1
            counts(k) = length(find(diff(neg)));
        else
            curr_state = neg(1);
            deb = neg;
            t = 2;
            while t <= trim_len
                if neg(t) ~= curr_state
                    cand = neg(t);
                    end_t = min(trim_len, t + min_dw - 1);
                    if all(neg(t:end_t) == cand) && (end_t - t + 1 >= min_dw || end_t == trim_len)
                        curr_state = cand;
                    end
                end
                deb(t) = curr_state;
                t = t + 1;
            end
            counts(k) = length(find(diff(deb)));
        end
    end
end
