%% header
% Markus Kühbach, Humboldt-Universität zu Berlin, Department of Physics
% NOMAD Oasis, FAIRmat 2024/05/21

%% context
% an example that shows how to process MTex class instances to map
% information content conceptually on NeXus class instances
% to work towards standardization in the field of texture analysis
% versioning, make sure that before committing the code with which
% the processing queue was computed that one runs
% git describe --dirty --tags --long --abbrev=8 --match '*[0-9]*' >mtex-version.txt
% in the mtex home directory to document which version was used for the
% queue

%% init
clear; clc;
%% for Linux might need to use qhull
setMTEXpref('voronoiMethod','qhull');
% see https://github.com/mtex-toolbox/mtex/discussions/2083 for details
%% load preprocessed color maps for all point groups
load('userScripts/FairmatNfdi/ipf_lgds.mat');
%% define custom mappings of (mis)spelled point groups used in EBSD maps
ipf_lgd_tsl_pg_map = containers.Map();
ipf_lgd_mtx_pg_map = containers.Map();
% https://orix.readthedocs.io/en/latest/tutorials/inverse_pole_figures.html
% customization for specific low-symmetry point groups for which TSL
% has no as ipf legends that are as detailed as those provided by MTex
ipf_lgd_tsl_pg_map('121') = '2';
ipf_lgd_mtx_pg_map('121') = '2';
ipf_lgd_tsl_pg_map('1m1') = 'm';
ipf_lgd_mtx_pg_map('1m1') = 'm';
ipf_lgd_tsl_pg_map('12/m1') = '2/m';
ipf_lgd_mtx_pg_map('12/m1') = '2/m';
ipf_lgd_tsl_pg_map('321') = '32';
ipf_lgd_mtx_pg_map('321') = '32';
ipf_lgd_tsl_pg_map('3m1') = '3m';
ipf_lgd_mtx_pg_map('3m1') = '3m';
ipf_lgd_tsl_pg_map('-3m1') = '-3m';
ipf_lgd_mtx_pg_map('-3m1') = '-3m';
% flip ipf_lgd vertically to have them showing up correctly aligned
% like the IPF RGB colored OIM maps, so far this was only possible
% when setting y-flip on by default
disp(['Mapping MTex point group names to closest TSL: OK']);
k = ipf_lgd_tsl_dct.keys;
v = ipf_lgd_tsl_dct.values;
for pg = 1:1:32
    tmp = ipf_lgd_tsl_dct(k{pg});
    ny = size(tmp, 3);
    flp = uint8(zeros(size(tmp)));
    for y = 1:1:ny
        flp(:, :, ny - y + 1) = tmp(:, :, y);
    end
    ipf_lgd_tsl_dct(k{pg}) = flp;
end
clearvars k v;
k = ipf_lgd_mtx_dct.keys;
v = ipf_lgd_mtx_dct.values;
for pg = 1:1:32
    tmp = ipf_lgd_mtx_dct(k{pg});
    ny = size(tmp, 3);
    flp = uint8(zeros(size(tmp)));
    for y = 1:1:ny
        flp(:, :, ny - y + 1) = tmp(:, :, y);
    end
    ipf_lgd_mtx_dct(k{pg}) = flp;
end
clearvars k v;
disp(['Precomputed IPF legends for all point groups flipped along y: OK']);


project_directory = 'CHANGEME';
target_directory = 'CHANGEME';
mtexdir = [pwd];
configdir = [project_directory];
inputdir = [target_directory '/unpacked'];
outputdir = [target_directory '/mtex'];
% addpath('userScripts/FairmatNfdi/tests');
addpath('data/EBSD');
addpath(mtexdir);
addpath(configdir);
addpath(inputdir);
addpath(outputdir);
% diary 'diary.log'
mtex_pref = configure_mtex_preferences();
mtex_plot_default = plottingConvention();
% disp(getMTEXpref('xAxisDirection'));
% disp(getMTEXpref('zAxisDirection'));
% diary off

%% load configuration from dataset extraction Python script
perform_io = 1;
case_id = '10';
ebsd_mime_types_to_use_mtex = {'ctf', 'ang', 'osc', 'crc'};
for mime_type_idx = 1:1:1  % length(ebsd_mime_types_to_use_mtex)
    mime_type = ebsd_mime_types_to_use_mtex{mime_type_idx};
    disp(mime_type);
    cfg_tbl = configure_examples( ...
        [project_directory '/harvest.examples.10.em.' mime_type '.unpack.csv'], ...
        [2, Inf]);
    n_size = size(cfg_tbl);
    n_rows = n_size(1);
    clearvars n_size;

    for row_idx = 1:1:n_rows
        clearvars -except mtexdir configdir inputdir outputdir mtex_pref ...
        perform_id case_id cfg_tbl n_rows ebsd_mime_types_to_use_mtex ...
        perf_file_name row_idx issues;
    % try
        use = cfg_tbl{row_idx, 1};
        if use ~= 1
            continue;
        end
        ifpath_main = cfg_tbl{row_idx, 4}{1};
        ifpath_supp = cfg_tbl{row_idx, 6}{1};
        % ifpath_main = 'data/EBSD/Forsterite.ctf';
        % ofpath = 'userScripts/FairmatNfdi/test.nxs';
        if strcmp(ifpath_main, '')
            continue;
        end
        if strcmp(mime_type, 'crc')
            if strcmp(ifpath_supp, '')
                continue;
            end
        end
        token = replace( ...
            ifpath_main, ...
            '/media/kaiobach/production/scidat_nomad_em/unpacked/mtex/', ...
            ''); 
        ofpath = [outputdir '/' token '.mtex.h5'];
        clearvars token;
        disp(['row_idx: ' int2str(row_idx) ...
            ' reference_frame_convention: ' reference_frame_convention]);
        disp(['ifpath_main: ' ifpath_main]);
        disp(['ifpath_supp: ' ifpath_supp]);
        disp(['ofpath: ' ofpath]);
        
        % if ~ismember(skip_these_map_ids, row_idx)
        %     continue;
        % end
        % parent = '/entry1/roi1/ebsd/indexing';

        tic;

        status = nexus_write_init(ofpath, perform_io);
        status = nexus_write_mtex_preferences( ...
                ofpath, ...
                '/entry1/roi1/ebsd/indexing', ...
                perform_io);

        if strcmp(reference_frame_convention, 's2e')
            % assuming just setting 2 is a very strong if not a wrong assumption
            if strcmp(mime_type, 'crc')
                ebsd_raw = loadEBSD_crc(ifpath_supp, ifpath_main, ...
                    'convertSpatial2EulerReferenceFrame', 'setting 2');
            else
                ebsd_raw = EBSD.load(ifpath_main, ...
                    'convertSpatial2EulerReferenceFrame', 'setting 2');
            end
        elseif strcmp(reference_frame_convention, 'e2s')
            if strcmp(mime_type, 'crc')
                ebsd_raw = loadEBSD_crc(ifpath_supp, ifpath_main, ...
                    'convertEuler2SpatialReferenceFrame', 'setting 2');
            else
                ebsd_raw = EBSD.load(input, ...
                    'convertEuler2SpatialReferenceFrame');
            end
        else
            ebsd_raw = EBSD.load(input);
        end

        % ebsd_raw 2D EBSD scan point set, arbitrary ROI shapes
        % plot(ebsd_raw);

        status = nexus_write_ebsd_phase( ...
            ebsd_raw, ...
            ofpath, ...
            '/entry1/roi1/ebsd/indexing', ...
            perform_io);

        status = nexus_write_ebsd_data( ...
            ebsd_raw, ...
            ofpath, ...
            '/entry1/roi1/ebsd/indexing', ...
            perform_io);
        % grid type, positions, euler, phase, quality descriptor

        % prepare a default plot on a square grid but represented
        % as an implicit array instead of an EBSDsquare object
        ebsd_sqr_roi_hweb = nexus_squarify_ebsd( ...
            ebsd_raw, ...
            'h5web_max_size', 2^14 - 1);

        status = nexus_write_ebsd_overview( ...
            ebsd_sqr_roi_hweb, ...
            ofpath, ...
            '/entry1/roi1/ebsd/indexing', ...
            perform_io);

        ebsd_sqr_ipf_hweb = nexus_squarify_ebsd( ...
            ebsd_raw, ...
            'h5web_max_size', 2^11 - 1);

        status = nexus_write_ebsd_phase_ipf( ...
            ebsd_raw, ...
            ebsd_sqr_ipf_hweb, ...
            ofpath, ...
            '/entry1/roi1/ebsd/indexing', ...
            perform_io, ...
            ipf_lgd_tsl_dct, ...
            ipf_lgd_mtx_dct, ...
            ipf_lgd_tsl_pg_map, ...
            ipf_lgd_mtx_pg_map);

        % skip for now computations which will increase the file size
        % substantially, i.e. ODF, PF, and microstructure
        status = nexus_write_ebsd_microstructure( ...
            ebsd_raw, ...
            ofpath, ...
            '/entry1/roi1/ebsd/indexing', ...
            perform_io);
        
        status = nexus_write_ebsd_odf( ...
            ebsd_raw, ...
            ofpath, ...
            '/entry1/roi1/ebsd/indexing', ...
            perform_io);

        %% the next function has not been tested enough
        % status = nexus_write_ebsd_pf( ...
        %       ebsd_raw, ...
        %       ofpath, ...
        %       '/entry1/roi1/ebsd/indexing', ...
        %       perform_io);
        % end

        dt = toc;
        h5w = HdfFiveSeqHdl(ofpath);
        attr = io_attributes();
        attr.add('NX_class', 'NXcs_profiling');
        grpnm = '/entry1/profiling';
        h5w.nexus_write_group(grpnm, attr);
        dsnm = [grpnm '/total_elapsed_time'];
        attr = io_attributes();
        attr.add('units', 's');
        h5w.nexus_write(dsnm, double(dt), attr);

        % disp(['Analysis took ' num2str(dt) ' s']);
        % writelines(ofpath, perf_file_name, WriteMode="append");
        % writelines(strcat(replace(string( ...
        %     datetime('now', 'TimeZone', 'UTC'), ...
        %     'yyyy-MM-dd HH:mm:ss.SSSSSSSSS'), ' ', 'T'), '+00:00'), ...
        %     perf_file_name, WriteMode="append");
    end
    % catch
    %     issues(length(issues)+1) = row_idx;
    %     writelines('\n', perf_file_name, WriteMode="append");
    %     writelines(strcat(replace(string( ...
    %         datetime('now', 'TimeZone', 'UTC'), ...
    %         'yyyy-MM-dd HH:mm:ss.SSSSSSSSS'), ' ', 'T'), '+00:00'), ...
    %         perf_file_name, WriteMode="append");  % overwrite");
    % end
end
