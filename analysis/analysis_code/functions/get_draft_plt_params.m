function plt_draft = get_draft_plt_params()
% GET_DRAFT_PLT_PARAMS Returns visual language parameters matching
% Heller_et_al_Rebuttal01_Ver01_UK.docx (colors, line widths, Calibri font, large typography).

    plt_draft = struct();
    plt_draft.con_col              = [0, 0.35294, 0.7098];     % Draft ocean blue (#005AB5)
    plt_draft.incon_col            = [0.86275, 0.19608, 0.12549]; % Draft vermilion red (#DC3220)
    plt_draft.con_avg_col          = [0, 0, 1];                 % Draft 'b' for single-subject avg
    plt_draft.incon_avg_col        = [1, 0, 0];                 % Draft 'r' for single-subject avg
    plt_draft.prereg_col           = [0.10, 0.52, 0.25];        % Forest green (Pre-registered)
    plt_draft.robust_col           = [0.05, 0.30, 0.12];        % Deep forest green (Robustness)
    plt_draft.temporal_col         = [0.46, 0.24, 0.68];        % Muted purple (Temporal Full-Trajectory)
    plt_draft.temporal_bg          = [0.94, 0.90, 0.98];        % Light purple band background
    plt_draft.nolong_col           = [0.76, 0.35, 0.05];        % Burnt orange (W/O Long Duration)
    plt_draft.f_alpha              = 0.22;
    plt_draft.alpha_size           = 0.05;
    plt_draft.linewidth            = 3.2;                       % Thick draft trajectory curves
    plt_draft.avg_plot_width       = 3.5;                       % Thick single-subject average curves
    plt_draft.axes_line_thickness  = 2.6;                       % Thick draft-style axes spines
    plt_draft.font_size            = 13.0;                      % Base tick/legend font size
    plt_draft.labels_font_size     = 14.5;                      % Axis labels font size
    plt_draft.title_font_size      = 16.0;                      % Panel title font size
    plt_draft.panel_letter_size    = 16.0;                      % Panel letter (a)-(m) font size
    plt_draft.font_name            = 'Calibri';
    plt_draft.errbar_type          = 'ci';
    plt_draft.space                = 1.2;
    plt_draft.n_perm               = 10000;
    plt_draft.n_perm_clust_tests   = 1000;
end
