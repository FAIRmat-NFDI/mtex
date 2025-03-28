function status = nexus_write_ebsd_phase(ebsd_orig, fpath, parent, perform_io)
% Write list of phases to NeXus/HDF5 file

% ebsd_orig:
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

% as white is a valid color in typical IPF plots black is used to mark
% pixel which have no associated IPF color value
if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);

n_phases = length(ebsd_orig.CSList);
if n_phases ~= length(ebsd_orig.mineralList)
    status = logical(0);
    return;
end

n_count_orig_total = length(ebsd_orig);
% total number of scan points in the original mapping
dsnm = [parent, '/number_of_scan_points'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint64(n_count_orig_total), attr);

phase_id = 0;
for phase_idx = 1:1:n_phases
    % there are more optional fields in the
    % NXem_ebsd_crystal_structure_model base class

    grpnm = [parent '/phase' num2str(phase_id)];
    attr = io_attributes();
    attr.add('NX_class', 'NXphase');
    ret = h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();

    dsnm = [grpnm '/phase_id'];
    ret = h5w.nexus_write(dsnm, int32(phase_id), attr);
    % in NeXus 0 is used for not indexed, Cstyle first i.e. 0th phase
    dsnm = [grpnm '/name'];
    ret = h5w.nexus_write(dsnm, ebsd_orig.mineralList{phase_idx}, attr);

    grpnm = [parent '/phase' num2str(phase_id)]; % '/unit_cell');
    attr = io_attributes();
    attr.add('NX_class', 'NXunit_cell');
    ret = h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();
    
    % additional information for true point groups
    if ~strcmp(ebsd_orig.mineralList{phase_idx}, 'notIndexed')
        dsnm = [grpnm '/point_group'];
        ret = h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.pointGroup, attr);

        dsnm = [grpnm '/a_b_c'];
        unit_cell_abc = [ebsd_orig.CSList{phase_idx}.aAxis.x ...
                         ebsd_orig.CSList{phase_idx}.bAxis.y ...
                         ebsd_orig.CSList{phase_idx}.cAxis.z];
        unit_cell_abc = unit_cell_abc * 0.1;  % angstroem to nm
        attr = io_attributes();
        attr.add('units', 'nm');
        ret = h5w.nexus_write(dsnm, unit_cell_abc, attr);

        dsnm = [grpnm '/alpha_beta_gamma'];
        unit_cell_alphabetagamma = [ebsd_orig.CSList{phase_idx}.alpha ...
                                    ebsd_orig.CSList{phase_idx}.beta ...
                                    ebsd_orig.CSList{phase_idx}.gamma];
        unit_cell_alphabetagamma = unit_cell_alphabetagamma / pi * 180.; % rad to deg
        attr = io_attributes();
        attr.add('units', '°');
        ret = h5w.nexus_write(dsnm, unit_cell_alphabetagamma, attr);
        attr = io_attributes();
        % TODO add all the other fields relevant
    end

    phase_id = phase_id + 1;
end
disp('NeXus/HDF5 exporting of pieces of information about phases was successful');
status = logical(1);
end