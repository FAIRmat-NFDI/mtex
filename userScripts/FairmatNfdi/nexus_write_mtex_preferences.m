function status = nexus_write_mtex_preferences(fpath, parent)
% Export current MTex and Matlab settings to NeXus/HDF5 file

% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

    mtex_pref = getMTEXpref;

    h5w = HdfFiveSeqHdl(fpath);

    grpnm = strcat(parent, '/mtex');
    attr = io_attributes();
    attr.add('NX_class', 'NXms_mtex_config');
    ret = h5w.nexus_write_group(grpnm, attr);
    
    % resetting attr and use it until again an HDF5 node with
    % attributes is required
%% versions
    grpnm = strcat(parent, '/mtex/program1'); % matlab
    attr = io_attributes();
    attr.add('NX_class', 'NXprogram');
    ret = h5w.nexus_write_group(grpnm, attr);
    
    dsnm = strcat(grpnm, '/program');
    attr = io_attributes();
    attr.add('version', version);
    ret = h5w.nexus_write(dsnm, 'Matlab', attr);

    grpnm = strcat(parent, '/mtex/program2'); % mtex
    attr = io_attributes();
    attr.add('NX_class', 'NXprogram');
    ret = h5w.nexus_write_group(grpnm, attr);

    dsnm = strcat(grpnm, '/program');
    attr = io_attributes();
    attr.add('version', mtex_pref.version);
    ret = h5w.nexus_write(dsnm, 'MTex', attr);    
%% conventions    
    grpnm = strcat(parent, '/mtex/conventions');
    attr = io_attributes();
    attr.add('NX_class', 'NXcollection');
    ret = h5w.nexus_write_group(grpnm, attr);

    attr = io_attributes();
    dsnm = strcat(grpnm, '/x_axis_direction');
    ret = h5w.nexus_write(dsnm, mtex_pref.xAxisDirection, attr);
    dsnm = strcat(grpnm, '/z_axis_direction');
    ret = h5w.nexus_write(dsnm, mtex_pref.zAxisDirection, attr);
    dsnm = strcat(grpnm, '/a_axis_direction');
    if ~strcmp(mtex_pref.aAxisDirection, '')
        ret = h5w.nexus_write(dsnm, mtex_pref.aAxisDirection, attr);
    else
        ret = h5w.nexus_write(dsnm, 'n/a', attr);
    end
    dsnm = strcat(grpnm, '/b_axis_direction');
    ret = h5w.nexus_write(dsnm, mtex_pref.bAxisDirection, attr);
    dsnm = strcat(grpnm, '/euler_angle');
    if strcmp(mtex_pref.EulerAngleConvention, 'Bunge')
        ret = h5w.nexus_write(dsnm, mtex_pref.EulerAngleConvention, attr);
    else
        ret = h5w.nexus_write(dsnm, 'undefined', attr);
    end

%% plotting
    grpnm = strcat(parent, '/mtex/plotting');
    attr = io_attributes();
    attr.add('NX_class', 'NXcollection');
    ret = h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();
    dsnm = strcat(grpnm, '/font_size');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.FontSize), attr);
    dsnm = strcat(grpnm, '/inner_plot_spacing');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.innerPlotSpacing), attr);
    dsnm = strcat(grpnm, '/outer_plot_spacing');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.outerPlotSpacing), attr);
    dsnm = strcat(grpnm, '/marker_size');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.markerSize), attr);
    dsnm = strcat(grpnm, '/figure_size');
    ret = h5w.nexus_write(dsnm, mtex_pref.figSize, attr);
    dsnm = strcat(grpnm, '/show_micron_bar');
    if strcmp(mtex_pref.showMicronBar, 'on')
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/show_coordinates');
    if strcmp(mtex_pref.showCoordinates, 'on')
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/pf_anno_fun_hdl');
    ret = h5w.nexus_write(dsnm, func2str(mtex_pref.pfAnnotations), attr);
    dsnm = strcat(grpnm, '/color_map');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.colors), attr);
    dsnm = strcat(grpnm, '/default_map');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.defaultColorMap), attr);
    dsnm = strcat(grpnm, '/color_palette');
    ret = h5w.nexus_write(dsnm, mtex_pref.colorPalette, attr);
    dsnm = strcat(grpnm, '/degree_character');
    ret = h5w.nexus_write(dsnm, mtex_pref.degreeChar, attr);
    dsnm = strcat(grpnm, '/arrow_character');
    ret = h5w.nexus_write(dsnm, mtex_pref.arrowChar, attr);
    dsnm = strcat(grpnm, '/marker');
    ret = h5w.nexus_write(dsnm, mtex_pref.annotationStyle{2}, attr);
    dsnm = strcat(grpnm, '/marker_edge_color');
    ret = h5w.nexus_write(dsnm, mtex_pref.annotationStyle{4}, attr);
    dsnm = strcat(grpnm, '/marker_face_color');
    ret = h5w.nexus_write(dsnm, mtex_pref.annotationStyle{6}, attr);
    dsnm = strcat(grpnm, '/hit_test');
    if strcmp(mtex_pref.annotationStyle{8}, 'off')
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    end
    % phaseColorOrder

%% others
    grpnm = strcat(parent, '/mtex/miscellaneous');
    attr.add('NX_class', 'NXcollection');
    ret = h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();
    dsnm = strcat(grpnm, '/mosek');
    if mtex_pref.mosek
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/generating_help_mode');
    ret = h5w.nexus_write(dsnm, mtex_pref.generatingHelpMode, attr);
    dsnm = strcat(grpnm, '/methods_advise');
    if mtex_pref.mtexMethodsAdvise
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/stop_on_symmetry_mismatch');
    if mtex_pref.stopOnSymmetryMissmatch
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/inside_poly');
    if mtex_pref.insidepoly
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end 
    dsnm = strcat(grpnm, '/text_interpreter');
    ret = h5w.nexus_write(dsnm, mtex_pref.textInterpreter, attr);
    dsnm = strcat(grpnm, '/voronoi_method');
    ret = h5w.nexus_write(dsnm, mtex_pref.voronoiMethod, attr);

%% numerics
    grpnm = strcat(parent, '/mtex/numerics');
    attr.add('NX_class', 'NXcollection');
    ret = h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();
    dsnm = strcat(grpnm, '/eps');
    ret = h5w.nexus_write(dsnm, double(eps), attr);
    dsnm = strcat(grpnm, '/fft_accuracy');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.FFTAccuracy), attr);
    dsnm = strcat(grpnm, '/max_sone_bandwidth');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.maxS1Bandwidth), attr);
    dsnm = strcat(grpnm, '/max_stwo_bandwidth');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.maxS2Bandwidth), attr);
    dsnm = strcat(grpnm, '/max_sothree_bandwidth');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.maxSO3Bandwidth), attr);

%% system
    grpnm = strcat(parent, '/mtex/system');
    attr.add('NX_class', 'NXcollection');
    ret = h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();
    dsnm = strcat(grpnm, '/memory');
    attr.add('unit', 'MiB');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.memory), attr);
    attr = io_attributes();
    dsnm = strcat(grpnm, '/open_gl_bug');
    if mtex_pref.openglBug
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/save_to_file');
    if mtex_pref.SaveToFile
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end

%% paths 
    % switch off these annotations as I do not want share my local system configuration
    if 1 == 0
        grpnm = strcat(parent, '/mtex/path');
        attr.add('NX_class', 'NXcollection');
        ret = h5w.nexus_write_group(grpnm, attr);
        attr = io_attributes();
       
        dsnm = strcat(grpnm, '/mtex');
        ret = h5w.nexus_write(dsnm, mtex_pref.mtexPath, attr);
        dsnm = strcat(grpnm, '/data');
        ret = h5w.nexus_write(dsnm, mtex_pref.DataPath, attr);
        dsnm = strcat(grpnm, '/cif');
        ret = h5w.nexus_write(dsnm, mtex_pref.CIFPath, attr);
        dsnm = strcat(grpnm, '/ebsd');
        ret = h5w.nexus_write(dsnm, mtex_pref.EBSDPath, attr);
        dsnm = strcat(grpnm, '/pf');
        ret = h5w.nexus_write(dsnm, mtex_pref.PoleFigurePath, attr);
        dsnm = strcat(grpnm, '/odf');
        ret = h5w.nexus_write(dsnm, mtex_pref.ODFPath, attr);
        dsnm = strcat(grpnm, '/tensor');
        ret = h5w.nexus_write(dsnm, mtex_pref.TensorPath, attr);
        dsnm = strcat(grpnm, '/example');
        ret = h5w.nexus_write(dsnm, mtex_pref.ExamplePath, attr);
        dsnm = strcat(grpnm, '/import_wizard');
        ret = h5w.nexus_write(dsnm, mtex_pref.ImportWizardPath, attr);
        dsnm = strcat(grpnm, '/pf_extensions');
        ret = h5w.nexus_write(dsnm, strjoin(mtex_pref.poleFigureExtensions, ';'), attr);
        dsnm = strcat(grpnm, '/ebsd_extensions');
        ret = h5w.nexus_write(dsnm, strjoin(mtex_pref.EBSDExtensions, ';'), attr);
    end

    status = logical(1);
end