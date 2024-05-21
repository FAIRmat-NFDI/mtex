function status = nexus_write_init(fpath)
% init fresh NeXus/HDF5 file with path and file name given by fpath

% disp(['Reporting results to NeXus/HDF5 to ' fpath]);
h5w = HdfFiveSeqHdl(fpath);
ret = h5w.nexus_create(fpath);
ret = h5w.nexus_open('H5F_ACC_RDWR');
ret = h5w.nexus_close();

% all root-level annotations will be added by pynxtools/em parser
grpnm = '/entry1';
attr = io_attributes();
attr.add('NX_class', 'NXentry');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/roi1';
attr = io_attributes();
attr.add('NX_class', 'NXroi');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/roi1/ebsd';
attr = io_attributes();
attr.add('NX_class', 'NXem_ebsd');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/roi1/ebsd/indexing1';
attr = io_attributes();
attr.add('NX_class', 'NXprocess');
ret = h5w.nexus_write_group(grpnm, attr);

% grpnm = '/entry1/roi1/ebsd/indexing1/odf';
% attr = io_attributes();
% attr.add('NX_class', 'NXms_odf_set');
% ret = h5w.nexus_write_group(grpnm, attr);

% grpnm = '/entry1/roi1/ebsd/indexing1/pf';
% attr = io_attributes();
% attr.add('NX_class', 'NXms_pf_set');
% ret = h5w.nexus_write_group(grpnm, attr);

% grpnm = '/entry1/roi1/ebsd/indexing1/microstructure1';
% attr = io_attributes();
% attr.add('NX_class', 'NXms_recon');
% ret = h5w.nexus_write_group(grpnm, attr);

status = logical(1);

end