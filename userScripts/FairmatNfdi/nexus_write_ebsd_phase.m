function status = nexus_write_ebsd_phase(ebsd_orig, fpath, parent)
% Write list of phases to NeXus/HDF5 file

% ebsd_orig:
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

% as white is a valid color in typical IPF plots black is used to mark
% pixel which have no associated IPF color value

h5w = HdfFiveSeqHdl(fpath);

n_phases = length(ebsd_orig.CSList);
if n_phases ~= length(ebsd_orig.mineralList)
    status = logical(0);
    return;
end

phase_id = 0;
for phase_idx = 1:1:n_phases
    % there are more optional fields in the
    % NXem_ebsd_crystal_structure_model base class
    
    grpnm = strcat(parent, ['/phase' num2str(phase_id)]);
    attr = io_attributes();
    attr.add('NX_class', 'NXcrystal_structure');
    ret = h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();

    dsnm = strcat(grpnm, '/phase_identifier');
    ret = h5w.nexus_write(dsnm, uint32(phase_id), attr);
    % in NeXus 0 is used for not indexed, Cstyle first i.e. 0th phase
    dsnm = strcat(grpnm, '/phase_name');
    ret = h5w.nexus_write(dsnm, ebsd_orig.mineralList{phase_idx}, attr);

    % additional information for true point groups
    if ~strcmp(ebsd_orig.mineralList{phase_idx}, 'notIndexed') 
        dsnm = strcat(grpnm, '/point_group');
        ret = h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.pointGroup, attr);
        
        dsnm = strcat(grpnm, '/unit_cell_abc');
        unit_cell_abc = [ebsd_orig.CSList{phase_idx}.aAxis.x ...
                         ebsd_orig.CSList{phase_idx}.bAxis.y ...
                         ebsd_orig.CSList{phase_idx}.cAxis.z];
        unit_cell_abc = unit_cell_abc * 0.1;  % angstroem to nm
        attr = io_attributes();
        attr.add('units', 'nm');
        ret = h5w.nexus_write(dsnm, unit_cell_abc, attr);
        
        dsnm = strcat(grpnm, '/unit_cell_alphabetagamma');
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