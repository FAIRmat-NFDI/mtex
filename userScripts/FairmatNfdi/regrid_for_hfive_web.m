function out = regrid_for_hfive_web(inp)
% process what you want for the ebsd map

out = inp.squarify;
% based on dev/422df7152c35fe3dd5629aa6812c9da7668a3c03 the squarify function was modified

% scan_unit = 'n/a';
% if isfield(inp, 'scanUnit')
%     if strcmp(inp.scanUnit, 'um')
%         scan_unit = 'µm'; 
%     else
%         scan_unit = lower(inp.scanUnit);
%     end
% end
% out.scan_unit = scan_unit;
% return;

% disp('Interpolate EBSD data on square grid for creating NeXus default plots...');
% d_x_0 = max(inp.unitCell(:,1)) - min(inp.unitCell(:,1));
% d_y_0 = max(inp.unitCell(:,2)) - min(inp.unitCell(:,2));  %TODO read unit
% xmin = min(inp.prop.x);
% xmax = max(inp.prop.x);
% ymin = min(inp.prop.y);
% ymax = max(inp.prop.y);
% 
% 
% % estimate resulting size of the grid
% l_x_0 = xmax - xmin;
% l_y_0 = ymax - ymin;
% n_x_0 = ceil(l_x_0 / d_x_0);  %TODO x and y have no meaning SUGGESTION: define where x and y is defined
% n_y_0 = ceil(l_y_0 / d_y_0);
% 
% % based on this size eventually scale down the size of the image
% n_max = 2048;  % one pixel to either side padding
% % do not upscale smaller maps but scale larger maps to the longest side
% % matching n_max
% scaler = 1.;
% if n_x_0 > n_max || n_y_0 > n_max
%     if n_x_0 > n_y_0
%         scaler = n_max / n_x_0;
%     else
%         scaler = n_max / n_y_0;
%     end
% end
% 
% % define final details of the interpolation grid
% d_x = d_x_0 / scaler;
% d_y = d_y_0 / scaler;
% com_x = xmin + 0.5*(xmax - xmin);
% com_y = ymin + 0.5*(ymax - ymin);
% n_x = ceil(n_x_0 * scaler);
% n_y = ceil(n_y_0 * scaler);
% xmin = com_x - 0.5 * (n_x * d_x);
% xmax = com_x + 0.5 * (n_x * d_x);
% ymin = com_y - 0.5 * (n_y * d_y);
% ymax = com_y + 0.5 * (n_y * d_y);
% 
% % interpolate ebsd using this grid
% x = linspace(xmin, xmax, n_x);
% y = linspace(ymin, ymax, n_y);
% [x,y] = meshgrid(x,y);
% xy = [x(:), y(:)].';
% 
% out = interp(inp, xy(1,:), xy(2,:));
% out.prop.aabb = [xmin, xmax, ymin, ymax];
% out.prop.grid = [n_x, n_y];
% out.prop.scan_unit = scan_unit;
end