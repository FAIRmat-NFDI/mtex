clear;
clc;
% proj_vector = [vector3d.X, vector3d.Y, vector3d.Z];
% proj_name = ['x', 'y', 'z'];
point_groups = { ...
    '1', '-1', ...
    '2', 'm', '2/m', '222', 'mm2', 'mmm', ...
    '4', '-4', '4/m', '422', '4mm', '-42m', '4/mmm', ...
    '3', '-3', '32', '3m', '-3m', ...
    '6', '-6', '6/m', '622', '6mm', '-6m2', '6/mmm', ...
    '23', 'm-3', '432', '-43m', 'm-3m' };
ipf_legend_dict = containers.Map();
for cs = 1:1:length(point_groups)
    pg = point_groups{cs};
    disp(pg);
    for proj_idx = 1:1:1 % 3      
        ipf_key = ipfColorKey(crystalSymmetry(pg));
        % ipf_key.CS1.mineral = point_groups{cs};
        % ipf_key.CS2 = specimenSymmetry('1');
        % ipf_key.inversePoleFigureDirection = proj_vector(proj_idx);
        
        %% add specific IPF color key used
        % grpnm = [parent '/phase' num2str(phase_id) '/ipf' num2str(proj_idx) '/legend'];
        % attr = io_attributes();
        % attr.add('NX_class', 'NXdata');
        % attr.add('signal', 'data');
        % attr.add('axes', {'axis_y', 'axis_x'});
        % attr.add('axis_y_indices', uint32(1));
        % attr.add('axis_x_indices', uint32(0));
        % ret = h5w.nexus_write_group(grpnm, attr);
        % attr = io_attributes();
        % dsnm = [grpnm '/title'];
        % ret = h5w.nexus_write(dsnm, ['IPF ' upper(proj_name(proj_idx)) ' color key with SST'], attr);
        
        figure('visible','off');
        plot(ipf_key);
        if cs < 10
            prefix = '0';
        else
            prefix = '';
        end
        png_fnm = ['temporary_' prefix num2str(cs) '.png'];  % '_' num2str(proj_idx) '.png'];
        exportgraphics(gcf, png_fnm, 'Resolution', 300);
        close all hidden;
        % ... framegrab this image to get the pixel color values (no alpha)
        im = imread(png_fnm);
        % delete(png_fnm);
        % remove the intermediately created figure
        % dsnm = [grpnm '/data'];
        sz = size(im);
        low_level = uint8(zeros(fliplr(sz)));
        for x = 1:sz(2)
            for y = 1:sz(1)
                idx = y + (x - 1) * sz(1);
                low_level(:, x, y) = im(y, x, :);
            end
        end
        ipf_legend_dict(pg) = low_level;
        clearvars -except point_groups cs ipf_legend_dict;
        % attr = io_attributes();
        % attr.add('long_name', 'Signal');
        % attr.add('CLASS', 'IMAGE');
        % attr.add('IMAGE_VERSION', '1.2');
        % attr.add('SUBCLASS_VERSION', uint32(15));
        % ret = h5w.nexus_write(dsnm, low_level, attr);
        % sz = size(im);
        % dsnm = [grpnm '/axis_y'];
        % nxs_px_y = uint32(linspace(1, sz(1), sz(1)));
        % attr = io_attributes();
        % attr.add('long_name', 'Pixel along y-axis');
        % ret = h5w.nexus_write(dsnm, nxs_px_y, attr);
        % dsnm = [grpnm '/axis_x'];
        % nxs_px_x = uint32(linspace(1, sz(2), sz(2)));
        % attr = io_attributes();
        % attr.add('long_name', 'Pixel along x-axis');
        % ret = h5w.nexus_write(dsnm, nxs_px_x, attr);
    end
end
clearvars cs;

% a = ipfColorKey();
% plot(a)
% tmp = getframe(gcf);
% b = tmp.cdata();
% close all force;
