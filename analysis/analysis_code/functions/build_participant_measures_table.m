function pt = build_participant_measures_table(roundName, proc_data_folder, good_subs, reach_avg_each, keyboard_avg_each, reach_area, dynamic_windows, p)
% BUILD_PARTICIPANT_MEASURES_TABLE Builds a comprehensive participant-level table
% containing trial counts, condition means, trial-weighted across-condition totals,
% and condition differences for all nominal and trajectory cluster measures.
% Also appends Group_Mean and Group_SD summary rows at the bottom.

    iTraj = 1;
    N_subs = length(good_subs);
    
    % Initialize participant labels
    part_labels = cell(N_subs + 2, 1);
    for i = 1:N_subs
        part_labels{i} = sprintf('Sub_%02d', i);
    end
    part_labels{N_subs + 1} = 'Group_Mean';
    part_labels{N_subs + 2} = 'Group_SD';
    
    sub_id_labels = cell(N_subs + 2, 1);
    for i = 1:N_subs
        sub_id_labels{i} = sprintf('%d', good_subs(i));
    end
    sub_id_labels{N_subs + 1} = 'Mean';
    sub_id_labels{N_subs + 2} = 'SD';
    
    % Trial counts
    n_r_c = reach_avg_each.n_trials(iTraj).con(good_subs)';
    n_r_i = reach_avg_each.n_trials(iTraj).incon(good_subs)';
    n_r_tot = reach_avg_each.n_trials(iTraj).total(good_subs)';
    
    n_k_c = keyboard_avg_each.n_trials(iTraj).con(good_subs)';
    n_k_i = keyboard_avg_each.n_trials(iTraj).incon(good_subs)';
    n_k_tot = keyboard_avg_each.n_trials(iTraj).total(good_subs)';

    % Keyboard RT (ms or z-score)
    kb_con = keyboard_avg_each.rt(iTraj).con(good_subs)';
    kb_incon = keyboard_avg_each.rt(iTraj).incon(good_subs)';
    kb_tot = keyboard_avg_each.rt(iTraj).total(good_subs)';
    if ~p.NORMALIZE_WITHIN_SUB && mean(kb_con, 'omitnan') < 10
        kb_con = kb_con * 1000;
        kb_incon = kb_incon * 1000;
        kb_tot = kb_tot * 1000;
    end
    kb_diff = kb_con - kb_incon;

    % Reach Area
    ra_con = reach_avg_each.ra(iTraj).con(good_subs)';
    ra_incon = reach_avg_each.ra(iTraj).incon(good_subs)';
    ra_tot = reach_avg_each.ra(iTraj).total(good_subs)';
    if ~p.NORMALIZE_WITHIN_SUB && ~p.NORM_TRAJ
        if mean(ra_con, 'omitnan') < 0.5
            ra_con = ra_con * 10000;
            ra_incon = ra_incon * 10000;
            ra_tot = ra_tot * 10000;
        end
    end
    ra_diff = ra_con - ra_incon;

    % Reaching Onset (ms or z-score)
    react_con = reach_avg_each.react(iTraj).con(good_subs)';
    react_incon = reach_avg_each.react(iTraj).incon(good_subs)';
    react_tot = reach_avg_each.react(iTraj).total(good_subs)';
    react_diff = react_con - react_incon;

    % Reaching Duration (ms or z-score)
    mt_con = reach_avg_each.mt(iTraj).con(good_subs)';
    mt_incon = reach_avg_each.mt(iTraj).incon(good_subs)';
    mt_tot = reach_avg_each.mt(iTraj).total(good_subs)';
    mt_diff = mt_con - mt_incon;

    % Total Distance Traveled (cm or z-score)
    dist_mult = 1;
    if ~p.NORMALIZE_WITHIN_SUB
        dist_mult = 100; % meters to cm
    end
    dist_con = reach_avg_each.tot_dist(iTraj).con(good_subs)' * dist_mult;
    dist_incon = reach_avg_each.tot_dist(iTraj).incon(good_subs)' * dist_mult;
    dist_tot = reach_avg_each.tot_dist(iTraj).total(good_subs)' * dist_mult;
    dist_diff = dist_con - dist_incon;

    % Num of COM
    com_con = reach_avg_each.com(iTraj).con(good_subs)';
    com_incon = reach_avg_each.com(iTraj).incon(good_subs)';
    com_tot = reach_avg_each.com(iTraj).total(good_subs)';
    com_diff = com_con - com_incon;

    % MAD (m or z-score)
    if p.NORMALIZE_WITHIN_SUB && isfield(reach_avg_each, 'mad_z')
        mad_con = reach_avg_each.mad_z(iTraj).con(good_subs)';
        mad_incon = reach_avg_each.mad_z(iTraj).incon(good_subs)';
        mad_tot = reach_avg_each.mad_z(iTraj).total(good_subs)';
    else
        mad_con = reach_avg_each.mad(iTraj).con(good_subs)';
        mad_incon = reach_avg_each.mad(iTraj).incon(good_subs)';
        mad_tot = reach_avg_each.mad(iTraj).total(good_subs)';
    end
    mad_diff = mad_con - mad_incon;

    % AUC
    auc_con = reach_avg_each.auc(iTraj).con(good_subs)';
    auc_incon = reach_avg_each.auc(iTraj).incon(good_subs)';
    auc_tot = reach_avg_each.auc(iTraj).total(good_subs)';
    auc_diff = auc_con - auc_incon;

    col_names = {'Participant', 'Sub_ID', ...
        'N_Reach_Valid', 'N_Reach_Con', 'N_Reach_Incon', ...
        'N_KB_Valid', 'N_KB_Con', 'N_KB_Incon', ...
        'KB_RT_Total', 'KB_RT_Con', 'KB_RT_Incon', 'KB_RT_Diff', ...
        'Reach_Area_Total', 'Reach_Area_Con', 'Reach_Area_Incon', 'Reach_Area_Diff', ...
        'Reaching_Onset_Total', 'Reaching_Onset_Con', 'Reaching_Onset_Incon', 'Reaching_Onset_Diff', ...
        'Reaching_Duration_Total', 'Reaching_Duration_Con', 'Reaching_Duration_Incon', 'Reaching_Duration_Diff', ...
        'Total_Distance_Total', 'Total_Distance_Con', 'Total_Distance_Incon', 'Total_Distance_Diff', ...
        'Num_COM_Total', 'Num_COM_Con', 'Num_COM_Incon', 'Num_COM_Diff', ...
        'MAD_Total', 'MAD_Con', 'MAD_Incon', 'MAD_Diff', ...
        'AUC_Total', 'AUC_Con', 'AUC_Incon', 'AUC_Diff'};

    numeric_matrix = [n_r_tot, n_r_c, n_r_i, ...
        n_k_tot, n_k_c, n_k_i, ...
        kb_tot, kb_con, kb_incon, kb_diff, ...
        ra_tot, ra_con, ra_incon, ra_diff, ...
        react_tot, react_con, react_incon, react_diff, ...
        mt_tot, mt_con, mt_incon, mt_diff, ...
        dist_tot, dist_con, dist_incon, dist_diff, ...
        com_tot, com_con, com_incon, com_diff, ...
        mad_tot, mad_con, mad_incon, mad_diff, ...
        auc_tot, auc_con, auc_incon, auc_diff];

    % Add trajectory cluster measures if present
    if isstruct(dynamic_windows)
        w_fields = fieldnames(dynamic_windows);
        for iW = 1:numel(w_fields)
            wf = w_fields{iW};
            win = dynamic_windows.(wf);
            st = win(1);
            en = win(2);
            switch wf
                case 'traj'
                    base_name = 'Dev_From_Center';
                    d_c = mean(reach_avg_each.traj(iTraj).con(st:en, good_subs, 1), 1)';
                    d_i = mean(reach_avg_each.traj(iTraj).incon(st:en, good_subs, 1), 1)';
                case 'iep'
                    base_name = 'IEP';
                    d_c = mean(reach_avg_each.iep(iTraj).con(st:en, good_subs), 1)';
                    d_i = mean(reach_avg_each.iep(iTraj).incon(st:en, good_subs), 1)';
                case 'x_std'
                    base_name = 'Movement_Variance';
                    d_c = mean(reach_avg_each.x_std(iTraj).con(st:en, good_subs), 1)';
                    d_i = mean(reach_avg_each.x_std(iTraj).incon(st:en, good_subs), 1)';
                case 'head_angle'
                    base_name = 'Heading_Angle';
                    d_c = mean(reach_avg_each.head_angle(iTraj).con(st:en, good_subs), 1)';
                    d_i = mean(reach_avg_each.head_angle(iTraj).incon(st:en, good_subs), 1)';
                otherwise
                    continue;
            end
            d_tot = (n_r_c .* d_c + n_r_i .* d_i) ./ (n_r_c + n_r_i);
            d_diff = d_c - d_i;
            col_names = [col_names, {[base_name '_Total'], [base_name '_Con'], [base_name '_Incon'], [base_name '_Diff']}];
            numeric_matrix = [numeric_matrix, d_tot, d_c, d_i, d_diff];
        end
    end

    % Compute Group_Mean and Group_SD
    mean_row = mean(numeric_matrix, 1, 'omitnan');
    sd_row   = std(numeric_matrix, 0, 1, 'omitnan');
    full_matrix = [numeric_matrix; mean_row; sd_row];

    % Construct final table
    pt = table(part_labels, sub_id_labels, 'VariableNames', {'Participant', 'Sub_ID'});
    num_cols = col_names(3:end);
    for c = 1:numel(num_cols)
        pt.(num_cols{c}) = full_matrix(:, c);
    end
end
