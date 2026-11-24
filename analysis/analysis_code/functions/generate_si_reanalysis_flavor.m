function [si_reanalysis_struct] = generate_si_reanalysis_flavor(analysisPrms, within_tbl_f1)
% GENERATE_SI_REANALYSIS_FLAVOR Performs the supplementary re-analysis
% removing the offline slow-movement ("very_slow_mvmnt", > 3 SD movement duration)
% exclusion criterion during trial and participant screening, while keeping online
% abort criteria ("early_res", "late_res") and all other pre-registered criteria intact.
%
% Returns all summary, decomposition, by-participant, permutation, and
% bootstrap tables in memory via si_reanalysis_struct.

    if nargin < 1 || isempty(analysisPrms)
        analysisPrms = getDefaultAnalysisParams();
    end

    curr_func_dir = fileparts(mfilename('fullpath'));
    addpath(genpath(curr_func_dir));

    if analysisPrms.fromRawData
        raw_proc_folder = analysisPrms.targetPreProcData_TrajNorm_noStandardization_folder;
    else
        raw_proc_folder = analysisPrms.readyPreProcData_TrajNorm_noStandardization_folder;
    end
    if ~exist(raw_proc_folder, 'dir')
        raw_proc_folder = fullfile(curr_func_dir, '../../processed_data/nonStandardized_TrajNorm');
    end
    target_proc_folder = fullfile(curr_func_dir, '../../processed_data/noTimeExclusion_TrajNorm');
    if ~exist(target_proc_folder, 'dir')
        mkdir(target_proc_folder);
    end

    % 1. Sample Definition (N = 31: Flavor 1 N=30 + Sub 74 rescued when very_slow_mvmnt is removed)
    good_subs_si = [47, 49:51, 53:57, 59, 62, 65:67, 70:72, 74:85, 88, 90]; % N=31
    n_subs = numel(good_subs_si);
    all_subs = [47, 49:85, 87:90]; % N=42

    exp_p_file = fullfile(curr_func_dir, '../../../experiment/RUN_ME/code/p.mat');
    p = load(exp_p_file); p = p.p;
    p.DAY = 'day2';
    p.SUBS = all_subs;
    p.ORIG_SUBS = all_subs;
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
    p.REF_DATA_FOLDER = raw_proc_folder;
    p.PROC_DATA_FOLDER = raw_proc_folder;
    p.DATA_FOLDER = fullfile(curr_func_dir, '../../../../raw_data_from_OSF/');

    traj_names = {{'target_x_to', 'target_y_to', 'target_z_to'}};

    cache_file = fullfile(target_proc_folder, 'si_noVerySlow_all_avgs.mat');
    legacy_cache_file = fullfile(target_proc_folder, 'si_noTimeExclusion_all_avgs.mat');

    if analysisPrms.usePreprocDataWhereverPossible && exist(cache_file, 'file')
        fprintf('Loading precomputed SI re-analysis averages from %s...\n', cache_file);
        loaded = load(cache_file);
        r_avgs = loaded.r_avgs;
        k_avgs = loaded.k_avgs;
        r_trials = loaded.r_trials;
        k_trials = loaded.k_trials;
        reach_area = loaded.reach_area;
    else
        fprintf('Computing SI re-analysis trial averages (removing offline very_slow_mvmnt exclusions)...\n');
        [r_avgs, k_avgs, r_trials, k_trials, reach_area] = compute_all_si_no_vslow(all_subs, raw_proc_folder, traj_names{1}, p);
        save(cache_file, 'r_avgs', 'k_avgs', 'r_trials', 'k_trials', 'reach_area');
        save(legacy_cache_file, 'r_avgs', 'k_avgs', 'r_trials', 'k_trials', 'reach_area');
    end

    % 2. Extract Data Matrices for N=31
    discrete_vars = {'kb_rt', 'ra', 'react', 'mt', 'tot_dist', 'com', 'mad', 'auc'};
    var_labels    = {'Keyboard RT', 'Reach Area', 'Reaching Onset', 'Movement Duration', ...
                     'Total Distance Traveled', 'Num of Changes of Mind', 'Maximum Absolute Deviation (MAD)', 'Area Under Curve (AUC)'};
    var_units     = {'ms', '10^2 cm^2', 'ms', 'ms', 'cm', 'count', 'cm', '10^2 cm^2'};
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
                    c_val = r_avg.auc.con;
                    i_val = r_avg.auc.incon;
                    t_val = mean([r_tr.auc.con(:); r_tr.auc.incon(:)], 'omitnan');
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
    sub_col = [arrayfun(@(x) sprintf('Prtcp %d', x), good_subs_si(:), 'UniformOutput', false); {'Group_Mean'; 'Group_SD'}];
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
        'Before', 1, 'NewVariableNames', 'Analysis');

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
    % Uses the exact same time-point cluster averaging formula as bootstrap_effect_sizes.m
    prereg_vars = {'kb_rt', 'ra', 'react', 'mt', 'tot_dist', 'com', 'traj', 'x_std'};
    n_prereg = numel(prereg_vars);

    n_boot = 10000;
    rng(42, 'twister');
    boot_indices = randi(n_subs, n_subs, n_boot);

    eff_rows_f4 = {};
    dist_store_f4 = struct();
    actual_dz_f4 = struct();

    for v_i = 1:n_prereg
        v_name = prereg_vars{v_i};
        switch v_name
            case 'kb_rt'
                d1 = con_mat(:, 1); d2 = incon_mat(:, 1);
            case 'ra'
                d1 = con_mat(:, 2); d2 = incon_mat(:, 2);
            case 'react'
                d1 = con_mat(:, 3); d2 = incon_mat(:, 3);
            case 'mt'
                d1 = con_mat(:, 4); d2 = incon_mat(:, 4);
            case 'tot_dist'
                d1 = con_mat(:, 5); d2 = incon_mat(:, 5);
            case 'com'
                d1 = con_mat(:, 6); d2 = incon_mat(:, 6);
            case 'traj'
                d1 = traj_con_mat(win_traj(1):win_traj(2), :)';
                d2 = traj_incon_mat(win_traj(1):win_traj(2), :)';
            case 'x_std'
                d1 = x_std_con_mat(win_xstd(1):win_xstd(2), :)';
                d2 = x_std_incon_mat(win_xstd(1):win_xstd(2), :)';
        end

        diff_actual = d1 - d2;
        mean_diff_per_time = mean(diff_actual, 1, 'omitnan');
        sd_diff_per_time   = std(diff_actual, 0, 1, 'omitnan');
        dz_per_time        = mean_diff_per_time ./ sd_diff_per_time;

        mean_diff    = mean(mean_diff_per_time, 'omitnan');
        sd_diff      = mean(sd_diff_per_time, 'omitnan');
        cohen_dz_val = abs(mean(dz_per_time, 'omitnan'));

        if size(diff_actual, 2) == 1
            q1 = prctile(diff_actual, 25);
            q3 = prctile(diff_actual, 75);
            iqr_val = q3 - q1;
            has_outliers = any(diff_actual < (q1 - 1.5 * iqr_val) | diff_actual > (q3 + 1.5 * iqr_val));
            dep_akp_val = abs(calc_dependent_akp(d1, d2));
        else
            has_outliers = false;
            dep_akp_val  = cohen_dz_val;
        end

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
            T = size(diff_actual, 2);
            if T == 1
                boot_s = diff_actual(boot_indices);
                dist = abs(mean(boot_s, 1, 'omitnan') ./ std(boot_s, 0, 1, 'omitnan'))';
            else
                boot_dz_per_time = zeros(T, n_boot);
                for t = 1:T
                    diff_t = diff_actual(:, t);
                    boot_samples_t = diff_t(boot_indices);
                    boot_means = mean(boot_samples_t, 1, 'omitnan');
                    boot_stds  = std(boot_samples_t, 0, 1, 'omitnan');
                    boot_dz_per_time(t, :) = boot_means ./ boot_stds;
                end
                dist = abs(mean(boot_dz_per_time, 1, 'omitnan'))';
            end
        end

        actual_dz_f4.(v_name) = reported_eff;
        dist_store_f4.(v_name) = dist;

        eff_rows_f4 = [eff_rows_f4; { ...
            "TrajNorm_noTimeExclusion", string(v_name), metric_name, has_outliers, ...
            mean_diff, sd_diff, reported_eff, cohen_dz_val, dep_akp_val, ...
            prctile(dist, 2.5), prctile(dist, 97.5) ...
        }]; %#ok<AGROW>
    end

    effects_tbl_f4 = cell2table(eff_rows_f4, 'VariableNames', { ...
        'Analysis', 'Effect', 'Metric_Used', 'Has_Outliers', ...
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
        }]; %#ok<AGROW>
    end

    within_tbl_f4 = cell2table(within_rows_f4, 'VariableNames', { ...
        'Analysis', 'Comparison', 'Effect_Size_Diff', 'CI_Lower', 'CI_Upper', 'P_Value'});

    % 8. Side-by-Side Comparison Table: WO Long-Duration Exclusion vs Pre-Registered
    if nargin < 2 || isempty(within_tbl_f1)
        if isfield(analysisPrms, 'statsTables') && isfield(analysisPrms.statsTables, 'Effect_Comparisons_Within')
            within_tbl_f1 = analysisPrms.statsTables.Effect_Comparisons_Within;
        else
            error('generate_si_reanalysis_flavor:MissingInput', ...
                'within_tbl_f1 must be provided in memory.');
        end
    end
    within_f1 = within_tbl_f1(string(within_tbl_f1.Flavor) == "TrajNorm_noStandardization", :);

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
                          'WO_Long_Dur_Delta_dz', 'WO_Long_Dur_CI_Lower', 'WO_Long_Dur_CI_Upper', 'WO_Long_Dur_P_Value', ...
                          'PreReg_Delta_dz', 'PreReg_CI_Lower', 'PreReg_CI_Upper', 'PreReg_P_Value'});

    % 9. Build Trial-Level & Subject-Level Decomposition Table (PreReg vs Rescued VSM vs Combined WO Long Dur)
    decomp_tbl = build_f4_decomposition_table(raw_proc_folder, traj_names{1}, p, r_avgs, r_trials, reach_area, good_subs_si, c_traj, c_xstd, c_iep);

    % 10. Package all SI re-analysis tables into output struct (no interim CSV/XLSX/figure files)
    si_reanalysis_struct = struct( ...
        'si_summary_tbl',      si_summary_tbl, ...
        'decomp_tbl',          decomp_tbl, ...
        'si_by_sub_tbl',       si_by_sub_tbl, ...
        'full_traj_clust_tbl', full_traj_clust_tbl, ...
        'effects_tbl_f4',      effects_tbl_f4, ...
        'within_tbl_f4',       within_tbl_f4, ...
        'f4_vs_f1_tbl',        f4_vs_f1_tbl, ...
        'good_subs_si',        good_subs_si);
    fprintf('=== Completed SI no-long-duration re-analysis in memory (N=%d) ===\n', n_subs);
end

function [r_avgs, k_avgs, r_trials, k_trials, reach_area] = compute_all_si_no_vslow(all_subs, raw_proc_folder, traj_name, p)
% COMPUTE_ALL_SI_NO_VSLOW Recomputes within-subject averages and Reach Area
% when offline slow-movement ("very_slow_mvmnt") exclusions are removed,
% restoring any underlying short_traj or missed_target flags masked by cancelDuplicates.

    bt_file = fullfile(raw_proc_folder, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat');
    bt = load(bt_file);
    reach_bad_trials_novslow = bt.reach_bad_trials;
    keyboard_bad_trials = bt.keyboard_bad_trials;

    p_raw = p;
    p_raw.PROC_DATA_FOLDER = [replace(raw_proc_folder, '\', '/'), '/'];

    r_avgs   = cell(max(all_subs), 1);
    k_avgs   = cell(max(all_subs), 1);
    r_trials = cell(max(all_subs), 1);
    k_trials = cell(max(all_subs), 1);
    reach_area = struct('con', NaN(max(all_subs), 1), 'incon', NaN(max(all_subs), 1));

    for s = all_subs
        p_sub = defineParams_within_round(p_raw, s);
        p_sub.PROC_DATA_FOLDER = p_raw.PROC_DATA_FOLDER;

        r_bt = reach_bad_trials_novslow{s};
        idx_vs = find(r_bt.very_slow_mvmnt > 0);
        if ~isempty(idx_vs)
            tr_raw = load(fullfile(raw_proc_folder, sprintf('sub%dday2_reach_traj.mat', s)));
            tr_pre = load(fullfile(raw_proc_folder, sprintf('sub%dday2_reach_pre_norm_traj.mat', s)));
            reach_traj_table = tr_raw.reach_traj_table;
            reach_pre_norm_traj_table = tr_pre.reach_pre_norm_traj_table;
            reach_traj_table(reach_traj_table.practice >= 1, :) = [];
            reach_pre_norm_traj_table(reach_pre_norm_traj_table.practice >= 1, :) = [];

            trajs_mat = reshape(reach_traj_table{:, traj_name}, p_sub.MAX_CAP_LENGTH, p_sub.NUM_TRIALS, 3);
            trajs_pre_norm = reshape(reach_pre_norm_traj_table{:, traj_name}, p_sub.MAX_CAP_LENGTH, p_sub.NUM_TRIALS, 3);

            for t = idx_vs'
                if ~testReachDist(squeeze(trajs_pre_norm(:, t, :)), p_sub)
                    r_bt.short_traj(t) = t;
                end
                if ~testMissTarget(squeeze(trajs_mat(:, t, :)), p_sub)
                    r_bt.missed_target(t) = t;
                end
            end
        end

        r_bt.very_slow_mvmnt(:) = 0;
        important_tests = setdiff(string(r_bt.Properties.VariableNames), ["slow_mvmnt", "loop", "any"]);
        r_bt.any = any(r_bt{:, cellstr(important_tests)} > 0, 2);
        reach_bad_trials_novslow{s} = r_bt;

        [r_avg, r_tr, k_avg, k_tr] = avgWithin(s, traj_name, reach_bad_trials_novslow, keyboard_bad_trials, 1, 0, p_sub);
        r_avgs{s}   = r_avg;
        r_trials{s} = r_tr;
        k_avgs{s}   = k_avg;
        k_trials{s} = k_tr;

        reach_area.con(s)   = calcReachArea(r_avg.traj.con_left, r_avg.traj.con_right, p_sub);
        reach_area.incon(s) = calcReachArea(r_avg.traj.incon_left, r_avg.traj.incon_right, p_sub);
    end
end

function decomp_tbl = build_f4_decomposition_table(raw_proc_folder, traj_name, p, r_avgs_f4, ~, ra_f4, good_subs_si, c_traj, c_xstd, c_iep)
% BUILD_F4_DECOMPOSITION_TABLE Compares pooled Flavor 1 trials, pooled rescued
% very_slow_mvmnt trials alone, and subject-level means (Flavor 1 N=30, Flavor 4 N=30, Flavor 4 N=31)
% across all discrete and full-trajectory reaching measures.

    good_subs_f1 = [47, 49:51, 53:57, 59, 62, 65:67, 70:72, 75:85, 88, 90]; % N=30
    bt_file = fullfile(raw_proc_folder, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat');
    bt = load(bt_file);
    reach_bt = bt.reach_bad_trials;

    p_raw = p;
    p_raw.PROC_DATA_FOLDER = [replace(raw_proc_folder, '\', '/'), '/'];

    r_avgs_f1 = cell(max(good_subs_si), 1);
    r_trials_f1 = cell(max(good_subs_si), 1);
    ra_f1 = struct('con', NaN(max(good_subs_si), 1), 'incon', NaN(max(good_subs_si), 1));

    f1_trajs_cl = []; f1_trajs_cr = []; f1_trajs_il = []; f1_trajs_ir = [];
    vsm_trajs_cl = []; vsm_trajs_cr = []; vsm_trajs_il = []; vsm_trajs_ir = [];
    f1_iep_c = []; f1_iep_i = [];
    vsm_iep_c = []; vsm_iep_i = [];

    disc_vars = {'react', 'mt', 'tot_dist', 'com', 'mad', 'auc'};
    f1_pool = struct(); vsm_pool = struct();
    for v = 1:numel(disc_vars)
        vn = disc_vars{v};
        f1_pool.(vn) = struct('c', [], 'i', []);
        vsm_pool.(vn) = struct('c', [], 'i', []);
    end

    for s = good_subs_f1
        p_sub = defineParams_within_round(p_raw, s);
        p_sub.PROC_DATA_FOLDER = p_raw.PROC_DATA_FOLDER;
        [r_avg, r_tr, ~, ~] = avgWithin(s, traj_name, reach_bt, bt.keyboard_bad_trials, 1, 0, p_sub);
        r_avgs_f1{s} = r_avg;
        r_trials_f1{s} = r_tr;
        ra_f1.con(s) = calcReachArea(r_avg.traj.con_left, r_avg.traj.con_right, p_sub);
        ra_f1.incon(s) = calcReachArea(r_avg.traj.incon_left, r_avg.traj.incon_right, p_sub);

        f1_trajs_cl = cat(2, f1_trajs_cl, r_tr.trajs.con_left);
        f1_trajs_cr = cat(2, f1_trajs_cr, r_tr.trajs.con_right);
        f1_trajs_il = cat(2, f1_trajs_il, r_tr.trajs.incon_left);
        f1_trajs_ir = cat(2, f1_trajs_ir, r_tr.trajs.incon_right);
        f1_iep_c = cat(2, f1_iep_c, [-r_tr.iep.con_left, r_tr.iep.con_right]);
        f1_iep_i = cat(2, f1_iep_i, [-r_tr.iep.incon_left, r_tr.iep.incon_right]);

        % Identify rescued VSM trials for subject s
        r_bt = reach_bt{s};
        reasons_f1 = setdiff(string(r_bt.Properties.VariableNames), ["any","slow_mvmnt","loop"]);
        bad_f1 = any(r_bt{:, cellstr(reasons_f1)}, 2);
        tr_raw = load(fullfile(raw_proc_folder, sprintf('sub%dday2_reach_traj.mat', s)));
        tr_pre = load(fullfile(raw_proc_folder, sprintf('sub%dday2_reach_pre_norm_traj.mat', s)));
        rt_t = tr_raw.reach_traj_table; rt_t(rt_t.practice >= 1, :) = [];
        rp_t = tr_pre.reach_pre_norm_traj_table; rp_t(rp_t.practice >= 1, :) = [];
        t_mat = reshape(rt_t{:, traj_name}, p_sub.MAX_CAP_LENGTH, p_sub.NUM_TRIALS, 3);
        tp_mat = reshape(rp_t{:, traj_name}, p_sub.MAX_CAP_LENGTH, p_sub.NUM_TRIALS, 3);
        r_bt4 = r_bt;
        for t = find(r_bt.very_slow_mvmnt > 0)'
            if ~testReachDist(squeeze(tp_mat(:,t,:)), p_sub), r_bt4.short_traj(t) = t; end
            if ~testMissTarget(squeeze(t_mat(:,t,:)), p_sub), r_bt4.missed_target(t) = t; end
        end
        r_bt4.very_slow_mvmnt(:) = 0;
        bad_f4 = any(r_bt4{:, cellstr(reasons_f1)}, 2);
        is_rescued = bad_f1 & ~bad_f4;
        r_bt_vsm_only = r_bt4;
        r_bt_vsm_only.very_slow_mvmnt(~is_rescued) = 1;
        [~, tr_vsm, ~, ~] = avgWithin(s, traj_name, [repmat({[]}, s-1, 1); {r_bt_vsm_only}], bt.keyboard_bad_trials, 1, 0, p_sub);

        vsm_trajs_cl = cat(2, vsm_trajs_cl, tr_vsm.trajs.con_left);
        vsm_trajs_cr = cat(2, vsm_trajs_cr, tr_vsm.trajs.con_right);
        vsm_trajs_il = cat(2, vsm_trajs_il, tr_vsm.trajs.incon_left);
        vsm_trajs_ir = cat(2, vsm_trajs_ir, tr_vsm.trajs.incon_right);
        vsm_iep_c = cat(2, vsm_iep_c, [-tr_vsm.iep.con_left, tr_vsm.iep.con_right]);
        vsm_iep_i = cat(2, vsm_iep_i, [-tr_vsm.iep.incon_left, tr_vsm.iep.incon_right]);

        for v = 1:numel(disc_vars)
            vn = disc_vars{v};
            mult = 1;
            if ismember(vn, {'react','mt'}), mult = 1000;
            elseif ismember(vn, {'tot_dist','mad'}), mult = 100;
            end
            f1_pool.(vn).c = [f1_pool.(vn).c; r_tr.(vn).con(:) * mult];
            f1_pool.(vn).i = [f1_pool.(vn).i; r_tr.(vn).incon(:) * mult];
            vsm_pool.(vn).c = [vsm_pool.(vn).c; tr_vsm.(vn).con(:) * mult];
            vsm_pool.(vn).i = [vsm_pool.(vn).i; tr_vsm.(vn).incon(:) * mult];
        end
    end

    p_sub = defineParams_within_round(p_raw, good_subs_f1(1));
    all_vars = {'ra', 'react', 'mt', 'tot_dist', 'com', 'mad', 'auc', 'traj', 'x_std', 'iep'};
    all_lbls = {'Reach Area', 'Reaching Onset', 'Reaching Duration', 'Distance Traveled', ...
                'Changes of Mind (COM)', 'Maximum Absolute Deviation (MAD)', 'Area Under Curve (AUC)', ...
                'Deviance From Center (Cluster)', 'Horizontal Movement Variation (Cluster)', 'Implied Endpoint (Cluster)'};
    all_units = {'10^2 cm^2', 'ms', 'ms', 'cm', 'count', 'cm', '10^2 cm^2', 'cm', 'cm', 'cm'};
    if nargin >= 10 && ~isempty(c_traj) && ~isempty(c_traj.start) && c_traj.p_val(1) < 0.05
        w_traj = c_traj.start(1):c_traj.end(1);
    else
        w_traj = 1:200;
    end
    if nargin >= 10 && ~isempty(c_xstd) && ~isempty(c_xstd.start) && c_xstd.p_val(1) < 0.05
        w_xstd = c_xstd.start(1):c_xstd.end(1);
    else
        w_xstd = 1:200;
    end
    if nargin >= 10 && ~isempty(c_iep) && ~isempty(c_iep.start) && c_iep.p_val(1) < 0.05
        w_iep = c_iep.start(1):c_iep.end(1);
    else
        w_iep = 1:200;
    end
    all_types = {'Ensemble (Left/Right Area)', 'Single-Trial', 'Single-Trial', 'Single-Trial', ...
                 'Single-Trial', 'Single-Trial', 'Single-Trial', ...
                 sprintf('Full-Traj Cluster (%.1f-%.1f%%)', w_traj(1)*0.5, w_traj(end)*0.5), ...
                 sprintf('Full-Traj Cluster (%.1f-%.1f%%)', w_xstd(1)*0.5, w_xstd(end)*0.5), ...
                 sprintf('Full-Traj Cluster (%.1f-%.1f%%)', w_iep(1)*0.5,  w_iep(end)*0.5)};

    rows = {};
    for k = 1:numel(all_vars)
        vn = all_vars{k};
        switch vn
            case 'ra'
                f1_c = calcReachArea(squeeze(mean(f1_trajs_cl, 2)), squeeze(mean(f1_trajs_cr, 2)), p_sub);
                f1_i = calcReachArea(squeeze(mean(f1_trajs_il, 2)), squeeze(mean(f1_trajs_ir, 2)), p_sub);
                vsm_c = calcReachArea(squeeze(mean(vsm_trajs_cl, 2)), squeeze(mean(vsm_trajs_cr, 2)), p_sub);
                vsm_i = calcReachArea(squeeze(mean(vsm_trajs_il, 2)), squeeze(mean(vsm_trajs_ir, 2)), p_sub);
                d_f1_30 = ra_f1.incon(good_subs_f1) - ra_f1.con(good_subs_f1);
                d_f4_30 = ra_f4.incon(good_subs_f1) - ra_f4.con(good_subs_f1);
                d_f4_31 = ra_f4.incon(good_subs_si) - ra_f4.con(good_subs_si);
            case {'react', 'mt', 'tot_dist', 'com', 'mad', 'auc'}
                f1_c = mean(f1_pool.(vn).c, 'omitnan');
                f1_i = mean(f1_pool.(vn).i, 'omitnan');
                vsm_c = mean(vsm_pool.(vn).c, 'omitnan');
                vsm_i = mean(vsm_pool.(vn).i, 'omitnan');
                mult = 1;
                if ismember(vn, {'react','mt'}), mult = 1000;
                elseif ismember(vn, {'tot_dist','mad'}), mult = 100;
                end
                d_f1_30 = arrayfun(@(s) (r_avgs_f1{s}.(vn).incon - r_avgs_f1{s}.(vn).con)*mult, good_subs_f1(:));
                d_f4_30 = arrayfun(@(s) (r_avgs_f4{s}.(vn).incon - r_avgs_f4{s}.(vn).con)*mult, good_subs_f1(:));
                d_f4_31 = arrayfun(@(s) (r_avgs_f4{s}.(vn).incon - r_avgs_f4{s}.(vn).con)*mult, good_subs_si(:));
            case 'traj'
                f1_tc = [-squeeze(f1_trajs_cl(w_traj, :, 1)), squeeze(f1_trajs_cr(w_traj, :, 1))] * 100;
                f1_ti = [-squeeze(f1_trajs_il(w_traj, :, 1)), squeeze(f1_trajs_ir(w_traj, :, 1))] * 100;
                vsm_tc = [-squeeze(vsm_trajs_cl(w_traj, :, 1)), squeeze(vsm_trajs_cr(w_traj, :, 1))] * 100;
                vsm_ti = [-squeeze(vsm_trajs_il(w_traj, :, 1)), squeeze(vsm_trajs_ir(w_traj, :, 1))] * 100;
                f1_c = mean(f1_tc, 'all'); f1_i = mean(f1_ti, 'all');
                vsm_c = mean(vsm_tc, 'all'); vsm_i = mean(vsm_ti, 'all');
                d_f1_30 = arrayfun(@(s) mean(r_avgs_f1{s}.traj.incon(w_traj,1) - r_avgs_f1{s}.traj.con(w_traj,1))*100, good_subs_f1(:));
                d_f4_30 = arrayfun(@(s) mean(r_avgs_f4{s}.traj.incon(w_traj,1) - r_avgs_f4{s}.traj.con(w_traj,1))*100, good_subs_f1(:));
                d_f4_31 = arrayfun(@(s) mean(r_avgs_f4{s}.traj.incon(w_traj,1) - r_avgs_f4{s}.traj.con(w_traj,1))*100, good_subs_si(:));
            case 'x_std'
                f1_xc = std([squeeze(f1_trajs_cl(w_xstd, :, 1)), squeeze(f1_trajs_cr(w_xstd, :, 1))] * 100, 0, 2);
                f1_xi = std([squeeze(f1_trajs_il(w_xstd, :, 1)), squeeze(f1_trajs_ir(w_xstd, :, 1))] * 100, 0, 2);
                vsm_xc = std([squeeze(vsm_trajs_cl(w_xstd, :, 1)), squeeze(vsm_trajs_cr(w_xstd, :, 1))] * 100, 0, 2);
                vsm_xi = std([squeeze(vsm_trajs_il(w_xstd, :, 1)), squeeze(vsm_trajs_ir(w_xstd, :, 1))] * 100, 0, 2);
                f1_c = mean(f1_xc); f1_i = mean(f1_xi);
                vsm_c = mean(vsm_xc); vsm_i = mean(vsm_xi);
                d_f1_30 = arrayfun(@(s) mean(r_avgs_f1{s}.x_std.incon(w_xstd) - r_avgs_f1{s}.x_std.con(w_xstd))*100, good_subs_f1(:));
                d_f4_30 = arrayfun(@(s) mean(r_avgs_f4{s}.x_std.incon(w_xstd) - r_avgs_f4{s}.x_std.con(w_xstd))*100, good_subs_f1(:));
                d_f4_31 = arrayfun(@(s) mean(r_avgs_f4{s}.x_std.incon(w_xstd) - r_avgs_f4{s}.x_std.con(w_xstd))*100, good_subs_si(:));
            case 'iep'
                f1_c = mean(f1_iep_c(w_iep, :)*100, 'all');
                f1_i = mean(f1_iep_i(w_iep, :)*100, 'all');
                vsm_c = mean(vsm_iep_c(w_iep, :)*100, 'all');
                vsm_i = mean(vsm_iep_i(w_iep, :)*100, 'all');
                d_f1_30 = arrayfun(@(s) mean(r_avgs_f1{s}.iep.incon(w_iep) - r_avgs_f1{s}.iep.con(w_iep))*100, good_subs_f1(:));
                d_f4_30 = arrayfun(@(s) mean(r_avgs_f4{s}.iep.incon(w_iep) - r_avgs_f4{s}.iep.con(w_iep))*100, good_subs_f1(:));
                d_f4_31 = arrayfun(@(s) mean(r_avgs_f4{s}.iep.incon(w_iep) - r_avgs_f4{s}.iep.con(w_iep))*100, good_subs_si(:));
        end

        m1 = mean(d_f1_30); sd1 = std(d_f1_30); dz1 = m1 / sd1;
        m4_30 = mean(d_f4_30); sd4_30 = std(d_f4_30); dz4_30 = m4_30 / sd4_30;
        m4_31 = mean(d_f4_31); sd4_31 = std(d_f4_31); dz4_31 = m4_31 / sd4_31;

        rows = [rows; { ...
            string(vn), string(all_lbls{k}), string(all_units{k}), string(all_types{k}), ...
            f1_c, f1_i, f1_i - f1_c, ...
            vsm_c, vsm_i, vsm_i - vsm_c, ...
            m1, sd1, dz1, ...
            m4_30, sd4_30, dz4_30, ...
            100*(abs(m4_30)-abs(m1))/abs(m1), 100*(sd4_30-sd1)/sd1, ...
            m4_31, sd4_31, dz4_31 ...
        }]; %#ok<AGROW>
    end

    decomp_tbl = cell2table(rows, 'VariableNames', { ...
        'Variable', 'Measure', 'Units', 'Metric_Type', ...
        'PreReg_Pooled_Con', 'PreReg_Pooled_Incon', 'PreReg_Pooled_Diff', ...
        'Rescued_Slow_Pooled_Con', 'Rescued_Slow_Pooled_Incon', 'Rescued_Slow_Pooled_Diff', ...
        'PreReg_N30_Mean_Diff', 'PreReg_N30_SD_Diff', 'PreReg_N30_Cohens_dz', ...
        'WO_Long_Dur_N30_Mean_Diff', 'WO_Long_Dur_N30_SD_Diff', 'WO_Long_Dur_N30_Cohens_dz', ...
        'Pct_Change_Mean_Diff_N30', 'Pct_Change_SD_Diff_N30', ...
        'WO_Long_Dur_N31_Mean_Diff', 'WO_Long_Dur_N31_SD_Diff', 'WO_Long_Dur_N31_Cohens_dz'});
end
