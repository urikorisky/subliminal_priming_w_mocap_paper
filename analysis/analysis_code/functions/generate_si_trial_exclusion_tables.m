function [counts_tbl, pct_tbl] = generate_si_trial_exclusion_tables(procFolder, good_subs, all_subs)
% GENERATE_SI_TRIAL_EXCLUSION_TABLES Generates comprehensive trial exclusion tables
% for the Supplementary Information detailing trial counts and percentages for each
% exclusion criterion across all 42 tested participants (both valid and excluded).
%
% Output:
%   counts_tbl - Table of exact trial exclusion counts per participant and group summaries
%   pct_tbl    - Table of trial exclusion percentages per participant and group summaries

    if nargin < 1 || isempty(procFolder)
        procFolder = '../processed_data/nonStandardized_TrajNorm';
    end
    if nargin < 2 || isempty(good_subs)
        good_subs = [47, 49:51, 53:57, 59, 62, 65:67, 70:72, 75:85, 88, 90]; % N=30
    end
    if nargin < 3 || isempty(all_subs)
        all_subs = [47, 49:85, 87:90]; % N=42
    end

    bt_file = fullfile(procFolder, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat');
    bt = load(bt_file);

    reach_reasons = {'hole_in_data', 'missing_data', 'diff_len', 'short_traj', 'missed_target', ...
                     'bad_stim_dur', 'early_res', 'late_res', 'slow_mvmnt', 'very_slow_mvmnt', ...
                     'incorrect', 'quit'};
    reach_col_names = {'Reach_Hole_Data', 'Reach_Missing_Data', 'Reach_Diff_Length', ...
                       'Reach_Short_Traj', 'Reach_Missed_Target', 'Reach_Bad_Stim_Dur', ...
                       'Reach_Early_Res', 'Reach_Late_Res', 'Reach_Slow_Mvmnt_Online', ...
                       'Reach_Very_Slow_Mvmnt', 'Reach_Incorrect', 'Reach_Quit', ...
                       'Reach_Total_Offline_Technical_and_Behavioral', 'Reach_PAS_gt_1', ...
                       'Reach_Total_Excluded_incl_PAS'};

    kb_reasons = {'bad_stim_dur', 'early_res', 'late_res', 'incorrect', 'quit'};
    kb_col_names = {'KB_Bad_Stim_Dur', 'KB_Early_Res', 'KB_Late_Res', ...
                    'KB_Incorrect', 'KB_Quit', ...
                    'KB_Total_Offline_Technical_and_Behavioral', 'KB_PAS_gt_1', ...
                    'KB_Total_Excluded_incl_PAS'};

    n_subs = numel(all_subs);
    n_r_cols = numel(reach_col_names);
    n_k_cols = numel(kb_col_names);
    total_cols = n_r_cols + n_k_cols;

    counts_mat = zeros(n_subs, total_cols);
    pct_mat    = zeros(n_subs, total_cols);

    participant_ids = strings(n_subs, 1);
    group_status    = strings(n_subs, 1);

    for s_idx = 1:n_subs
        s = all_subs(s_idx);
        participant_ids(s_idx) = sprintf('Sub_%02d', s);
        if ismember(s, good_subs)
            group_status(s_idx) = "Valid";
        else
            group_status(s_idx) = "Excluded";
        end

        % 1. Reaching trials
        r_dt_file = fullfile(procFolder, sprintf('sub%dday2_reach_data_proc.mat', s));
        r_loaded = load(r_dt_file);
        r_tbl = r_loaded.reach_data_table;
        r_tbl(r_tbl.practice >= 1, :) = [];
        r_bt = bt.reach_bad_trials{s};
        n_r_trials = height(r_tbl);

        % Counts for each reach reason
        for r_i = 1:numel(reach_reasons)
            counts_mat(s_idx, r_i) = sum(r_bt.(reach_reasons{r_i}) > 0);
        end

        % Total offline technical & behavioral (omits online 'slow_mvmnt' and 'loop')
        r_active_reasons = {'hole_in_data', 'missing_data', 'diff_len', 'short_traj', 'missed_target', ...
                            'bad_stim_dur', 'early_res', 'late_res', 'very_slow_mvmnt', 'incorrect', 'quit'};
        r_active_bad = any(r_bt{:, r_active_reasons} > 0, 2);
        r_pas_gt_1   = ismember(r_tbl.pas, [2, 3, 4]);
        r_total_excl = r_active_bad | ~ismember(r_tbl.pas, 1);

        counts_mat(s_idx, 13) = sum(r_active_bad);
        counts_mat(s_idx, 14) = sum(r_pas_gt_1);
        counts_mat(s_idx, 15) = sum(r_total_excl);

        % Percentages
        pct_mat(s_idx, 1:n_r_cols) = counts_mat(s_idx, 1:n_r_cols) / n_r_trials * 100;

        % 2. Keyboard trials
        k_dt_file = fullfile(procFolder, sprintf('sub%dday2_keyboard_data_proc.mat', s));
        k_loaded = load(k_dt_file);
        k_tbl = k_loaded.keyboard_data_table;
        k_tbl(k_tbl.practice >= 1, :) = [];
        k_bt = bt.keyboard_bad_trials{s};
        n_k_trials = height(k_tbl);

        for k_i = 1:numel(kb_reasons)
            col_idx = n_r_cols + k_i;
            counts_mat(s_idx, col_idx) = sum(k_bt.(kb_reasons{k_i}) > 0);
        end

        k_active_reasons = {'bad_stim_dur', 'early_res', 'late_res', 'incorrect', 'quit'};
        k_active_bad = any(k_bt{:, k_active_reasons} > 0, 2);
        k_pas_gt_1   = ismember(k_tbl.pas, [2, 3, 4]);
        k_total_excl = k_active_bad | ~ismember(k_tbl.pas, 1);

        counts_mat(s_idx, n_r_cols + 6) = sum(k_active_bad);
        counts_mat(s_idx, n_r_cols + 7) = sum(k_pas_gt_1);
        counts_mat(s_idx, n_r_cols + 8) = sum(k_total_excl);

        pct_mat(s_idx, (n_r_cols + 1):total_cols) = counts_mat(s_idx, (n_r_cols + 1):total_cols) / n_k_trials * 100;
    end

    all_col_names = [reach_col_names, kb_col_names];

    % Calculate Group Summaries
    is_valid = group_status == "Valid";
    is_excl  = group_status == "Excluded";

    valid_counts_mean = mean(counts_mat(is_valid, :), 1);
    valid_counts_sd   = std(counts_mat(is_valid, :), 0, 1);
    valid_counts_sum  = sum(counts_mat(is_valid, :), 1);

    excl_counts_mean  = mean(counts_mat(is_excl, :), 1);
    excl_counts_sd    = std(counts_mat(is_excl, :), 0, 1);
    excl_counts_sum   = sum(counts_mat(is_excl, :), 1);

    all_counts_mean   = mean(counts_mat, 1);
    all_counts_sd     = std(counts_mat, 0, 1);
    all_counts_sum    = sum(counts_mat, 1);

    valid_pct_mean    = mean(pct_mat(is_valid, :), 1);
    valid_pct_sd      = std(pct_mat(is_valid, :), 0, 1);

    excl_pct_mean     = mean(pct_mat(is_excl, :), 1);
    excl_pct_sd       = std(pct_mat(is_excl, :), 0, 1);

    all_pct_mean      = mean(pct_mat, 1);
    all_pct_sd        = std(pct_mat, 0, 1);

    % Build Summary Rows
    summary_ids_counts = [
        "Valid_Participants_Mean";
        "Valid_Participants_SD";
        "Valid_Participants_Sum";
        "Excluded_Participants_Mean";
        "Excluded_Participants_SD";
        "Excluded_Participants_Sum";
        "All_Participants_Mean";
        "All_Participants_SD";
        "All_Participants_Sum"
    ];
    summary_status_counts = [
        "Valid_Summary"; "Valid_Summary"; "Valid_Summary";
        "Excluded_Summary"; "Excluded_Summary"; "Excluded_Summary";
        "All_Summary"; "All_Summary"; "All_Summary"
    ];
    summary_mat_counts = [
        valid_counts_mean;
        valid_counts_sd;
        valid_counts_sum;
        excl_counts_mean;
        excl_counts_sd;
        excl_counts_sum;
        all_counts_mean;
        all_counts_sd;
        all_counts_sum
    ];

    summary_ids_pct = [
        "Valid_Participants_Mean_Pct";
        "Valid_Participants_SD_Pct";
        "Excluded_Participants_Mean_Pct";
        "Excluded_Participants_SD_Pct";
        "All_Participants_Mean_Pct";
        "All_Participants_SD_Pct"
    ];
    summary_status_pct = [
        "Valid_Summary"; "Valid_Summary";
        "Excluded_Summary"; "Excluded_Summary";
        "All_Summary"; "All_Summary"
    ];
    summary_mat_pct = [
        valid_pct_mean;
        valid_pct_sd;
        excl_pct_mean;
        excl_pct_sd;
        all_pct_mean;
        all_pct_sd
    ];

    % Construct final tables
    counts_tbl = array2table([counts_mat; summary_mat_counts], 'VariableNames', all_col_names);
    counts_tbl = addvars(counts_tbl, [group_status; summary_status_counts], 'Before', 1, 'NewVariableNames', 'Group_Status');
    counts_tbl = addvars(counts_tbl, [participant_ids; summary_ids_counts], 'Before', 1, 'NewVariableNames', 'Participant');

    pct_tbl = array2table([pct_mat; summary_mat_pct], 'VariableNames', strcat(all_col_names, '_Pct'));
    pct_tbl = addvars(pct_tbl, [group_status; summary_status_pct], 'Before', 1, 'NewVariableNames', 'Group_Status');
    pct_tbl = addvars(pct_tbl, [participant_ids; summary_ids_pct], 'Before', 1, 'NewVariableNames', 'Participant');
end
