function [excl_stats] = compute_trial_exclusion_stats(procFolder_TrajNorm, procFolder_noTrajNorm, good_subs, day_str, subs_str)
% COMPUTE_TRIAL_EXCLUSION_STATS Computes offline trial exclusion percentages (Mean % and SD %)
% across the included participants (good_subs), in total and split by active offline reasons.
%
% Explicitly omits online non-excluding flags ('slow_mvmnt' and 'loop') and reach-only
% kinematic flags from Keyboard. Includes both Total Offline Screen ('any' over active
% reasons) and Total Excluded including PAS > 1.

    if nargin < 4 || isempty(day_str), day_str = 'day2'; end
    if nargin < 5 || isempty(subs_str), subs_str = '47_49-85_87-90'; end

    bt_tn  = load(fullfile(procFolder_TrajNorm, sprintf('bad_trials_%s_target_x_to_subs_%s.mat', day_str, subs_str)));
    bt_ntn = load(fullfile(procFolder_noTrajNorm, sprintf('bad_trials_%s_target_x_to_subs_%s.mat', day_str, subs_str)));

    kb_reasons = {'bad_stim_dur', 'late_res', 'early_res', 'incorrect', 'quit'};
    kb_labels  = {'Bad_Stim_Duration', 'Late_Response', 'Early_Response', 'Incorrect_Target', 'Quit'};

    reach_reasons = {'hole_in_data', 'missing_data', 'diff_len', 'short_traj', 'missed_target', ...
                     'bad_stim_dur', 'late_res', 'very_slow_mvmnt', 'early_res', 'incorrect', 'quit'};
    reach_labels  = {'Hole_in_Data', 'Missing_Data', 'Insufficient_Length', 'Short_Trajectory', 'Missed_Target', ...
                     'Bad_Stim_Duration', 'Late_Response', 'Very_Slow_Movement', 'Early_Response', 'Incorrect_Target', 'Quit'};

    % Build detailed per-subject (%) + Group Mean/SD tables
    [kb_tbl, kb_mean, kb_sd, kb_cols] = build_modality_excl_table( ...
        bt_tn.keyboard_bad_trials, procFolder_TrajNorm, 'keyboard', good_subs, day_str, kb_reasons, kb_labels);

    [r_tn_tbl, r_tn_mean, r_tn_sd, r_cols] = build_modality_excl_table( ...
        bt_tn.reach_bad_trials, procFolder_TrajNorm, 'reach', good_subs, day_str, reach_reasons, reach_labels);

    [r_ntn_tbl, r_ntn_mean, r_ntn_sd, ~] = build_modality_excl_table( ...
        bt_ntn.reach_bad_trials, procFolder_noTrajNorm, 'reach', good_subs, day_str, reach_reasons, reach_labels);

    % Build unified cross-modality / cross-flavor summary table
    n_rows = numel(r_cols);
    kb_mean_aligned = NaN(n_rows, 1);
    kb_sd_aligned   = NaN(n_rows, 1);
    for i = 1:n_rows
        idx_k = find(strcmp(kb_cols, r_cols{i}), 1);
        if ~isempty(idx_k)
            kb_mean_aligned(i) = kb_mean(idx_k);
            kb_sd_aligned(i)   = kb_sd(idx_k);
        end
    end

    summary_tbl = table( ...
        string(r_cols(:)), ...
        kb_mean_aligned, kb_sd_aligned, ...
        r_tn_mean(:), r_tn_sd(:), ...
        r_ntn_mean(:), r_ntn_sd(:), ...
        'VariableNames', { ...
            'Exclusion_Reason', ...
            'Keyboard_Mean_Pct', 'Keyboard_SD_Pct', ...
            'Reach_TrajNorm_Mean_Pct', 'Reach_TrajNorm_SD_Pct', ...
            'Reach_noTrajNorm_Mean_Pct', 'Reach_noTrajNorm_SD_Pct'});

    excl_stats = struct();
    excl_stats.Summary          = summary_tbl;
    excl_stats.Keyboard         = kb_tbl;
    excl_stats.Reach_TrajNorm   = r_tn_tbl;
    excl_stats.Reach_noTrajNorm = r_ntn_tbl;
end

function [out_tbl, mean_pct, sd_pct, col_names] = build_modality_excl_table(bad_trials_cell, proc_folder, task_type, good_subs, day_str, reason_vars, reason_labels)
    n_subs = numel(good_subs);
    n_reasons = numel(reason_vars);
    col_names = [reason_labels, {'Total_Offline_Screen', 'PAS_gt_1', 'Total_Excluded_incl_PAS_gt_1'}];
    n_cols = numel(col_names);

    pct_mat = NaN(n_subs, n_cols);
    sub_labels = strings(n_subs + 2, 1);

    for s = 1:n_subs
        iSub = good_subs(s);
        sub_labels(s) = sprintf('Sub_%d', iSub);

        bt_sub = bad_trials_cell{iSub};
        dt_file = fullfile(proc_folder, sprintf('sub%d%s_%s_data_proc.mat', iSub, day_str, task_type));
        dt_loaded = load(dt_file);
        data_tbl = dt_loaded.([task_type '_data_table']);
        data_tbl(data_tbl.practice >= 1, :) = [];

        n_trials = height(bt_sub); % 240 experimental trials

        % Active technical/behavioral reasons (in trialScreen, failed trials store iTrial > 0; NaN is false)
        for r = 1:n_reasons
            pct_mat(s, r) = sum(bt_sub.(reason_vars{r}) > 0) / n_trials * 100;
        end

        active_bad = any(bt_sub{:, reason_vars} > 0, 2);
        pas_gt_1   = ismember(data_tbl.pas, [2, 3, 4]);
        total_excl = active_bad | ~ismember(data_tbl.pas, 1);

        pct_mat(s, n_reasons + 1) = sum(active_bad) / n_trials * 100;
        pct_mat(s, n_reasons + 2) = sum(pas_gt_1)   / n_trials * 100;
        pct_mat(s, n_reasons + 3) = sum(total_excl) / n_trials * 100;
    end

    mean_pct = mean(pct_mat, 1, 'omitnan');
    sd_pct   = std(pct_mat, 0, 1, 'omitnan');

    sub_labels(n_subs + 1) = "Group_Mean_Pct";
    sub_labels(n_subs + 2) = "Group_SD_Pct";

    full_mat = [pct_mat; mean_pct; sd_pct];

    out_tbl = array2table(full_mat, 'VariableNames', strcat(col_names, '_Pct'));
    out_tbl = addvars(out_tbl, sub_labels, 'Before', 1, 'NewVariableNames', 'Participant');
end
