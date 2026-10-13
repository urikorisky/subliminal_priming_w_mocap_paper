function [updatedStatsTables,treeFig_handle] = Calc_and_plot_TreeBH(statsTables)
    
    updatedStatsTables = statsTables;
    % plt_p.alpha_size = .05;

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


    keyboard_rt_raw_p_val = statsTables.analyzed_stats_tables.pVal(statsTables.analyzed_stats_tables.name == 'Keyboard RT' & statsTables.analyzed_stats_tables.Within_Participant_Standardization == false);
    keyboard_rt_zScored_p_val = statsTables.analyzed_stats_tables.pVal(statsTables.analyzed_stats_tables.name == 'Keyboard RT' & statsTables.analyzed_stats_tables.Within_Participant_Standardization == true);
    react_p_val = statsTables.analyzed_stats_tables.pVal(statsTables.analyzed_stats_tables.name == 'Reaching Onset');
    mt_p_val = statsTables.analyzed_stats_tables.pVal(statsTables.analyzed_stats_tables.name == 'Reaching Duration');
    com_p_val = statsTables.analyzed_stats_tables.pVal(statsTables.analyzed_stats_tables.name == "Num of COM");
    tot_dist_p_val = statsTables.analyzed_stats_tables.pVal(statsTables.analyzed_stats_tables.name == "Total Distance Traveled");
    if ismember('Flavor', statsTables.fullTrajAnalysis.Properties.VariableNames)
        dev_p = statsTables.fullTrajAnalysis.p_val(statsTables.fullTrajAnalysis.name == "Deviation From center" & statsTables.fullTrajAnalysis.Flavor == "noTrajNorm_noStandardization");
        iep_p = statsTables.fullTrajAnalysis.p_val(statsTables.fullTrajAnalysis.name == "iEP" & statsTables.fullTrajAnalysis.Flavor == "noTrajNorm_noStandardization");
        head_p = statsTables.fullTrajAnalysis.p_val(statsTables.fullTrajAnalysis.name == "Heading angle" & statsTables.fullTrajAnalysis.Flavor == "noTrajNorm_noStandardization");
    else
        dev_p = statsTables.fullTrajAnalysis.p_val(statsTables.fullTrajAnalysis.name == "Deviation From center");
        iep_p = statsTables.fullTrajAnalysis.p_val(statsTables.fullTrajAnalysis.name == "iEP");
        head_p = statsTables.fullTrajAnalysis.p_val(statsTables.fullTrajAnalysis.name == "Heading angle");
    end
    devFromCent_clust1_p_val = dev_p(1);
    iEP_clust1_p_val = iep_p(1);
    headingAngle_clust1_p_val = head_p(1);
    ra_p_val = statsTables.analyzed_stats_tables.pVal(statsTables.analyzed_stats_tables.name == "Reach Area");
    mad_p_val = statsTables.analyzed_stats_tables.pVal(statsTables.analyzed_stats_tables.name == "Maximum Absolute Deviation (MAD)");

    node_p_values = [nan,...
        nan, nan,...
        nan, nan, nan...
        nan, nan,...
        keyboard_rt_raw_p_val, keyboard_rt_zScored_p_val,...
        react_p_val, mt_p_val, com_p_val, tot_dist_p_val,...
        devFromCent_clust1_p_val, iEP_clust1_p_val, headingAngle_clust1_p_val,...
        ra_p_val,mad_p_val];

    % Create a a tree.
    g = createtree(parents_vec, node_names, node_p_values);
    
    % Run Tree-BH.
    plot_tree = 1; % plot it or not it.
    interactive_plot = 0;
    recalculate_p = 1;
    alpha_size = 0.05;
    [g_output, treeFig_handle] = treeBH(g, plot_tree, interactive_plot, recalculate_p, alpha_size);

    % Print results to terminal.
    disp('@@@@--------Tree-BH Correction--------@@@@')
    g_output.Nodes.name = string(g_output.Nodes.name);
    disp(g_output.Nodes(:, {'name','p','corr_p'}));

    % update results in relevant stats tables, under "TreeBH-corrected
    % p-value":
    newColName = 'p_Val_TreeBH_Corrected';
    updatedStatsTables.analyzed_stats_tables(find(statsTables.analyzed_stats_tables.name == 'Keyboard RT' & statsTables.analyzed_stats_tables.Within_Participant_Standardization == false),newColName) = g_output.Nodes(9,'corr_p');
    updatedStatsTables.analyzed_stats_tables(find(statsTables.analyzed_stats_tables.name == 'Keyboard RT' & statsTables.analyzed_stats_tables.Within_Participant_Standardization == true),newColName) = g_output.Nodes(10,'corr_p');
    updatedStatsTables.analyzed_stats_tables(find(statsTables.analyzed_stats_tables.name == 'Reaching Onset'),newColName) = g_output.Nodes(11,'corr_p');
    updatedStatsTables.analyzed_stats_tables(find(statsTables.analyzed_stats_tables.name == 'Reaching Duration'),newColName) = g_output.Nodes(12,'corr_p');
    updatedStatsTables.analyzed_stats_tables(find(statsTables.analyzed_stats_tables.name == "Num of COM"),newColName) = g_output.Nodes(13,'corr_p');
    updatedStatsTables.analyzed_stats_tables(find(statsTables.analyzed_stats_tables.name == "Total Distance Traveled"),newColName) = g_output.Nodes(14,'corr_p');
    if ismember('Flavor', statsTables.fullTrajAnalysis.Properties.VariableNames)
        idx_dev = find(statsTables.fullTrajAnalysis.name == "Deviation From center" & statsTables.fullTrajAnalysis.Flavor == "noTrajNorm_noStandardization");
        idx_iep = find(statsTables.fullTrajAnalysis.name == "iEP" & statsTables.fullTrajAnalysis.Flavor == "noTrajNorm_noStandardization");
        idx_head = find(statsTables.fullTrajAnalysis.name == "Heading angle" & statsTables.fullTrajAnalysis.Flavor == "noTrajNorm_noStandardization");
    else
        idx_dev = find(statsTables.fullTrajAnalysis.name == "Deviation From center");
        idx_iep = find(statsTables.fullTrajAnalysis.name == "iEP");
        idx_head = find(statsTables.fullTrajAnalysis.name == "Heading angle");
    end
    updatedStatsTables.fullTrajAnalysis(idx_dev, newColName) = g_output.Nodes(15,'corr_p');
    updatedStatsTables.fullTrajAnalysis(idx_iep, newColName) = g_output.Nodes(16,'corr_p');
    updatedStatsTables.fullTrajAnalysis(idx_head, newColName) = g_output.Nodes(17,'corr_p');
    updatedStatsTables.analyzed_stats_tables(find(statsTables.analyzed_stats_tables.name == "Reach Area"),newColName) = g_output.Nodes(18,'corr_p');
    updatedStatsTables.analyzed_stats_tables(find(statsTables.analyzed_stats_tables.name == "Maximum Absolute Deviation (MAD)"),newColName) = g_output.Nodes(19,'corr_p');

end