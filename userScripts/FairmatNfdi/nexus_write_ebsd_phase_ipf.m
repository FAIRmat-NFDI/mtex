function status = nexus_write_ebsd_phase_ipf(ebsd_orig, ebsd_grd, fpath, parent)
% Generate default inverse pole figure plot (for each phase) for H5Web and write data to NeXus/HDF5 file

% ebsd_orig, ebsd_grd
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

% as white is a valid color in typical IPF plots, black is used to mark
% pixels which were not indexed to belong to the phase in question
h5w = HdfFiveSeqHdl(fpath);

n_phases = length(ebsd_grd.CSList);
if n_phases ~= length(ebsd_grd.mineralList)
    status = logical(0);
    return;
end

grid = size(ebsd_grd);
scan_unit = 'n/a';
if isprop(ebsd_grd, 'scanUnit')
    if strcmp(ebsd_grd.scanUnit, 'um')
        scan_unit = 'µm'; 
    else
        scan_unit = lower(ebsd_grd.scanUnit);
    end
end

n_count_orig_indexed = 0;
n_count_orig_total = length(ebsd_orig);
% total number of scan points in the original mapping
% not the H5Web resized one!
dsnm = strcat(parent, '/number_of_scan_points');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint64(n_count_orig_total), attr);

phase_id = 0;
for phase_idx = 1:1:length(ebsd_grd.mineralList)
    % TODO: add a map for all those points not indexed
    
    grpnm = strcat(parent, ['/phase' num2str(phase_id)]);
    dsnm = strcat(grpnm, '/number_of_scan_points');
    % for some examples the phaseMap starts at -1 for the notIndex
    % how many scan points of that phase in original EBSD map
    if min(ebsd_orig.phaseMap) == -1
        n_count_orig = sum(sum(ebsd_orig.phase == (phase_id - 1)));
    elseif min(ebsd_orig.phaseMap) == 0 || min(ebsd_grd.phaseMap) == 1
        n_count_orig = sum(sum(ebsd_orig.phase == phase_id));
    else
        error('ERROR: The phaseMap for this EBSD map uses an unexpected indexing!');
    end
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, uint64(n_count_orig), attr);
    if ~strcmp(ebsd_orig.mineralList{phase_idx}, 'notIndexed')
        n_count_orig_indexed = n_count_orig_indexed + n_count_orig;
    end

    % how many scan points of that phase in eventually downsampled H5Web
    % preview of that IPF
    if min(ebsd_grd.phaseMap) == -1
        n_count = sum(sum(ebsd_grd.phase == (phase_id - 1)));
    elseif min(ebsd_grd.phaseMap) == 0 || min(ebsd_grd.phaseMap) == 1
        n_count = sum(sum(ebsd_grd.phase == phase_id));
    else
        error('ERROR: The phaseMap for this EBSD map uses an unexpected indexing!');
    end

    if ~strcmp(ebsd_grd.mineralList{phase_idx}, 'notIndexed') & n_count > 0
        % the null-phase, for MTex @EBSD.phase == 0 but confusingly @EBSD.phaseId == 1 !
        proj_vector = [vector3d.X, vector3d.Y, vector3d.Z];
        proj_name = ['x', 'y', 'z'];
        phase_name = ebsd_grd.mineralList{phase_idx};
        disp(['nexus_write_ebsd_ipf ' num2str(phase_idx) '/' num2str(length(ebsd_grd.mineralList)) ' ' phase_name ' phase_id ' num2str(phase_id)]);
        for proj_idx = 1:1:3
            clearvars ipf_key colors nx_ipf_map_u8_f nxs_ipf_y nxs_ipf_x phase_i_idx v low_level idx;
            % ipf_hsv_key = ipfHSVKey(ebsd_grd(phase_name));
            if min(ebsd_grd.phaseMap) == -1
                ipf_key = ipfColorKey(ebsd_grd(ebsd_grd.phase == (phase_id - 1)));
            else
                ipf_key = ipfColorKey(ebsd_grd(ebsd_grd.phase == phase_id));
            end
            ipf_key.inversePoleFigureDirection = proj_vector(proj_idx);
            colors = ipf_key.orientation2color(ebsd_grd(phase_name).orientations);
            % from normalized colors to RGB colors
            colors = uint8(uint32(colors * 255.));
            % base color black
            nxs_ipf_map_u8_f = uint8(uint32(zeros([3, grid(1) * grid(2)]) * 255.));
            nxs_ipf_y = ebsd_grd.prop.y(:, 1)';
            nxs_ipf_x = ebsd_grd.prop.x(1, :);

            % get array indices of all those pixels which were indexed as phase phase_idx
            if min(ebsd_grd.phaseMap) == -1
                phase_i_idx = uint32(ebsd_grd.id(ebsd_grd.phase == (phase_id - 1)));
            else
                phase_i_idx = uint32(ebsd_grd.id(ebsd_grd.phase == phase_id));
            end
            nxs_ipf_map_u8_f(:, phase_i_idx) = colors(1:length(phase_i_idx), :)';  

            grpnm = strcat(parent, ['/phase' num2str(phase_id) ...
                '/ipf' num2str(proj_idx)]);  % lower(proj_name(proj_idx))]);
            attr = io_attributes();
            attr.add('NX_class', 'NXms_ipf');
            attr.add('depends_on', ['phase' num2str(phase_id)]);
            ret = h5w.nexus_write_group(grpnm, attr);

            dsnm = strcat(grpnm, '/projection_direction');
            attr = io_attributes();
            v = proj_vector(proj_idx);
            ret = h5w.nexus_write(dsnm, single([v.x v.y v.z]), attr);
            
            % dsnm = strcat(grpnm, '/bitdepth');
            % ret = h5w.nexus_write(dsnm, uint32(8), attr);
            % read from mtex_pref instead
            % dsnm = strcat(grpnm, '/program');
            % attr = io_attributes();
            % attr.add('version', ['Matlab: ', version ', MTex: 5.8.2']);
            % ret = h5w.nexus_write(dsnm, 'mtex', attr);

            grpnm =  strcat(parent, ['/phase' num2str(phase_id) ...
                '/ipf' num2str(proj_idx) '/map']);
            attr = io_attributes();
            attr.add('NX_class', 'NXdata');
            attr.add('signal', 'data');
            attr.add('axes', {'axis_y', 'axis_x'});
            attr.add('axis_y_indices', uint32(1));
            attr.add('axis_x_indices', uint32(0));
            ret = h5w.nexus_write_group(grpnm, attr);

            dsnm = strcat(grpnm, '/title');
            ret = h5w.nexus_write(dsnm, ['Inverse pole figure ' ...
                upper(proj_name(proj_idx)) ' ' phase_name], attr);

            dsnm = strcat(grpnm, '/data');
            low_level = uint8(uint32(zeros([3 grid(2) grid(1)])));
            %fliplr(size(nxs_ipf_map_u8_f))));
            for x = 1:1:grid(2)
                for y = 1:1:grid(1)
                    idx = y + (x - 1) * grid(1);
                    low_level(:, x, y) = nxs_ipf_map_u8_f(:, idx);
                end
            end
            attr = io_attributes();
            attr.add('long_name', 'IPF color-coded orientation mapping');
            attr.add('CLASS', 'IMAGE');
            attr.add('IMAGE_VERSION', '1.2');
            attr.add('SUBCLASS_VERSION', uint32(15));
            ret = h5w.nexus_write(dsnm, low_level, attr);

            dsnm = strcat(grpnm, '/axis_y');
            attr = io_attributes();
            attr.add('units', scan_unit);
            attr.add('long_name', ['Calibrated coordinate along y-axis (' scan_unit ')']);
            ret = h5w.nexus_write(dsnm, nxs_ipf_y, attr);
            dsnm = strcat(grpnm, '/axis_x');
            attr = io_attributes();
            attr.add('units', scan_unit);
            attr.add('long_name', ['Calibrated coordinate along x-axis (' scan_unit ')']);
            ret = h5w.nexus_write(dsnm, nxs_ipf_x, attr);

            %% add specific IPF color key used
            grpnm = strcat(parent, ['/phase' num2str(phase_id) ...
                '/ipf' num2str(proj_idx) '/legend']);
            attr = io_attributes();
            attr.add('NX_class', 'NXdata');
            attr.add('signal', 'data');
            attr.add('axes', {'axis_y', 'axis_x'});
            attr.add('axis_y_indices', uint32(1));
            attr.add('axis_x_indices', uint32(0));
            ret = h5w.nexus_write_group(grpnm, attr);
            attr = io_attributes();

            dsnm = strcat(grpnm, '/title');
            ret = h5w.nexus_write(dsnm, ['IPF ' upper(proj_name(proj_idx)) ' color key with SST'], attr);
            figure('visible','off');
            plot(ipf_key);
            % f = gcf;
            png_fnm = ['temporary.png'];
            exportgraphics(gcf, png_fnm, 'Resolution', 300);
            close gcf
            % ... framegrab this image to get the pixel color values (no alpha)
            im = imread(png_fnm);
            delete(png_fnm); % remove the intermediately created figure
            % better would be to use the image directly as a matrix
            % or make a color fingerprint, i.e. defined orientation set pump
            % through color code and then rendered as n_orientations x 3 RGB
            % array this could also be used nicely for machine learning
    
            dsnm = strcat(grpnm, '/data');
            sz = size(im);
            low_level = uint8(zeros(fliplr(sz)));
            for x = 1:sz(2)
                for y = 1:sz(1)
                    idx = y + (x - 1) * sz(1);
                    low_level(:, x, y) = im(y, x, :);
                end
            end
            attr = io_attributes();
            attr.add('long_name', 'Signal');
            attr.add('CLASS', 'IMAGE');
            attr.add('IMAGE_VERSION', '1.2');
            attr.add('SUBCLASS_VERSION', uint32(15));
            ret = h5w.nexus_write(dsnm, low_level, attr);
            sz = size(im);
            dsnm = strcat(grpnm, '/axis_y');
            nxs_px_y = uint32(linspace(1, sz(1), sz(1)));
            attr = io_attributes();
            attr.add('long_name', 'Pixel along y-axis');
            ret = h5w.nexus_write(dsnm, nxs_px_y, attr);
            dsnm = strcat(grpnm, '/axis_x');
            nxs_px_x = uint32(linspace(1, sz(2), sz(2)));
            attr = io_attributes();
            attr.add('long_name', 'Pixel along x-axis');
            ret = h5w.nexus_write(dsnm, nxs_px_x, attr);
        end
    end

    phase_id = phase_id + 1;
end

dsnm = strcat(parent, '/indexing_rate');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, ...
    double(double(n_count_orig_indexed) / ...
    double(n_count_orig_total)), attr);

disp('NeXus/HDF5 exporting of phase-specific inverse pole figures was successful');
status = logical(1);

end
