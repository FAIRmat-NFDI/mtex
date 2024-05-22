%% header
% Markus Kühbach, Humboldt-Universität zu Berlin, Department of Physics
% NOMAD Oasis, FAIRmat 2024/05/21


%% context
% an example that shows how to process MTex class instances to map
% information content conceptually on NeXus class instances
% to work towards standardization in the field of texture analysis

%% init
clear; clc;
thatone = 'CHANGEME';
mtexdir = [thatone '/mtextoolbox/mtex'];
configdir = [thatone];
thatone = 'CHANGEME';
inputdir = [thatone '/unpacked'];
outputdir = [thatone '/mtex'];
addpath(mtexdir);
addpath(configdir);
addpath(inputdir);
addpath(outputdir);
% diary 'diary.log'
mtex_pref = configure_mtex_preferences();
disp(getMTEXpref('xAxisDirection'));
disp(getMTEXpref('zAxisDirection'));
% diary off

%% load configuration from dataset extraction Python script
case_id = '08';
cfg_tbl = readtable([configdir ...
    '/harvest.examples.' case_id '.em.mtex.xls']);
n_size = size(cfg_tbl);
n_rows = n_size(1);
clearvars n_size;

ebsd_mime_types_to_use_mtex = {'cpr', 'crc', 'ang', 'ctf', 'osc'};

perf_file_name = [outputdir '/performance.' case_id '.log'];

issues = [141, 328, 329, 415, 416, 418, 419, 420, 421, 422, ...
    423, 424, 425, 426, 427, 428, 429, 430, 472, 473, 485, ...
    793, 1235, 1236, 1237, 1239, 1241, 1243, 1245, 1247, 1248, ...
    1648];

writelines('\n', perf_file_name, WriteMode="append");
writelines(strcat(replace(string( ...
    datetime('now', 'TimeZone', 'UTC'), ...
    'yyyy-MM-dd HH:mm:ss.SSSSSSSSS'), ' ', 'T'), '+00:00'), ...
    perf_file_name, WriteMode="append");  % overwrite");
% 2324 two phases...

for row_idx = 3618:1:n_rows
    clearvars -except mtexdir configdir inputdir outputdir mtex_pref ...
        case_id cfg_tbl n_rows ebsd_mime_types_to_use_mtex ...
        perf_file_name row_idx issues;
    % try
        cnvrsn = cfg_tbl{row_idx, 2}{1};
        ifpath_main = cfg_tbl{row_idx, 3}{1};
        ifpath_supp = cfg_tbl{row_idx, 4}{1};
        ofpath = [outputdir '/' cfg_tbl{row_idx, 5}{1} '.nxs'];
        disp(['row_idx: ' int2str(row_idx) ' cnvrsn: ' cnvrsn]);
        disp(['ifpath_main: ' ifpath_main]);
        disp(['ifpath_supp: ' ifpath_supp]);
        disp(['ofpath: ' ofpath]);
        tmp = strsplit(ifpath_main, '.');
        mime_type = tmp(length(tmp));
        if any(ismember(ebsd_mime_types_to_use_mtex, mime_type))
            % if ~ismember(skip_these_map_ids, row_idx)
            % disp(['Processing ' ifpath_main ' ' ifpath_supp]);
    
            tic;
            status = nexus_write_init(ofpath);
            status = nexus_write_mtex_preferences( ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing1');
    
            if strcmp(cnvrsn, 's2e')
                % assuming just setting 2 is a very strong if not a wrong assumption
                if strcmp(mime_type{1}, 'cpr')
                    ebsd_raw = loadEBSD_crc(ifpath_main, ifpath_supp, ...
                        'convertSpatial2EulerReferenceFrame', 'setting 2');
                else
                    ebsd_raw = EBSD.load(ifpath_main, ...
                        'convertSpatial2EulerReferenceFrame', 'setting 2');
                end
            elseif strcmp(cnvrsn, 'e2s')
                if strcmp(mime_type{1}, 'cpr')
                    ebsd_raw = loadEBSD_crc(ifpath_main, ifpath_supp, ...
                        'convertEuler2SpatialReferenceFrame', 'setting 2');
                else
                    ebsd_raw = EBSD.load(input, ...
                        'convertEuler2SpatialReferenceFrame');
                end
            else
                ebsd_raw = EBSD.load(input);
            end
            % ebsd_raw is a classical EBSD object (2D scan points set)
            % i.e. material points with data per point, different ROI shapes
            % plot(ebsd_raw);
            % return;
            
            status = nexus_write_ebsd_phase( ...
                ebsd_raw, ...
                ofpath, ...
                '/entry1/roi1/ebsd/indexing1');
            ebsd_sqr_roi_hweb = nexus_squarify_ebsd( ...
                ebsd_raw, ...
                'h5web_max_size', 2^14 - 1);
            status = nexus_write_ebsd_overview( ...
                ebsd_sqr_roi_hweb, ...
                ofpath, ...
                '/entry1/roi1/ebsd/indexing1');
    
            ebsd_sqr_ipf_hweb = nexus_squarify_ebsd( ...
                ebsd_raw, ...
                'h5web_max_size', 2^11 - 1);
            status = nexus_write_ebsd_phase_ipf( ...
                ebsd_raw, ...
                ebsd_sqr_ipf_hweb, ...
                ofpath, ...
                '/entry1/roi1/ebsd/indexing1');
    
            % skip for now computations which will increase the file size
            % substantially, i.e. ODF, PF, and microstructure
            if 1 == 0
                status = nexus_write_ebsd_microstructure( ...
                    ebsd_raw, ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing1');
                status = nexus_write_ebsd_odf( ...
                    ebsd_raw, ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing1');
                status = nexus_write_ebsd_pf( ...
                    ebsd_raw, ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing1');
            end
    
            dt = toc;
            disp(['Analysis took ' num2str(dt) ' s']);
            writelines(ofpath, perf_file_name, WriteMode="append");
            writelines(strcat(replace(string( ...
                datetime('now', 'TimeZone', 'UTC'), ...
                'yyyy-MM-dd HH:mm:ss.SSSSSSSSS'), ' ', 'T'), '+00:00'), ...
                perf_file_name, WriteMode="append");
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
