function [pas_summary_table, pas_by_sub_table, pas_stats_table, kb_PAS_Pct_Table, reach_PAS_Pct_Table] = compute_pas_analyses(reach_avg_each, keyboard_avg_each, good_subs, out_stats_dir)
% COMPUTE_PAS_ANALYSES Analyzes perceptual awareness scores (PAS 1-4) by Task and Congruency
%
% Computes:
%   1. 2x2 Repeated-Measures ANOVA on Average PAS Score (Task x Congruency, N=30)
%   2. Level-by-level within-subject paired tests across participants (Wilcoxon signed-rank and paired t-test)
%   3. Group-level descriptive statistics table with all marginals (Table 2 for manuscript)
%   4. Detailed participant-level descriptive statistics table

    arguments
        reach_avg_each struct
        keyboard_avg_each struct
        good_subs double
        out_stats_dir char = '../statistics'
    end

    n_subs = numel(good_subs);
    weights = [1, 2, 3, 4]; % PAS scale weights

    % Extract counts: matrices of size (n_subs, 4)
    r_con_cnt   = reach_avg_each.pas.con(good_subs, :);
    r_incon_cnt = reach_avg_each.pas.incon(good_subs, :);
    k_con_cnt   = keyboard_avg_each.pas.con(good_subs, :);
    k_incon_cnt = keyboard_avg_each.pas.incon(good_subs, :);

    r_con_tot_trials   = sum(r_con_cnt, 2);
    r_incon_tot_trials = sum(r_incon_cnt, 2);
    k_con_tot_trials   = sum(k_con_cnt, 2);
    k_incon_tot_trials = sum(k_incon_cnt, 2);

    % Compute per-participant percentages
    r_con_pct   = (r_con_cnt ./ r_con_tot_trials) * 100;
    r_incon_pct = (r_incon_cnt ./ r_incon_tot_trials) * 100;
    k_con_pct   = (k_con_cnt ./ k_con_tot_trials) * 100;
    k_incon_pct = (k_incon_cnt ./ k_incon_tot_trials) * 100;

    % Combined task percentages per participant
    comb_con_cnt = r_con_cnt + k_con_cnt;
    comb_incon_cnt = r_incon_cnt + k_incon_cnt;
    comb_con_tot = sum(comb_con_cnt, 2);
    comb_incon_tot = sum(comb_incon_cnt, 2);
    comb_con_pct = (comb_con_cnt ./ comb_con_tot) * 100;
    comb_incon_pct = (comb_incon_cnt ./ comb_incon_tot) * 100;

    % Compute per-participant mean PAS score
    r_con_mean_pas   = sum(r_con_cnt .* weights, 2) ./ r_con_tot_trials;
    r_incon_mean_pas = sum(r_incon_cnt .* weights, 2) ./ r_incon_tot_trials;
    k_con_mean_pas   = sum(k_con_cnt .* weights, 2) ./ k_con_tot_trials;
    k_incon_mean_pas = sum(k_incon_cnt .* weights, 2) ./ k_incon_tot_trials;

    r_tot_cnt = r_con_cnt + r_incon_cnt;
    r_tot_trials = sum(r_tot_cnt, 2);
    r_tot_pct = (r_tot_cnt ./ r_tot_trials) * 100;
    r_tot_mean_pas = sum(r_tot_cnt .* weights, 2) ./ r_tot_trials;

    k_tot_cnt = k_con_cnt + k_incon_cnt;
    k_tot_trials = sum(k_tot_cnt, 2);
    k_tot_pct = (k_tot_cnt ./ k_tot_trials) * 100;
    k_tot_mean_pas = sum(k_tot_cnt .* weights, 2) ./ k_tot_trials;

    comb_tot_cnt = comb_con_cnt + comb_incon_cnt;
    comb_tot_trials = sum(comb_tot_cnt, 2);
    comb_tot_pct = (comb_tot_cnt ./ comb_tot_trials) * 100;
    comb_tot_mean_pas = sum(comb_tot_cnt .* weights, 2) ./ comb_tot_trials;

    %% 1. Group-Level Table 2 (Descriptive Statistics with All Marginals)
    % Cell definitions
    cells = {
        'Reaching', 'Congruent', sum(r_con_cnt, 1), r_con_mean_pas;
        'Reaching', 'Incongruent', sum(r_incon_cnt, 1), r_incon_mean_pas;
        'Reaching', 'Total (Marginal)', sum(r_tot_cnt, 1), r_tot_mean_pas;
        'Keyboard', 'Congruent', sum(k_con_cnt, 1), k_con_mean_pas;
        'Keyboard', 'Incongruent', sum(k_incon_cnt, 1), k_incon_mean_pas;
        'Keyboard', 'Total (Marginal)', sum(k_tot_cnt, 1), k_tot_mean_pas;
        'Marginal by Congruency', 'Congruent Total', sum(comb_con_cnt, 1), sum(comb_con_cnt .* weights, 2) ./ comb_con_tot;
        'Marginal by Congruency', 'Incongruent Total', sum(comb_incon_cnt, 1), sum(comb_incon_cnt .* weights, 2) ./ comb_incon_tot;
        'Grand Total', 'All Tasks & Conditions', sum(comb_tot_cnt, 1), comb_tot_mean_pas
    };

    n_rows = size(cells, 1);
    t_task = strings(n_rows, 1);
    t_cond = strings(n_rows, 1);
    t_tot_trials = zeros(n_rows, 1);
    t_pas1_pct = zeros(n_rows, 1);
    t_pas1_cnt = zeros(n_rows, 1);
    t_pas2_pct = zeros(n_rows, 1);
    t_pas2_cnt = zeros(n_rows, 1);
    t_pas3_pct = zeros(n_rows, 1);
    t_pas3_cnt = zeros(n_rows, 1);
    t_pas4_pct = zeros(n_rows, 1);
    t_pas4_cnt = zeros(n_rows, 1);
    t_mean_pas = zeros(n_rows, 1);
    t_sd_pas   = zeros(n_rows, 1);

    for r_i = 1:n_rows
        t_task(r_i) = cells{r_i, 1};
        t_cond(r_i) = cells{r_i, 2};
        cnts = cells{r_i, 3};
        tot = sum(cnts);
        t_tot_trials(r_i) = tot;
        
        t_pas1_cnt(r_i) = cnts(1);
        t_pas1_pct(r_i) = cnts(1) / tot * 100;
        t_pas2_cnt(r_i) = cnts(2);
        t_pas2_pct(r_i) = cnts(2) / tot * 100;
        t_pas3_cnt(r_i) = cnts(3);
        t_pas3_pct(r_i) = cnts(3) / tot * 100;
        t_pas4_cnt(r_i) = cnts(4);
        t_pas4_pct(r_i) = cnts(4) / tot * 100;

        sub_means = cells{r_i, 4};
        t_mean_pas(r_i) = mean(sub_means);
        t_sd_pas(r_i)   = std(sub_means);
    end

    pas_summary_table = table(t_task, t_cond, t_tot_trials, ...
        t_pas1_pct, t_pas1_cnt, t_pas2_pct, t_pas2_cnt, ...
        t_pas3_pct, t_pas3_cnt, t_pas4_pct, t_pas4_cnt, ...
        t_mean_pas, t_sd_pas, ...
        'VariableNames', {'Task', 'Condition', 'Total_Trials', ...
        'PAS_1_Percent', 'PAS_1_Count', 'PAS_2_Percent', 'PAS_2_Count', ...
        'PAS_3_Percent', 'PAS_3_Count', 'PAS_4_Percent', 'PAS_4_Count', ...
        'Mean_PAS_Score', 'SD_PAS_Score'});

    %% 2. Statistical Analysis Suite (All 3 Analyses)
    stats_rows = {};

    % --- Analysis 1: 2x2 rm-ANOVA on Mean PAS Score ---
    % Contrasts
    d_task = (k_con_mean_pas + k_incon_mean_pas)/2 - (r_con_mean_pas + r_incon_mean_pas)/2;
    [~, p_task, ~, stat_task] = ttest(d_task);
    f_task = stat_task.tstat^2;
    eta_task = f_task / (f_task + (n_subs - 1));

    d_cong = (r_incon_mean_pas + k_incon_mean_pas)/2 - (r_con_mean_pas + k_con_mean_pas)/2;
    [~, p_cong, ~, stat_cong] = ttest(d_cong);
    f_cong = stat_cong.tstat^2;
    eta_cong = f_cong / (f_cong + (n_subs - 1));

    d_inter = (r_incon_mean_pas - r_con_mean_pas) - (k_incon_mean_pas - k_con_mean_pas);
    [~, p_inter, ~, stat_inter] = ttest(d_inter);
    f_inter = stat_inter.tstat^2;
    eta_inter = f_inter / (f_inter + (n_subs - 1));

    stats_rows(end+1, :) = {'rm_ANOVA_Mean_PAS', 'Main_Effect_Congruency (Incon - Con)', 'Both', ...
        sprintf('Mean Diff = %.3f', mean(d_cong)), f_cong, 1, n_subs-1, p_cong, eta_cong, 'Omnibus 2x2 rm-ANOVA on average PAS score (1-4)'};
    stats_rows(end+1, :) = {'rm_ANOVA_Mean_PAS', 'Main_Effect_Task (KB - Reach)', 'Both', ...
        sprintf('Mean Diff = %.3f', mean(d_task)), f_task, 1, n_subs-1, p_task, eta_task, 'Omnibus 2x2 rm-ANOVA on average PAS score (1-4)'};
    stats_rows(end+1, :) = {'rm_ANOVA_Mean_PAS', 'Interaction_Task_x_Congruency', 'Both', ...
        sprintf('Diff-of-Diffs = %.3f', mean(d_inter)), f_inter, 1, n_subs-1, p_inter, eta_inter, 'Omnibus 2x2 rm-ANOVA on average PAS score (1-4)'};

    % --- Analysis 2: Level-by-level within-subject tests for Reaching, Keyboard, and Combined ---
    comparisons = {
        'Reaching', r_con_pct, r_incon_pct;
        'Keyboard', k_con_pct, k_incon_pct;
        'Combined_Tasks', comb_con_pct, comb_incon_pct
    };

    for c_i = 1:size(comparisons, 1)
        mod_name = comparisons{c_i, 1};
        cp_mat = comparisons{c_i, 2};
        ip_mat = comparisons{c_i, 3};

        % Level-by-level
        for k = 1:4
            diff_pct = cp_mat(:, k) - ip_mat(:, k);
            mean_c = mean(cp_mat(:, k));
            mean_i = mean(ip_mat(:, k));
            mean_diff = mean(diff_pct);

            % Paired t-test
            [~, p_t, ~, st_t] = ttest(cp_mat(:, k), ip_mat(:, k));
            t_val = st_t.tstat;

            % Wilcoxon signed rank
            [p_w, ~, st_w] = signrank(cp_mat(:, k), ip_mat(:, k));
            if isfield(st_w, 'signedrank')
                w_val = st_w.signedrank;
            else
                w_val = NaN;
            end

            stats_rows(end+1, :) = {'Paired_t_test_Pct', sprintf('PAS_%d', k), mod_name, ...
                sprintf('Con=%.2f%%, Incon=%.2f%%, Diff=%.2f%%', mean_c, mean_i, mean_diff), ...
                t_val, st_t.df, NaN, p_t, NaN, 'Within-subject paired t-test on participant %'};

            stats_rows(end+1, :) = {'Wilcoxon_Signed_Rank', sprintf('PAS_%d', k), mod_name, ...
                sprintf('Con=%.2f%%, Incon=%.2f%%, Median Diff=%.2f%%', mean_c, mean_i, median(diff_pct)), ...
                w_val, n_subs, NaN, p_w, NaN, 'Within-subject non-parametric signed-rank test on participant %'};
        end
    end

    pas_stats_table = cell2table(stats_rows, 'VariableNames', ...
        {'Analysis_Type', 'Test_Contrast', 'Modality', 'Descriptive_Summary', ...
        'Test_Statistic', 'df1', 'df2', 'P_Value', 'Effect_Size_Partial_Eta2', 'Notes'});

    %% 3. Participant-Level Detailed Table (All 30 Good Subs)
    sub_col = (1:n_subs)';
    sub_id_col = good_subs(:);

    pas_by_sub_table = table(sub_col, sub_id_col, ...
        r_con_pct(:,1), r_con_pct(:,2), r_con_pct(:,3), r_con_pct(:,4), r_con_mean_pas, ...
        r_incon_pct(:,1), r_incon_pct(:,2), r_incon_pct(:,3), r_incon_pct(:,4), r_incon_mean_pas, ...
        r_tot_pct(:,1), r_tot_pct(:,2), r_tot_pct(:,3), r_tot_pct(:,4), r_tot_mean_pas, ...
        k_con_pct(:,1), k_con_pct(:,2), k_con_pct(:,3), k_con_pct(:,4), k_con_mean_pas, ...
        k_incon_pct(:,1), k_incon_pct(:,2), k_incon_pct(:,3), k_incon_pct(:,4), k_incon_mean_pas, ...
        k_tot_pct(:,1), k_tot_pct(:,2), k_tot_pct(:,3), k_tot_pct(:,4), k_tot_mean_pas, ...
        'VariableNames', {'Index', 'Participant_ID', ...
        'Reach_Con_PAS1_Pct', 'Reach_Con_PAS2_Pct', 'Reach_Con_PAS3_Pct', 'Reach_Con_PAS4_Pct', 'Reach_Con_Mean_PAS', ...
        'Reach_Incon_PAS1_Pct', 'Reach_Incon_PAS2_Pct', 'Reach_Incon_PAS3_Pct', 'Reach_Incon_PAS4_Pct', 'Reach_Incon_Mean_PAS', ...
        'Reach_Total_PAS1_Pct', 'Reach_Total_PAS2_Pct', 'Reach_Total_PAS3_Pct', 'Reach_Total_PAS4_Pct', 'Reach_Total_Mean_PAS', ...
        'KB_Con_PAS1_Pct', 'KB_Con_PAS2_Pct', 'KB_Con_PAS3_Pct', 'KB_Con_PAS4_Pct', 'KB_Con_Mean_PAS', ...
        'KB_Incon_PAS1_Pct', 'KB_Incon_PAS2_Pct', 'KB_Incon_PAS3_Pct', 'KB_Incon_PAS4_Pct', 'KB_Incon_Mean_PAS', ...
        'KB_Total_PAS1_Pct', 'KB_Total_PAS2_Pct', 'KB_Total_PAS3_Pct', 'KB_Total_PAS4_Pct', 'KB_Total_Mean_PAS'});

    %% 4. Format Augmented Per-Participant Sheets (Matching previous Table_2_Keyboard and Table_2_Reaching)
    kb_PAS_Pct_Table = table(sub_col, sub_id_col, ...
        k_tot_pct(:,1), k_tot_pct(:,2), k_tot_pct(:,3), k_tot_pct(:,4), ...
        k_con_pct(:,1), k_con_pct(:,2), k_con_pct(:,3), k_con_pct(:,4), ...
        k_incon_pct(:,1), k_incon_pct(:,2), k_incon_pct(:,3), k_incon_pct(:,4), ...
        k_tot_mean_pas, k_con_mean_pas, k_incon_mean_pas, ...
        keyboard_avg_each.fc_prime.incon(good_subs)' * 100, ...
        keyboard_avg_each.fc_prime.con(good_subs)' * 100, ...
        'VariableNames', {'Participant_Index', 'Participant_ID', ...
        'PAS_1_Percent', 'PAS_2_Percent', 'PAS_3_Percent', 'PAS_4_Percent', ...
        'PAS_1_Con_Pct', 'PAS_2_Con_Pct', 'PAS_3_Con_Pct', 'PAS_4_Con_Pct', ...
        'PAS_1_Incon_Pct', 'PAS_2_Incon_Pct', 'PAS_3_Incon_Pct', 'PAS_4_Incon_Pct', ...
        'Mean_PAS_Total', 'Mean_PAS_Con', 'Mean_PAS_Incon', ...
        'Obj_PAS1_Incon_Percent', 'Obj_PAS1_Con_Percent'});

    reach_PAS_Pct_Table = table(sub_col, sub_id_col, ...
        r_tot_pct(:,1), r_tot_pct(:,2), r_tot_pct(:,3), r_tot_pct(:,4), ...
        r_con_pct(:,1), r_con_pct(:,2), r_con_pct(:,3), r_con_pct(:,4), ...
        r_incon_pct(:,1), r_incon_pct(:,2), r_incon_pct(:,3), r_incon_pct(:,4), ...
        r_tot_mean_pas, r_con_mean_pas, r_incon_mean_pas, ...
        reach_avg_each.fc_prime.incon(good_subs)' * 100, ...
        reach_avg_each.fc_prime.con(good_subs)' * 100, ...
        'VariableNames', {'Participant_Index', 'Participant_ID', ...
        'PAS_1_Percent', 'PAS_2_Percent', 'PAS_3_Percent', 'PAS_4_Percent', ...
        'PAS_1_Con_Pct', 'PAS_2_Con_Pct', 'PAS_3_Con_Pct', 'PAS_4_Con_Pct', ...
        'PAS_1_Incon_Pct', 'PAS_2_Incon_Pct', 'PAS_3_Incon_Pct', 'PAS_4_Incon_Pct', ...
        'Mean_PAS_Total', 'Mean_PAS_Con', 'Mean_PAS_Incon', ...
        'Obj_PAS1_Incon_Percent', 'Obj_PAS1_Con_Percent'});

    %% 5. Save Standalone CSVs
    if ~exist(out_stats_dir, 'dir')
        mkdir(out_stats_dir);
    end
    writetable(pas_summary_table, fullfile(out_stats_dir, 'Table_2_PAS_Summary.csv'));
    writetable(pas_stats_table, fullfile(out_stats_dir, 'Table_2_PAS_Statistical_Tests.csv'));
    writetable(pas_by_sub_table, fullfile(out_stats_dir, 'Table_2_PAS_By_Sub.csv'));
    fprintf('Saved PAS summary, statistical tests, and by-sub CSVs to %s\n', out_stats_dir);
end
