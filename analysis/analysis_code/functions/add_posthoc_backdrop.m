function ax_bg = add_posthoc_backdrop(ax, pad_norm)
% ADD_POSTHOC_BACKDROP Places a light-yellow background frame behind a plot axes.
%   The plot axes itself stays opaque white inside its frame while labels, ticks,
%   axis labels, and title around the plot sit on the light-yellow backdrop.
%   pad_norm = [pad_left, pad_bottom, pad_right, pad_top] in normalized figure units.

    if nargin < 2 || numel(pad_norm) ~= 4
        pad_norm = [0.048, 0.034, 0.010, 0.042];
    end

    ax = ax(:);
    ax = ax(isgraphics(ax, 'axes'));
    if isempty(ax)
        ax_bg = gobjects(0);
        return;
    end

    fig_h = ancestor(ax(1), 'figure');
    x0 = inf; y0 = inf; x1 = -inf; y1 = -inf;
    for ii = 1:numel(ax)
        orig_units = ax(ii).Units;
        ax(ii).Units = 'normalized';
        pos_i = ax(ii).Position;
        ax(ii).Units = orig_units;
        x0 = min(x0, pos_i(1));
        y0 = min(y0, pos_i(2));
        x1 = max(x1, pos_i(1) + pos_i(3));
        y1 = max(y1, pos_i(2) + pos_i(4));
    end

    bg_x = max(0.002, x0 - pad_norm(1));
    bg_y = max(0.002, y0 - pad_norm(2));
    bg_w = min(0.998 - bg_x, (x1 + pad_norm(3)) - bg_x);
    bg_h = min(0.998 - bg_y, (y1 + pad_norm(4)) - bg_y);

    ax_bg = axes('Parent', fig_h, 'Units', 'normalized', 'Position', [bg_x, bg_y, bg_w, bg_h], ...
        'XLim', [0, 1], 'YLim', [0, 1], 'Color', 'none', ...
        'HitTest', 'off', 'PickableParts', 'none', 'HandleVisibility', 'off');
    patch(ax_bg, [0, 1, 1, 0], [0, 0, 1, 1], [1.00, 0.985, 0.89], ...
        'EdgeColor', 'none', 'HandleVisibility', 'off');
    axis(ax_bg, 'off');

    % Ensure the light-yellow backdrop sits behind all data/label axes
    uistack(ax_bg, 'bottom');
end
