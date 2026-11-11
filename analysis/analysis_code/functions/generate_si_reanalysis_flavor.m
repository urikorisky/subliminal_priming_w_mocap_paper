function [si_summary_tbl, si_by_sub_tbl, full_traj_clust_tbl, effects_tbl_f4, within_tbl_f4] = generate_si_reanalysis_flavor(analysisPrms)
% GENERATE_SI_REANALYSIS_FLAVOR Performs an entire re-analysis of the experimental
% data ignoring time-sensitive exclusion criteria ("too early", "too late", and
% "slow movement") during preprocessing and screening (Flavor 4).
%
% Re-analysis specifications:
% - Analysis Flavor: Trajectories normalized to %path, no within-participant standardization (Flavor 1 pre-registered).
% - Included Sample: All participants who meet the >= 25 minimum trials/condition criterion
%   based strictly on non-time-sensitive criteria (N = 36 included, 6 excluded: Subs 58, 64, 68, 69, 73, 89).
% - Computes 8 discrete measures (Congruent, Incongruent, Diff, Total Across Conditions, Cohen's dz, paired t, p-value).
% - Computes continuous full-trajectory cluster permutation tests (traj, iep, x_std) identically formatted to the main analysis.
% - Computes 10,000 bootstrap effect sizes and comparisons vs Keyboard RT strictly for pre-registered variables.
% - Generates forest plots:
%     1. Effect_Sizes_Flavor_4_noTimeExclusion
%     2. Effect_Comparisons_Flavor_4_vs_KB_RT
%     3. Effect_Comparisons_Flavor_4_vs_Flavor_1_SideBySide (paired with Flavor 4 right above Flavor 1)
% - Exports results to a dedicated standalone workbook:
%   analysis/statistics/SI_Reanalysis_noTimeExclusions.xlsx
%   (and standalone CSV files), keeping the primary manuscript All_Statistics.xlsx pristine.

    if nargin < 1 || isempty(analysisPrms)
        analysisPrms = getDefaultAnalysisParams();
    end

    curr_func_dir = fileparts(mfilename('fullpath'));
    addpath(genpath(curr_func_dir));

    raw_proc_folder = analysisPrms.readyPreProcData_TrajNorm_noStandardization_folder;
    target_proc_folder = fullfile(fileparts(mfilename('fullpath')), '../../processed_data/noTimeExclusion_TrajNorm');
    if ~exist(target_proc_folder, 'dir')
        mkdir(target_proc_folder);
    end

    out_stats_dir = analysisPrms.targetStats_allAnalysesCombined;
    if ~exist(out_stats_dir, 'dir')
        mkdir(out_stats_dir);
    end

    out_figs_dir = fullfile(analysisPrms.targetFigs_allAnalysesCombined, 'Effect_Sizes');
    if ~exist(out_figs_dir, 'dir')
        mkdir(out_figs_dir);
    end

    % 1. Sample Definition
    good_subs_si = [47, 49:57, 59:63, 65:67, 70:72, 74:85, 87, 88, 90]; % N=36
    n_subs = numel(good_subs_si);
    all_subs = [47, 49:85, 87:90]; % N=42

    p = load('../../experiment/RUN_ME/code/p.mat'); p = p.p;
    p.DAY = 'day2';
    p.SUBS = all_subs;
    p.SUBS_STRING = regexprep(num2str(all_subs), '\s+', '_');
    p.REF_RATE_HZ = 100;
    p.NORM_TRAJ = true;
    p.NORMALIZE_WITHIN_SUB = false;
    p.MIN_SAMP_LEN = 0.1;
    p.MIN_TRIM_FRAMES = p.MIN_SAMP_LEN * p.REF_RATE_HZ;
    p.MIN_TRIALS_PER_COND = 25;
    p.OUTLIER_REMOVAL = false;
    p.REMOVE_REVERSALS = false;
    p.TRIM_EDGES_BEFORE_CALC = true;
    p.TRIM_EDGES_BEFORE_FILTER = false;
    p.FILTER_ORDER = 4;
    p.LOW_PASS_CUT_OFF = 10;
    p.USE_REF_DATA = false;
    p.REF_DATA_FOLDER = fullfile(fileparts(mfilename('fullpath')), '../../processed_data/nonStandardized_TrajNorm');
    p.PROC_DATA_FOLDER = target_proc_folder;

    traj_names = {{'target_x_to', 'target_y_to', 'target_z_to'}};

    cache_file = fullfile(target_proc_folder, 'si_noTimeExclusion_all_avgs.mat');
    if analysisPrms.usePreprocDataWhereverPossible && exist(cache_file, 'file')
        fprintf('Loading precomputed SI re-analysis averages from %s...\n', cache_file);
        loaded = load(cache_file);
        r_avgs = loaded.r_avgs;
        k_avgs = loaded.k_avgs;
        r_trials = loaded.r_trials;
        k_trials = loaded.k_trials;
        reach_area = loaded.reach_area;
    else
        fprintf('Computing SI re-analysis trial averages (ignoring time-sensitive exclusions)...\n');
        k_avgs = cell(max(all_subs), 1);
        k_trials = cell(max(all_subs), 1);
        r_avgs = cell(max(all_subs), 1);
        r_trials = cell(max(all_subs), 1);

        for s = all_subs
            [r_avg, k_avg, r_tr, k_tr] = compute_subject_si_no_time_exclusions(s, raw_proc_folder, p);
            k_avgs{s} = k_avg;
            k_trials{s} = k_tr;
            r_avgs{s} = r_avg;
            r_trials{s} = r_tr;
        end

        reach_area = struct('con', NaN(max(all_subs), 1), 'incon', NaN(max(all_subs), 1));
        for s = all_subs
            r_tbl_file = fullfile(raw_proc_folder, sprintf('sub%dday2_reach_data_proc.mat', s));
            r_loaded = load(r_tbl_file);
            r_tbl = r_loaded.reach_data_table;
            r_tbl(r_tbl.practice >= 1, :) = [];

            bt_file = fullfile(raw_proc_folder, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat');
            bt = load(bt_file);
            r_bt = bt.reach_bad_trials{s};

            time_crit = ["early_res", "late_res", "slow_mvmnt", "very_slow_mvmnt"];
            nontime_reasons = setdiff(string(r_bt.Properties.VariableNames), ["any", "incorrect", "slow_mvmnt", "loop", time_crit]);
            bad_nontime = any(r_bt{:, cellstr(nontime_reasons)} > 0, 2);

            valid_mask = ~bad_nontime & (r_tbl.pas == 1) & (r_tbl.target_correct == 1);

            con_mask = valid_mask & (r_tbl.target_label == r_tbl.prime_label);
            incon_mask = valid_mask & (r_tbl.target_label ~= r_tbl.prime_label);

            c_trajs = r_tbl.target_x_to(con_mask);
            i_trajs = r_tbl.target_x_to(incon_mask);

            if ~isempty(c_trajs)
                c_mat = cell2mat(cellfun(@(x) x(:,1)', c_trajs, 'UniformOutput', false));
                c_mean = mean(c_mat, 1, 'omitnan');
                reach_area.con(s) = trapz(abs(c_mean)) * (1/200);
            end
            if ~isempty(i_trajs)
                i_mat = cell2mat(cellfun(@(x) x(:,1)', i_trajs, 'UniformOutput', false));
                i_mean = mean(i_mat, 1, 'omitnan');
                reach_area.incon(s) = trapz(abs(i_mean)) * (1/200);
            end
        end

        save(cache_file, 'r_avgs', 'k_avgs', 'r_trials', 'k_trials', 'reach_area');
    end

    % 2. Extract Data Matrices for N=36
    discrete_vars = {'kb_rt', 'ra', 'react', 'mt', 'tot_dist', 'com', 'mad', 'auc'};
    var_labels    = {'Keyboard RT', 'Reach Area', 'Reaching Onset', 'Movement Duration', ...
                     'Total Distance Traveled', 'Num of Changes of Mind', 'Maximum Absolute Deviation (MAD)', 'Area Under Curve (AUC)'};
    var_units     = {'ms', 'cm^2', 'ms', 'ms', 'cm', 'count', 'cm', 'cm^2'};
    n_vars = numel(discrete_vars);

    con_mat   = NaN(n_subs, n_vars);
    incon_mat = NaN(n_subs, n_vars);
    diff_mat  = NaN(n_subs, n_vars);
    total_mat = NaN(n_subs, n_vars);

    traj_con_mat   = NaN(200, n_subs);
    traj_incon_mat = NaN(200, n_subs);
    iep_con_mat    = NaN(200, n_subs);
    iep_incon_mat  = NaN(200, n_subs);
    x_std_con_mat  = NaN(200, n_subs);
    x_std_incon_mat= NaN(200, n_subs);

    for s_idx = 1:n_subs
        s = good_subs_si(s_idx);
        r_avg = r_avgs{s};
        k_avg = k_avgs{s};
        r_tr  = r_trials{s};
        k_tr  = k_trials{s};

        traj_con_mat(:, s_idx)   = r_avg.traj.con(:, 1);
        traj_incon_mat(:, s_idx) = r_avg.traj.incon(:, 1);
        iep_con_mat(:, s_idx)    = r_avg.iep.con;
        iep_incon_mat(:, s_idx)  = r_avg.iep.incon;
        x_std_con_mat(:, s_idx)  = r_avg.x_std.con;
        x_std_incon_mat(:, s_idx)= r_avg.x_std.incon;

        n_r_con   = numel(r_tr.react.con);
        n_r_incon = numel(r_tr.react.incon);
        n_r_tot   = n_r_con + n_r_incon;

        n_k_con   = numel(k_tr.rt.con);
        n_k_incon = numel(k_tr.rt.incon);
        n_k_tot   = n_k_con + n_k_incon;

        for v_i = 1:n_vars
            v_name = discrete_vars{v_i};
            switch v_name
                case 'kb_rt'
                    c_val = k_avg.rt.con * 1000;
                    i_val = k_avg.rt.incon * 1000;
                    t_val = mean([k_tr.rt.con(:); k_tr.rt.incon(:)], 'omitnan') * 1000;
                case 'ra'
                    c_val = reach_area.con(s);
                    i_val = reach_area.incon(s);
                    t_val = (c_val * n_r_con + i_val * n_r_incon) / n_r_tot;
                case 'react'
                    c_val = r_avg.react.con * 1000;
                    i_val = r_avg.react.incon * 1000;
                    t_val = mean([r_tr.react.con(:); r_tr.react.incon(:)], 'omitnan') * 1000;
                case 'mt'
                    c_val = r_avg.mt.con * 1000;
                    i_val = r_avg.mt.incon * 1000;
                    t_val = mean([r_tr.mt.con(:); r_tr.mt.incon(:)], 'omitnan') * 1000;
                case 'tot_dist'
                    c_val = r_avg.tot_dist.con * 100;
                    i_val = r_avg.tot_dist.incon * 100;
                    t_val = mean([r_tr.tot_dist.con(:); r_tr.tot_dist.incon(:)], 'omitnan') * 100;
                case 'com'
                    c_val = r_avg.com.con;
                    i_val = r_avg.com.incon;
                    t_val = mean([r_tr.com.con(:); r_tr.com.incon(:)], 'omitnan');
                case 'mad'
                    c_val = r_avg.mad.con * 100;
                    i_val = r_avg.mad.incon * 100;
                    t_val = mean([r_tr.mad.con(:); r_tr.mad.incon(:)], 'omitnan') * 100;
                case 'auc'
                    c_val = r_avg.auc.con * 10000;
                    i_val = r_avg.auc.incon * 10000;
                    t_val = mean([r_tr.auc.con(:); r_tr.auc.incon(:)], 'omitnan') * 10000;
            end
            con_mat(s_idx, v_i)   = c_val;
            incon_mat(s_idx, v_i) = i_val;
            diff_mat(s_idx, v_i)  = i_val - c_val;
            total_mat(s_idx, v_i) = t_val;
        end
    end

    % 3. Group Summary Statistics
    con_mean   = mean(con_mat, 1, 'omitnan');
    con_sd     = std(con_mat, 0, 1, 'omitnan');
    incon_mean = mean(incon_mat, 1, 'omitnan');
    incon_sd   = std(incon_mat, 0, 1, 'omitnan');
    diff_mean  = mean(diff_mat, 1, 'omitnan');
    diff_sd    = std(diff_mat, 0, 1, 'omitnan');
    total_mean = mean(total_mat, 1, 'omitnan');
    total_sd   = std(total_mat, 0, 1, 'omitnan');

    cohen_dz   = diff_mean ./ diff_sd;
    t_stat     = NaN(1, n_vars);
    df_val     = repmat(n_subs - 1, 1, n_vars);
    p_val      = NaN(1, n_vars);

    for v_i = 1:n_vars
        diff_vals = diff_mat(:, v_i);
        diff_vals(isnan(diff_vals)) = [];
        [~, p_v, ~, stats_t] = ttest(diff_vals, 0);
        t_stat(v_i) = stats_t.tstat;
        p_val(v_i)  = p_v;
    end

    si_summary_tbl = table( ...
        string(discrete_vars(:)), ...
        string(var_labels(:)), ...
        string(var_units(:)), ...
        con_mean(:), con_sd(:), ...
        incon_mean(:), incon_sd(:), ...
        diff_mean(:), diff_sd(:), ...
        total_mean(:), total_sd(:), ...
        cohen_dz(:), t_stat(:), df_val(:), p_val(:), ...
        'VariableNames', { ...
            'Variable', 'Label', 'Units', ...
            'Congruent_Mean', 'Congruent_SD', ...
            'Incongruent_Mean', 'Incongruent_SD', ...
            'Diff_Mean', 'Diff_SD', ...
            'Total_Across_Conditions_Mean', 'Total_Across_Conditions_SD', ...
            'Cohen_dz', 't_stat', 'df', 'p_val'});

    % 4. Build Participant Breakdown Table (By_Sub_SI_noTimeExclusion)
    sub_col = [good_subs_si(:); NaN; NaN];
    by_sub_vars = cell(1, n_vars * 3);
    by_sub_varnames = cell(1, n_vars * 3);

    col_idx = 1;
    for v_i = 1:n_vars
        v_name = discrete_vars{v_i};
        c_col = [con_mat(:, v_i); con_mean(v_i); con_sd(v_i)];
        i_col = [incon_mat(:, v_i); incon_mean(v_i); incon_sd(v_i)];
        t_col = [total_mat(:, v_i); total_mean(v_i); total_sd(v_i)];

        by_sub_vars{col_idx} = c_col;
        by_sub_varnames{col_idx} = sprintf('%s_Congruent', v_name);
        by_sub_vars{col_idx + 1} = i_col;
        by_sub_varnames{col_idx + 1} = sprintf('%s_Incongruent', v_name);
        by_sub_vars{col_idx + 2} = t_col;
        by_sub_varnames{col_idx + 2} = sprintf('%s_Total_Across_Conditions', v_name);
        col_idx = col_idx + 3;
    end

    si_by_sub_tbl = table(sub_col, by_sub_vars{:}, 'VariableNames', [{'Participant'}, by_sub_varnames]);

    % 5. Continuous Trajectory Permutation Testing (Identical structure to main analysis)
    n_perm = 10000;
    n_perm_clust_tests = 1;
    rng(42, 'twister');
    c_traj = permCluster(traj_con_mat, traj_incon_mat, n_perm, n_perm_clust_tests);
    c_iep  = permCluster(iep_con_mat, iep_incon_mat, n_perm, n_perm_clust_tests);
    c_xstd = permCluster(x_std_con_mat, x_std_incon_mat, n_perm, n_perm_clust_tests);

    tbl_traj = printTsStats('Deviation From center', c_traj);
    tbl_iep  = printTsStats('iEP', c_iep);
    tbl_xstd = printTsStats('Movement variation', c_xstd);

    full_traj_clust_tbl = [tbl_traj; tbl_iep; tbl_xstd];
    full_traj_clust_tbl = addvars(full_traj_clust_tbl, repmat("TrajNorm_noTimeExclusion", height(full_traj_clust_tbl), 1), ...
        'Before', 1, 'NewVariableNames', 'Flavor');

    try
        adj_p = mafdr(full_traj_clust_tbl.p_val, 'BHFDR', true);
    catch
        [sorted_p, s_idx] = sort(full_traj_clust_tbl.p_val);
        m_p = length(sorted_p);
        adj_sorted = sorted_p .* (m_p ./ (1:m_p)');
        adj_sorted = cummin(adj_sorted, 'reverse');
        adj_p = zeros(size(sorted_p));
        adj_p(s_idx) = min(adj_sorted, 1.0);
    end
    full_traj_clust_tbl.p_Val_TreeBH_Corrected = adj_p;

    % Dynamic cluster windows
    win_traj = [c_traj.start(1), c_traj.end(1)];
    win_xstd = [c_xstd.start(1), c_xstd.end(1)];

    % 6. Bootstrap Effect Sizes strictly for Pre-Registered Variables (Flavor 4)
    prereg_vars = {'kb_rt', 'ra', 'react', 'mt', 'tot_dist', 'com', 'traj', 'x_std'};
    n_prereg = numel(prereg_vars);

    data1_prereg = NaN(n_subs, n_prereg);
    data2_prereg = NaN(n_subs, n_prereg);

    for s_i = 1:n_subs
        s = good_subs_si(s_i);
        r = r_avgs{s};
        k = k_avgs{s};

        data1_prereg(s_i, 1) = k.rt.con * 1000;
        data2_prereg(s_i, 1) = k.rt.incon * 1000;

        data1_prereg(s_i, 2) = reach_area.con(s);
        data2_prereg(s_i, 2) = reach_area.incon(s);

        data1_prereg(s_i, 3) = r.react.con * 1000;
        data2_prereg(s_i, 3) = r.react.incon * 1000;

        data1_prereg(s_i, 4) = r.mt.con * 1000;
        data2_prereg(s_i, 4) = r.mt.incon * 1000;

        data1_prereg(s_i, 5) = r.tot_dist.con * 100;
        data2_prereg(s_i, 5) = r.tot_dist.incon * 100;

        data1_prereg(s_i, 6) = r.com.con;
        data2_prereg(s_i, 6) = r.com.incon;

        data1_prereg(s_i, 7) = mean(r.traj.con(win_traj(1):win_traj(2), 1));
        data2_prereg(s_i, 7) = mean(r.traj.incon(win_traj(1):win_traj(2), 1));

        data1_prereg(s_i, 8) = mean(r.x_std.con(win_xstd(1):win_xstd(2)));
        data2_prereg(s_i, 8) = mean(r.x_std.incon(win_xstd(1):win_xstd(2)));
    end

    n_boot = 10000;
    rng(42, 'twister');
    boot_indices = randi(n_subs, n_subs, n_boot);

    eff_rows_f4 = {};
    dist_store_f4 = struct();
    actual_dz_f4 = struct();

    for v_i = 1:n_prereg
        v_name = prereg_vars{v_i};
        d1 = data1_prereg(:, v_i);
        d2 = data2_prereg(:, v_i);

        diff_actual = d1 - d2;
        mean_diff = mean(diff_actual, 'omitnan');
        sd_diff   = std(diff_actual, 0, 'omitnan');
        cohen_dz_val = abs(mean_diff / sd_diff);

        q1 = prctile(diff_actual, 25);
        q3 = prctile(diff_actual, 75);
        iqr_val = q3 - q1;
        has_outliers = any(diff_actual < (q1 - 1.5 * iqr_val) | diff_actual > (q3 + 1.5 * iqr_val));
        dep_akp_val = abs(calc_dependent_akp(d1, d2));

        if has_outliers
            reported_eff = dep_akp_val;
            metric_name  = "Dependent_AKP";
            diff_s = d1 - d2;
            tr = 0.20; g = floor(tr * n_subs);
            z_tr = norminv(1 - tr); phi_z = normpdf(z_tr);
            cterm = sqrt((erf(z_tr / sqrt(2)) - 2 * z_tr * phi_z) + 2 * (z_tr^2) * tr);
            dist = zeros(n_boot, 1);
            for b = 1:n_boot
                bd = diff_s(boot_indices(:, b));
                sbd = sort(bd);
                win_bd = bd;
                win_bd(win_bd <= sbd(g + 1)) = sbd(g + 1);
                win_bd(win_bd >= sbd(end - g)) = sbd(end - g);
                sw = std(win_bd);
                if sw > 0
                    dist(b) = abs(cterm * trimmean(bd, 2 * tr * 100) / sw);
                else
                    dist(b) = NaN;
                end
            end
        else
            reported_eff = cohen_dz_val;
            metric_name  = "Cohen_dz";
            diff_s = d1 - d2;
            boot_s = diff_s(boot_indices);
            dist = abs(mean(boot_s, 1, 'omitnan') ./ std(boot_s, 0, 1, 'omitnan'))';
        end

        actual_dz_f4.(v_name) = reported_eff;
        dist_store_f4.(v_name) = dist;

        eff_rows_f4 = [eff_rows_f4; { ...
            "TrajNorm_noTimeExclusion", string(v_name), metric_name, has_outliers, ...
            mean_diff, sd_diff, reported_eff, cohen_dz_val, dep_akp_val, ...
            prctile(dist, 2.5), prctile(dist, 97.5) ...
        }];
    end

    effects_tbl_f4 = cell2table(eff_rows_f4, 'VariableNames', { ...
        'Flavor', 'Effect', 'Metric_Used', 'Has_Outliers', ...
        'Mean_Diff', 'SD_Diff', 'Reported_Effect_Size', 'Cohens_dz', 'Dependent_AKP', ...
        'CI_Lower', 'CI_Upper'});

    % 7. Pairwise Comparisons vs Keyboard RT (Flavor 4)
    kin_vars = {'ra', 'mt', 'tot_dist', 'react', 'com', 'traj', 'x_std'};
    kb_dist = dist_store_f4.kb_rt;
    kb_eff  = actual_dz_f4.kb_rt;

    within_rows_f4 = {};
    for k_i = 1:numel(kin_vars)
        kv = kin_vars{k_i};
        k_dist = dist_store_f4.(kv);
        k_eff  = actual_dz_f4.(kv);

        actual_diff = k_eff - kb_eff;
        diff_dist   = k_dist - kb_dist;

        ci_l = prctile(diff_dist, 2.5);
        ci_u = prctile(diff_dist, 97.5);
        p_val_2s = min(sum(diff_dist > 0), sum(diff_dist < 0)) / n_boot * 2;

        within_rows_f4 = [within_rows_f4; { ...
            "TrajNorm_noTimeExclusion", ...
            string(sprintf('%s_minus_kb_rt', kv)), ...
            actual_diff, ci_l, ci_u, p_val_2s ...
        }];
    end

    within_tbl_f4 = cell2table(within_rows_f4, 'VariableNames', { ...
        'Flavor', 'Comparison', 'Effect_Size_Diff', 'CI_Lower', 'CI_Upper', 'P_Value'});

    % 8. Side-by-Side Comparison Table: Flavor 4 vs Flavor 1
    loaded_boot = load(fullfile(out_stats_dir, 'Bootstrap_Stats_Tables.mat'));
    within_f1  = loaded_boot.within_tbl(string(loaded_boot.within_tbl.Flavor) == "TrajNorm_noStandardization", :);

    f1_diff = zeros(numel(kin_vars), 1);
    f1_low  = zeros(numel(kin_vars), 1);
    f1_up   = zeros(numel(kin_vars), 1);
    f1_p    = zeros(numel(kin_vars), 1);

    for v = 1:numel(kin_vars)
        vn = kin_vars{v};
        idx = find(within_f1.Comparison == sprintf('%s_minus_kb_rt', vn) | within_f1.Comparison == sprintf('kb_rt_minus_%s', vn));
        if ~isempty(idx)
            row = within_f1(idx(1), :);
            if row.Comparison == sprintf('%s_minus_kb_rt', vn)
                f1_diff(v) = row.Effect_Size_Diff;
                f1_low(v)  = row.CI_Lower;
                f1_up(v)   = row.CI_Upper;
            else
                f1_diff(v) = -row.Effect_Size_Diff;
                f1_low(v)  = -row.CI_Upper;
                f1_up(v)   = -row.CI_Lower;
            end
            f1_p(v) = row.P_Value;
        end
    end

    f4_vs_f1_tbl = table(string(kin_vars'), ...
        within_tbl_f4.Effect_Size_Diff, within_tbl_f4.CI_Lower, within_tbl_f4.CI_Upper, within_tbl_f4.P_Value, ...
        f1_diff, f1_low, f1_up, f1_p, ...
        'VariableNames', {'Kinematic_Metric', ...
                          'F4_Delta_dz', 'F4_CI_Lower', 'F4_CI_Upper', 'F4_P_Value', ...
                          'F1_Delta_dz', 'F1_CI_Lower', 'F1_CI_Upper', 'F1_P_Value'});

    % 9. Generate Forest Plots
    plot_si_reanalysis_forests(effects_tbl_f4, within_tbl_f4, f4_vs_f1_tbl, out_figs_dir);

    % 10. Save Standalone CSVs
    writetable(si_summary_tbl, fullfile(out_stats_dir, 'SI_Reanalysis_Summary.csv'));
    writetable(si_by_sub_tbl, fullfile(out_stats_dir, 'By_Sub_SI_noTimeExclusion.csv'));
    writetable(full_traj_clust_tbl, fullfile(out_stats_dir, 'Full_Traj_Permutation_Stats_Flavor_4.csv'));
    writetable(effects_tbl_f4, fullfile(out_stats_dir, 'Effect_Sizes_Flavor_4.csv'));
    writetable(within_tbl_f4, fullfile(out_stats_dir, 'Effect_Comparisons_Flavor_4_vs_KB_RT.csv'));
    writetable(f4_vs_f1_tbl, fullfile(out_stats_dir, 'Effect_Comparisons_Flavor_4_vs_Flavor_1.csv'));

    % 11. Generate Trial Exclusion Appendix Tables
    [counts_tbl, pct_tbl] = generate_si_trial_exclusion_tables(raw_proc_folder, [47, 49:51, 53:57, 59, 62, 65:67, 70:72, 75:85, 88, 90], all_subs, out_stats_dir);

    % 12. Save Dedicated Excel Workbook: SI_Reanalysis_noTimeExclusions.xlsx
    xlsx_path = fullfile(out_stats_dir, 'SI_Reanalysis_noTimeExclusions.xlsx');
    if exist(xlsx_path, 'file')
        try, delete(xlsx_path); catch, end
    end

    writetable(si_summary_tbl, xlsx_path, 'Sheet', 'SI_Reanalysis_Summary');
    writetable(si_by_sub_tbl, xlsx_path, 'Sheet', 'By_Sub_SI_noTimeExclusion');
    writetable(counts_tbl, xlsx_path, 'Sheet', 'SI_Excl_All_Subs_Counts');
    writetable(pct_tbl, xlsx_path, 'Sheet', 'SI_Excl_All_Subs_Pct');
    writetable(full_traj_clust_tbl, xlsx_path, 'Sheet', 'Full_Traj_Permutation_Stats');
    writetable(effects_tbl_f4, xlsx_path, 'Sheet', 'Effect_Sizes_Summary');
    writetable(within_tbl_f4, xlsx_path, 'Sheet', 'Effect_Comparisons_vs_KB_RT');
    writetable(f4_vs_f1_tbl, xlsx_path, 'Sheet', 'Effect_Comparisons_F4_vs_F1');

    fprintf('Saved dedicated SI re-analysis workbook to %s\n', xlsx_path);
end

function plot_si_reanalysis_forests(effects_tbl_f4, within_tbl_f4, f4_vs_f1_tbl, out_figs_dir)
% PLOT_SI_REANALYSIS_FORESTS Generates effect size and paired forest plots for Flavor 4

    readable_names = containers.Map(...
        {'react', 'mt', 'com', 'tot_dist', 'ra', 'kb_rt', 'traj', 'x_std'}, ...
        {'Reaching Onset', 'Reaching Duration', 'Num of COM', ...
         'Total Distance Traveled', 'Reach Area', 'Keyboard RT', ...
         'Deviation From Center', 'Movement Variance (X-STD)'});

    % -------------------------------------------------------------
    % Plot 1: Standardized Effect Sizes for Flavor 4 Alone
    % -------------------------------------------------------------
    fig1 = figure('Name', 'Effect Sizes - Flavor 4', 'Color', 'w', 'Position', [80 80 1120 580], 'Visible', 'off');
    ax1 = axes('Parent', fig1);
    hold(ax1, 'on');

    n_rows = height(effects_tbl_f4);
    y = n_rows : -1 : 1;
    vars = effects_tbl_f4.Effect;

    readable_vars = strings(length(vars), 1);
    for v = 1:length(vars)
        if isKey(readable_names, char(vars(v)))
            readable_vars(v) = readable_names(char(vars(v)));
        else
            readable_vars(v) = strrep(char(vars(v)), '_', ' ');
        end
    end

    err_neg = effects_tbl_f4.Reported_Effect_Size - effects_tbl_f4.CI_Lower;
    err_pos = effects_tbl_f4.CI_Upper - effects_tbl_f4.Reported_Effect_Size;

    errorbar(ax1, effects_tbl_f4.Reported_Effect_Size, y, err_neg, err_pos, 'horizontal', 's', ...
        'LineWidth', 1.6, 'MarkerSize', 8, 'MarkerFaceColor', [0.05 0.35 0.85], ...
        'Color', [0.00 0.35 0.75], 'CapSize', 10);

    [sorted_y, s_idx] = sort(y);
    set(ax1, 'YTick', sorted_y, 'YTickLabel', readable_vars(s_idx), 'FontSize', 11.5);
    ylim(ax1, [0.4, n_rows + 0.65]);
    min_x = min(0, min(effects_tbl_f4.CI_Lower) - 0.1);
    max_x = max(effects_tbl_f4.CI_Upper) + 0.65;
    xlim(ax1, [min_x, max_x]);
    xlabel(ax1, 'Standardized Effect Size (d_z / Dependent AKP)', 'FontSize', 13.5);
    title(ax1, {'Supplementary Re-Analysis (Flavor 4): Pre-Registered Variables Only', ...
                'No Time-Sensitive Exclusion Criteria (Trajectories normalized to %path, N=36)'}, ...
                'FontSize', 12.5, 'FontWeight', 'bold');

    for j = 1:length(y)
        val_str = format_num(effects_tbl_f4.Reported_Effect_Size(j));
        low_str = format_num(effects_tbl_f4.CI_Lower(j));
        up_str  = format_num(effects_tbl_f4.CI_Upper(j));
        txt = sprintf('%s [%s, %s]', val_str, low_str, up_str);
        text(ax1, effects_tbl_f4.CI_Upper(j) + 0.04, y(j), txt, 'VerticalAlignment', 'middle', 'FontSize', 10.5);
    end
    box(ax1, 'off');
    set(ax1, 'TickDir', 'out');
    grid(ax1, 'on');

    f1_base = fullfile(out_figs_dir, 'Effect_Sizes_Flavor_4_noTimeExclusion');
    exportgraphics(fig1, [f1_base, '.png'], 'Resolution', 300);
    exportgraphics(fig1, [f1_base, '.pdf'], 'ContentType', 'vector');
    saveas(fig1, [f1_base, '.fig']);
    saveas(fig1, [f1_base, '.svg']);
    close(fig1);

    % -------------------------------------------------------------
    % Plot 2: Paired Side-by-Side Forest Plot: Flavor 4 vs Flavor 1
    %         (Flavor 4 right above Flavor 1 for each kinematic metric)
    % -------------------------------------------------------------
    kin_vars = {'ra', 'mt', 'tot_dist', 'react', 'com', 'traj', 'x_std'};
    kin_labels = { ...
        'Reach Area', ...
        'Reaching Duration', ...
        'Total Distance Traveled', ...
        'Reaching Onset', ...
        'Num of COM', ...
        'Deviation From Center', ...
        'Movement Variance (X-STD)' ...
    };
    n_k = numel(kin_vars);

    fig2 = figure('Name', 'Effect Comparisons - Flavor 4 vs Flavor 1', 'Color', 'w', 'Position', [80 80 1350 780], 'Visible', 'off');
    ax2 = axes('Parent', fig2);
    hold(ax2, 'on');

    y_centers = (n_k : -1 : 1) * 2;
    y_f4 = y_centers + 0.28;
    y_f1 = y_centers - 0.28;

    % Background bands
    for v = 1:n_k
        y_b = y_centers(v) - 0.75;
        y_t = y_centers(v) + 0.75;
        if mod(v, 2) == 1
            patch(ax2, [-10 10 10 -10], [y_b y_b y_t y_t], [0.96 0.97 1.00], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
        else
            patch(ax2, [-10 10 10 -10], [y_b y_b y_t y_t], [0.98 0.98 0.98], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
        end
    end

    plot(ax2, [0 0], [0.5, max(y_centers) + 1.2], 'k--', 'LineWidth', 1.5);

    % Flavor 1: Red circles
    err_neg_f1 = f4_vs_f1_tbl.F1_Delta_dz - f4_vs_f1_tbl.F1_CI_Lower;
    err_pos_f1 = f4_vs_f1_tbl.F1_CI_Upper - f4_vs_f1_tbl.F1_Delta_dz;
    h_f1 = errorbar(ax2, f4_vs_f1_tbl.F1_Delta_dz, y_f1, err_neg_f1, err_pos_f1, 'horizontal', 'o', ...
        'LineWidth', 1.6, 'MarkerSize', 7, 'MarkerFaceColor', [0.85 0.15 0.15], ...
        'Color', [0.85 0.15 0.15], 'CapSize', 8, 'DisplayName', 'Flavor 1: Pre-registered (With Time Exclusions, N=30)');

    % Flavor 4: Blue squares
    err_neg_f4 = f4_vs_f1_tbl.F4_Delta_dz - f4_vs_f1_tbl.F4_CI_Lower;
    err_pos_f4 = f4_vs_f1_tbl.F4_CI_Upper - f4_vs_f1_tbl.F4_Delta_dz;
    h_f4 = errorbar(ax2, f4_vs_f1_tbl.F4_Delta_dz, y_f4, err_neg_f4, err_pos_f4, 'horizontal', 's', ...
        'LineWidth', 1.6, 'MarkerSize', 7, 'MarkerFaceColor', [0.05 0.35 0.85], ...
        'Color', [0.05 0.35 0.85], 'CapSize', 8, 'DisplayName', 'Flavor 4: SI Re-analysis (No Time Exclusions, N=36)');

    min_x = min([f4_vs_f1_tbl.F1_CI_Lower; f4_vs_f1_tbl.F4_CI_Lower]) - 0.20;
    max_x = max([f4_vs_f1_tbl.F1_CI_Upper; f4_vs_f1_tbl.F4_CI_Upper]) + 1.25;
    xlim(ax2, [min_x, max_x]);
    ylim(ax2, [0.5, max(y_centers) + 1.2]);

    [y_sorted, s_idx] = sort(y_centers);
    set(ax2, 'YTick', y_sorted, 'YTickLabel', kin_labels(s_idx), 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(ax2, '\Delta Standardized Effect Size (Kinematic Variable - Keyboard RT)', 'FontSize', 12.5, 'FontWeight', 'bold');
    title(ax2, {'Pre-Registered Kinematic Effect Size Differences Compared to KB RT', ...
               'Side-by-Side Comparison: Flavor 4 (No Time Exclusions, N=36) vs. Flavor 1 (Pre-registered, N=30)'}, ...
               'FontSize', 13, 'FontWeight', 'bold');

    legend(ax2, [h_f4, h_f1], {'Flavor 4 (SI Re-analysis: No Time Exclusions, N=36)', ...
                              'Flavor 1 (Main Manuscript: Pre-registered Time Exclusions, N=30)'}, ...
           'Location', 'northwest', 'FontSize', 10, 'Box', 'on', 'Color', [1 1 1 0.9]);

    for v = 1:n_k
        txt_f4 = sprintf('F4: %s [%s, %s], %s', format_num(f4_vs_f1_tbl.F4_Delta_dz(v)), ...
            format_num(f4_vs_f1_tbl.F4_CI_Lower(v)), format_num(f4_vs_f1_tbl.F4_CI_Upper(v)), format_p(f4_vs_f1_tbl.F4_P_Value(v)));
        text(ax2, f4_vs_f1_tbl.F4_CI_Upper(v) + 0.04, y_f4(v), txt_f4, 'FontSize', 9.5, 'Color', [0.05 0.30 0.75], 'VerticalAlignment', 'middle', 'FontWeight', 'bold');

        txt_f1 = sprintf('F1: %s [%s, %s], %s', format_num(f4_vs_f1_tbl.F1_Delta_dz(v)), ...
            format_num(f4_vs_f1_tbl.F1_CI_Lower(v)), format_num(f4_vs_f1_tbl.F1_CI_Upper(v)), format_p(f4_vs_f1_tbl.F1_P_Value(v)));
        text(ax2, f4_vs_f1_tbl.F1_CI_Upper(v) + 0.04, y_f1(v), txt_f1, 'FontSize', 9.5, 'Color', [0.75 0.10 0.10], 'VerticalAlignment', 'middle');
    end

    box(ax2, 'off');
    set(ax2, 'TickDir', 'out');
    grid(ax2, 'on');

    f2_base = fullfile(out_figs_dir, 'Effect_Comparisons_Flavor_4_vs_Flavor_1_SideBySide');
    exportgraphics(fig2, [f2_base, '.png'], 'Resolution', 300);
    exportgraphics(fig2, [f2_base, '.pdf'], 'ContentType', 'vector');
    saveas(fig2, [f2_base, '.fig']);
    saveas(fig2, [f2_base, '.svg']);
    close(fig2);

    fprintf('Saved all Flavor 4 effect size figures to %s\n', out_figs_dir);
end

function s = format_num(val)
    s = sprintf('%.2f', val);
    s = strrep(s, '0.', '.');
    s = strrep(s, '-0.', '-.');
end

function s = format_p(p)
    if p < 0.001
        s = 'p<.001';
    else
        s = sprintf('p=%.3f', p);
        s = strrep(s, 'p=0.', 'p=.');
    end
end
