function status = nexus_write_ebsd_overview(ebsd_grd, fpath, parent)
% Generate default plot for H5Web and write data to NeXus/HDF5 file

% ebsd_obj
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

grid = size(ebsd_grd.phase);
scan_unit = 'n/a';
if isprop(ebsd_grd, 'scanUnit')
    if strcmp(ebsd_grd.scanUnit, 'um')
        scan_unit = 'µm'; 
    else
        scan_unit = lower(ebsd_grd.scanUnit);
    end
end

h5w = HdfFiveSeqHdl(fpath);

%% compute and add band-contrast overview image
grpnm = strcat(parent, '/roi');
attr = io_attributes();
attr.add('NX_class', 'NXdata');
attr.add('signal', 'data');
attr.add('axes', {'axis_y', 'axis_x'});
attr.add('axis_y_indices', uint32(1)); % int64 needed?
attr.add('axis_x_indices', uint32(0));
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/descriptor');
attr = io_attributes();
which_descriptor = 'undefined';
if isfield(ebsd_grd.prop, 'bc')
    ret = h5w.nexus_write(dsnm, 'normalized_band_contrast', attr);
    which_descriptor = 'normalized_band_contrast';
elseif isfield(ebsd_grd.prop, 'ci') || isfield(ebsd_grd.prop, 'confidenceindex')
    ret = h5w.nexus_write(dsnm, 'normalized_confidence_index', attr);
    which_descriptor = 'normalized_confidence_index';
else
    ret = h5w.nexus_write(dsnm, which_descriptor, attr);
end

dsnm = strcat(grpnm, '/data');
% compute the relevant image values ...
% the MTex-style implicit 2d arrays how they come and are used in @EBSD
if strcmp(which_descriptor, 'normalized_band_contrast')
    nxs_roi_map_u8_f = uint8(uint32( ...
        ebsd_grd.prop.bc / ...
        max(max(ebsd_grd.prop.bc)) * 255.));
elseif strcmp(which_descriptor, 'normalized_confidence_index')
    if isfield(ebsd_grd.prop, 'ci')
        nxs_roi_map_u8_f = uint8(uint32( ...
            ebsd_grd.prop.ci / ...
            max(max(ebsd_grd.prop.ci)) * 255.));
    else
        nxs_roi_map_u8_f = uint8(uint32( ...
            ebsd_grd.prop.confidenceindex / ...
            max(max(ebsd_grd.prop.confidenceindex)) * 255.));
    end
else
    error('Which descriptor for overview ROI must not be undefined!')
end
% this will map NaN on zero (i.e. black in a grayscale/RGB color map)
attr = io_attributes();
attr.add('long_name', 'Signal');
attr.add('CLASS', 'IMAGE');
attr.add('IMAGE_VERSION', '1.2');
attr.add('SUBCLASS_VERSION', uint32(15));
ret = h5w.nexus_write(dsnm, nxs_roi_map_u8_f', attr);

% ... and dimension scale axis positions
dsnm = strcat(grpnm, '/axis_y');
nxs_bc_y = ebsd_grd.prop.y(:, 1)';
attr = io_attributes();
attr.add('units', scan_unit);
attr.add('long_name', ['Calibrated coordinate along y-axis (', scan_unit, ')']);
ret = h5w.nexus_write(dsnm, nxs_bc_y, attr);
dsnm = strcat(grpnm, '/axis_x');
nxs_bc_x = ebsd_grd.prop.x(1, :);
attr = io_attributes();
attr.add('units', scan_unit);
attr.add('long_name', ['Calibrated coordinate along x-axis (', scan_unit, ')']);
ret = h5w.nexus_write(dsnm, nxs_bc_x, attr);
dsnm = strcat(grpnm, '/title');
if strcmp(which_descriptor, 'normalized_band_contrast')
    ret = h5w.nexus_write(dsnm, 'Region-of-interest normalized band contrast', attr);
elseif strcmp(which_descriptor, 'normalized_confidence_index')
    ret = h5w.nexus_write(dsnm, 'Region-of-interest normalized confidence index', attr);
else
    ret = h5w.nexus_write(dsnm, 'Region-of-interest', attr); 
end
disp('NeXus/HDF5 exporting of ROI overview image was successful');
status = logical(1);

end