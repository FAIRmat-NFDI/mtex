function out = squarify_map(inp, varargin)
% process what you want for the ebsd map
% based on dev/422df7152c35fe3dd5629aa6812c9da7668a3c03 the squarify function was modified

%inp = ebsd_raw;
nlimit = get_option(varargin,'h5web_max_size');
% disp(['H5Web maximum image size ' num2str(nlimit)]);

scan_unit = 'n/a';
if isprop(inp, 'scanUnit')
    if strcmp(inp.scanUnit, 'um')
        scan_unit = 'µm'; 
    else
        scan_unit = lower(inp.scanUnit);
    end
end
% get roi extent
xmin = min(inp.prop.x);
xmax = max(inp.prop.x);
ymin = min(inp.prop.y);
ymax = max(inp.prop.y);

% get unit cell (uc) size
dx0 = max(inp.unitCell(:,1)) - min(inp.unitCell(:,1));
dy0 = max(inp.unitCell(:,2)) - min(inp.unitCell(:,2));

% estimate resulting size of the grid when staying close to original uc
nx0 = ceil((xmax - xmin) / dx0);
ny0 = ceil((ymax - ymin) / dy0);
% ##MK::TODO x and y have no meaning SUGGESTION: define where x and y is defined

% H5Web has a maximum edge number in pixel along for each image axis
% for the contrast image of the ROI we use a heatmap which has a larger
% limit
% nlimit = 200; % 2^32;  % dunno exactly for heatmaps but likely much smaller
% % do not upscale smaller maps but scale down larger maps
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
% xy = [x(:), y(:)]; % .';

% check that each support vertex of a triplePoint is just a copy of a
% vertex to the boundary network support vertices
kdtree = KDTreeSearcher([inp.prop.x, inp.prop.y]);
closest_scan_point_id = knnsearch(kdtree, [x(:), y(:)]);  %xy);
np = length(closest_scan_point_id);
clearvars kdtree;

out = EBSDsquare();
out.dx = 2. * hx;
out.dy = 2. * hy;
% out.xmin = xmin;
% out.xmax = xmax;
% out.ymin = ymin;
% out.ymax = ymax;
out.id = reshape(linspace(1, np, np)', fliplr([nx, ny]));
out.rotations = reshape(inp(closest_scan_point_id).rotations, fliplr([nx, ny]));
out.scanUnit = inp.scanUnit;
out.unitCell = [+hx, +hy; -hx, +hx; -hx, -hy; +hx, -hy];
out.phaseId = inp(closest_scan_point_id).phaseId;
out.CSList = inp.CSList;
out.phaseMap = inp.phaseMap;
out.phase = reshape(inp(closest_scan_point_id).phase, fliplr([nx, ny]));
% out.isIndexed = reshape(inp(closest_scan_point_id).isIndexed, fliplr([nx, ny]));
% out.mineralList = inp.mineralList;
% out.indexedPhasesId = inp.indexedPhasesId;
for fn = fieldnames(inp.prop).'
    if any(strcmp(char(fn), {'x','y','z'}))
        continue;
    end
    out.prop.(char(fn)) = reshape(inp( ...
        closest_scan_point_id).prop.(char(fn)), fliplr([nx, ny]));
end
out.prop.x = x;
out.prop.y = y;
out.prop.oldId = reshape(linspace(1, np, np), fliplr([nx, ny]));

% plot(out)

% a = EBSD()';
% a.id = linspace(1, np, np)';
% a.rotations = inp(closest_scan_point_id).rotations';
% a.scanUnit = scan_unit;
% a.unitCell = [+hx, +hy; -hx, +hx; -hx, -hy; +hx, -hy];
% % a.orientations;
% a.phaseId = inp(closest_scan_point_id).phaseId';
% a.CSList = inp.CSList;
% a.phaseMap = inp.phaseMap;
% a.phase = inp(closest_scan_point_id).phase;
% a.isIndexed = inp(closest_scan_point_id).isIndexed;
% a.mineralList = inp.mineralList;
% a.indexedPhasesId = inp.indexedPhasesId;
% for fn = fieldnames(inp.prop).'
%     if any(strcmp(char(fn), {'x','y','z'}))
%         continue;
%     end
%     a.prop.(char(fn)) = inp(closest_scan_point_id).prop.(char(fn));
% end

end