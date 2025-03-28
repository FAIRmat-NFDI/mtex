function out = squarify_map(inp, varargin)
% process what you want for the ebsd map
% based on dev/422df7152c35fe3dd5629aa6812c9da7668a3c03 the squarify function was modified

%inp = ebsd_raw;
nlimit = get_option(varargin,'h5web_max_size');
% disp(['H5Web maximum image size ' num2str(nlimit)]);

scan_unit = 'n/a';
if strcmp(inp.scanUnit, 'um')
    scan_unit = 'µm'; 
else
    scan_unit = lower(inp.scanUnit);
end
% get roi extent assuming x and y are scan point center positions 
% individually exact details depend on the flight plan of the scan box
% from the microscope
xmin = min(inp.pos.x);
xmax = max(inp.pos.x);
ymin = min(inp.pos.y);
ymax = max(inp.pos.y);

% sz = size(inp.unitCell);
% sz(1) == 4 for square grid and sz(1) == 6 for (flat-top?) hexagon grid
dx0 = abs(median(diff(unique(inp.pos.x, 'stable'))));
dy0 = abs(median(diff(unique(inp.pos.y, 'stable'))));  

% estimate resulting size of the grid when staying close to original uc
nx0 = ceil((xmax - xmin) / dx0);
ny0 = ceil((ymax - ymin) / dy0);
% ##MK::TODO x and y have no meaning

% H5Web has a maximum edge number in pixel along for each image axis for
% the contrast image of the ROI we use a heatmap which has a larger limit
% do not upscale smaller maps but scale down larger maps
scaler = 1.;
if nx0 > nlimit || ny0 > nlimit
    if nx0 > ny0
        scaler = nlimit / nx0;
    else
        scaler = nlimit / ny0;
    end
end
disp(['H5Web default plot generation, scaling ' num2str(scaler) ', nx0 ' num2str(nx0) ', ny0 ' num2str(ny0) ', nlimit ' num2str(nlimit)]);

% decide the rediscretization grid
hx = 0.5 * (dx0 / scaler);
hy = 0.5 * (dy0 / scaler);
nx = 1 + round(nx0 * scaler);
ny = 1 + round(ny0 * scaler);

% generate interpolation grid
[x, y] = meshgrid( ...
    linspace(xmin, xmax, nx), ...
    linspace(ymin, ymax, ny));

kdtree = KDTreeSearcher([inp.pos.x, inp.pos.y]);
closest_scan_point_id = knnsearch(kdtree, [x(:), y(:)]);
np = length(closest_scan_point_id);
clearvars kdtree;

out = EBSDsquare();
out.id = reshape(linspace(1, np, np)', fliplr([nx, ny]));
out.rotations = reshape(inp(closest_scan_point_id).rotations, fliplr([nx, ny]));
out.scanUnit = scan_unit;
out.unitCell = [+hx, +hy; -hx, +hx; -hx, -hy; +hx, -hy];
out.phaseId = inp(closest_scan_point_id).phaseId;
out.CSList = inp.CSList;
out.phaseMap = inp.phaseMap;
out.phase = reshape(inp(closest_scan_point_id).phase, fliplr([nx, ny]));
for descriptor = {'bc', 'ci', 'confidenceindex', 'mad'}
    if isfield(inp.prop, char(descriptor))
        tmp = inp(closest_scan_point_id).getProp(char(descriptor));
        disp(descriptor)
        disp(size(tmp));
        clearvars tmp;
        break;
    end
end
out.x = x;
out.y = y;
% no z 2D-case for now

end