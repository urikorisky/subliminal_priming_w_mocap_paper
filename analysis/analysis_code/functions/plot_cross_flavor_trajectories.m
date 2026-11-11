function [fig_handle] = plot_cross_flavor_trajectories(analysisPrms, save_dir)
% PLOT_CROSS_FLAVOR_TRAJECTORIES Generates a 2-row x 4-column comparison figure
% contrasting full-trajectory congruency dynamics and significant permutation clusters across:
%   - Top row: noTrajNorm_noStandardization (Chronological Time Domain, 0-340 ms; 4 features)
%   - Bottom row: TrajNorm_noStandardization / TrajNorm_Standardization (Spatial Path Domain, 0-100%; 3 features)

    load('../../experiment/RUN_ME/code/p.mat', 'p');
    p.SUBS = [47, 49:85, 87:90];
    p.ORIG_SUBS = p.SUBS;
    p.DAY = 'day2';
    traj_names = {{'target_x_to', 'target_y_to', 'target_z_to'}};

    % Shared plotting parameters matching Fig. 4
    plt_p = struct();
    plt_p.alpha_size = 0.05;
    plt_p.n_perm = 10000;
    plt_p.errbar_type = 'ci';
    plt_p.n_perm_clust_tests = 1;
    plt_p.avg_plot_width = 4;
    plt_p.space = 3;
    plt_p.f_alpha = 0.2;
    plt_p.linewidth = 3.2;
    plt_p.con_col = [0 0.35294 0.7098];
    plt_p.con_avg_col = 'b';
    plt_p.incon_col = [0.86275 0.19608 0.12549];
    plt_p.incon_avg_col = 'r';
    plt_p.axes_line_thickness = 1.8;
    plt_p.left_right_ticks = -10 : 5 : 10;
    plt_p.font_name = 'Calibri';
    plt_p.font_size = 13;
    plt_p.labels_font_size = 13;

    % Configure Flavor 3 (noTrajNorm) and Flavor 1/2 (TrajNorm) structs
    p_ntn = p;
    if analysisPrms.fromRawData
        p_ntn.PROC_DATA_FOLDER = analysisPrms.targetPreProcData_noTrajNorm_noStandardization_folder;
    else
        p_ntn.PROC_DATA_FOLDER = analysisPrms.readyPreProcData_noTrajNorm_noStandardization_folder;
    end
    p_ntn.NORMALIZE_WITHIN_SUB = 0;
    p_ntn.NORM_TRAJ = 0;
    p_ntn.MIN_SAMP_LEN = 0.34;
    p_ntn.MIN_TRIM_FRAMES = p_ntn.MIN_SAMP_LEN * p_ntn.REF_RATE_HZ;
    p_ntn = defineParams_within_round(p_ntn, p_ntn.SUBS(1));

    plt_ntn = plt_p;
    plt_ntn.x_as_func_of = "time";
    plt_ntn.time_ticks = 0 : 50 : 300;
    plt_ntn.percent_path_ticks = 0 : 20 : 100;

    p_tn = p;
    if analysisPrms.fromRawData
        p_tn.PROC_DATA_FOLDER = analysisPrms.targetPreProcData_TrajNorm_noStandardization_folder;
    else
        p_tn.PROC_DATA_FOLDER = analysisPrms.readyPreProcData_TrajNorm_noStandardization_folder;
    end
    p_tn.NORMALIZE_WITHIN_SUB = 0;
    p_tn.NORM_TRAJ = 1;
    p_tn.MIN_SAMP_LEN = 0.1;
    p_tn.MIN_TRIM_FRAMES = p_tn.MIN_SAMP_LEN * p_tn.REF_RATE_HZ;
    p_tn = defineParams_within_round(p_tn, p_tn.SUBS(1));

    plt_tn = plt_p;
    plt_tn.x_as_func_of = "zaxis";
    plt_tn.time_ticks = 0 : 50 : 300;
    plt_tn.percent_path_ticks = 0 : 20 : 100;

    fig_handle = figure('Name', 'Cross-Flavor Full-Trajectory Comparison', ...
        'Color', 'w', 'Position', [50, 50, 1650, 920]);

    tl = tiledlayout(fig_handle, 2, 4, 'TileSpacing', 'compact', 'Padding', 'loose');
    title(tl, 'Full-Trajectory Cluster Comparison Across Preprocessing Flavors', ...
        'FontSize', 16, 'FontWeight', 'bold', 'FontName', 'Calibri');
    subtitle(tl, 'Top Row: Time Domain (noTrajNorm_noStandardization, 0–340 ms)   |   Bottom Row: Spatial Path Domain (TrajNorm, 0–100% Path)', ...
        'FontSize', 12.5, 'FontName', 'Calibri', 'Interpreter', 'none');

    % --- Row 1: noTrajNorm_noStandardization (0-340 ms, 4 features) ---
    ax1 = nexttile(tl, 1);
    plotMultiAvgTrajWithShade(traj_names, plt_ntn, p_ntn, true);
    title(ax1, '(a) Deviation From Center (Time)', 'FontSize', 13);

    ax2 = nexttile(tl, 2);
    plotMultiIEP(traj_names, [], 0, plt_ntn, p_ntn);
    title(ax2, '(b) Implied End Point (Time)', 'FontSize', 13);

    ax3 = nexttile(tl, 3);
    plotMultiXStd(traj_names, plt_ntn, p_ntn);
    title(ax3, '(c) Movement Variation (Time)', 'FontSize', 13);

    ax4 = nexttile(tl, 4);
    plotMultiHeadAngle(traj_names, plt_ntn, p_ntn, 'xangle', true);
    title(ax4, '(d) Heading Angle (Time)', 'FontSize', 13);

    % --- Row 2: TrajNorm (0-100% Path Traveled, 3 valid features) ---
    ax5 = nexttile(tl, 5);
    plotMultiAvgTrajWithShade(traj_names, plt_tn, p_tn, true);
    title(ax5, '(e) Deviation From Center (% Path)', 'FontSize', 13);

    ax6 = nexttile(tl, 6);
    plotMultiIEP(traj_names, [], 0, plt_tn, p_tn);
    title(ax6, '(f) Implied End Point (% Path)', 'FontSize', 13);

    ax7 = nexttile(tl, 7);
    plotMultiXStd(traj_names, plt_tn, p_tn);
    title(ax7, '(g) Movement Variation (% Path)', 'FontSize', 13);

    % Tile 8: Explanatory annotation for Heading Angle exclusion under spatial resampling
    ax8 = nexttile(tl, 8);
    axis(ax8, 'off');
    text(ax8, 0.5, 0.5, ...
        {'Heading Angle', 'Not Analyzed in TrajNorm', '(Spatial B-spline resampling', 'distorts tangent angles)'}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 12, 'FontAngle', 'italic', 'Color', [0.45 0.45 0.45], 'FontName', 'Calibri');

    if nargin >= 2 && ~isempty(save_dir)
        if ~exist(save_dir, 'dir'), mkdir(save_dir); end
        base_out = fullfile(save_dir, 'Fig_Full_Trajectory_Flavor_Comparison');
        try, savefig(fig_handle, [base_out '.fig']); catch, end
        try
            exportgraphics(fig_handle, [base_out '.png'], 'Resolution', 300);
        catch
            saveas(fig_handle, [base_out '.png']);
        end
        try
            exportgraphics(fig_handle, [base_out '.svg'], 'ContentType', 'vector');
        catch
        end
    end
end
