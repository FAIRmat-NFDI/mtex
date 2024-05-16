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

grpnm = '/entry1/measurement';
attr = io_attributes();
attr.add('NX_class', 'NXem_msr');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/simulation';
attr = io_attributes();
attr.add('NX_class', 'NXem_sim');
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

% grpnm = '/entry1/roi1';
% grpnm = '/entry1/roi1/ebsd/indexing1/odf*';
% grpnm = '/entry1/roi1/ebsd/indexing1/pf*';

status = logical(1);

end