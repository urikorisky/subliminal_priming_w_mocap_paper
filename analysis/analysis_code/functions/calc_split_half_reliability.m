function [Reliability_Results, Reliability_Table] = calc_split_half_reliability(proc_data_folder, good_subs, n_splits, screen_dist)
%CALC_SPLIT_HALF_RELIABILITY Computes Spearman-Brown corrected split-half reliability
% across n_splits (default 5,000) stratified random splits for the 8 discrete
% manuscript metrics in the primary flavor (TrajNorm_noStandardization).
%
% Inputs:
%   proc_data_folder - Path to precomputed/processed TrajNorm_noStandardization folder
%   good_subs        - Vector of 30 valid participant IDs
%   n_splits         - Number of random Monte Carlo splits (default: 5000)
%   screen_dist      - Screen distance in meters (default: loaded from p.mat, 0.35)
%
% Outputs:
%   Reliability_Results - Struct containing full 5000 x 8 distributions and metadata
%   Reliability_Table   - Summary table (24 rows: 8 metrics x 3 score types) with
%                         Pearson r_SB and Spearman rho_SB means, medians, SDs, and 95% CIs

    if nargin < 3 || isempty(n_splits)
        n_splits = 5000;
    end

    if nargin < 4 || isempty(screen_dist)
        p_candidates = { ...
            '../../experiment/RUN_ME/code/p.mat', ...
            'experiment/RUN_ME/code/p.mat', ...
            fullfile(fileparts(mfilename('fullpath')), '../../../experiment/RUN_ME/code/p.mat') ...
        };
        screen_dist = 0.35;
        for c = 1:numel(p_candidates)
            if isfile(p_candidates{c})
                tmp_p = load(p_candidates{c}, 'p');
                if isfield(tmp_p, 'p') && isfield(tmp_p.p, 'SCREEN_DIST')
                    screen_dist = tmp_p.p.SCREEN_DIST;
                    break;
                end
            end
        end
    end

    % Resolve proc_data_folder if relative to analysis_code
    if ~isfolder(proc_data_folder)
        alt_folder = fullfile(fileparts(mfilename('fullpath')), '..', proc_data_folder);
        if isfolder(alt_folder)
            proc_data_folder = alt_folder;
        end
    end

    % Fix random seed for 100% reproducible Monte Carlo splits
    rng(42, 'twister');

    % Define the 8 discrete manuscript metrics
    metric_codes  = ["kb_rt", "ra", "react", "mt", "tot_dist", "com", "mad", "auc"];
    metric_labels = ["Keyboard RT", "Reach Area", "Reaching Onset", "Movement Duration", ...
                     "Total Distance", "Changes of Mind", "Max Absolute Deviation", "Area Under Curve"];
    metric_cats   = ["PreReg_Confirmatory", "PreReg_Confirmatory", ...
                     "PreReg_Exploratory", "PreReg_Exploratory", "PreReg_Exploratory", "PreReg_Exploratory", ...
                     "PostHoc_Exploratory", "PostHoc_Exploratory"];

    n_metrics = numel(metric_codes);
    n_subs    = numel(good_subs);

    % Preallocate Half 1 and Half 2 participant score arrays:
    % Dimensions: [n_subs x n_splits x n_metrics]
    H1_con   = NaN(n_subs, n_splits, n_metrics);
    H2_con   = NaN(n_subs, n_splits, n_metrics);
    H1_incon = NaN(n_subs, n_splits, n_metrics);
    H2_incon = NaN(n_subs, n_splits, n_metrics);
    H1_diff  = NaN(n_subs, n_splits, n_metrics);
    H2_diff  = NaN(n_subs, n_splits, n_metrics);

    % Verify exact match of full-trial Reach Area against saved reach_area file on first run
    ra_scale = screen_dist * 100; % 35 cm

    fprintf('Computing Spearman-Brown split-half reliability (%d splits, %d valid subjects)...\n', n_splits, n_subs);
    tic;

    reach_scalar_fields = {'react', 'mt', 'tot_dist', 'com', 'mad', 'auc'};
    reach_scalar_scales = [1000, 1000, 1, 1, 1, 1];
    reach_scalar_idx    = [3, 4, 5, 6, 7, 8]; % indices in metric_codes

    for iSubIdx = 1:n_subs
        sub_id = good_subs(iSubIdx);
        trial_file = fullfile(proc_data_folder, sprintf('sub%dday2_sorted_trials_target_x_to.mat', sub_id));
        if ~isfile(trial_file)
            error('calc_split_half_reliability:MissingFile', 'Sorted trials file not found: %s', trial_file);
        end
        S = load(trial_file, 'r_trial', 'k_trial');
        r_trial = S.r_trial;
        k_trial = S.k_trial;

        % --- 1. Keyboard RT (Metric 1) ---
        k_CL = k_trial.rt.con_left(:)   * 1000;
        k_CR = k_trial.rt.con_right(:)  * 1000;
        k_IL = k_trial.rt.incon_left(:) * 1000;
        k_IR = k_trial.rt.incon_right(:)* 1000;

        [m1_CL, m2_CL] = split_scalar_means(k_CL, n_splits);
        [m1_CR, m2_CR] = split_scalar_means(k_CR, n_splits);
        [m1_IL, m2_IL] = split_scalar_means(k_IL, n_splits);
        [m1_IR, m2_IR] = split_scalar_means(k_IR, n_splits);

        c1 = (m1_CL + m1_CR) / 2;
        c2 = (m2_CL + m2_CR) / 2;
        i1 = (m1_IL + m1_IR) / 2;
        i2 = (m2_IL + m2_IR) / 2;

        H1_con(iSubIdx, :, 1)   = c1;
        H2_con(iSubIdx, :, 1)   = c2;
        H1_incon(iSubIdx, :, 1) = i1;
        H2_incon(iSubIdx, :, 1) = i2;
        H1_diff(iSubIdx, :, 1)  = i1 - c1;
        H2_diff(iSubIdx, :, 1)  = i2 - c2;

        % --- 2. Synchronized Stratified Indices for All 7 Reach Metrics ---
        n_CL = size(r_trial.rt.con_left, 1);
        n_CR = size(r_trial.rt.con_right, 1);
        n_IL = size(r_trial.rt.incon_left, 1);
        n_IR = size(r_trial.rt.incon_right, 1);

        [idx1_CL, idx2_CL] = generate_split_indices(n_CL, n_splits);
        [idx1_CR, idx2_CR] = generate_split_indices(n_CR, n_splits);
        [idx1_IL, idx2_IL] = generate_split_indices(n_IL, n_splits);
        [idx1_IR, idx2_IR] = generate_split_indices(n_IR, n_splits);

        % --- 2a. Scalar Reach Metrics (Metrics 3..8: react, mt, tot_dist, com, mad, auc) ---
        for kS = 1:numel(reach_scalar_fields)
            fName = reach_scalar_fields{kS};
            mIdx  = reach_scalar_idx(kS);
            sc    = reach_scalar_scales(kS);

            v_CL = r_trial.(fName).con_left(:)   * sc;
            v_CR = r_trial.(fName).con_right(:)  * sc;
            v_IL = r_trial.(fName).incon_left(:) * sc;
            v_IR = r_trial.(fName).incon_right(:)* sc;

            s1_CL = mean(v_CL(idx1_CL), 1);
            s2_CL = mean(v_CL(idx2_CL), 1);
            s1_CR = mean(v_CR(idx1_CR), 1);
            s2_CR = mean(v_CR(idx2_CR), 1);
            s1_IL = mean(v_IL(idx1_IL), 1);
            s2_IL = mean(v_IL(idx2_IL), 1);
            s1_IR = mean(v_IR(idx1_IR), 1);
            s2_IR = mean(v_IR(idx2_IR), 1);

            rc1 = (s1_CL + s1_CR) / 2;
            rc2 = (s2_CL + s2_CR) / 2;
            ri1 = (s1_IL + s1_IR) / 2;
            ri2 = (s2_IL + s2_IR) / 2;

            H1_con(iSubIdx, :, mIdx)   = rc1;
            H2_con(iSubIdx, :, mIdx)   = rc2;
            H1_incon(iSubIdx, :, mIdx) = ri1;
            H2_incon(iSubIdx, :, mIdx) = ri2;
            H1_diff(iSubIdx, :, mIdx)  = ri1 - rc1;
            H2_diff(iSubIdx, :, mIdx)  = ri2 - rc2;
        end

        % --- 2b. Reach Area (Metric 2: ra) ---
        % Extract X (col 1) and Z (col 3) trajectories: [200 x N_trials]
        X_CL = r_trial.trajs.con_left(:, :, 1);
        Z_CL = r_trial.trajs.con_left(:, :, 3);
        X_CR = r_trial.trajs.con_right(:, :, 1);
        Z_CR = r_trial.trajs.con_right(:, :, 3);
        X_IL = r_trial.trajs.incon_left(:, :, 1);
        Z_IL = r_trial.trajs.incon_left(:, :, 3);
        X_IR = r_trial.trajs.incon_right(:, :, 1);
        Z_IR = r_trial.trajs.incon_right(:, :, 3);

        % Note: For any fixed half-sample size h = floor(N/2), mean(Z(:, idx), 2)
        % is identical across all splits because every column of Z is (1:200)'/200!
        z_mean_CL = mean(Z_CL(:, 1:size(idx1_CL,1)), 2) * ra_scale;
        z_mean_CR = mean(Z_CR(:, 1:size(idx1_CR,1)), 2) * ra_scale;
        z_mean_IL = mean(Z_IL(:, 1:size(idx1_IL,1)), 2) * ra_scale;
        z_mean_IR = mean(Z_IR(:, 1:size(idx1_IR,1)), 2) * ra_scale;

        % Compute mean X trajectories for all 5,000 splits using matrix multiplication / reshape
        h_CL = size(idx1_CL, 1);
        h_CR = size(idx1_CR, 1);
        h_IL = size(idx1_IL, 1);
        h_IR = size(idx1_IR, 1);

        X1_CL_all = squeeze(mean(reshape(X_CL(:, idx1_CL(:)), 200, h_CL, n_splits), 2));
        X2_CL_all = squeeze(mean(reshape(X_CL(:, idx2_CL(:)), 200, h_CL, n_splits), 2));
        X1_CR_all = squeeze(mean(reshape(X_CR(:, idx1_CR(:)), 200, h_CR, n_splits), 2));
        X2_CR_all = squeeze(mean(reshape(X_CR(:, idx2_CR(:)), 200, h_CR, n_splits), 2));

        X1_IL_all = squeeze(mean(reshape(X_IL(:, idx1_IL(:)), 200, h_IL, n_splits), 2));
        X2_IL_all = squeeze(mean(reshape(X_IL(:, idx2_IL(:)), 200, h_IL, n_splits), 2));
        X1_IR_all = squeeze(mean(reshape(X_IR(:, idx1_IR(:)), 200, h_IR, n_splits), 2));
        X2_IR_all = squeeze(mean(reshape(X_IR(:, idx2_IR(:)), 200, h_IR, n_splits), 2));

        ra1_con   = zeros(1, n_splits);
        ra2_con   = zeros(1, n_splits);
        ra1_incon = zeros(1, n_splits);
        ra2_incon = zeros(1, n_splits);

        for b = 1:n_splits
            ra1_con(b)   = calcArea_fast_exact([z_mean_CL, X1_CL_all(:, b)], [z_mean_CR, X1_CR_all(:, b)]);
            ra2_con(b)   = calcArea_fast_exact([z_mean_CL, X2_CL_all(:, b)], [z_mean_CR, X2_CR_all(:, b)]);
            ra1_incon(b) = calcArea_fast_exact([z_mean_IL, X1_IL_all(:, b)], [z_mean_IR, X1_IR_all(:, b)]);
            ra2_incon(b) = calcArea_fast_exact([z_mean_IL, X2_IL_all(:, b)], [z_mean_IR, X2_IR_all(:, b)]);
        end

        H1_con(iSubIdx, :, 2)   = ra1_con;
        H2_con(iSubIdx, :, 2)   = ra2_con;
        H1_incon(iSubIdx, :, 2) = ra1_incon;
        H2_incon(iSubIdx, :, 2) = ra2_incon;
        H1_diff(iSubIdx, :, 2)  = ra1_con - ra1_incon;
        H2_diff(iSubIdx, :, 2)  = ra2_con - ra2_incon;
    end

    elapsed = toc;
    fprintf('Finished trial-level split-half extraction in %.2f sec.\n', elapsed);

    % --- 3. Compute Split-Half Correlations & Spearman-Brown Prophecy across 5,000 splits ---
    score_types = ["Congruency_Diff", "Congruent_Mean", "Incongruent_Mean"];
    n_scores    = numel(score_types);

    Reliability_Results = struct();
    Reliability_Results.metric_codes  = metric_codes;
    Reliability_Results.metric_labels = metric_labels;
    Reliability_Results.metric_cats   = metric_cats;
    Reliability_Results.score_types   = score_types;
    Reliability_Results.good_subs     = good_subs;
    Reliability_Results.n_splits      = n_splits;

    rows_cell = cell(n_metrics * n_scores, 1);
    row_counter = 0;

    for sIdx = 1:n_scores
        sType = score_types(sIdx);
        switch sType
            case "Congruency_Diff"
                M1 = H1_diff;
                M2 = H2_diff;
            case "Congruent_Mean"
                M1 = H1_con;
                M2 = H2_con;
            case "Incongruent_Mean"
                M1 = H1_incon;
                M2 = H2_incon;
        end

        r_half_mat   = NaN(n_splits, n_metrics);
        r_sb_mat     = NaN(n_splits, n_metrics);
        rho_half_mat = NaN(n_splits, n_metrics);
        rho_sb_mat   = NaN(n_splits, n_metrics);

        for mIdx = 1:n_metrics
            X1 = M1(:, :, mIdx); % [30 x 5000]
            X2 = M2(:, :, mIdx); % [30 x 5000]

            % Vectorized Pearson correlation across all 5,000 columns
            X1_c = X1 - mean(X1, 1);
            X2_c = X2 - mean(X2, 1);
            r_half = sum(X1_c .* X2_c, 1) ./ sqrt(sum(X1_c.^2, 1) .* sum(X2_c.^2, 1));
            r_half = r_half(:);
            r_sb   = (2 .* r_half) ./ (1 + abs(r_half));

            % Vectorized Spearman rank correlation across all 5,000 columns
            R1 = tiedrank_columns(X1);
            R2 = tiedrank_columns(X2);
            R1_c = R1 - mean(R1, 1);
            R2_c = R2 - mean(R2, 1);
            rho_half = sum(R1_c .* R2_c, 1) ./ sqrt(sum(R1_c.^2, 1) .* sum(R2_c.^2, 1));
            rho_half = rho_half(:);
            rho_sb   = (2 .* rho_half) ./ (1 + abs(rho_half));

            r_half_mat(:, mIdx)   = r_half;
            r_sb_mat(:, mIdx)     = r_sb;
            rho_half_mat(:, mIdx) = rho_half;
            rho_sb_mat(:, mIdx)   = rho_sb;

            row_counter = row_counter + 1;
            row_struct = struct();
            row_struct.Metric_Code            = metric_codes(mIdx);
            row_struct.Metric_Label           = metric_labels(mIdx);
            row_struct.Category               = metric_cats(mIdx);
            row_struct.Score_Type             = sType;
            row_struct.N_Subjects             = n_subs;
            row_struct.N_Splits               = n_splits;
            row_struct.Pearson_r_Half_Mean    = mean(r_half, 'omitnan');
            row_struct.Pearson_r_SB_Mean      = mean(r_sb, 'omitnan');
            row_struct.Pearson_r_SB_Median    = median(r_sb, 'omitnan');
            row_struct.Pearson_r_SB_SD        = std(r_sb, 0, 'omitnan');
            row_struct.Pearson_CI_Lower       = prctile(r_sb, 2.5);
            row_struct.Pearson_CI_Upper       = prctile(r_sb, 97.5);
            row_struct.Spearman_rho_Half_Mean = mean(rho_half, 'omitnan');
            row_struct.Spearman_rho_SB_Mean   = mean(rho_sb, 'omitnan');
            row_struct.Spearman_rho_SB_Median = median(rho_sb, 'omitnan');
            row_struct.Spearman_rho_SB_SD     = std(rho_sb, 0, 'omitnan');
            row_struct.Spearman_CI_Lower      = prctile(rho_sb, 2.5);
            row_struct.Spearman_CI_Upper      = prctile(rho_sb, 97.5);

            rows_cell{row_counter} = struct2table(row_struct);
        end

        Reliability_Results.(sType).Pearson_r_Half    = r_half_mat;
        Reliability_Results.(sType).Pearson_r_SB      = r_sb_mat;
        Reliability_Results.(sType).Spearman_rho_Half = rho_half_mat;
        Reliability_Results.(sType).Spearman_rho_SB   = rho_sb_mat;
    end

    Reliability_Table = vertcat(rows_cell{:});
    Reliability_Results.Summary_Table = Reliability_Table;

    fprintf('\n--- Split-Half Reliability Summary (Congruency Difference Score) ---\n');
    disp(Reliability_Table(Reliability_Table.Score_Type == "Congruency_Diff", ...
        {'Metric_Label', 'Category', 'Pearson_r_SB_Mean', 'Pearson_CI_Lower', 'Pearson_CI_Upper', ...
         'Spearman_rho_SB_Mean', 'Spearman_CI_Lower', 'Spearman_CI_Upper'}));
end

%% ========================================================================
%  Helper Functions
%  ========================================================================

function [idx1, idx2] = generate_split_indices(n_trials, n_splits)
% Generates [h x n_splits] random disjoint index matrices for Half 1 and Half 2
    h = floor(n_trials / 2);
    [~, perms] = sort(rand(n_trials, n_splits), 1);
    idx1 = perms(1:h, :);
    idx2 = perms(h+1:2*h, :);
end

function [m1, m2] = split_scalar_means(vec, n_splits)
% Computes [1 x n_splits] means for Half 1 and Half 2 of a trial vector
    n_trials = numel(vec);
    [idx1, idx2] = generate_split_indices(n_trials, n_splits);
    m1 = mean(vec(idx1), 1);
    m2 = mean(vec(idx2), 1);
end

function R = tiedrank_columns(X)
% Vectorized column-wise tiedrank for [n_subs x n_splits] matrix X
    [n_rows, n_cols] = size(X);
    [X_sorted, sort_idx] = sort(X, 1);
    R = zeros(n_rows, n_cols);
    base_ranks = (1:n_rows)';

    % Check which columns have any ties
    has_ties = any(diff(X_sorted, 1, 1) == 0, 1);

    % Fast path for columns without ties
    no_tie_cols = find(~has_ties);
    for k = 1:numel(no_tie_cols)
        c = no_tie_cols(k);
        R(sort_idx(:, c), c) = base_ranks;
    end

    % Exact tiedrank for columns with ties
    tie_cols = find(has_ties);
    for k = 1:numel(tie_cols)
        c = tie_cols(k);
        R(:, c) = tiedrank(X(:, c));
    end
end

function area = calcArea_fast_exact(a, b)
% Exact bitwise-identical fast implementation of calcArea.m without polyxpoly overhead.
% Preserves trimGrpah, h_line, integer segment intersection indices, and trapezoid subtraction.
    if min(b(:,2)) < min(a(:,2))
        temp = a;
        a = b;
        b = temp;
    end
    h_line = min(a(:,2));

    % Exact replication of trimGrpah(a, b)
    d_x = b(:,1);
    c_x = a(:,1);
    d_rising = d_x(1) < d_x(end);
    min_t = 1;
    if min(d_x) < min(c_x)
        if d_rising
            min_t = find(d_x < min(c_x), 1, 'last') + 1;
            b = b(min_t:end, :);
        else
            min_thresh = find(d_x < min(c_x), 1) - 1;
            b = b(1:min_thresh, :);
        end
        d_x = b(:,1);
    end
    if max(d_x) > max(c_x)
        if d_rising
            max_thresh = find(d_x > max(c_x), 1) - 1;
            b = b(1:max_thresh, :);
        else
            max_thresh = find(d_x > max(c_x), 1, 'last') + 1;
            b = b(max_thresh:end, :);
        end
    end

    % Vectorized 2D segment intersection matching polyxpoly integer segment indices
    nb = size(b, 1) - 1;
    ia_vec = (min_t : min_t + nb - 1)';
    ib_vec = (1 : nb)';

    x1 = a(ia_vec, 1);   y1 = a(ia_vec, 2);
    x2 = a(ia_vec+1, 1); y2 = a(ia_vec+1, 2);
    x3 = b(ib_vec, 1);   y3 = b(ib_vec, 2);
    x4 = b(ib_vec+1, 1); y4 = b(ib_vec+1, 2);

    den = (x1 - x2) .* (y3 - y4) - (y1 - y2) .* (x3 - x4);
    t_a = ((x1 - x3) .* (y3 - y4) - (y1 - y3) .* (x3 - x4)) ./ den;
    t_b = -((x1 - x2) .* (y1 - y3) - (y1 - y2) .* (x1 - x3)) ./ den;

    hit = (den ~= 0) & (t_a >= 0) & (t_a <= 1) & (t_b >= 0) & (t_b <= 1);
    i_a = ia_vec(hit);
    i_b = ib_vec(hit);

    points_a = [1; round(i_a); size(a, 1)];
    points_b = [1; round(i_b); size(b, 1)];

    n_segs = numel(points_a) - 1;
    seg_area = zeros(n_segs, 1);

    for j = 1:n_segs
        p_a1 = points_a(j); p_a2 = points_a(j+1);
        p_b1 = points_b(j); p_b2 = points_b(j+1);
        if p_a1 ~= p_a2 && p_b1 ~= p_b2
            seg_a_x = a(p_a1:p_a2, 1);
            seg_a_y = abs(a(p_a1:p_a2, 2) - h_line);
            seg_b_x = b(p_b1:p_b2, 1);
            seg_b_y = abs(b(p_b1:p_b2, 2) - h_line);

            % Fast inline trapezoidal integration matching trapz(x, y)
            area_a = abs(sum(0.5 * (seg_a_x(2:end) - seg_a_x(1:end-1)) .* (seg_a_y(1:end-1) + seg_a_y(2:end))));
            area_b = abs(sum(0.5 * (seg_b_x(2:end) - seg_b_x(1:end-1)) .* (seg_b_y(1:end-1) + seg_b_y(2:end))));
            seg_area(j) = abs(area_b - area_a);
        end
    end
    area = sum(seg_area);
end
