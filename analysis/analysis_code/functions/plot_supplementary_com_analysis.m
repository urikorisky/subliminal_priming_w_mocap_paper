function [Stats_Table] = plot_supplementary_com_analysis(data_dir)
%PLOT_SUPPLEMENTARY_COM_ANALYSIS Computes the Supplementary Information (SI)
% Change of Mind (COM) dwell-time and debouncing threshold sweep statistics
% across normalized sample thresholds and physical millisecond thresholds.
%
% Author: Antigravity / Uri

    func_dir = fileparts(mfilename('fullpath'));
    repo_root = fullfile(func_dir, '..', '..');

    % Locate latest acceleration-corrected processed TrajNorm data
    if nargin < 1 || isempty(data_dir)
        data_dir = fullfile(repo_root, 'processed_data', 'nonStandardized_TrajNorm');
        if ~exist(data_dir, 'dir')
            data_dir = fullfile(repo_root, 'processed_data', 'standardized_TrajNorm');
        end
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

    fprintf('Tracked %d valid trials for COM threshold sweep.\n', length(trial_data));

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

    %% =====================================================================
    %% 3. PHYSICAL MILLISECOND THRESHOLDS (10 ms, 25 ms, 50 ms, 80 ms)
    %% =====================================================================
    ms_targets = [10, 25, 50, 80];
    n_ms = length(ms_targets);

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
    end

    %% ---------------------------------------------------------------------
    %% 4. BUILD STATISTICAL SUMMARY TABLE (SPLIT BY CORRECTNESS)
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
    fprintf('=== Successfully computed Supplementary COM threshold statistics in memory ===\n');
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
