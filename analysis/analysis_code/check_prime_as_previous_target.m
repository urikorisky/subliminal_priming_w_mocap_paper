% Script to inspect experiment logs of stimuli presentation across all 42 participants:
% Specifically checks: Were there trials in which the prime word served as a target word in previous trials?

clear; clc;

data_dir = '../processed_data/nonStandardized_TrajNorm';
subs = [47, 49:85, 87:90]; % All 42 participants

% Results storage
results = struct();

fprintf('Analyzing %d participants...\n', length(subs));

sub_summary = table();

for s_idx = 1:length(subs)
    sub = subs(s_idx);
    
    kb_file = fullfile(data_dir, sprintf('sub%dday2_keyboard_data.mat', sub));
    reach_file = fullfile(data_dir, sprintf('sub%dday2_reach_data.mat', sub));
    
    if ~isfile(kb_file) || ~isfile(reach_file)
        warning('Missing file for sub %d', sub);
        continue;
    end
    
    k_data = load(kb_file);
    r_data = load(reach_file);
    
    kb_tbl = k_data.keyboard_data_table;
    reach_tbl = r_data.reach_data_table;
    
    % Determine session order
    % From main.m: reach_first = mod(p.SUB_NUM, 4) >= 2;
    reach_first = mod(sub, 4) >= 2;
    
    % Separate test trials
    kb_test = kb_tbl(kb_tbl.practice == 0, :);
    reach_test = reach_tbl(reach_tbl.practice == 0, :);
    
    % 1. Within Keyboard test session
    [kb_any_prev, kb_con_prev, kb_incon_prev, kb_same_blk, kb_diff_blk, kb_n_minus_1] = ...
        analyze_session_trials(kb_test);
        
    % 2. Within Reach test session
    [reach_any_prev, reach_con_prev, reach_incon_prev, reach_same_blk, reach_diff_blk, reach_n_minus_1] = ...
        analyze_session_trials(reach_test);
        
    % 3. Chronological across entire Day 2 (practice + test, or test + test)
    % Reconstruct chronological trial stream
    if reach_first
        session1_tbl = reach_tbl;
        session1_name = 'Reach';
        session2_tbl = kb_tbl;
        session2_name = 'Keyboard';
    else
        session1_tbl = kb_tbl;
        session1_name = 'Keyboard';
        session2_tbl = reach_tbl;
        session2_name = 'Reach';
    end
    
    % Chronological test trials only
    s1_test = session1_tbl(session1_tbl.practice == 0, :);
    s2_test = session2_tbl(session2_tbl.practice == 0, :);
    chron_test = [s1_test; s2_test];
    
    [chron_any_prev, chron_con_prev, chron_incon_prev, chron_same_blk, chron_diff_blk, chron_n_minus_1] = ...
        analyze_session_trials(chron_test);
        
    % How many primes in Session 2 appeared as targets in Session 1?
    s1_targets = unique(s1_test.target);
    s2_primes_in_s1_targets = sum(ismember(s2_test.prime, s1_targets));
    
    row = table(sub, reach_first, height(kb_test), height(reach_test), ...
        kb_any_prev, kb_con_prev, kb_incon_prev, kb_same_blk, kb_diff_blk, kb_n_minus_1, ...
        reach_any_prev, reach_con_prev, reach_incon_prev, reach_same_blk, reach_diff_blk, reach_n_minus_1, ...
        chron_any_prev, chron_con_prev, chron_incon_prev, chron_n_minus_1, ...
        s2_primes_in_s1_targets, ...
        'VariableNames', {'Participant', 'ReachFirst', 'N_KB_Trials', 'N_Reach_Trials', ...
        'KB_AnyPrevTarget', 'KB_Con_Prev', 'KB_Incon_Prev', 'KB_SameBlock_Prev', 'KB_DiffBlock_Prev', 'KB_N_minus_1', ...
        'Reach_AnyPrevTarget', 'Reach_Con_Prev', 'Reach_Incon_Prev', 'Reach_SameBlock_Prev', 'Reach_DiffBlock_Prev', 'Reach_N_minus_1', ...
        'Chron_AnyPrevTarget', 'Chron_Con_Prev', 'Chron_Incon_Prev', 'Chron_N_minus_1', ...
        'S2_Primes_In_S1_Targets'});
        
    sub_summary = [sub_summary; row];
end

fprintf('\n=======================================================\n');
fprintf('SUMMARY ACROSS %d PARTICIPANTS (TEST TRIALS):\n', height(sub_summary));
fprintf('=======================================================\n');

fprintf('\n--- 1. WITHIN KEYBOARD SESSION (240 test trials per participant) ---\n');
fprintf('Mean trials where prime served as earlier target: %.2f / 240 (%.1f%%) [min: %d, max: %d]\n', ...
    mean(sub_summary.KB_AnyPrevTarget), mean(sub_summary.KB_AnyPrevTarget)/240*100, ...
    min(sub_summary.KB_AnyPrevTarget), max(sub_summary.KB_AnyPrevTarget));
fprintf('  - Congruent trials:   %.2f / 120 (%.1f%%)\n', mean(sub_summary.KB_Con_Prev), mean(sub_summary.KB_Con_Prev)/120*100);
fprintf('  - Incongruent trials: %.2f / 120 (%.1f%%)\n', mean(sub_summary.KB_Incon_Prev), mean(sub_summary.KB_Incon_Prev)/120*100);
fprintf('  - Within same block:  %.2f trials\n', mean(sub_summary.KB_SameBlock_Prev));
fprintf('  - In earlier blocks:  %.2f trials\n', mean(sub_summary.KB_DiffBlock_Prev));
fprintf('  - Immediate trial n-1: %.2f trials [min: %d, max: %d]\n', ...
    mean(sub_summary.KB_N_minus_1), min(sub_summary.KB_N_minus_1), max(sub_summary.KB_N_minus_1));

fprintf('\n--- 2. WITHIN REACHING SESSION (240 test trials per participant) ---\n');
fprintf('Mean trials where prime served as earlier target: %.2f / 240 (%.1f%%) [min: %d, max: %d]\n', ...
    mean(sub_summary.Reach_AnyPrevTarget), mean(sub_summary.Reach_AnyPrevTarget)/240*100, ...
    min(sub_summary.Reach_AnyPrevTarget), max(sub_summary.Reach_AnyPrevTarget));
fprintf('  - Congruent trials:   %.2f / 120 (%.1f%%)\n', mean(sub_summary.Reach_Con_Prev), mean(sub_summary.Reach_Con_Prev)/120*100);
fprintf('  - Incongruent trials: %.2f / 120 (%.1f%%)\n', mean(sub_summary.Reach_Incon_Prev), mean(sub_summary.Reach_Incon_Prev)/120*100);
fprintf('  - Within same block:  %.2f trials\n', mean(sub_summary.Reach_SameBlock_Prev));
fprintf('  - In earlier blocks:  %.2f trials\n', mean(sub_summary.Reach_DiffBlock_Prev));
fprintf('  - Immediate trial n-1: %.2f trials [min: %d, max: %d]\n', ...
    mean(sub_summary.Reach_N_minus_1), min(sub_summary.Reach_N_minus_1), max(sub_summary.Reach_N_minus_1));

fprintf('\n--- 3. CHRONOLOGICALLY ACROSS ENTIRE DAY 2 (480 test trials per participant) ---\n');
fprintf('Mean trials where prime served as earlier target: %.2f / 480 (%.1f%%) [min: %d, max: %d]\n', ...
    mean(sub_summary.Chron_AnyPrevTarget), mean(sub_summary.Chron_AnyPrevTarget)/480*100, ...
    min(sub_summary.Chron_AnyPrevTarget), max(sub_summary.Chron_AnyPrevTarget));
fprintf('  - In Session 2 alone (240 test trials): %.2f / 240 (%.1f%%) primes were targets in Session 1\n', ...
    mean(sub_summary.S2_Primes_In_S1_Targets), mean(sub_summary.S2_Primes_In_S1_Targets)/240*100);
fprintf('  - Across all 480 trials, immediate trial n-1: %.2f trials\n', mean(sub_summary.Chron_N_minus_1));

% Save table to CSV
writetable(sub_summary, '../statistics/Prime_Served_As_Previous_Target_By_Sub.csv');
fprintf('\nSaved participant breakdown table to ../statistics/Prime_Served_As_Previous_Target_By_Sub.csv\n');

function [any_prev, con_prev, incon_prev, same_blk, diff_blk, n_minus_1] = analyze_session_trials(tbl)
    past_targets = {};
    any_prev = 0;
    con_prev = 0;
    incon_prev = 0;
    same_blk = 0;
    diff_blk = 0;
    n_minus_1 = 0;
    
    current_block = -1;
    block_past_targets = {};
    
    for t_i = 1:height(tbl)
        b = tbl.iBlock(t_i);
        if b ~= current_block
            current_block = b;
            block_past_targets = {};
        end
        
        p = tbl.prime{t_i};
        t = tbl.target{t_i};
        c = tbl.con(t_i);
        
        if ismember(p, past_targets)
            any_prev = any_prev + 1;
            if c == 1
                con_prev = con_prev + 1;
            else
                incon_prev = incon_prev + 1;
            end
            
            if ismember(p, block_past_targets)
                same_blk = same_blk + 1;
            else
                diff_blk = diff_blk + 1;
            end
        end
        
        if t_i > 1 && strcmp(p, tbl.target{t_i - 1})
            n_minus_1 = n_minus_1 + 1;
        end
        
        past_targets{end+1} = t;
        block_past_targets{end+1} = t;
    end
end
