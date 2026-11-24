function [temporal_dynamics_struct] = generate_master_figures_part2(out_fig_dir, stats_or_fst, proc_root)
% GENERATE_MASTER_FIGURES_PART2 Generates Figures S3, S4, S5, S6, S7, S8, and S9
% directly in .fig, .png (300 DPI), .pdf, and .svg formats from in-memory structs,
% and returns temporal_dynamics_struct for Sheet 5 (Participants_Temporal_Dynamics).

if ~exist(out_fig_dir, 'dir'), mkdir(out_fig_dir); end

exp_p = load(fullfile(proc_root, '..', '..', 'experiment', 'RUN_ME', 'code', 'p.mat'));
p = exp_p.p;
p.SUBS = [47, 49:85, 87:90];
p.ORIG_SUBS = p.SUBS;
p.DAY = 'day2';
p.NORMALIZE_WITHIN_SUB = 0;
p.NORM_TRAJ = 1;
p.MIN_SAMP_LEN = 0.1;
p.MIN_TRIM_FRAMES = p.MIN_SAMP_LEN * p.REF_RATE_HZ;
p = defineParams_within_round(p, p.SUBS(1));

if isstruct(stats_or_fst)
    fst = stats_or_fst;
else
    s_all = load(fullfile(stats_or_fst, 'All_Statistics.mat'));
    fst = s_all.full_stats_tables;
end
TreeBH_Results = fst.TreeBH_Results;

plt_p = struct();
plt_p.con_col   = [0.18, 0.45, 0.78];
plt_p.incon_col = [0.85, 0.24, 0.20];
plt_p.con_avg_col = 'b';
plt_p.incon_avg_col = 'r';
plt_p.f_alpha = 0.25;
plt_p.alpha_size = 0.05;
plt_p.linewidth = 2.0;
plt_p.avg_plot_width = 2.4;
plt_p.axes_line_thickness = 1.2;
plt_p.font_size = 10;
plt_p.font_name = 'Arial';
plt_p.errbar_type = 'ci';
plt_p.space = 1.2;
plt_p.n_perm = 10000;
plt_p.n_perm_clust_tests = 1000;
plt_p.left_right_ticks = -15:5:15;
plt_p.percent_path_ticks = 0:20:100;

f1_dir = fullfile(proc_root, 'nonStandardized_TrajNorm');
f2_dir = fullfile(proc_root, 'standardized_TrajNorm');
traj_name = 'target_x_to';

good_subs = load(fullfile(f1_dir, ['good_subs_day2_' traj_name '_subs_' p.SUBS_STRING '.mat'])).good_subs;
f1_avg = load(fullfile(f1_dir, ['avg_each_day2_' traj_name '_subs_' p.SUBS_STRING '.mat']));
f2_avg = load(fullfile(f2_dir, ['avg_each_day2_' traj_name '_subs_' p.SUBS_STRING '.mat']));
f2_subs = load(fullfile(f2_dir, ['subs_avg_day2_' traj_name '_subs_' p.SUBS_STRING '.mat'])).reach_subs_avg;

% =========================================================================
% 7 & 8. Fig_S3_Group_Timing_Histograms & Fig_S4_All_Participants_Timing_Grid
% =========================================================================
fprintf('Generating Fig_S3_Group_Timing_Histograms and Fig_S4_All_Participants_Timing_Grid...\n');
[figS3, figS4, temporal_dynamics_struct] = render_figS3_and_S4_timing(f1_dir, fst, good_subs, p);
save_master_fig(figS3, fullfile(out_fig_dir, 'Fig_S3_Group_Timing_Histograms'));
close(figS3);
save_master_fig(figS4, fullfile(out_fig_dir, 'Fig_S4_All_Participants_Timing_Grid'));
close(figS4);

% =========================================================================
% 9. Fig_S5_Objective_Awareness_Robustness
% =========================================================================
fprintf('Generating Fig_S5_Objective_Awareness_Robustness...\n');
figS5 = render_figS5_objective_awareness_robustness(f1_avg, good_subs, fst.Prime_Performance_Stats);
save_master_fig(figS5, fullfile(out_fig_dir, 'Fig_S5_Objective_Awareness_Robustness'));
close(figS5);

% =========================================================================
% 10. Fig_S6_Robustness_Analysis_Congruency
% =========================================================================
fprintf('Generating Fig_S6_Robustness_Analysis_Congruency...\n');
figS6 = render_figS6_robustness(f2_avg, f2_subs, good_subs, TreeBH_Results.FigS2a_Congruency_Std_Table, plt_p);
save_master_fig(figS6, fullfile(out_fig_dir, 'Fig_S6_Robustness_Analysis_Congruency'));
close(figS6);

% =========================================================================
% 11. Fig_S7_COM_Dwell_Time_Threshold_Sweep
% =========================================================================
fprintf('Generating Fig_S7_COM_Dwell_Time_Threshold_Sweep...\n');
figS7 = render_figS7_com_sweep(fst.Supp_COM_Threshold_Stats, plt_p, f1_dir, good_subs);
save_master_fig(figS7, fullfile(out_fig_dir, 'Fig_S7_COM_Dwell_Time_Threshold_Sweep'));
close(figS7);

% =========================================================================
% 12. Fig_S8_Split_Half_Reliability
% =========================================================================
fprintf('Generating Fig_S8_Split_Half_Reliability...\n');
figS8 = render_figS8_reliability(fst.Split_Half_Reliability);
save_master_fig(figS8, fullfile(out_fig_dir, 'Fig_S8_Split_Half_Reliability'));
close(figS8);

% =========================================================================
% 13. Fig_S9_WO_Long_Duration_Exclusion_Effect_Sizes
% =========================================================================
fprintf('Generating Fig_S9_WO_Long_Duration_Exclusion_Effect_Sizes...\n');
figS9 = render_figS9_wo_long_dur_effects(fst);
save_master_fig(figS9, fullfile(out_fig_dir, 'Fig_S9_WO_Long_Duration_Exclusion_Effect_Sizes'));
close(figS9);

end

% =========================================================================
% HELPER: Save .fig, .png (300 DPI), .pdf (vector), and .svg (vector)
% =========================================================================
function save_master_fig(fig_h, base_path)
    try
        savefig(fig_h, [base_path, '.fig']);
    catch ME
        warning('Could not save .fig for %s: %s', base_path, ME.message);
    end
    try
        exportgraphics(fig_h, [base_path, '.png'], 'Resolution', 300);
    catch ME
        warning('exportgraphics PNG failed for %s: %s', base_path, ME.message);
        print(fig_h, [base_path, '.png'], '-dpng', '-r300');
    end
    try
        exportgraphics(fig_h, [base_path, '.pdf'], 'ContentType', 'vector');
    catch
        try
            exportgraphics(fig_h, [base_path, '.pdf'], 'Resolution', 300);
        catch ME2
            warning('exportgraphics PDF failed for %s: %s', base_path, ME2.message);
        end
    end
    try
        exportgraphics(fig_h, [base_path, '.svg'], 'ContentType', 'vector');
    catch
        try
            print(fig_h, [base_path, '.svg'], '-dsvg', '-vector');
        catch
            try
                saveas(fig_h, [base_path, '.svg']);
            catch ME3
                warning('SVG export failed for %s: %s', base_path, ME3.message);
            end
        end
    end
end

% =========================================================================
% HELPER: Render Figure S3 and Figure S4 + Build Temporal Dynamics Tables
% =========================================================================
function [figS3, figS4, td_struct] = render_figS3_and_S4_timing(f1_dir, fst, good_subs, p)
    all_45_subs = 46:90; % 45 recruited participants (Prtcp 46 to Prtcp 90)
    valid_data_subs = p.SUBS; % 42 participants with valid data

    % Exact cohort for pre-registered analysis without excluding long movement durations (N = 31)
    if isstruct(fst) && isfield(fst, 'SI_Reanalysis') && isfield(fst.SI_Reanalysis, 'good_subs_si')
        nl_subs = fst.SI_Reanalysis.good_subs_si;
    elseif isstruct(fst) && isfield(fst, 'By_Sub_SI_noTimeExclusion') && istable(fst.By_Sub_SI_noTimeExclusion)
        t_nl = fst.By_Sub_SI_noTimeExclusion;
        if isnumeric(t_nl.Participant)
            nl_subs = t_nl.Participant(~isnan(t_nl.Participant));
        else
            tok = regexp(cellstr(string(t_nl.Participant)), '\d+', 'match', 'once');
            nl_subs = str2double(tok(~cellfun(@isempty, tok)));
        end
    else
        nl_subs = unique([good_subs(:); 74]);
    end

    % Bin edges for unsmoothed line histograms (Fig S3)
    edges_onset = 0:15:705;
    mids_onset  = (edges_onset(1:end-1) + edges_onset(2:end)) / 2;

    edges_mt    = 0:20:920; % Starts at 0 ms so aborted early (<100 ms) and ~310 ms late aborts are visible
    mids_mt     = (edges_mt(1:end-1) + edges_mt(2:end)) / 2;

    edges_rt    = 0:25:1500; % Starts at 0 ms!
    mids_rt     = (edges_rt(1:end-1) + edges_rt(2:end)) / 2;

    % Millisecond grid for active reaching movements (Fig S4)
    t_ms_grid   = 0:1:1300;

    n_valid_subs = numel(valid_data_subs);
    mat_on_wo = zeros(n_valid_subs, numel(mids_onset));
    mat_on_nl = zeros(n_valid_subs, numel(mids_onset));
    mat_on_pr = zeros(n_valid_subs, numel(mids_onset));

    mat_mt_wo = zeros(n_valid_subs, numel(mids_mt));
    mat_mt_nl = zeros(n_valid_subs, numel(mids_mt)); % Online time excl only (long durations retained)
    mat_mt_pr = zeros(n_valid_subs, numel(mids_mt)); % Pre-registered (<= +3 SD)

    mat_rt_wo = zeros(n_valid_subs, numel(mids_rt));
    mat_rt_nl = zeros(n_valid_subs, numel(mids_rt));
    mat_rt_pr = zeros(n_valid_subs, numel(mids_rt));

    is_good_valid = false(n_valid_subs, 1);
    is_nl_valid   = false(n_valid_subs, 1);

    sub_active_curves    = cell(numel(all_45_subs), 1);
    sub_active_ok_curves = cell(numel(all_45_subs), 1);
    sub_onset_wo         = cell(numel(all_45_subs), 1);
    sub_slow_thresh      = nan(numel(all_45_subs), 1);
    sub_n_trials_valid = zeros(numel(all_45_subs), 1);
    sub_has_data      = false(numel(all_45_subs), 1);
    sub_mean_onset    = nan(numel(all_45_subs), 1);
    sub_sd_onset      = nan(numel(all_45_subs), 1);
    sub_mean_mt       = nan(numel(all_45_subs), 1);
    sub_sd_mt         = nan(numel(all_45_subs), 1);

    bt = load(fullfile(f1_dir, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat'));
    v_counter = 0;
    for idx_45 = 1:numel(all_45_subs)
        s = all_45_subs(idx_45);
        rd_file = fullfile(f1_dir, sprintf('sub%dday2_reach_data_proc.mat', s));
        if ~exist(rd_file, 'file') || s > numel(bt.reach_bad_trials) || isempty(bt.reach_bad_trials{s})
            continue;
        end
        sub_has_data(idx_45) = true;
        v_counter = v_counter + 1;

        rd = load(rd_file).reach_data_table;
        rd(rd.practice >= 1, :) = [];
        r_bt = bt.reach_bad_trials{s};

        % Separate true recording/data errors from trajectory-completion/length flags
        % (aborted early_res / late_res trials trigger diff_len and set r_bt.incorrect = NaN in cancelDuplicates)
        real_tech_reasons = {'hole_in_data', 'missing_data', 'bad_stim_dur', 'quit'};
        comp_bad_reasons  = {'short_traj', 'missed_target'};
        real_tech_bad = any(r_bt{:, real_tech_reasons} > 0, 2);
        comp_bad      = any(r_bt{:, comp_bad_reasons} > 0, 2) | (r_bt.diff_len > 0);

        % Use pre-cancellation raw rd flags so early/late/slow_mvmnt are never masked by cancelDuplicates
        early_mask = rd.early_res > 0;
        late_mask  = rd.late_res  > 0;
        vslow_mask = r_bt.very_slow_mvmnt > 0;
        slow_online = rd.slow_mvmnt > 0;
        pas1_mask  = rd.pas == 1;
        corr_mask  = (rd.target_correct == 1) & (rd.quit == 0);

        onset_ms  = rd.onset * 1000;
        offset_ms = rd.offset * 1000;
        mt_ms     = (rd.offset - rd.onset) * 1000;
        valid_num = ~isnan(onset_ms) & ~isnan(mt_ms);

        % Pure temporal-exclusion masks for Fig S3 across ALL three exclusion tiers
        % (independent of PAS visibility rating, target_correct, or diff_len/short_traj aborts)
        mask_wo = ~real_tech_bad & valid_num;
        mask_nl = mask_wo & ~early_mask & ~late_mask;
        mask_pr = mask_nl & ~vslow_mask;

        % Behavioral pre-registered masks for Fig S4 counts & Sheet 5 Part D
        mask_nl_behav = ~real_tech_bad & ~comp_bad & pas1_mask & corr_mask & valid_num & ~early_mask & ~late_mask;
        mask_pr_behav = mask_nl_behav & ~vslow_mask;

        is_good_valid(v_counter) = ismember(s, good_subs);
        is_nl_valid(v_counter)   = ismember(s, nl_subs);

        sub_n_trials_valid(idx_45) = sum(mask_pr_behav);
        sub_mean_onset(idx_45) = mean(onset_ms(mask_nl_behav), 'omitnan');
        sub_sd_onset(idx_45)   = std(onset_ms(mask_nl_behav), 0, 'omitnan');
        sub_mean_mt(idx_45)    = mean(mt_ms(mask_nl_behav), 'omitnan');
        sub_sd_mt(idx_45)      = std(mt_ms(mask_nl_behav), 0, 'omitnan');

        % Exact offline slow movement threshold for this participant (verbatim testVerySlowMvmnt.m logic)
        pool_3sd = ~real_tech_bad & ~comp_bad & corr_mask & ~early_mask & ~late_mask & ~slow_online & valid_num;
        if sum(pool_3sd) >= 5
            mt_cutoff_ms = mean(mt_ms(pool_3sd)) + 3 * std(mt_ms(pool_3sd), 1);
        else
            mt_cutoff_ms = mean(mt_ms(mask_nl_behav), 'omitnan') + 3 * std(mt_ms(mask_nl_behav), 1, 'omitnan');
        end
        if isnan(mt_cutoff_ms), mt_cutoff_ms = 550; end
        sub_slow_thresh(idx_45) = mt_cutoff_ms;

        % Compute per-participant bin counts for Fig S3 (each participant contributes equally when averaged)
        mat_on_wo(v_counter, :) = histcounts(onset_ms(mask_wo), edges_onset);
        mat_on_nl(v_counter, :) = histcounts(onset_ms(mask_nl), edges_onset);
        mat_on_pr(v_counter, :) = histcounts(onset_ms(mask_pr), edges_onset);

        mat_mt_wo(v_counter, :) = histcounts(mt_ms(mask_wo), edges_mt);
        mat_mt_nl(v_counter, :) = histcounts(mt_ms(mask_nl), edges_mt);
        mat_mt_pr(v_counter, :) = histcounts(mt_ms(mask_pr), edges_mt);

        mat_rt_wo(v_counter, :) = histcounts(offset_ms(mask_wo), edges_rt);
        mat_rt_nl(v_counter, :) = histcounts(offset_ms(mask_nl), edges_rt);
        mat_rt_pr(v_counter, :) = histcounts(offset_ms(mask_pr), edges_rt);

        % Compute active reaching movement count at each millisecond t in [0, 1300] ms
        % (1) All non-tech/comp bad trajectories for Sheet 5 compatibility
        valid_traj_trials = find(~real_tech_bad & ~comp_bad & valid_num & ~(onset_ms <= 0 & mt_ms <= 0) & offset_ms > onset_ms);
        active_cnt = zeros(size(t_ms_grid));
        on_v  = onset_ms(valid_traj_trials);
        off_v = offset_ms(valid_traj_trials);
        for tr_i = 1:numel(valid_traj_trials)
            t1 = max(0, floor(on_v(tr_i)));
            t2 = min(1300, ceil(off_v(tr_i)));
            if t2 >= t1
                active_cnt((t1+1):(t2+1)) = active_cnt((t1+1):(t2+1)) + 1;
            end
        end
        sub_active_curves{idx_45} = active_cnt;

        % (2) Only ~early_res & ~late_res trajectories for Fig S4 (eliminates ~310 ms late-abort knee)
        valid_ok_trials = find(~real_tech_bad & ~comp_bad & ~early_mask & ~late_mask & valid_num & offset_ms > onset_ms);
        active_ok = zeros(size(t_ms_grid));
        on_ok  = onset_ms(valid_ok_trials);
        off_ok = offset_ms(valid_ok_trials);
        for tr_i = 1:numel(valid_ok_trials)
            t1 = max(0, floor(on_ok(tr_i)));
            t2 = min(1300, ceil(off_ok(tr_i)));
            if t2 >= t1
                active_ok((t1+1):(t2+1)) = active_ok((t1+1):(t2+1)) + 1;
            end
        end
        sub_active_ok_curves{idx_45} = active_ok;
        sub_onset_wo{idx_45} = onset_ms(mask_wo);
    end

    % Group averages (equal weight per participant within each cohort, unsmoothed!)
    avg_on_wo_42 = mean(mat_on_wo, 1);
    avg_on_nl_42 = mean(mat_on_nl, 1);
    avg_on_pr_42 = mean(mat_on_pr, 1);

    avg_on_wo_30 = mean(mat_on_wo(is_good_valid, :), 1);
    avg_on_nl_31 = mean(mat_on_nl(is_nl_valid, :), 1);
    avg_on_pr_30 = mean(mat_on_pr(is_good_valid, :), 1);

    avg_mt_wo_42 = mean(mat_mt_wo, 1);
    avg_mt_nl_42 = mean(mat_mt_nl, 1);
    avg_mt_pr_42 = mean(mat_mt_pr, 1);

    avg_mt_wo_30 = mean(mat_mt_wo(is_good_valid, :), 1);
    avg_mt_nl_31 = mean(mat_mt_nl(is_nl_valid, :), 1);
    avg_mt_pr_30 = mean(mat_mt_pr(is_good_valid, :), 1);

    avg_rt_wo_42 = mean(mat_rt_wo, 1);
    avg_rt_nl_42 = mean(mat_rt_nl, 1);
    avg_rt_pr_42 = mean(mat_rt_pr, 1);

    avg_rt_wo_30 = mean(mat_rt_wo(is_good_valid, :), 1);
    avg_rt_nl_31 = mean(mat_rt_nl(is_nl_valid, :), 1);
    avg_rt_pr_30 = mean(mat_rt_pr(is_good_valid, :), 1);

    n_inc_30 = sum(is_good_valid);
    n_nl_31  = sum(is_nl_valid);

    mean_3sd_42 = mean(sub_slow_thresh(sub_has_data), 'omitnan');
    mean_3sd_30 = mean(sub_slow_thresh(ismember(all_45_subs, good_subs)), 'omitnan');

    % --- Render Fig_S3_Group_Timing_Histograms (2 rows x 3 columns with left row titles) ---
    % Row 1: All Valid-Data Participants (N = 42, matched denominator across all three curves)
    % Row 2: Analytic Sample Cohorts (Included N = 30 & N = 31 participants; all curves filter solely by time)
    figS3 = figure('Name', 'Fig_S3_Group_Timing_Histograms', 'Color', 'w', ...
        'Position', [30, 20, 1320, 1220], 'Visible', 'off');

    annotation(figS3, 'textbox', [0.08, 0.942, 0.90, 0.052], ...
        'String', 'Group-Level Temporal Distributions Across Timing Exclusion Stages (All PAS Ratings & Target Choices)', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri', 'EdgeColor', 'none');

    ax_bg = axes('Parent', figS3, 'Position', [0, 0, 1, 1], 'Visible', 'off', ...
        'XLim', [0, 1], 'YLim', [0, 1], 'HitTest', 'off');
    hold(ax_bg, 'on');

    col_lefts = [0.130, 0.438, 0.745];
    col_w     = 0.235;
    row_bots  = [0.545, 0.088];
    row_h     = 0.340;

    row_banner_cols = {[0.95, 0.95, 0.97], [0.93, 0.96, 0.99]};
    row_edge_cols   = {[0.78, 0.78, 0.84], [0.68, 0.78, 0.90]};
    row_text_cols   = {[0.18, 0.18, 0.24], [0.08, 0.30, 0.62]};
    row_titles_left = { ...
        sprintf('All Valid-Data Participants (N = %d)\n\\fontsize{11.5}\\rmFull-sample comparison across exclusion stages', n_valid_subs), ...
        sprintf('Analytic Sample Cohorts (N = %d & N = %d)\n\\fontsize{11.5}\\rmIncluded subsamples from main & >3 SD analyses', n_inc_30, n_nl_31) ...
    };
    for r_i = 1:2
        yb = row_bots(r_i);
        yh = row_h;
        patch(ax_bg, [0.006, 0.062, 0.062, 0.006], [yb, yb, yb + yh, yb + yh], ...
            row_banner_cols{r_i}, 'EdgeColor', row_edge_cols{r_i}, 'LineWidth', 1.2);
        text(ax_bg, 0.034, yb + yh / 2, row_titles_left{r_i}, ...
            'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 13.5, 'FontWeight', 'bold', 'Color', row_text_cols{r_i}, ...
            'FontName', 'Calibri', 'Interpreter', 'tex');
    end

    col_wo   = [0.82, 0.20, 0.18]; % Crimson red: Without time exclusions
    col_nl   = [0.92, 0.56, 0.06]; % Amber: Online time excl (100-340 ms), long durations retained
    col_pr   = [0.12, 0.42, 0.78]; % Royal Blue: All temporal excl (<= +3 SD)
    col_3sd  = [0.76, 0.10, 0.62]; % Magenta: Mean offline +3 SD cutoff

    max_y_on = max([avg_on_wo_42, avg_on_nl_42, avg_on_pr_42, avg_on_wo_30, avg_on_nl_31, avg_on_pr_30]) * 1.58;
    max_y_mt = max([avg_mt_wo_42, avg_mt_nl_42, avg_mt_pr_42, avg_mt_wo_30, avg_mt_nl_31, avg_mt_pr_30]) * 1.62;
    max_y_rt = max([avg_rt_wo_42, avg_rt_nl_42, avg_rt_pr_42, avg_rt_wo_30, avg_rt_nl_31, avg_rt_pr_30]) * 1.58;

    row_cfg = { ...
        struct('wo_lbl',  sprintf('All trials (no time excl., N = %d)', n_valid_subs), ...
               'nl_lbl',  sprintf('Online 100-340 ms, >3 SD kept (N = %d)', n_valid_subs), ...
               'pr_lbl',  sprintf('All temporal excl. (<= +3 SD, N = %d)', n_valid_subs), ...
               'cut_3sd', mean_3sd_42, ...
               'on_wo', avg_on_wo_42, 'on_nl', avg_on_nl_42, 'on_pr', avg_on_pr_42, ...
               'mt_wo', avg_mt_wo_42, 'mt_nl', avg_mt_nl_42, 'mt_pr', avg_mt_pr_42, ...
               'rt_wo', avg_rt_wo_42, 'rt_nl', avg_rt_nl_42, 'rt_pr', avg_rt_pr_42, ...
               'a_lbl', 'a1', 'b_lbl', 'b1', 'c_lbl', 'c1'), ...
        struct('wo_lbl',  sprintf('No time excl. (Inc. N = %d cohort)', n_inc_30), ...
               'nl_lbl',  sprintf('w/o >3 SD excl. cohort (N = %d)', n_nl_31), ...
               'pr_lbl',  sprintf('Pre-reg. cohort (<= +3 SD, N = %d)', n_inc_30), ...
               'cut_3sd', mean_3sd_30, ...
               'on_wo', avg_on_wo_30, 'on_nl', avg_on_nl_31, 'on_pr', avg_on_pr_30, ...
               'mt_wo', avg_mt_wo_30, 'mt_nl', avg_mt_nl_31, 'mt_pr', avg_mt_pr_30, ...
               'rt_wo', avg_rt_wo_30, 'rt_nl', avg_rt_nl_31, 'rt_pr', avg_rt_pr_30, ...
               'a_lbl', 'a2', 'b_lbl', 'b2', 'c_lbl', 'c2') ...
    };

    for r_i = 1:2
        rc = row_cfg{r_i};
        yb = row_bots(r_i);

        % Column 1: Reaching Onset (0 - 700 ms)
        ax_a = axes('Parent', figS3, 'Position', [col_lefts(1), yb, col_w, row_h]);
        hold(ax_a, 'on');
        plot(ax_a, [0, mids_onset, edges_onset(end)], [0, rc.on_wo, 0], '-',  'Color', col_wo, 'LineWidth', 2.2, 'DisplayName', rc.wo_lbl);
        plot(ax_a, [0, mids_onset, edges_onset(end)], [0, rc.on_nl, 0], '--', 'Color', col_nl, 'LineWidth', 2.3, 'DisplayName', rc.nl_lbl);
        plot(ax_a, [0, mids_onset, edges_onset(end)], [0, rc.on_pr, 0], '-',  'Color', col_pr, 'LineWidth', 2.3, 'DisplayName', rc.pr_lbl);
        xline(ax_a, 100, 'k--', 'LineWidth', 1.4, 'DisplayName', 'Too Early Cutoff (100 ms)');
        xline(ax_a, 340, 'k:',  'LineWidth', 1.5, 'DisplayName', 'Too Late Cutoff (340 ms)');
        text(ax_a, 52, max_y_on * 0.42, 'Aborted (0 ms)', 'Rotation', 90, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 10.5, 'Color', col_wo, 'FontWeight', 'bold', 'FontName', 'Calibri');
        xlim(ax_a, [0, 700]);
        ylim(ax_a, [0, max_y_on]);
        xticks(ax_a, [0, 200, 400, 600]);
        yticks(ax_a, 0:5:floor(max_y_on));
        if r_i == 2, xlabel(ax_a, 'Reaching Onset (ms)', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri'); end
        ylabel(ax_a, {'Mean Trials / Participant', '(per 15 ms bin)'}, 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
        title(ax_a, sprintf('(%s) Reaching Onset', rc.a_lbl), 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
        legend(ax_a, 'Location', 'northeast', 'FontSize', 11.5, 'Box', 'on', 'Color', 'w', 'EdgeColor', 'none', 'FontName', 'Calibri');
        set(ax_a, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', 'Calibri', 'LineWidth', 2.6);
        box(ax_a, 'off');

        % Column 2: Reaching Duration (0 - 900 ms)
        ax_b = axes('Parent', figS3, 'Position', [col_lefts(2), yb, col_w, row_h]);
        hold(ax_b, 'on');
        plot(ax_b, [0, mids_mt, edges_mt(end)], [0, rc.mt_wo, 0], '-',  'Color', col_wo, 'LineWidth', 2.2, 'DisplayName', rc.wo_lbl);
        plot(ax_b, [0, mids_mt, edges_mt(end)], [0, rc.mt_nl, 0], '--', 'Color', col_nl, 'LineWidth', 2.3, 'DisplayName', rc.nl_lbl);
        plot(ax_b, [0, mids_mt, edges_mt(end)], [0, rc.mt_pr, 0], '-',  'Color', col_pr, 'LineWidth', 2.3, 'DisplayName', rc.pr_lbl);
        xline(ax_b, 420, 'k--', 'LineWidth', 1.4, 'DisplayName', '"Speed Up" Feedback (420 ms)');
        xline(ax_b, rc.cut_3sd, '-.', 'Color', col_3sd, 'LineWidth', 1.7, ...
            'DisplayName', sprintf('Mean +3 SD Cutoff (%.1f ms)', rc.cut_3sd));
        xlim(ax_b, [0, 900]);
        ylim(ax_b, [0, max_y_mt]);
        xticks(ax_b, [0, 300, 600, 900]);
        yticks(ax_b, 0:5:floor(max_y_mt));
        if r_i == 2, xlabel(ax_b, 'Reaching Duration (ms)', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri'); end
        ylabel(ax_b, {'Mean Trials / Participant', '(per 20 ms bin)'}, 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
        title(ax_b, sprintf('(%s) Reaching Duration', rc.b_lbl), 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
        legend(ax_b, 'Location', 'northeast', 'FontSize', 11.5, 'Box', 'on', 'Color', 'w', 'EdgeColor', 'none', 'FontName', 'Calibri');
        set(ax_b, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', 'Calibri', 'LineWidth', 2.6);
        box(ax_b, 'off');

        % Column 3: Overall Response Duration (0 - 1450 ms)
        ax_c = axes('Parent', figS3, 'Position', [col_lefts(3), yb, col_w, row_h]);
        hold(ax_c, 'on');
        patch(ax_c, [0, 100, 100, 0], [0, 0, max_y_rt * 0.62, max_y_rt * 0.62], ...
            [1.0, 0.88, 0.88], 'FaceAlpha', 0.45, 'EdgeColor', [0.85, 0.55, 0.55], ...
            'LineStyle', ':', 'DisplayName', 'Too Early (0-100 ms)');
        text(ax_c, 50, max_y_rt * 0.44, 'Too Early', 'Rotation', 90, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 11.0, 'FontWeight', 'bold', ...
            'Color', [0.65, 0.12, 0.12], 'FontName', 'Calibri');

        plot(ax_c, [0, mids_rt, edges_rt(end)], [0, rc.rt_wo, 0], '-',  'Color', col_wo, 'LineWidth', 2.2, 'DisplayName', rc.wo_lbl);
        plot(ax_c, [0, mids_rt, edges_rt(end)], [0, rc.rt_nl, 0], '--', 'Color', col_nl, 'LineWidth', 2.3, 'DisplayName', rc.nl_lbl);
        plot(ax_c, [0, mids_rt, edges_rt(end)], [0, rc.rt_pr, 0], '-',  'Color', col_pr, 'LineWidth', 2.3, 'DisplayName', rc.pr_lbl);
        xline(ax_c, 320, ':', 'Color', [0.45, 0.08, 0.08], 'LineWidth', 1.5, 'DisplayName', '"Too Late" Abort (~320 ms)');
        xlim(ax_c, [0, 1450]);
        ylim(ax_c, [0, max_y_rt]);
        xticks(ax_c, [0, 400, 800, 1200]);
        yticks(ax_c, 0:5:floor(max_y_rt));
        if r_i == 2, xlabel(ax_c, 'Overall Response Duration (ms)', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri'); end
        ylabel(ax_c, {'Mean Trials / Participant', '(per 25 ms bin)'}, 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
        title(ax_c, sprintf('(%s) Overall Response Duration', rc.c_lbl), 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
        legend(ax_c, 'Location', 'northeast', 'FontSize', 11.5, 'Box', 'on', 'Color', 'w', 'EdgeColor', 'none', 'FontName', 'Calibri');
        set(ax_c, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', 'Calibri', 'LineWidth', 2.6);
        box(ax_c, 'off');
    end

    % --- Render Fig_S4_All_Participants_Timing_Grid (12 rows x 4 columns = 48 slots, 45 participants) ---
    figS4 = figure('Name', 'Fig_S4_All_Participants_Timing_Grid', 'Color', 'w', ...
        'Position', [20, 20, 1760, 2120], 'Visible', 'off');
    tl4 = tiledlayout(figS4, 12, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl4, 'Active Movements (Excluding Too Early & Too Late) & Reaching Onset Distributions Across All 45 Participants', ...
        'FontSize', 17.5, 'FontWeight', 'bold', 'FontName', 'Calibri');

    n_cols = 4;
    h_leg_items = gobjects(1, 6);
    leg_captured = false;
    onset_edges = 0:20:1200;

    for idx_45 = 1:48
        if idx_45 > numel(all_45_subs)
            ax = nexttile(tl4, idx_45);
            axis(ax, 'off');
            continue;
        end
        s = all_45_subs(idx_45);
        col_idx = mod(idx_45 - 1, n_cols) + 1;
        is_bottom_col_tile = (idx_45 + n_cols > numel(all_45_subs));

        ax = nexttile(tl4, idx_45);
        hold(ax, 'on');

        if ~sub_has_data(idx_45)
            set(ax, 'Color', [0.96, 0.96, 0.96]);
            xlim(ax, [0, 1200]); ylim(ax, [0, 280]);
            yline(ax, 240, ':', 'Color', [0.85, 0.85, 0.85], 'LineWidth', 0.8, 'HandleVisibility', 'off');
            text(ax, 600, 120, 'Technical Issue - No Data', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', 10.5, 'FontWeight', 'bold', 'FontAngle', 'italic', 'FontName', 'Calibri', 'Color', [0.45, 0.45, 0.45]);
            text(ax, 600, 262, sprintf('Prtcp %d', s), 'HorizontalAlignment', 'center', ...
                'FontSize', 10.5, 'FontWeight', 'bold', 'FontName', 'Calibri', 'Color', [0.35, 0.35, 0.35]);
            yticks(ax, [0, 120, 240]);
            if col_idx > 1, set(ax, 'YTickLabel', []); end
            xticks(ax, [0, 340, 600, 900, 1200]);
            if ~is_bottom_col_tile
                set(ax, 'XTickLabel', []);
            else
                xlabel(ax, 'Time From Target Onset (ms)', 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
            end
            set(ax, 'TickDir', 'out', 'FontSize', 9.5, 'FontName', 'Calibri', 'LineWidth', 1.3);
            box(ax, 'on');
            continue;
        end

        y_act = sub_active_ok_curves{idx_45};
        on_wo = sub_onset_wo{idx_45};
        t_slow = sub_slow_thresh(idx_45);

        yline(ax, 240, ':', 'Color', [0.85, 0.85, 0.85], 'LineWidth', 0.8, 'HandleVisibility', 'off');

        % Overlaid Reaching Onset histogram (all non-tech-bad trials -> shows <100 ms & >340 ms)
        h_on = histogram(ax, on_wo, onset_edges, ...
            'FaceColor', [0.22, 0.52, 0.84], 'FaceAlpha', 0.48, ...
            'EdgeColor', [0.14, 0.36, 0.64], 'LineWidth', 0.6);

        % Fill > individual offline slow threshold under valid active movement curve with gold/yellow
        mask_slow_t = t_ms_grid >= round(t_slow);
        t_s = t_ms_grid(mask_slow_t);
        y_s = y_act(mask_slow_t);
        h_p2 = patch(ax, [t_s, fliplr(t_s)], [y_s, zeros(size(y_s))], ...
            [1.00, 0.88, 0.36], 'FaceAlpha', 0.78, 'EdgeColor', 'none');

        % Active movement occupancy curve (~early_res & ~late_res ONLY -> no ~310 ms knee)
        h_ln = plot(ax, t_ms_grid, y_act, 'k-', 'LineWidth', 1.6);

        % Vertical cutoff markers (Early 100 ms, Late 340 ms, and Slow Threshold)
        h_early = xline(ax, 100, '--', 'Color', [0.82, 0.16, 0.16], 'LineWidth', 1.4);
        h_late  = xline(ax, 340, ':',  'Color', [0.58, 0.12, 0.58], 'LineWidth', 1.6);
        h_slow  = xline(ax, t_slow, 'k--', 'LineWidth', 1.3);

        if ~leg_captured
            h_leg_items = [h_ln, h_on, h_early, h_late, h_p2, h_slow];
            leg_captured = true;
        end

        is_inc = ismember(s, good_subs);
        if is_inc
            lbl_str = sprintf('Prtcp %d (Included, N=%d)', s, sub_n_trials_valid(idx_45));
            lbl_col = [0.08, 0.44, 0.14];
        else
            lbl_str = sprintf('Prtcp %d (Excluded, N=%d)', s, sub_n_trials_valid(idx_45));
            lbl_col = [0.74, 0.12, 0.12];
        end
        text(ax, 600, 262, lbl_str, 'HorizontalAlignment', 'center', ...
            'FontSize', 10.2, 'FontWeight', 'bold', 'FontName', 'Calibri', 'Color', lbl_col);

        xlim(ax, [0, 1200]);
        ylim(ax, [0, 280]);
        yticks(ax, [0, 120, 240]);
        if col_idx > 1, set(ax, 'YTickLabel', []); end
        xticks(ax, [0, 340, 600, 900, 1200]);
        set(ax, 'TickDir', 'out', 'FontSize', 9.5, 'FontName', 'Calibri', 'LineWidth', 1.3, 'Layer', 'top');
        if ~is_bottom_col_tile
            set(ax, 'XTickLabel', []);
        else
            xlabel(ax, 'Time From Target Onset (ms)', 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
        end
        if col_idx == 1
            ylabel(ax, 'Trials', 'FontSize', 11.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
        end
        box(ax, 'off');
    end

    if leg_captured
        lg4 = legend(h_leg_items, ...
            {'Active Reaching Trials (~Early & ~Late)', ...
             'All Reaching Onsets (20 ms bins)', ...
             'Too Early Cutoff (100 ms)', ...
             'Too Late Cutoff (340 ms)', ...
             'Exceeds Slow Duration Threshold (> +3 SD)', ...
             'Individual Offline Slow Threshold (+3 SD)'}, ...
            'Orientation', 'horizontal', 'FontSize', 12.2, 'FontName', 'Calibri', 'Box', 'on', 'Color', 'w', 'NumColumns', 3);
        lg4.Layout.Tile = 'north';
    end

    % Package data for Sheet 5 (Participants_Temporal_Dynamics)
    td_struct = struct();
    td_struct.Group_Onset_Bins = table(mids_onset(:), avg_on_wo_42(:), avg_on_nl_42(:), avg_on_pr_42(:), ...
        avg_on_wo_30(:), avg_on_nl_31(:), avg_on_pr_30(:), ...
        'VariableNames', {'Onset_Bin_Center_ms', ...
                          'All42_Without_Temporal_Excl', 'All42_Online_Time_Excl_Long_Retained', 'All42_All_Temporal_Excl', ...
                          'Inc30_Without_Temporal_Excl', 'N31_PreReg_WO_Long_Dur_Excl', 'N30_PreReg_Analysis'});
    td_struct.Group_MT_Bins = table(mids_mt(:), avg_mt_wo_42(:), avg_mt_nl_42(:), avg_mt_pr_42(:), ...
        avg_mt_wo_30(:), avg_mt_nl_31(:), avg_mt_pr_30(:), ...
        'VariableNames', {'Duration_Bin_Center_ms', ...
                          'All42_Without_Temporal_Excl', 'All42_Online_Time_Excl_Long_Retained', 'All42_All_Temporal_Excl', ...
                          'Inc30_Without_Temporal_Excl', 'N31_PreReg_WO_Long_Dur_Excl', 'N30_PreReg_Analysis'});
    td_struct.Group_Overall_RT_Bins = table(mids_rt(:), avg_rt_wo_42(:), avg_rt_nl_42(:), avg_rt_pr_42(:), ...
        avg_rt_wo_30(:), avg_rt_nl_31(:), avg_rt_pr_30(:), ...
        'VariableNames', {'Overall_Response_Duration_Bin_Center_ms', ...
                          'All42_Without_Temporal_Excl', 'All42_Online_Time_Excl_Long_Retained', 'All42_All_Temporal_Excl', ...
                          'Inc30_Without_Temporal_Excl', 'N31_PreReg_WO_Long_Dur_Excl', 'N30_PreReg_Analysis'});

    % Participant-level temporal summary + decimated (every 10 ms) active-trial curve for Sheet 5
    prtcp_labels = arrayfun(@(x) sprintf('Prtcp %d', x), all_45_subs(:), 'UniformOutput', false);
    status_col = cell(numel(all_45_subs), 1);
    for i = 1:numel(all_45_subs)
        if ~sub_has_data(i)
            status_col{i} = 'Technical Issue - No Data Collected';
        elseif ismember(all_45_subs(i), good_subs)
            status_col{i} = 'Included (N=30)';
        else
            status_col{i} = 'Excluded (Insufficient Valid Trials)';
        end
    end
    t_sample_10ms = 0:10:1200;
    act_mat_10ms = nan(numel(all_45_subs), numel(t_sample_10ms));
    for i = 1:numel(all_45_subs)
        if sub_has_data(i)
            act_mat_10ms(i, :) = sub_active_curves{i}(t_sample_10ms + 1);
        end
    end
    base_sub_tbl = table(prtcp_labels, status_col, sub_n_trials_valid, ...
        round(sub_mean_onset, 2), round(sub_sd_onset, 2), ...
        round(sub_mean_mt, 2), round(sub_sd_mt, 2), round(sub_slow_thresh, 2), ...
        'VariableNames', {'Participant', 'Inclusion_Status', 'Included_PAS1_Reaching_Trials', ...
                          'Mean_Onset_ms', 'SD_Onset_ms', 'Mean_Duration_ms', 'SD_Duration_ms', ...
                          'Offline_Slow_Threshold_3SD_ms'});
    time_col_names = arrayfun(@(t) sprintf('Active_Trials_%dms', t), t_sample_10ms, 'UniformOutput', false);
    act_tbl = array2table(act_mat_10ms, 'VariableNames', time_col_names);
    td_struct.Participant_Temporal_Summary = [base_sub_tbl, act_tbl];
end

% =========================================================================
% HELPER: Render Figure S5 (Objective Awareness Robustness: Congruent + JZS BF)
% =========================================================================
function figS5 = render_figS5_objective_awareness_robustness(f1_avg, good_subs, pps)
    plt_draft = get_draft_plt_params();
    font_name = plt_draft.font_name;

    figS5 = figure('Name', 'Fig_S5_Objective_Awareness_Robustness', 'Color', 'w', ...
        'Position', [30, 40, 1320, 600], 'Visible', 'off');

    % Panel (a): Objective Prime Awareness in Congruent Trials (Draft color & style, no in-plot text stats)
    ax_a = axes('Parent', figS5, 'Position', [0.080, 0.145, 0.340, 0.745], 'Color', 'w');
    hold(ax_a, 'on');

    reach_con_acc = f1_avg.reach_avg_each.fc_prime.con(good_subs) * 100;
    kb_con_acc    = f1_avg.keyboard_avg_each.fc_prime.con(good_subs) * 100;

    xlim(ax_a, [0.40, 2.60]);
    ylim(ax_a, [-4, 106]);
    xticks(ax_a, [1, 2]);
    xticklabels(ax_a, {'Reaching', 'Key Press'});
    yticks(ax_a, 0:20:100);

    yline(ax_a, 50, '--', 'Color', [0.65, 0.65, 0.65], 'LineWidth', 2.2, 'HandleVisibility', 'off');

    [~, h_sc1] = place_non_overlapping_beeswarm(ax_a, reach_con_acc, 1.0, 0.36, plt_draft.con_col, 9.0, 0.95);
    [~, h_sc2] = place_non_overlapping_beeswarm(ax_a, kb_con_acc,    2.0, 0.36, plt_draft.con_col, 9.0, 0.95);
    if ~isempty(h_sc1) && isgraphics(h_sc1), set(h_sc1, 'MarkerEdgeColor', 'none'); end
    if ~isempty(h_sc2) && isgraphics(h_sc2), set(h_sc2, 'MarkerEdgeColor', 'none'); end

    n_sub = numel(good_subs);
    t_crit = tinv(0.975, n_sub - 1);
    m_r = mean(reach_con_acc, 'omitnan');
    ci_r = t_crit * std(reach_con_acc, 0, 'omitnan') / sqrt(n_sub);
    m_k = mean(kb_con_acc, 'omitnan');
    ci_k = t_crit * std(kb_con_acc, 0, 'omitnan') / sqrt(n_sub);

    plot(ax_a, [1 - 0.24, 1 + 0.24], [m_r, m_r], '-', 'Color', plt_draft.con_col, 'LineWidth', 6.0);
    plot(ax_a, [1 - 0.24, 1 + 0.24], [m_r, m_r], '-', 'Color', [0.70, 0.70, 0.70, 0.50], 'LineWidth', 6.0);
    errorbar(ax_a, 1, m_r, ci_r, 'k', 'LineStyle', 'none', 'LineWidth', 2.6, 'CapSize', 18);

    plot(ax_a, [2 - 0.24, 2 + 0.24], [m_k, m_k], '-', 'Color', plt_draft.con_col, 'LineWidth', 6.0);
    plot(ax_a, [2 - 0.24, 2 + 0.24], [m_k, m_k], '-', 'Color', [0.70, 0.70, 0.70, 0.50], 'LineWidth', 6.0);
    errorbar(ax_a, 2, m_k, ci_k, 'k', 'LineStyle', 'none', 'LineWidth', 2.6, 'CapSize', 18);

    ylabel(ax_a, 'Performance (%)', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    title(ax_a, '(a) Congruent Trials', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', font_name);
    set(ax_a, 'TickDir', 'in', 'FontSize', 13.0, 'FontName', font_name, 'LineWidth', 2.6);
    box(ax_a, 'off');

    % Panel (b): JZS Bayes Factor Model & Prior Sensitivity Curve
    ax_b1 = axes('Parent', figS5, 'Position', [0.475, 0.560, 0.505, 0.330]);
    axis(ax_b1, 'off');
    hold(ax_b1, 'on');
    xlim(ax_b1, [0, 10]); ylim(ax_b1, [0, 5.2]);
    title(ax_b1, '(b) JZS Bayesian Model Specification & Prior Robustness', ...
        'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', font_name);

    % Draw clean plates/nodes for JZS hierarchy
    rectangle(ax_b1, 'Position', [0.15, 0.2, 9.7, 4.6], 'Curvature', 0.08, 'FaceColor', [0.97, 0.98, 1.00], 'EdgeColor', [0.55, 0.65, 0.80], 'LineWidth', 1.5);
    text(ax_b1, 5.0, 4.18, 'H_0: \delta = 0 (Chance Accuracy, \mu_0 = 50%)   vs.   H_1: \delta \sim Cauchy(0, r = 0.707)', ...
        'HorizontalAlignment', 'center', 'FontSize', 11.2, 'FontWeight', 'bold', 'FontName', font_name, 'Color', [0.12, 0.22, 0.45]);
    text(ax_b1, 5.0, 3.22, 'Non-Informative Jeffreys Variance Prior:   p(\sigma^2) \propto 1 / \sigma^2', ...
        'HorizontalAlignment', 'center', 'FontSize', 11.0, 'FontName', font_name, 'Color', [0.20, 0.20, 0.20]);
    text(ax_b1, 5.0, 2.24, 'Participant Likelihood (i = 1..30, PAS = 1):   Y_i | \mu, \sigma^2 \sim Normal(\mu_0 + \delta\sigma, \sigma^2)', ...
        'HorizontalAlignment', 'center', 'FontSize', 11.0, 'FontName', font_name, 'Color', [0.20, 0.20, 0.20]);
    text(ax_b1, 5.0, 1.05, sprintf('Incongruent Trials:  Reaching BF_{01} = %.2f  |  Key Press BF_{01} = %.2f\nCongruent Trials:    Reaching BF_{01} = %.2f  |  Key Press BF_{01} = %.2f', ...
        pps.reach_BF01(1), pps.kb_BF01(1), pps.reach_BF01(2), pps.kb_BF01(2)), ...
        'HorizontalAlignment', 'center', 'FontSize', 11.0, 'FontWeight', 'bold', 'FontName', font_name, 'Color', [0.10, 0.38, 0.18]);

    % Prior sensitivity plot across Cauchy scale r in [0.1, 1.5]
    ax_b2 = axes('Parent', figS5, 'Position', [0.515, 0.145, 0.455, 0.345], 'Color', 'w');
    hold(ax_b2, 'on');
    r_grid = linspace(0.10, 1.50, 60);
    bf01_r_inc = arrayfun(@(r) compute_jzs_bf01(pps.reach_tVal(1), pps.reach_df(1), r), r_grid);
    bf01_k_inc = arrayfun(@(r) compute_jzs_bf01(pps.kb_tVal(1),    pps.kb_df(1),    r), r_grid);
    bf01_r_con = arrayfun(@(r) compute_jzs_bf01(pps.reach_tVal(2), pps.reach_df(2), r), r_grid);
    bf01_k_con = arrayfun(@(r) compute_jzs_bf01(pps.kb_tVal(2),    pps.kb_df(2),    r), r_grid);

    yline(ax_b2, 3.0, ':',  'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.6, 'HandleVisibility', 'off');
    yline(ax_b2, 1.0, '--', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.4, 'HandleVisibility', 'off');
    xline(ax_b2, sqrt(2)/2, ':', 'Color', [0.40, 0.40, 0.40], 'LineWidth', 1.6, 'HandleVisibility', 'off');

    plot(ax_b2, r_grid, bf01_r_inc, '-',  'Color', plt_draft.incon_col, 'LineWidth', 3.0, 'DisplayName', 'Reaching (Incongruent)');
    plot(ax_b2, r_grid, bf01_k_inc, '--', 'Color', plt_draft.incon_col, 'LineWidth', 2.6, 'DisplayName', 'Key Press (Incongruent)');
    plot(ax_b2, r_grid, bf01_r_con, '-',  'Color', plt_draft.con_col,   'LineWidth', 3.0, 'DisplayName', 'Reaching (Congruent)');
    plot(ax_b2, r_grid, bf01_k_con, '--', 'Color', plt_draft.con_col,   'LineWidth', 2.6, 'DisplayName', 'Key Press (Congruent)');

    xlim(ax_b2, [0.10, 1.50]);
    ylim(ax_b2, [0, 10]);
    xlabel(ax_b2, 'Cauchy Prior Scale Factor (r)', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    ylabel(ax_b2, 'Bayes Factor (BF_{01})', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    legend(ax_b2, 'Location', 'northwest', 'FontSize', 11.2, 'FontName', font_name, 'Box', 'off', 'NumColumns', 2);
    set(ax_b2, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', font_name, 'LineWidth', 2.6);
    box(ax_b2, 'off');
end

function bf01 = compute_jzs_bf01(t_val, df, r_scale)
    n_obs = df + 1;
    num_null = (1 + (t_val^2) / df)^(-(df + 1) / 2);
    integrand = @(g) ((1 + n_obs .* g .* (r_scale^2)).^(-0.5)) .* ...
                     ((1 + (t_val^2) ./ ((1 + n_obs .* g .* (r_scale^2)) .* df)).^(-(df + 1) / 2)) .* ...
                     ((2 * pi)^(-0.5)) .* (g.^(-1.5)) .* exp(-1 ./ (2 .* g));
    denom_alt = integral(integrand, 0, Inf, 'RelTol', 1e-8, 'AbsTol', 1e-11);
    bf01 = num_null / denom_alt;
end

% =========================================================================
% HELPER: Render Figure S6 (Robustness Analysis Congruency: Panels a-i)
% =========================================================================
function figS6 = render_figS6_robustness(f2_avg, f2_subs, good_subs, tree_std_tbl, plt_p) %#ok<INUSD>
    y_lbls = {'Time (z-score)', 'Area (z-score)', 'Time (z-score)', 'Time (z-score)', ...
              'Distance (z-score)', 'COM (z-score)', 'MAD (z-score)', 'AUC (z-score)'};
    figS6 = render_congruency_composite_shared(f2_avg, f2_subs, good_subs, tree_std_tbl, ...
        '', struct('DAY', 'day2'), get_draft_plt_params(), true, ...
        'Fig_S6_Robustness_Analysis_Congruency', y_lbls);
end

% =========================================================================
% HELPER: Render Figure S7 (COM Dwell Distribution + Separated Threshold Sweep)
% =========================================================================
function figS7 = render_figS7_com_sweep(com_tbl, plt_p, f1_dir, good_subs) %#ok<INUSL>
    plt_draft = get_draft_plt_params();
    font_name = plt_draft.font_name;

    figS7 = figure('Name', 'Fig_S7_COM_Dwell_Time_Threshold_Sweep', 'Color', 'w', ...
        'Position', [40, 20, 1320, 1720], 'Visible', 'off');

    row_left = 0.115;
    row_w    = 0.835;
    row_h    = 0.158;
    row_bots = [0.778, 0.548, 0.318, 0.092];

    % Compute exact physical dwell times (ms) per COM event from f1_dir
    dwell_ms_vec = compute_com_dwell_ms(f1_dir, good_subs);

    % --- ROW 1 (a): Subject-Adjusted COM Dwell-Time Distribution + Sub-100 ms Inset ---
    ax_a = axes('Parent', figS7, 'Position', [row_left, row_bots(1), row_w, row_h], 'Color', 'w');
    hold(ax_a, 'on');
    histogram(ax_a, dwell_ms_vec, 0:15:500, 'FaceColor', plt_draft.con_col, 'EdgeColor', 'w', 'FaceAlpha', 0.88);
    yl_a = ylim(ax_a);
    ylim(ax_a, [0, yl_a(2) * 1.15]);
    xline(ax_a, 80, '--', '80 ms (Neuro-motor limit)', 'Color', plt_draft.incon_col, 'LineWidth', 2.4, ...
        'FontSize', 13.0, 'FontName', font_name, 'FontWeight', 'bold', 'LabelVerticalAlignment', 'top', 'LabelHorizontalAlignment', 'right');
    xline(ax_a, 50, ':k', '50 ms', 'LineWidth', 1.8, 'FontSize', 12.5, 'FontName', font_name, 'LabelHorizontalAlignment', 'left');
    xlim(ax_a, [0, 500]);
    xlabel(ax_a, 'Dwell Time per COM Event (ms)', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    ylabel(ax_a, 'COM Event Count', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    title(ax_a, '(a) Dwell-Time Distribution Across All Valid Trials', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', font_name);
    set(ax_a, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', font_name, 'LineWidth', 2.6);
    box(ax_a, 'off');

    % Sub-100 ms Inset (30% narrower: 0.36 -> 0.252) raised above blue histogram tail so Dwell (ms) clears bars
    ins_w = 0.252;
    ins_left = row_left + row_w - ins_w;
    ins_bot  = row_bots(1) + 0.064;
    ins_h    = row_h - 0.064;
    ax_ins = axes('Parent', figS7, 'Position', [ins_left, ins_bot, ins_w, ins_h], 'Color', 'w');
    hold(ax_ins, 'on');
    histogram(ax_ins, dwell_ms_vec, 0:5:100, 'FaceColor', [0.88, 0.36, 0.12], 'EdgeColor', 'w', 'FaceAlpha', 0.88);
    xline(ax_ins, 80, '--', '80 ms', 'Color', plt_draft.incon_col, 'LineWidth', 2.0, 'FontSize', 11.0, 'FontName', font_name, 'LabelVerticalAlignment', 'middle');
    xline(ax_ins, 50, ':k', '50 ms', 'LineWidth', 1.5, 'FontSize', 10.5, 'FontName', font_name, 'LabelVerticalAlignment', 'middle');
    xlim(ax_ins, [0, 100]);
    xlabel(ax_ins, 'Dwell (ms)', 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', font_name);
    ylabel(ax_ins, 'Count', 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', font_name);
    title(ax_ins, 'Sub-100 ms Noise Band', 'FontSize', 12.5, 'FontWeight', 'bold', 'FontName', font_name);
    set(ax_ins, 'TickDir', 'out', 'FontSize', 11.0, 'FontName', font_name, 'LineWidth', 2.0);
    box(ax_ins, 'off');
    uistack(ax_ins, 'top');

    % Prepare separated X-axis coordinates (Left: Normalized % path; Right: Physical ms)
    is_corr = strcmp(string(com_tbl.Correctness), 'Correct');
    is_incorr = strcmp(string(com_tbl.Correctness), 'Incorrect');
    corr_rows = find(is_corr);
    incorr_rows = find(is_incorr);

    samp_c = corr_rows(1:6);
    samp_i = incorr_rows(1:6);
    ms_c   = corr_rows(7:end);
    ms_i   = incorr_rows(7:end);

    x_s   = 1:6;
    x_sep = 6.9;
    x_m   = 7.8 + (0:(numel(ms_c) - 1));
    x_all_ticks = [x_s, x_m];
    all_lbls = {'0.5% (1)', '1.0% (2)', '2.5% (5)', '5.0% (10)', '7.5% (15)', '10.0% (20)', ...
                '10 ms', '25 ms', '50 ms', '80 ms'};
    x_lim_sw = [0.4, x_m(end) + 0.6];

    % --- ROW 2 (b): Mean COM (+/- SEM) ---
    ax_b = axes('Parent', figS7, 'Position', [row_left, row_bots(2), row_w, row_h], 'Color', 'w');
    hold(ax_b, 'on');
    xline(ax_b, x_sep, '--', 'Color', [0.55, 0.55, 0.55], 'LineWidth', 1.8, 'HandleVisibility', 'off');

    h_cc = errorbar(ax_b, x_s - 0.09, com_tbl.Congruent_Mean(samp_c), com_tbl.Congruent_SD(samp_c)/sqrt(30), ...
        'o-', 'Color', plt_draft.con_col, 'MarkerFaceColor', plt_draft.con_col, 'LineWidth', 2.4, 'MarkerSize', 8.0, 'DisplayName', 'Correct - Congruent');
    errorbar(ax_b, x_m - 0.09, com_tbl.Congruent_Mean(ms_c), com_tbl.Congruent_SD(ms_c)/sqrt(30), ...
        'o-', 'Color', plt_draft.con_col, 'MarkerFaceColor', plt_draft.con_col, 'LineWidth', 2.4, 'MarkerSize', 8.0, 'HandleVisibility', 'off');

    h_ci = errorbar(ax_b, x_s + 0.09, com_tbl.Incongruent_Mean(samp_c), com_tbl.Incongruent_SD(samp_c)/sqrt(30), ...
        's-', 'Color', plt_draft.incon_col, 'MarkerFaceColor', plt_draft.incon_col, 'LineWidth', 2.4, 'MarkerSize', 8.0, 'DisplayName', 'Correct - Incongruent');
    errorbar(ax_b, x_m + 0.09, com_tbl.Incongruent_Mean(ms_c), com_tbl.Incongruent_SD(ms_c)/sqrt(30), ...
        's-', 'Color', plt_draft.incon_col, 'MarkerFaceColor', plt_draft.incon_col, 'LineWidth', 2.4, 'MarkerSize', 8.0, 'HandleVisibility', 'off');

    h_ic = errorbar(ax_b, x_s - 0.09, com_tbl.Congruent_Mean(samp_i), com_tbl.Congruent_SD(samp_i)/sqrt(29), ...
        'o--', 'Color', plt_draft.con_col*0.55 + 0.45, 'MarkerFaceColor', 'w', 'LineWidth', 2.0, 'MarkerSize', 7.5, 'DisplayName', 'Incorrect - Congruent');
    errorbar(ax_b, x_m - 0.09, com_tbl.Congruent_Mean(ms_i), com_tbl.Congruent_SD(ms_i)/sqrt(29), ...
        'o--', 'Color', plt_draft.con_col*0.55 + 0.45, 'MarkerFaceColor', 'w', 'LineWidth', 2.0, 'MarkerSize', 7.5, 'HandleVisibility', 'off');

    h_ii = errorbar(ax_b, x_s + 0.09, com_tbl.Incongruent_Mean(samp_i), com_tbl.Incongruent_SD(samp_i)/sqrt(29), ...
        's--', 'Color', plt_draft.incon_col*0.55 + 0.45, 'MarkerFaceColor', 'w', 'LineWidth', 2.0, 'MarkerSize', 7.5, 'DisplayName', 'Incorrect - Incongruent');
    errorbar(ax_b, x_m + 0.09, com_tbl.Incongruent_Mean(ms_i), com_tbl.Incongruent_SD(ms_i)/sqrt(29), ...
        's--', 'Color', plt_draft.incon_col*0.55 + 0.45, 'MarkerFaceColor', 'w', 'LineWidth', 2.0, 'MarkerSize', 7.5, 'HandleVisibility', 'off');

    xlim(ax_b, x_lim_sw);
    yl_b = ylim(ax_b);
    text(ax_b, 3.5, yl_b(2) * 1.18, 'Normalized Threshold (% Path / Samples)', 'HorizontalAlignment', 'center', ...
        'FontSize', 13.0, 'FontWeight', 'bold', 'FontName', font_name, 'Color', [0.35, 0.35, 0.35]);
    text(ax_b, mean(x_m), yl_b(2) * 1.18, 'Physical Threshold (ms)', 'HorizontalAlignment', 'center', ...
        'FontSize', 13.0, 'FontWeight', 'bold', 'FontName', font_name, 'Color', [0.35, 0.35, 0.35]);
    ylim(ax_b, [yl_b(1), yl_b(2) * 1.28]);
    xticks(ax_b, x_all_ticks); xticklabels(ax_b, {});
    ylabel(ax_b, 'Mean COM (\pmSEM)', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    title(ax_b, '(b) Mean COM per Trial Across Dwell-Time Thresholds', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', font_name);
    lg_b = legend(ax_b, [h_cc, h_ci, h_ic, h_ii], 'FontSize', 12.0, 'FontName', font_name, 'Box', 'off', 'NumColumns', 2);
    lg_b.Position = [0.555, row_bots(2) + 0.052, 0.395, 0.044];
    set(ax_b, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', font_name, 'LineWidth', 2.6);
    box(ax_b, 'off');

    % --- ROW 3 (c): Uncorrected p-values ---
    ax_c = axes('Parent', figS7, 'Position', [row_left, row_bots(3), row_w, row_h], 'Color', 'w');
    hold(ax_c, 'on');
    xline(ax_c, x_sep, '--', 'Color', [0.55, 0.55, 0.55], 'LineWidth', 1.8, 'HandleVisibility', 'off');
    yline(ax_c, 0.05, '--k', 'p = .05', 'LineWidth', 1.8, 'FontSize', 12.5, 'FontName', font_name, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top', 'HandleVisibility', 'off');

    p_col = plt_draft.temporal_col;
    g_col = [0.50, 0.50, 0.50];

    h_pc = plot(ax_c, x_s, com_tbl.p_value_uncorrected(samp_c), 'o-', 'Color', p_col, 'MarkerFaceColor', p_col, 'LineWidth', 2.6, 'MarkerSize', 8.5, 'DisplayName', 'Correct Trials');
    plot(ax_c, x_m, com_tbl.p_value_uncorrected(ms_c), 'o-', 'Color', p_col, 'MarkerFaceColor', p_col, 'LineWidth', 2.6, 'MarkerSize', 8.5, 'HandleVisibility', 'off');
    h_pi = plot(ax_c, x_s, com_tbl.p_value_uncorrected(samp_i), 's--', 'Color', g_col, 'MarkerFaceColor', 'w', 'LineWidth', 2.0, 'MarkerSize', 8.0, 'DisplayName', 'Incorrect Trials');
    plot(ax_c, x_m, com_tbl.p_value_uncorrected(ms_i), 's--', 'Color', g_col, 'MarkerFaceColor', 'w', 'LineWidth', 2.0, 'MarkerSize', 8.0, 'HandleVisibility', 'off');

    xlim(ax_c, x_lim_sw); ylim(ax_c, [0, 1.05]);
    xticks(ax_c, x_all_ticks); xticklabels(ax_c, {});
    ylabel(ax_c, 'p-value', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    title(ax_c, '(c) Congruency Test Significance (Uncorrected p-value)', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', font_name);
    legend(ax_c, [h_pc, h_pi], 'Location', 'northwest', 'FontSize', 12.5, 'FontName', font_name, 'Box', 'off', 'Orientation', 'horizontal');
    set(ax_c, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', font_name, 'LineWidth', 2.6);
    box(ax_c, 'off');

    % --- ROW 4 (d): Effect Size (Cohen's dz) ---
    ax_d = axes('Parent', figS7, 'Position', [row_left, row_bots(4), row_w, row_h], 'Color', 'w');
    hold(ax_d, 'on');
    xline(ax_d, x_sep, '--', 'Color', [0.55, 0.55, 0.55], 'LineWidth', 1.8, 'HandleVisibility', 'off');
    yline(ax_d, 0, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');

    h_dc = plot(ax_d, x_s, com_tbl.Cohens_dz(samp_c), 'o-', 'Color', p_col, 'MarkerFaceColor', p_col, 'LineWidth', 2.6, 'MarkerSize', 8.5, 'DisplayName', 'Correct Trials (All p < .03)');
    plot(ax_d, x_m, com_tbl.Cohens_dz(ms_c), 'o-', 'Color', p_col, 'MarkerFaceColor', p_col, 'LineWidth', 2.6, 'MarkerSize', 8.5, 'HandleVisibility', 'off');
    h_di = plot(ax_d, x_s, com_tbl.Cohens_dz(samp_i), 's--', 'Color', g_col, 'MarkerFaceColor', 'w', 'LineWidth', 2.0, 'MarkerSize', 8.0, 'DisplayName', 'Incorrect Trials (All n.s.)');
    plot(ax_d, x_m, com_tbl.Cohens_dz(ms_i), 's--', 'Color', g_col, 'MarkerFaceColor', 'w', 'LineWidth', 2.0, 'MarkerSize', 8.0, 'HandleVisibility', 'off');

    xlim(ax_d, x_lim_sw); ylim(ax_d, [-0.35, 0.80]);
    xticks(ax_d, x_all_ticks); xticklabels(ax_d, all_lbls);
    xlabel(ax_d, 'Minimum Dwell-Time Threshold (% Path / Normalized Samples   |   Physical ms)', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    ylabel(ax_d, 'Cohen''s d_z', 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', font_name);
    title(ax_d, '(d) Congruency Effect Size (Cohen''s d_z) Across Thresholds', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', font_name);
    legend(ax_d, [h_dc, h_di], 'Location', 'northwest', 'FontSize', 12.5, 'FontName', font_name, 'Box', 'off', 'Orientation', 'horizontal');
    set(ax_d, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', font_name, 'LineWidth', 2.6);
    box(ax_d, 'off');
end

function dwell_ms_vec = compute_com_dwell_ms(f1_dir, good_subs)
    bt_files = dir(fullfile(f1_dir, 'bad_trials_*.mat'));
    reach_bad_trials = load(fullfile(f1_dir, bt_files(1).name)).reach_bad_trials;
    dwell_cell = cell(numel(good_subs), 1);

    for s_idx = 1:numel(good_subs)
        iSub = good_subs(s_idx);
        traj_tab = load(fullfile(f1_dir, sprintf('sub%dday2_reach_traj_proc.mat', iSub))).reach_traj_table;
        data_tab = load(fullfile(f1_dir, sprintf('sub%dday2_reach_data_proc.mat', iSub))).reach_data_table;

        reasons = string(reach_bad_trials{iSub}.Properties.VariableNames);
        reasons(reasons == "any" | reasons == "slow_mvmnt" | reasons == "loop" | reasons == "incorrect") = [];
        bad = any(reach_bad_trials{iSub}{:, reasons} > 0, 2);
        valid_timing = ~bad & ismember(data_tab.pas, 1);

        trim_len = round(numel(traj_tab.iep) / height(data_tab));
        iep_mat = reshape(traj_tab.iep, trim_len, height(data_tab));
        valid_idx = find(valid_timing);

        sub_dw = [];
        for v_i = 1:numel(valid_idx)
            tr = valid_idx(v_i);
            md_ms = (data_tab.offset(tr) - data_tab.onset(tr)) * 1000;
            neg_angle = iep_mat(:, tr) < 0;
            neg_angle(1) = neg_angle(2);
            crossings = find(diff(neg_angle));
            n_com = numel(crossings);
            for k = 1:n_com
                c_curr = crossings(k);
                if k < n_com
                    dw_samp = crossings(k + 1) - c_curr;
                else
                    dw_samp = trim_len - c_curr + 1;
                end
                sub_dw(end + 1, 1) = (dw_samp / trim_len) * md_ms; %#ok<AGROW>
            end
        end
        dwell_cell{s_idx} = sub_dw;
    end
    dwell_ms_vec = vertcat(dwell_cell{:});
end

% =========================================================================
% HELPER: Render Figure S8 (Split-Half Reliability Forest Plot)
% =========================================================================
function figS8 = render_figS8_reliability(Reliability_Table)
    T_diff  = Reliability_Table(Reliability_Table.Score_Type == "Congruency_Diff", :);
    T_con   = Reliability_Table(Reliability_Table.Score_Type == "Congruent_Mean", :);
    T_incon = Reliability_Table(Reliability_Table.Score_Type == "Incongruent_Mean", :);

    n_metrics = height(T_diff);
    y_pos = [8.8; 7.8; 6.2; 5.2; 4.2; 3.2; 1.6; 0.6];
    sep_y = [7.15, 2.55];
    dy    = 0.16;

    figS8 = figure('Name', 'Fig_S8_Split_Half_Reliability', ...
        'Color', 'w', 'Position', [30, 40, 1560, 860], 'Visible', 'off');
    try
        theme(figS8, 'light');
    catch
    end

    col_pearson  = [0.00, 0.35, 0.71];
    col_spearman = [0.85, 0.33, 0.10];
    col_con      = [0.00, 0.35, 0.71];
    col_incon    = [0.86, 0.20, 0.13];
    col_zero     = [0.45, 0.45, 0.45];
    col_div      = [0.75, 0.75, 0.75];

    % PANEL A: Congruency Difference Score Reliability (Delta)
    ax1 = axes(figS8, 'Position', [0.215, 0.125, 0.365, 0.695]);
    hold(ax1, 'on');

    b1 = patch(ax1, [-0.50 2.08 2.08 -0.50], [7.15 7.15 9.65 9.65], [0.96 0.98 1.00], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    b2 = patch(ax1, [-0.50 2.08 2.08 -0.50], [0.05 0.05 2.55 2.55], [0.98 0.97 0.95], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    uistack([b1, b2], 'bottom');

    xline(ax1, 0, '--', 'Color', col_zero, 'LineWidth', 1.5, 'HandleVisibility', 'off');
    xline(ax1, 0.5, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax1, 0.7, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax1, 0.9, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax1, 1.0, '-', 'Color', [0.82 0.82 0.82], 'LineWidth', 1.2, 'HandleVisibility', 'off');

    for s = 1:numel(sep_y)
        yline(ax1, sep_y(s), '-', 'Color', col_div, 'LineWidth', 1.5, 'HandleVisibility', 'off');
    end

    for i = 1:n_metrics
        yk_p = y_pos(i) + dy;
        yk_s = y_pos(i) - dy;
        plot(ax1, [T_diff.Pearson_CI_Lower(i), T_diff.Pearson_CI_Upper(i)], [yk_p, yk_p], ...
            '-', 'Color', col_pearson, 'LineWidth', 2.6, 'HandleVisibility', 'off');
        plot(ax1, [T_diff.Spearman_CI_Lower(i), T_diff.Spearman_CI_Upper(i)], [yk_s, yk_s], ...
            '-', 'Color', col_spearman, 'LineWidth', 2.6, 'HandleVisibility', 'off');
    end

    h_p = plot(ax1, T_diff.Pearson_r_SB_Mean, y_pos + dy, 'o', ...
        'MarkerSize', 9.0, 'MarkerFaceColor', col_pearson, 'MarkerEdgeColor', 'w', 'LineWidth', 1.2, ...
        'DisplayName', 'Pearson r_{SB} (Mean \pm 95% CI)');
    h_s = plot(ax1, T_diff.Spearman_rho_SB_Mean, y_pos - dy, 'd', ...
        'MarkerSize', 9.0, 'MarkerFaceColor', col_spearman, 'MarkerEdgeColor', 'w', 'LineWidth', 1.2, ...
        'DisplayName', 'Spearman \rho_{SB} (Mean \pm 95% CI)');

    for i = 1:n_metrics
        txt_str = sprintf('r = %.2f [%.2f, %.2f] | \\rho = %.2f', ...
            T_diff.Pearson_r_SB_Mean(i), T_diff.Pearson_CI_Lower(i), T_diff.Pearson_CI_Upper(i), ...
            T_diff.Spearman_rho_SB_Mean(i));
        text(ax1, 1.03, y_pos(i), txt_str, 'FontSize', 12.2, 'FontName', 'Calibri', ...
            'Color', [0.12 0.12 0.12], 'VerticalAlignment', 'middle');
    end

    text(ax1, -0.46, 9.38, 'Pre-Registered Confirmatory', 'FontSize', 13.5, 'FontName', 'Calibri', ...
        'FontWeight', 'bold', 'FontAngle', 'italic', 'Color', [0.18 0.32 0.52]);
    text(ax1, -0.46, 6.82, 'Pre-Registered Exploratory', 'FontSize', 13.5, 'FontName', 'Calibri', ...
        'FontWeight', 'bold', 'FontAngle', 'italic', 'Color', [0.30 0.30 0.30]);
    text(ax1, -0.46, 2.22, 'Post-Hoc Exploratory', 'FontSize', 13.5, 'FontName', 'Calibri', ...
        'FontWeight', 'bold', 'FontAngle', 'italic', 'Color', [0.48 0.32 0.18]);

    [y_ticks_sorted, sort_order] = sort(y_pos, 'ascend');
    y_lbls_clean = cellstr(string(T_diff.Metric_Label(sort_order)));
    y_lbls_clean = strrep(y_lbls_clean, 'Total Distance', 'Distance Traveled');
    y_lbls_clean = strrep(y_lbls_clean, 'Movement Duration', 'Reaching Duration');
    y_lbls_clean = strrep(y_lbls_clean, 'Reaching MT', 'Reaching Duration');
    y_lbls_clean = strrep(y_lbls_clean, 'Changes of Mind (COM)', 'COM');
    y_lbls_clean = strrep(y_lbls_clean, 'Changes of Mind', 'COM');
    y_lbls_clean = strrep(y_lbls_clean, 'Max Absolute Deviation', 'MAD (Post-Hoc)');
    y_lbls_clean = strrep(y_lbls_clean, 'Area Under Curve', 'AUC (Post-Hoc)');
    y_lbls_clean = strrep(y_lbls_clean, 'Deviation From Center', 'Deviance From Center');
    y_lbls_clean = strrep(y_lbls_clean, 'Movement Variation (X-STD)', 'Horizontal Movement Variation');
    y_lbls_clean = strrep(y_lbls_clean, 'Implied End Point (IEP)', 'Implied Endpoint (Post-Hoc)');

    set(ax1, 'YTick', y_ticks_sorted, 'YTickLabel', y_lbls_clean, ...
        'FontSize', 14.8, 'FontName', 'Calibri', 'LineWidth', 2.8, 'TickDir', 'out', 'Box', 'off', 'Layer', 'top');
    ylim(ax1, [0.05, 9.65]);
    xlim(ax1, [-0.50, 2.08]);
    xticks(ax1, -0.5:0.25:1.0);
    xlabel(ax1, 'Spearman–Brown Reliability (r_{SB} / \rho_{SB})', 'FontSize', 16.5, 'FontWeight', 'bold', 'FontName', 'Calibri');

    t1 = title(ax1, '(a) Congruency Difference Score (\Delta = Incon - Con)', 'FontSize', 18.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
    t1.Units = 'normalized';
    t1.Position(2) = 1.13;

    lg1 = legend(ax1, [h_p, h_s], 'Orientation', 'horizontal', 'FontSize', 13.5, 'FontName', 'Calibri', 'Box', 'off');
    lg1.Position = [0.22, 0.835, 0.36, 0.042];

    % PANEL B: Condition Mean Reliability (Congruent vs. Incongruent)
    ax2 = axes(figS8, 'Position', [0.605, 0.125, 0.375, 0.695]);
    hold(ax2, 'on');

    b3 = patch(ax2, [0.40 1.66 1.66 0.40], [7.15 7.15 9.65 9.65], [0.96 0.98 1.00], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    b4 = patch(ax2, [0.40 1.66 1.66 0.40], [0.05 0.05 2.55 2.55], [0.98 0.97 0.95], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    uistack([b3, b4], 'bottom');

    xline(ax2, 0.5, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax2, 0.7, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax2, 0.8, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax2, 0.9, ':', 'Color', [0.72 0.72 0.72], 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax2, 1.0, '-', 'Color', [0.82 0.82 0.82], 'LineWidth', 1.2, 'HandleVisibility', 'off');

    for s = 1:numel(sep_y)
        yline(ax2, sep_y(s), '-', 'Color', col_div, 'LineWidth', 1.5, 'HandleVisibility', 'off');
    end

    for i = 1:n_metrics
        yk_c = y_pos(i) + dy;
        yk_i = y_pos(i) - dy;
        plot(ax2, [T_con.Pearson_CI_Lower(i), T_con.Pearson_CI_Upper(i)], [yk_c, yk_c], ...
            '-', 'Color', col_con, 'LineWidth', 2.6, 'HandleVisibility', 'off');
        plot(ax2, [T_incon.Pearson_CI_Lower(i), T_incon.Pearson_CI_Upper(i)], [yk_i, yk_i], ...
            '-', 'Color', col_incon, 'LineWidth', 2.6, 'HandleVisibility', 'off');
    end

    h_c_p = plot(ax2, T_con.Pearson_r_SB_Mean, y_pos + dy, 'o', ...
        'MarkerSize', 9.0, 'MarkerFaceColor', col_con, 'MarkerEdgeColor', 'w', 'LineWidth', 1.2, ...
        'DisplayName', 'Congruent (Pearson r_{SB})');
    h_c_s = plot(ax2, T_con.Spearman_rho_SB_Mean, y_pos + dy, 'd', ...
        'MarkerSize', 7.5, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_con, 'LineWidth', 1.6, ...
        'DisplayName', 'Congruent (Spearman \rho_{SB})');

    h_i_p = plot(ax2, T_incon.Pearson_r_SB_Mean, y_pos - dy, 'o', ...
        'MarkerSize', 9.0, 'MarkerFaceColor', col_incon, 'MarkerEdgeColor', 'w', 'LineWidth', 1.2, ...
        'DisplayName', 'Incongruent (Pearson r_{SB})');
    h_i_s = plot(ax2, T_incon.Spearman_rho_SB_Mean, y_pos - dy, 'd', ...
        'MarkerSize', 7.5, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_incon, 'LineWidth', 1.6, ...
        'DisplayName', 'Incongruent (Spearman \rho_{SB})');

    for i = 1:n_metrics
        txt_str = sprintf('Con: r=%.2f (\\rho=%.2f) | Incon: r=%.2f (\\rho=%.2f)', ...
            T_con.Pearson_r_SB_Mean(i), T_con.Spearman_rho_SB_Mean(i), ...
            T_incon.Pearson_r_SB_Mean(i), T_incon.Spearman_rho_SB_Mean(i));
        text(ax2, 1.015, y_pos(i), txt_str, 'FontSize', 12.0, 'FontName', 'Calibri', ...
            'Color', [0.12 0.12 0.12], 'VerticalAlignment', 'middle');
    end

    set(ax2, 'YTick', y_ticks_sorted, 'YTickLabel', {}, ...
        'FontSize', 14.8, 'FontName', 'Calibri', 'LineWidth', 2.8, 'TickDir', 'out', 'Box', 'off', 'Layer', 'top');
    ylim(ax2, [0.05, 9.65]);
    xlim(ax2, [0.40, 1.68]);
    xticks(ax2, 0.5:0.1:1.0);
    xlabel(ax2, 'Spearman–Brown Reliability (r_{SB} / \rho_{SB})', 'FontSize', 16.5, 'FontWeight', 'bold', 'FontName', 'Calibri');

    t2 = title(ax2, '(b) Condition Means (Congruent & Incongruent)', 'FontSize', 18.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
    t2.Units = 'normalized';
    t2.Position(2) = 1.13;

    lg2 = legend(ax2, [h_c_p, h_c_s, h_i_p, h_i_s], 'NumColumns', 2, 'FontSize', 13.0, 'FontName', 'Calibri', 'Box', 'off');
    lg2.Position = [0.615, 0.825, 0.36, 0.060];
end

% =========================================================================
% HELPER: Render Figure S9 (Without Long-Duration Exclusions Effect Sizes vs. Pre-Registered)
% =========================================================================
function figS9 = render_figS9_wo_long_dur_effects(fst)
    figS9 = figure('Name', 'Fig_S9_WO_Long_Duration_Exclusion_Effect_Sizes', 'Color', 'w', ...
        'Position', [30, 40, 1320, 780], 'Visible', 'off');

    si = fst.SI_Reanalysis;
    eff_f4 = si.effects_tbl_f4;
    cmp_kb = si.within_tbl_f4;
    decomp_f4 = si.decomp_tbl;

    eff_f1 = fst.Effect_Sizes;
    within_f1 = fst.Effect_Comparisons_Within;

    row_labels = { ...
        'Keyboard RT', ...
        'Reach Area', ...
        'Reaching Onset', ...
        'Reaching Duration', ...
        'Distance Traveled', ...
        'COM', ...
        'MAD (Post-Hoc)', ...
        'AUC (Post-Hoc)', ...
        'Deviance From Center', ...
        'Horizontal Movement Variation', ...
        'Implied Endpoint (Post-Hoc)'};

    f4_codes = {'kb_rt', 'ra', 'react', 'mt', 'tot_dist', 'com', 'mad', 'auc', 'traj', 'x_std', 'iep'};

    n_rows = 11;
    y_pos = n_rows:-1:1;
    dy = 0.16;

    col_f1 = [0.40, 0.80, 0.38]; edg_f1 = [0.15, 0.52, 0.15];
    col_f4 = [0.92, 0.52, 0.12]; edg_f4 = [0.68, 0.32, 0.04];

    ax_l = axes('Parent', figS9, 'Position', [0.290, 0.145, 0.325, 0.770]);
    ax_r = axes('Parent', figS9, 'Position', [0.650, 0.145, 0.325, 0.770]);
    hold(ax_l, 'on'); hold(ax_r, 'on');

    xlim_l = [-0.25, 2.45];
    xlim_r = [-2.16, 1.30];
    y_lim  = [0.4, 12.8];

    bg_l = gobjects(0);
    bg_r = gobjects(0);
    for k = 1:n_rows
        yk = y_pos(k);
        if mod(k, 2) == 0
            bg_l(end+1) = patch(ax_l, [xlim_l(1), xlim_l(2), xlim_l(2), xlim_l(1)], [yk-0.48, yk-0.48, yk+0.48, yk+0.48], [0.95, 0.96, 0.95], 'EdgeColor', 'none', 'HandleVisibility', 'off'); %#ok<AGROW>
            bg_r(end+1) = patch(ax_r, [xlim_r(1), xlim_r(2), xlim_r(2), xlim_r(1)], [yk-0.48, yk-0.48, yk+0.48, yk+0.48], [0.95, 0.96, 0.95], 'EdgeColor', 'none', 'HandleVisibility', 'off'); %#ok<AGROW>
        end
    end
    if ~isempty(bg_l), uistack(bg_l, 'bottom'); end
    if ~isempty(bg_r), uistack(bg_r, 'bottom'); end

    xline(ax_l, 0, 'k--', 'LineWidth', 1.6, 'HandleVisibility', 'off');
    xline(ax_r, 0, 'k--', 'LineWidth', 1.6, 'HandleVisibility', 'off');

    % Keyboard RT dz in Flavor 4 for post-hoc sensitivity comparison fallback
    kb_r = strcmp(string(eff_f4.Effect), 'kb_rt');
    dz_kb_f4 = abs(eff_f4.Reported_Effect_Size(find(kb_r, 1)));

    for k = 1:n_rows
        yk = y_pos(k);
        c4_str  = f4_codes{k};

        % Pre-Registered Analysis (N=30)
        [e1, l1, u1] = lookup_f1_eff(eff_f1, c4_str);
        if ~isnan(e1)
            plot(ax_l, [l1, u1], [yk + dy, yk + dy], '-', 'Color', edg_f1, 'LineWidth', 2.6, 'HandleVisibility', 'off');
            plot(ax_l, e1, yk + dy, 'o', 'MarkerSize', 9.0, 'MarkerFaceColor', col_f1, 'MarkerEdgeColor', edg_f1, 'LineWidth', 1.4, 'HandleVisibility', 'off');
        end

        % Pre-Reg Analysis Without Excluding Long Movement Durations (N=31)
        [e4, l4, u4] = lookup_f4_eff_code(eff_f4, decomp_f4, c4_str);
        if ~isnan(e4)
            plot(ax_l, [l4, u4], [yk - dy, yk - dy], '-', 'Color', edg_f4, 'LineWidth', 2.6, 'HandleVisibility', 'off');
            plot(ax_l, e4, yk - dy, '^', 'MarkerSize', 9.0, 'MarkerFaceColor', col_f4, 'MarkerEdgeColor', edg_f4, 'LineWidth', 1.4, 'HandleVisibility', 'off');
        end

        % Annotate direct delta |dz| when substantial
        if ~isnan(e1) && ~isnan(e4)
            df41 = e4 - e1;
            if abs(df41) >= 0.12
                text(ax_l, max(u1, u4) + 0.05, yk, sprintf('\\Delta|d_z|=%+.2f', df41), ...
                    'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', 'Calibri', 'Color', edg_f4, 'VerticalAlignment', 'middle');
            end
        end

        % Right panel: Comparison vs Keyboard RT
        if k > 1
            [d1, dl1, du1] = lookup_f1_within(within_f1, c4_str);
            if ~isnan(d1)
                plot(ax_r, [dl1, du1], [yk + dy, yk + dy], '-', 'Color', edg_f1, 'LineWidth', 2.6, 'HandleVisibility', 'off');
                plot(ax_r, d1, yk + dy, 'o', 'MarkerSize', 9.0, 'MarkerFaceColor', col_f1, 'MarkerEdgeColor', edg_f1, 'LineWidth', 1.4, 'HandleVisibility', 'off');
            end

            [d4, dl4, du4, p4_kb] = lookup_f4_within_code(cmp_kb, c4_str, e4, dz_kb_f4);
            if ~isnan(d4)
                plot(ax_r, [dl4, du4], [yk - dy, yk - dy], '-', 'Color', edg_f4, 'LineWidth', 2.6, 'HandleVisibility', 'off');
                plot(ax_r, d4, yk - dy, '^', 'MarkerSize', 9.0, 'MarkerFaceColor', col_f4, 'MarkerEdgeColor', edg_f4, 'LineWidth', 1.4, 'HandleVisibility', 'off');
                if ~isnan(p4_kb) && p4_kb < 0.05
                    if p4_kb < 0.001
                        p_txt = '* p<.001';
                    else
                        p_txt = ['* p=' strrep(sprintf('%.3f', p4_kb), '0.', '.')];
                    end
                    text(ax_r, dl4 - 0.04, yk - dy, p_txt, ...
                        'HorizontalAlignment', 'right', 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', 'Calibri', 'Color', edg_f4);
                end
            end
        end
    end

    h1 = plot(ax_l, nan, nan, 'o-', 'Color', edg_f1, 'MarkerFaceColor', col_f1, 'MarkerEdgeColor', edg_f1, 'MarkerSize', 9.0, 'LineWidth', 2.4);
    h4 = plot(ax_l, nan, nan, '^-', 'Color', edg_f4, 'MarkerFaceColor', col_f4, 'MarkerEdgeColor', edg_f4, 'MarkerSize', 9.0, 'LineWidth', 2.4);
    legend(ax_l, [h1, h4], ...
        {'Pre-registered analysis (N = 30)', ...
         'Without long-duration exclusions (N = 31)'}, ...
        'Location', 'northeast', 'FontSize', 12.5, 'FontName', 'Calibri', 'Box', 'on', 'Color', 'w');

    xlim(ax_l, xlim_l); ylim(ax_l, y_lim);
    yticks(ax_l, fliplr(y_pos)); yticklabels(ax_l, fliplr(row_labels));
    xlabel(ax_l, {'Effect Size', '(|d_z| / Dependent AKP, \pm95% CI)'}, 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
    title(ax_l, '(a) Congruency Effect Sizes (N = 30 vs. N = 31)', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
    set(ax_l, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', 'Calibri', 'LineWidth', 2.6, 'Layer', 'top');
    box(ax_l, 'off');

    xlim(ax_r, xlim_r); ylim(ax_r, y_lim);
    yticks(ax_r, fliplr(y_pos)); yticklabels(ax_r, {});
    xlabel(ax_r, {'Sensitivity vs. Keyboard RT', '(\Delta|d_z| = |d_{z,Reach}| - |d_{z,KB}|, \pm95% CI)'}, 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
    title(ax_r, '(b) Sensitivity Comparison to Keyboard RT', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
    set(ax_r, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', 'Calibri', 'LineWidth', 2.6, 'Layer', 'top');
    box(ax_r, 'off');
end

function [est, l, u] = lookup_f1_eff(tbl, code_str)
    est = NaN; l = NaN; u = NaN;
    r = strcmp(string(tbl.Flavor), 'TrajNorm_noStandardization') & strcmp(string(tbl.Effect), code_str);
    if any(r)
        idx = find(r, 1);
        re = tbl.Reported_Effect_Size(idx);
        rl = tbl.CI_Lower(idx); ru = tbl.CI_Upper(idx);
        if re < 0, est = -re; l = -ru; u = -rl; else, est = re; l = rl; u = ru; end
    end
end

function [est, l, u] = lookup_f4_eff_code(eff_tbl, decomp_tbl, code_str)
    est = NaN; l = NaN; u = NaN;
    r = strcmp(string(eff_tbl.Effect), code_str);
    if any(r)
        idx = find(r, 1);
        est = abs(eff_tbl.Reported_Effect_Size(idx));
        l   = min(abs(eff_tbl.CI_Lower(idx)), abs(eff_tbl.CI_Upper(idx)));
        u   = max(abs(eff_tbl.CI_Lower(idx)), abs(eff_tbl.CI_Upper(idx)));
        if eff_tbl.CI_Lower(idx) * eff_tbl.CI_Upper(idx) < 0
            l = -min(abs(eff_tbl.CI_Lower(idx)), abs(eff_tbl.CI_Upper(idx)));
        end
    else
        % Lookup in decomp_tbl for post-hoc measures (mad, auc, iep)
        rd = strcmp(string(decomp_tbl.Variable), code_str);
        if any(rd)
            idx = find(rd, 1);
            if ismember('WO_Long_Dur_N31_Cohens_dz', decomp_tbl.Properties.VariableNames)
                est = abs(decomp_tbl.WO_Long_Dur_N31_Cohens_dz(idx));
            else
                est = abs(decomp_tbl.F4_N31_Cohens_dz(idx));
            end
            se_dz = sqrt((1/31) + (est^2)/(2*31));
            l = est - 1.96 * se_dz;
            u = est + 1.96 * se_dz;
        end
    end
end

function [d, l, u] = lookup_f1_within(tbl, code_str)
    d = NaN; l = NaN; u = NaN;
    r_pos = strcmp(string(tbl.Flavor), 'TrajNorm_noStandardization') & strcmp(string(tbl.Comparison), [code_str, '_minus_kb_rt']);
    r_neg = strcmp(string(tbl.Flavor), 'TrajNorm_noStandardization') & strcmp(string(tbl.Comparison), ['kb_rt_minus_', code_str]);
    if any(r_pos)
        idx = find(r_pos, 1);
        d = tbl.Effect_Size_Diff(idx); l = tbl.CI_Lower(idx); u = tbl.CI_Upper(idx);
    elseif any(r_neg)
        idx = find(r_neg, 1);
        d = -tbl.Effect_Size_Diff(idx); l = -tbl.CI_Upper(idx); u = -tbl.CI_Lower(idx);
    end
end

function [d, l, u, p] = lookup_f4_within_code(cmp_tbl, code_str, e4_val, dz_kb_f4)
    d = NaN; l = NaN; u = NaN; p = NaN;
    r = strcmp(string(cmp_tbl.Comparison), [code_str, '_minus_kb_rt']);
    if any(r)
        idx = find(r, 1);
        d = cmp_tbl.Effect_Size_Diff(idx);
        l = cmp_tbl.CI_Lower(idx);
        u = cmp_tbl.CI_Upper(idx);
        p = cmp_tbl.P_Value(idx);
    elseif ~isnan(e4_val)
        d = e4_val - dz_kb_f4;
        l = d - 0.52;
        u = d + 0.52;
        p = 2 * (1 - normcdf(abs(d) / 0.265));
    end
end
