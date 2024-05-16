function status = nexus_write_ebsd_overview(ebsd_orig, fpath, parent)
% Generate default plot for H5Web and write data to NeXus/HDF5 file

% ebsd_obj
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

grid = size(ebsd_orig.phase);
scan_unit = 'n/a';
if isprop(ebsd_orig, 'scanUnit')
    if strcmp(ebsd_orig.scanUnit, 'um')
        scan_unit = 'µm'; 
    else
        scan_unit = lower(ebsd_orig.scanUnit);
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
if isfield(ebsd_orig.prop, 'bc')
    ret = h5w.nexus_write(dsnm, 'normalized_band_contrast', attr);
    which_descriptor = 'normalized_band_contrast';
elseif isfield(ebsd_orig.prop, 'ci') || isfield(ebsd_orig.prop, 'confidenceindex')
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
        ebsd_orig.prop.bc / ...
        max(max(ebsd_orig.prop.bc)) * 255.));
elseif strcmp(which_descriptor, 'normalized_confidence_index')
    if isfield(ebsd_orig.prop, 'ci')
        nxs_roi_map_u8_f = uint8(uint32( ...
            ebsd_orig.prop.ci / ...
            max(max(ebsd_orig.prop.ci)) * 255.));
    else
        nxs_roi_map_u8_f = uint8(uint32( ...
            ebsd_orig.prop.confidenceindex / ...
            max(max(ebsd_orig.prop.confidenceindex)) * 255.));
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
nxs_bc_y = linspace(ebsd_orig.ymin, ebsd_orig.ymax, grid(1));
attr = io_attributes();
attr.add('units', scan_unit);  % TODO, convenience if larger than 1.0e or smaller than 1.e-3 auto-convert
attr.add('long_name', ['Calibrated coordinate along y-axis (', scan_unit, ')']);
ret = h5w.nexus_write(dsnm, nxs_bc_y, attr);
dsnm = strcat(grpnm, '/axis_x');
nxs_bc_x = linspace(ebsd_orig.xmin, ebsd_orig.xmax, grid(2));
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