function [] = plotTreeBH_hardCodedValues_URI_ver02_PreRegDesc(plt_p, p)
    
    plt_p.alpha_size = .05;

    % Specify tree structure.
    parents_vec = [1, 1,...
        2, 2, 2, 3, 3,...
        7,8,...
        5, 5, 5, 5,...
        5, 6,...
        5, ...
        4, 4];
    node_names = [{'Manuscript'},...
        {'Reaching', 'Keyboard'},...
        {'Pre-Registered Confirmatory', 'Pre-Registered Exploratory', 'Non Pre-Registered Exploratory'},... %reaching, 4,5,6
        {'Pre-Registered Confirmatory', 'Pre-Registered Exploratory'},... % KB, 7,8
        {'RT(raw)','RT(z-scored)'},... %KB measures
        {'Reaction time', 'Movement time', 'COM', 'Traveled distance',...
        'Deviation from center (1 cluster)','Implied endpoint (1 cluster)',...
        'Heading angle (1 cluster)'},... %reaching - exploratory
        {'Reach Area','MAD(raw)'}]; %reaching - confirmatory

    % Add p-values to tree.
    exp4.keyboard_rt_raw_p_val = 4.9674e-07;
    exp4.keyboard_rt_zScored_p_val = 4.0862e-07;
    exp4.react_p_val = 0.1649;
    exp4.mt_p_val = 1.5469e-07;
    exp4.com_p_val = 0.0187;
    exp4.tot_dist_p_val = 4.1039e-05;
    exp4.ra_p_val = 0.00076927;
    exp4.mad_p_val = 7.432600848551920e-06;
    exp4.devFromCent_clust1_p_val = 0.035599;
    exp4.iEP_clust1_p_val = 0.00047354;
    exp4.headingAngle_clust1_p_val = 0.0011701;
    
    

    node_p_values = [nan,...
        nan, nan,...
        nan, nan, nan...
        nan, nan,...
        exp4.keyboard_rt_raw_p_val, exp4.keyboard_rt_zScored_p_val,...
        exp4.react_p_val, exp4.mt_p_val, exp4.com_p_val, exp4.tot_dist_p_val,...
        exp4.devFromCent_clust1_p_val, exp4.iEP_clust1_p_val, exp4.headingAngle_clust1_p_val,...
        exp4.ra_p_val,exp4.mad_p_val];

    % Create a a tree.
    g = createtree(parents_vec, node_names, node_p_values);
    
    % Run Tree-BH.
    plot_tree = 1; % plot it or not it.
    interactive_plot = 1;
    recalculate_p = 0;
    [g_output, g_plot_handle] = treeBH(g, plot_tree, interactive_plot, recalculate_p, plt_p.alpha_size);

    % Print results to terminal.
    disp('@@@@--------Tree-BH Correction--------@@@@')
    g_output.Nodes.name = string(g_output.Nodes.name);
    disp(g_output.Nodes(:, {'name','p','corr_p'}));
end