%% example showing how to convert class instances from MatLab/MTex
% for ingestion into the nomad-parser-nexus developed in the FAIRmat
% project of the German National Research Data Infrastructure
% Markus Kühbach, Humboldt-Universität zu Berlin, Department of Physics


%% initalize, specify crystal and specimen symmetries
clear;
clc;
setMTEXpref('showCoordinates', 'on');
setMTEXpref('FontSize', 12.0);
setMTEXpref('figSize', 'normal');
% coordinate system, utilize SI units
% we redefine the MTex default coordinate system conventions from x2north
% and z out of plane to x east and zinto plane which is the Setting 2 case
% of TSL
% https://github.com/mtex-toolbox/mtex/issues/56
setMTEXpref('xAxisDirection','east');
setMTEXpref('zAxisDirection','intoPlane');
% right-handed Cartesian coordinate system
% getMTEXpref('EulerAngleConvention');
% getMTEXpref('xAxisDirection');
% getMTEXpref('zAxisDirection');

%% specify location of production datasets
location = ['C:/Users/kuehbacm/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/' ...
    'Sprint16/EbsdOasis/'];
workdir = ['D:/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/Sprint10/' ...
    'extend_dataconverter_em_for_ebsd_and_nion/production'];

%% load configuration from dataset extraction Python script
cfg_tbl = readtable([location 'mtex_to_nxmtex_configuration.04.csv']);
n_size = size(cfg_tbl);
n_rows = n_size(1);
clearvars n_size;

phase_names_file = "phase_names.04.txt";
% lines = "proj_id_map_id;phase_names";
% writelines(lines, phase_names_file, WriteMode="overwrite");

% failures for specific row_indices
% maldeformed:
% 92
% unknown format:
% 229, 236, 237, 254, 269, 299, 342, 350, 415, 427, 487, 555, 603, 726,
% 1131, 1150
% crc does not match data:
% 589, 706, 768, 1033
% ctf parsing error:
% 1421
% uitable issues 1643, 1786, 1888, 1930
% (maldeformed or modified and renamed to ctf)?
% ang issues:
% 2018, 2027, 2028, 2036, 2039, 2042, 2048, 2056, 2066, 2072

for row_idx = 2073:1:n_rows
    clearvars proj_id map_id mime_type use_mtex cnvrsn fpath ebsd phase_names;
    proj_id = cfg_tbl{row_idx, 2};
    map_id = cfg_tbl{row_idx, 3};
    mime_type = cfg_tbl{row_idx, 4}{1};
    use_mtex = cfg_tbl{row_idx, 5}{1};
    cnvrsn = cfg_tbl{row_idx, 6}{1};
    % file name is of Python format f"{proj_id}_{map_id}.{mime_type}"
    fpath = strcat(workdir, '/');
    if proj_id < 100 fpath = strcat(fpath, '0'); end
    if proj_id < 10 fpath = strcat(fpath, '0'); end
    fpath = strcat(fpath, num2str(proj_id), '_');
    if map_id < 1000 fpath = strcat(fpath, '0'); end
    if map_id < 100 fpath = strcat(fpath, '0'); end
    if map_id < 10 fpath = strcat(fpath, '0'); end      
    fpath = strcat(fpath, num2str(map_id));
    fpath = strcat(fpath, '.');
    fpath = strcat(fpath, mime_type);
    disp(fpath);
    if strcmp(use_mtex, 'yes')
        if strcmp(cnvrsn, 's2e')
            % ##MK::TODO assuming just setting 2 is a very strong if not a wrong assumption
            ebsd = EBSD.load(fpath, 'convertSpatial2EulerReferenceFrame', 'setting 2');
        elseif strcmp(cnvrsn, 'e2s')
            ebsd = EBSD.load(fpath, 'convertEuler2SpatialReferenceFrame');
        else
            ebsd = EBSD.load(fpath);
        end
        % ##MK::TODO conversions needed for each mime_type in the same way?
        phase_names = '';
        for phase_idx = 1:1:length(ebsd.CSList)
            if strcmp(ebsd.CSList{phase_idx}, 'notIndexed')
                phase_names = strcat(phase_names, ['notIndexed' ';']);
            else
                phase_names = strcat(phase_names, [ebsd.CSList{phase_idx}.mineral ';']);
            end
        end
        disp(phase_names);
        writelines([fpath ';' phase_names], phase_names_file, WriteMode="append");
    end
end

        % if length(ebsd.CSList) == 0
        %     disp('There is another issue with the phases in this dataset!');
        % elseif length(ebsd.CSList) == 1
        %     if strcmp(ebsd.CSList{1}, 'notIndexed')
        %         disp('There are no phases indexed in this dataset!');
        %     else
        %         disp('There is another issue with the phases in this dataset!');
        %     end
        % else 
        %     disp([num2str(length(ebsd.CSList)) ' phases for this dataset']);
        % end















use_case = '186_ger_freiberg_hielscher';
use_case = '204';
%fpath = [workdir '/' {proj_id}_{map_id}.{suffix}];
fpath = [prefix '/' use_case '/Forsterite.ctf'];
fpath = [prefix '/' use_case '/Project 2 Specimen 1 Lova 0907 Montaged Data 1 Montaged Map Data.cpr'];
disp(fpath);

loadEBSD_crc
%% currently available examples
if strcmp(use_case, 'fra_montpellier_tommasi')
    file_name = [prefix '/fra_montpellier_tommasi/PAL24.ctf'];
    CS = {... 
      'notIndexed',...
      crystalSymmetry('mmm', [4.8 10 6], 'mineral', 'Forsterite', 'color', [0.53 0.81 0.98]),...
      crystalSymmetry('mmm', [18 8.8 5.2], 'mineral', 'Enstatite  Opx AV77', 'color', [0.56 0.74 0.56]),...
      crystalSymmetry('12/m1', [9.7 9 5.3], [90,105.63,90]*degree, 'X||a*', 'Y||b*', 'Z||c', 'mineral', 'Diopside   CaMgSi2O6', 'color', [0.85 0.65 0.13]),...
      crystalSymmetry('m-3m', [8.4 8.4 8.4], 'mineral', 'Chromite', 'color', [0.94 0.5 0.5]),...
      crystalSymmetry('12/m1', [9.8 18 5.3], [90,105.05,90]*degree, 'X||a*', 'Y||b*', 'Z||c', 'mineral', 'Hornblende', 'color', [0 0 0.55])};
    %setMTEXpref('xAxisDirection','north');
    %setMTEXpref('zAxisDirection','outOfPlane');
    ebsd = EBSD.load(file_name,CS,'interface','ctf', 'convertEuler2SpatialReferenceFrame');
end
if strcmp(use_case, 'ger_duesseldorf_kuehbach')
    file_name = [prefix '/ger_duesseldorf_kuehbach/800H_G1b_013_01_Scan1.osc'];
    CS = {...
        'notIndexed', ...
        crystalSymmetry('m-3m', [3.65 3.65 3.65], 'mineral', 'Iron (Gamma)', 'color', 'light blue')};
    ebsd = EBSD.load(file_name, CS, 'interface', 'osc', 'convertEuler2SpatialReferenceFrame');
end
if strcmp(use_case, 'gbr_lightform_byres')
    file_name = [prefix '/gbr_lightform_byres/Large_Forging_Apreo.cpr'];
    CS = {... 
      'notIndexed',...
      crystalSymmetry('6/mmm', [3 3 4.7], 'X||a*', 'Y||b', 'Z||c*', 'mineral', 'Ti-Hex', 'color', [0.53 0.81 0.98]),...
      crystalSymmetry('m-3m', [3.2 3.2 3.2], 'mineral', 'Titanium cubic', 'color', [0.56 0.74 0.56])};
    ebsd = EBSD.load(file_name,CS,'interface','crc', 'convertEuler2SpatialReferenceFrame');
end
if strcmp(use_case, 'ger_aachen_gerdt')
    file_name = [prefix '/ger_aachen_gerdt/TWIP-Stahl/EBSDMappings/V19_30%_700C_130S_500M.cpr'];
    CS = {... 
      'notIndexed',...
      crystalSymmetry('m-3m', [3.6 3.6 3.6], 'mineral', 'Fe-FCC', 'color', [0.53 0.81 0.98])};
    ebsd = EBSD.load(file_name,CS,'interface','crc', 'convertEuler2SpatialReferenceFrame');
end
if strcmp(use_case, '186_ger_freiberg_hielscher')
    file_name = [prefix '/186_ger_freiberg_hielscher/Forsterite.ctf'];
    CS = {... 
      'notIndexed',...
      crystalSymmetry('mmm', [4.8 10 6], 'mineral', 'Forsterite', 'color', [0.53 0.81 0.98]),...
      crystalSymmetry('mmm', [18 8.8 5.2], 'mineral', 'Enstatite', 'color', [0.56 0.74 0.56]),...
      crystalSymmetry('12/m1', [9.7 9 5.3], [90,105.63,90]*degree, 'X||a*', 'Y||b*', 'Z||c', 'mineral', 'Diopside', 'color', [0.85 0.65 0.13]),...
      crystalSymmetry('m-3m', [5.4 5.4 5.4], 'mineral', 'Silicon', 'color', [0.94 0.5 0.5])};
    ebsd = EBSD.load(file_name,CS,'interface','ctf', 'convertEuler2SpatialReferenceFrame');
end
if strcmp(use_case, 'ger_aachen_dickert')
    file_name = [prefix '/ger_aachen_dickert/X30MnAl7-6Kubus_EBSD_Test_02.cpr'];
    CS = { ...
      'notIndexed', ...
      crystalSymmetry('m-3m', [3.6 3.6 3.6], 'mineral', 'Austenit_SS2012_HS1', 'color', [0.53 0.81 0.98]), ...
      crystalSymmetry('m-3m', [2.9 2.9 2.9], 'mineral', 'Ferrit_SS2012_HS1', 'color', [0.56 0.74 0.56])};
    ebsd = EBSD.load(file_name, CS, 'interface','crc', 'convertEuler2SpatialReferenceFrame');
end
if strcmp(use_case, 'nzl_otago_fan')
    file_name = [prefix '/nzl_otago_fan/def010.cpr'];
    CS = {...
        'notIndexed', ...
        crystalSymmetry('6/mmm', [4.5113 4.5113 7.3463], 'X||a*', 'Y||b', 'Z||c*', 'mineral', 'Ice 1h', 'color', 'blue')};
    ebsd = EBSD.load(file_name,CS,'interface','crc', 'convertEuler2SpatialReferenceFrame'); % no conversion spatial euler?
end
if strcmp(use_case, 'ger_freiberg_niessen')
    file_name = [prefix '/ger_freiberg_niessen/TRWIP_CR10_E7_1C.cpr'];
    ebsd = EBSD.load(file_name); % no conversion spatial euler?
    %ebsd('Iron fcc').CS.mineral = 'Gamma';
    %ebsd('Iron bcc').CS.mineral = 'AlphaP';
    %ebsd('Epsilon').CS.mineral = 'Epsilon';
end
if strcmp(use_case, 'ger_juelich_lastam')
    file_name = [prefix '/ger_juelich_lastam/Figure 11a.cpr'];
    CS = {... 
          'notIndexed',...
          crystalSymmetry('-3m1', [5e+14 5e+14 1.7e+14], 'X||a*', 'Y||b', 'Z||c*', 'mineral', 'Calcite', 'color', [0.53 0.81 0.98]),...
          crystalSymmetry('mmm', [5e+14 8e+14 5.7e+14], 'mineral', 'Aragonit', 'color', [0.56 0.74 0.56])};
    ebsd = EBSD.load(file_name,CS,'interface','crc','convertEuler2SpatialReferenceFrame'); % no conversion spatial euler?
end
if strcmp(use_case, 'gbr_london_tong')
    file_name = [prefix '/gbr_london_tong/TKD_BOR_Data/Data/TKD_Trial.ctf'];
    CS = {... 
          'notIndexed',...
          crystalSymmetry('m-3m', [3.3 3.3 3.3], 'mineral', 'Titanium-beta', 'color', [0.53 0.81 0.98]),...
          crystalSymmetry('6/mmm', [3 3 4.7], 'X||a*', 'Y||b', 'Z||c*', 'mineral', 'Titanium', 'color', [0.56 0.74 0.56]) ...
         };
    ebsd = EBSD.load(file_name,CS,'interface','ctf','convertEuler2SpatialReferenceFrame');
end
if strcmp(use_case, 'ger_aachen_ackermann')
    file_name = [prefix '/ger_aachen_ackermann/EBSD+IEHK/Fatigue_iBain1_450_500x_OPS Specimen 1 Site 1 Map Data 1.ctf'];
    CS = {... 
          'notIndexed',...
          crystalSymmetry('m-3m', [2.9 2.9 2.9], 'mineral', 'Iron bcc (old)', 'color', [0.53 0.81 0.98]),...
          crystalSymmetry('m-3m', [3.7 3.7 3.7], 'mineral', 'Iron fcc', 'color', [0.56 0.74 0.56]),...
          crystalSymmetry('mmm', [5.1 6.8 4.5], 'mineral', 'Fe3C', 'color', [0.85 0.65 0.13])};
    ebsd = EBSD.load(file_name,CS,'interface','ctf','convertEuler2SpatialReferenceFrame');
end

disp(['Working with use_case: ' use_case]);

%% grain reconstruction
plot(ebsd,'micronBar','off')
legend off

% different methods are availabel to compute grains from orientation maps
% the classical approach is to segment along steep orientation gradient, i.e. use iso-disorientation-contour
grains_old = calcGrains(ebsd('indexed'),'boundary', 'tight', 'angle', 5.0*degree);
% for subtle orientation gradients, fast multi-scale clustering, https://doi.org/10.1016/j.ultramic.2013.04.009
% for the ger_freiberg_hielscher (forsterite example) this is not very useful as the boundary profiles are very ragged

if 1 == 0
    if strcmp(use_case, 'ger_freiberg_hielscher')
        grains_fmc = calcGrains(ebsd('indexed'), 'boundary', 'tight', 'FMC', 3.5);
        % also for subtle orientation gradients, Markov graph clustering
        % https://micans.org/mcl/
        % http://dx.doi.org/10.1007/s11661-018-4904-9
        % for the ger_freiberg_hielscher (forsterite example) this is useless as it
        % tries to allocate a 294GB matrix :D !!
        grains_mcl = calcGrains(ebsd('indexed'), 'boundary', 'tight', 'mcl', [1.24 50], 'soft', [0.2 0.3]*degree);
        
        % plot the grain boundary
        hold on
        plot(grains_old.boundary, 'linewidth', 1.5, 'linecolor', 'black')
        hold on
        plot(grains_fmc.boundary, 'linewidth', 1.5, 'linecolor', 'blue')
        % hold
        % plot(grains_mcl.boundary, 'linewidth', 1.5, 'linecolor', 'orange')
        hold off
    
        % for a mixture of homo and hetero-phase boundaries no misorientation is
        % computed
        gB = grains_old.boundary('Forsterite', 'Forsterite');
        Sigma3 = gB(angle(gB.misorientation, CSL(3, ebsd('Forsterite').CS)) < 30.0*degree);
        hold on
        plot(ebsd('Forsterite'),log(ebsd('Forsterite').prop.bc), 'figSize', 'large')
        mtexColorMap black2white
        hold on
        plot(gB, 'linewidth', 1.5, 'linecolor', 'black', 'DisplayName', 'Forsterite/Forsterite homo-phase boundaries')
        hold on
        plot(Sigma3, 'lineColor', 'gold', 'linewidth', 1.5, 'DisplayName','CSL3 within 30deg')
        hold off
    end
    
    if strcmp(use_case, 'fra_montpellier_tommasi')
        % the large/complex Enstatite OPX Av77 crystal with island grains inside
        test_grain_x = 5336;
        test_grain_y = 8251;
        hold on
        plot(grains_old(test_grain_x, test_grain_y).boundary,'linewidth',4,'linecolor','blue')
        hold off
    end
    
    % boundary contact
    outerBoundary_id = any(grains_old.boundary.grainId==0, 2);
    innerBoundary_id = ~outerBoundary_id;
end

% check that each support vertex of a triplePoint is just a copy of a
% vertex to the boundary network support vertices
bnd_vrts = KDTreeSearcher(grains_old.V);
nn = knnsearch(bnd_vrts, grains_old.triplePoints.V);
display(max(abs(nn - grains_old.triplePoints.id)));
% we observe nn is grains_old.triplePoints.id
clearvars bnd_vrts nn ans;


%% write results to NeXus/HDF5
file_suffix = '.grains.mtex.h5';
disp(['Reporting results to NeXus/HDF5 to ' file_name file_suffix]);

h5w = HdfFiveSeqHdl([file_name file_suffix]);
ret = h5w.nexus_create([file_name file_suffix]);
ret = h5w.nexus_open('H5F_ACC_RDWR');
ret = h5w.nexus_close();

grpnm = '/entry1';
attr = io_attributes();
attr.add('NX_class', 'NXentry');
ret = h5w.nexus_write_group(grpnm, attr);

%% store MTex settings ...
if 1 == 1
    grpnm = '/entry1/get_mtex_preferences';
    attr = io_attributes();
    attr.add('NX_class', 'NXprocess');
    ret = h5w.nexus_write_group(grpnm, attr);
    
    mtex_pref = getMTEXpref;
    
    dsnm = strcat(grpnm, '/mtex_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.mtexPath, attr);
    dsnm = strcat(grpnm, '/data_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.DataPath, attr);
    dsnm = strcat(grpnm, '/version');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.version, attr);
    dsnm = strcat(grpnm, '/generating_help_mode');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.generatingHelpMode, attr);
    dsnm = strcat(grpnm, '/font_size');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, double(mtex_pref.FontSize), attr);
    dsnm = strcat(grpnm, '/inner_plot_spacing');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, double(mtex_pref.innerPlotSpacing), attr);
    dsnm = strcat(grpnm, '/x_axis_direction');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.xAxisDirection, attr);
    dsnm = strcat(grpnm, '/z_axis_direction');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.zAxisDirection, attr);
    % dsnm = strcat(grpnm, '/a_axis_direction');  % fix this if string is empty
    % hdf5wrapper throws an error!
    % attr = io_attributes();
    % ret = h5w.nexus_write(dsnm, mtex_pref.aAxisDirection, attr);
    dsnm = strcat(grpnm, '/b_axis_direction');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.bAxisDirection, attr);
    dsnm = strcat(grpnm, '/figure_size');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.figSize, attr);
    dsnm = strcat(grpnm, '/show_micron_bar');
    attr = io_attributes();
    if strcmp(mtex_pref.showMicronBar, 'on')
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/show_coordinates');
    attr = io_attributes();
    if strcmp(mtex_pref.showCoordinates, 'on')
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/pole_figure_annotations');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, func2str(mtex_pref.pfAnnotations), attr);
    dsnm = strcat(grpnm, '/outer_plot_spacing');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, double(mtex_pref.outerPlotSpacing), attr);
    dsnm = strcat(grpnm, '/marker_size');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, double(mtex_pref.markerSize), attr);
    % dsnm = strcat(grpnm, '/annotation_style');
    % attr = io_attributes();
    % ret = h5w.nexus_write(dsnm, mtex_pref.mtexPath, attr);
    dsnm = strcat(grpnm, '/open_gl_bug');
    attr = io_attributes();
    if mtex_pref.openglBug
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/euler_angle_convention');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.EulerAngleConvention, attr);
    % dsnm = strcat(grpnm, '/pole_figure_extensions');
    % attr = io_attributes();
    % ret = h5w.nexus_write(dsnm, double(mtex_pref.markerSize), attr);
    % dsnm = strcat(grpnm, '/ebsd_extensions');
    % attr = io_attributes();
    % ret = h5w.nexus_write(dsnm, double(mtex_pref.markerSize), attr);
    dsnm = strcat(grpnm, '/colors');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, double(mtex_pref.colors), attr);
    dsnm = strcat(grpnm, '/save_to_file');
    attr = io_attributes();
    if mtex_pref.SaveToFile
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/cif_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.CIFPath, attr);
    dsnm = strcat(grpnm, '/ebsd_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.EBSDPath, attr);
    dsnm = strcat(grpnm, '/pole_figure_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.PoleFigurePath, attr);
    dsnm = strcat(grpnm, '/odf_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.ODFPath, attr);
    dsnm = strcat(grpnm, '/tensor_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.TensorPath, attr);
    dsnm = strcat(grpnm, '/example_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.ExamplePath, attr);
    dsnm = strcat(grpnm, '/import_wizard_path');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.ImportWizardPath, attr);
    dsnm = strcat(grpnm, '/default_color_map');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, double(mtex_pref.defaultColorMap), attr);
    dsnm = strcat(grpnm, '/color_palette');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.colorPalette, attr);
    % dsnm = strcat(grpnm, '/phase_color_order');
    % attr = io_attributes();
    % ret = h5w.nexus_write(dsnm, mtex_pref.CIFPath, attr);
    dsnm = strcat(grpnm, '/stop_on_symmetry_mismatch');
    attr = io_attributes();
    if mtex_pref.stopOnSymmetryMissmatch
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/mtex_methods_advise');
    attr = io_attributes();
    if mtex_pref.mtexMethodsAdvise
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/mosek');
    attr = io_attributes();
    if mtex_pref.mosek
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/inside_poly');
    attr = io_attributes();
    if mtex_pref.insidepoly
        ret = h5w.nexus_write(dsnm, uint8(1), attr);
    else
        ret = h5w.nexus_write(dsnm, uint8(0), attr);
    end
    dsnm = strcat(grpnm, '/text_interpreter');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.textInterpreter, attr);
    dsnm = strcat(grpnm, '/memory');
    attr = io_attributes();
    attr.add('unit', 'MiB');
    ret = h5w.nexus_write(dsnm, double(mtex_pref.memory), attr);
    dsnm = strcat(grpnm, '/fft_accuracy');
    attr = io_attributes();  % unit ?
    ret = h5w.nexus_write(dsnm, double(mtex_pref.FFTAccuracy), attr);
    dsnm = strcat(grpnm, '/max_stwo_bandwidth');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, double(mtex_pref.maxS2Bandwidth), attr);
    dsnm = strcat(grpnm, '/max_sothree_bandwidth');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, double(mtex_pref.maxSO3Bandwidth), attr);
    dsnm = strcat(grpnm, '/degree_character');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.degreeChar, attr);
    dsnm = strcat(grpnm, '/arrow_character');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, mtex_pref.arrowChar, attr);
end
%% store discretization of grain boundary network discretization vertices
% ome of them are triplePoints
% some of them support the ROI boundary
% most discrete the polygon about the grain

% eventually wrap this into an ROI
grpnm = '/entry1/discretization';
attr = io_attributes();
attr.add('NX_class', 'NXprocess');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/discretization/vertices';
attr = io_attributes();
attr.add('NX_class', 'NXcg_point_set');
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/dimensionality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);

dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains_old.V, 1)), attr);

dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);

dsnm = strcat(grpnm, '/identifier');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1:1:size(grains_old.V, 1)), attr);

dsnm = strcat(grpnm, '/position');
attr = io_attributes();
attr.add('unit', grains_old.scanUnit);
ret = h5w.nexus_write(dsnm, double(grains_old.V)', attr);

%% the set of polylines representing individual interface facets
% problem the term facet is used for both a discretization of an interface
% patch as well as for describing a specific (low-energy or low Miller
% indices) face of a crystal

grpnm = '/entry1/discretization/facets';
attr = io_attributes();
attr.add('NX_class', 'NXcg_polyline_set');
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/dimensionality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);

dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains_old.boundary.F, 1)), attr);

dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);

% dsnm = strcat(grpnm, '/identifier');
% attr = io_attributes();
% ret = h5w.nexus_write(dsnm, uint32(1:1:size(grains_old.boundary.F, 1)), attr);

dsnm = strcat(grpnm, '/identifier');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(grains_old.boundary.F)', attr);
% are they really identifier?

facet_length = double(nan([1, size(grains_old.boundary.F, 1)]));
for idx = 1:1:size(grains_old.boundary.F, 1)
    u = grains_old.boundary.F(idx, 1);
    v = grains_old.boundary.F(idx, 2);
    p_u = grains_old.V(u, :);
    p_v = grains_old.V(v, :);
    facet_length(idx) = sqrt((p_u(1) - p_v(1))^2 + (p_u(2) - p_v(2))^2);
end
if any(isnan(facet_length))
    disp('ERROR: None of these should be NaN!');
end
dsnm = strcat(grpnm, '/length');
attr = io_attributes();
attr.add('unit', ebsd.scanUnit);
ret = h5w.nexus_write(dsnm, facet_length, attr);
clearvars idx u v p_u p_v facet_length;

%% store grains

grpnm = '/entry1/crystallites';
attr = io_attributes();
attr.add('NX_class', 'NXms_feature_set');
attr.add('depends_on', '/entry1/discretization');
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/dimensionality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);
dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains_old.id, 1)), attr);

dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);

% dsnm = strcat(grpnm, '/identifier');
% going for implicit naming, or should we use explicit naming?
% attr = io_attributes();
% ret = h5w.nexus_write(dsnm, uint32(grains_old.id), attr);

%% store grain descriptors

grpnm = '/entry1/crystallites/descriptor';
attr = io_attributes();
attr.add('NX_class', 'NXprocess');  % descriptor set
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/pixel_area');  % which type of area all pixels, polygon area?
area_per_ebsd_pixel = (max(max(ebsd.unitCell)) - min(min(ebsd.unitCell)))^2;  % incorrect Wigner-Seitz cell can be hexagon
attr = io_attributes();
attr.add('unit', strcat(ebsd.scanUnit, '^2'));
ret = h5w.nexus_write(dsnm, double(grains_old.grainSize * area_per_ebsd_pixel), attr);
clearvars area_per_ebsd_pixel;

dsnm = strcat(grpnm, '/phase_identifier');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(grains_old.phaseId), attr);

% evaluate if grain has boundary contact
% convenience, can be logically/topologically inferred from entry1/interfaces 
dsnm = strcat(grpnm, '/boundary_contact');
attr = io_attributes();
boundary_contact = logical(zeros(size(grains_old.id)));
for idx = 1:1:length(grains_old.boundary.grainId)
    if any(grains_old.boundary.grainId(idx, :) == 0)
        boundary_contact(max(grains_old.boundary.grainId(idx, :))) = true;
    end
end
ret = h5w.nexus_write(dsnm, uint8(boundary_contact), attr);
clearvars boundary_contact idx;

grpnm = '/entry1/crystallites/descriptor';
dsnm = strcat(grpnm, '/orientation_spread');
attr = io_attributes();
attr.add( 'unit', 'rad');
ret = h5w.nexus_write(dsnm, double(grains_old.prop.GOS), attr);

grpnm = '/entry1/crystallites/descriptor/mean_rotation';
attr = io_attributes();
attr.add('NX_class', 'NXrotation_set');  % NOT a orientation set !
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/parameterization');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'quaternion', attr);

dsnm = strcat(grpnm, '/rotation');
attr = io_attributes();
quat = double(zeros([4, length(grains_old.prop.meanRotation.a)]));
quat(1,:) = double(grains_old.prop.meanRotation.a');
quat(2,:) = double(grains_old.prop.meanRotation.b');
quat(3,:) = double(grains_old.prop.meanRotation.c');
quat(4,:) = double(grains_old.prop.meanRotation.d');
ret = h5w.nexus_write(dsnm, quat, attr);
clearvars quat;

%% interface facets which discretize the segments of the polygons
% which describe the crystallite and ROI boundar(ies) as polylines
% are not mandatory they can be interferred from topological analysis
% ideally for this the grains should be stored as a half-edge data
% structure instead of face, vertex lists

%% store crystal boundaries which can be homo (aka grain) or hetero (phase) boundaries/interfaces 
% (not their facets as a boundary can be discretized with differing number of support points)
% interfaces are pairs of half-edges because an interface separates two crystals
% each interface is discretized using at least one so-called facet, i.e.
% typically much more facets (polyline segments or triangles exist than
% conceptual interfaces

grpnm = '/entry1/interfaces';
attr = io_attributes();
attr.add('NX_class', 'NXms_feature_set');
attr.add('depends_on', '/entry1/crystallites');
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/dimensionality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);

% group interface facets to grains via hashing min/max crystal id pair
dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
facet_to_interface_lu = uint64(zeros([size(grains_old.boundary.grainId, 1), 1]));
for idx = 1:1:size(grains_old.boundary.grainId, 1)
    mi = min(grains_old.boundary.grainId(idx, :));
    mx = max(grains_old.boundary.grainId(idx, :));
    hash = uint64(mi) + uint64(2^32) * uint64(mx);
    facet_to_interface_lu(idx) = hash;
end
clearvars mi mx hash idx;
unique_interfaces = unique(facet_to_interface_lu);
keys = num2cell(unique_interfaces');
values = uint32(1:1:length(unique_interfaces));
hash_to_interface_id = containers.Map(keys, values);
clearvars keys values;
% includes interfaces of crystals to the edge of the ROI / boundary
crystal_id_pair = uint32(zeros([2, length(unique_interfaces)]));
mx = unique_interfaces ./ uint64(2^32);
mi = unique_interfaces - (uint64(2^32) .* uint64(mx));
if max(mi) >= uint64(2^32) | max(mx) >= uint64(2^32)
    disp('ERROR: crystal_id must not be >= 2^32 !');
    % stop
end
crystal_id_pair(1, :) = mi;
crystal_id_pair(2, :) = mx;
clearvars mi mx;
ret = h5w.nexus_write(dsnm, uint32(size(unique_interfaces, 1)), attr);
clearvars unique_interfaces;

dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);

dsnm = strcat(grpnm, '/identifier');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1:1:size(crystal_id_pair, 2)), attr);

dsnm = strcat(grpnm, '/crystal_identifier');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, crystal_id_pair, attr);

dsnm = strcat(grpnm, '/facet_identifier');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'LINK TO: /entry1/discretization/facets', attr);

% store interphase descriptors
grpnm = '/entry1/interfaces/descriptor';
attr = io_attributes();
attr.add('NX_class', 'NXprocess');  % descriptor set
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/phase_identifier');
attr = io_attributes();
% check that for each facet with the same interface_hash
% the phase_id pair is exactly the same!
phase_id_pair = int64(zeros(size(crystal_id_pair))) - 1; % mark unknown with -1 
for idx = 1:1:size(grains_old.boundary.phaseId, 1)
    interface_id = facet_to_interface_lu(idx);  % never zero unless 0 + (2^32 * 0) not possible by virtue of construction?
    interface_idx = hash_to_interface_id(interface_id);
    mi = min(uint32(grains_old.boundary.phaseId(idx, :)));
    mx = max(uint32(grains_old.boundary.phaseId(idx, :)));
    % in the case of mi == mx we have a homophase interface
    % in the case of any([mi, mx]) zero we have boundary contact
    % in all other cases we have heterophase interface
    if phase_id_pair(1, interface_idx) == -1 & phase_id_pair(2, interface_idx) == -1
        phase_id_pair(1, interface_idx) = mi;
        phase_id_pair(2, interface_idx) = mx;
    else
        % test consistency and throw if there are double assignments
        if phase_id_pair(1, interface_idx) == mi & phase_id_pair(2, interface_idx) == mx
        else
            disp([num2str(idx) ' problem !']);
        end
    end
end
% check that no index remains -1
if min(min(phase_id_pair)) >= 0 & max(max(phase_id_pair)) < int64(2^32)
    phase_id_pair = uint32(phase_id_pair);
end
% so the information e.g. phase_id_pair  (0, 2) means this interface
% is an interface between phase 0 and phase 2
ret = h5w.nexus_write(dsnm, phase_id_pair, attr);
clearvars idx interface_id interface_idx mi mx phase_id_pair crystal_id_pair;

%% triple junctions

grpnm = '/entry1/triple_junctions'
attr = io_attributes();
attr.add('NX_class', 'NXms_feature_set');
attr.add('depends_on', '/entry1/interfaces');
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/dimensionality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);

dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains_old.triplePoints.id, 1)), attr);

dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);

dsnm = strcat(grpnm, '/identifier');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1:1:size(grains_old.triplePoints.id, 2)), attr);
% HOW TO DECIDE WHICH ONE KICKS IN AND HOW TO RESOLVE AMBIGUITIES?
% e.g. if one just gives identifier_offset and assumes as a NeXus default
% that ids run from offset:1:: then what if there is another field called
% identifier, see below which refers to completely different ids though?
% at least two possibilities exist how to interpret "identifier"
% TRICKY, benefit of explicit stating which vertices are triple junctions
% is that minimal information is stored and one is explicit, more
% cumbersome one could add a boolean array behind discretization/vertices
% and name which are triple junctions then from the order one would have to
% compute back their ids but explicit names are always clearer than rely on
% implicit assumptions also for the sake of being self-descriptive
% above-mentioned means we introduce explicitly the ids of each triple
% junction
% alternatively one could here list the indices of the discretized vertices
% i.e. those vertices of the interface network which are triple points
% all other vertices are supporting vertices between triple junctions for
% discretizing the polyline contour approximation of the interface segment
% in the grain growth literature these are known as e.g. virtual vertices
% their spacing is dictated by the discretization of the underlying EBSD
% map

% the key question here is from which level to describe the hierarchy
% top-down or bottom-up
% from bottom-up triple lines connect interfaces which delineate crystals
% from top-down crystals are delineated by interface (s segments) two of which meet at triple
% junctions
% both description describe equally the topological and logical grouping
dsnm = strcat(grpnm, '/vertex_identifier');  % THE SPECIAL SITUATION FOR indexing with offset +1 is that
% identifier and indices can have the same value but represent two different
% concepts: an identifier is a name of an instance (a specific vertex)
% while an index is a variable to know from where to dereference pieces of
% information in a sequence (tuple, list, array)
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(grains_old.triplePoints.id), attr);
% THIS SCREAMS for getting an own i.e. vertex_identifier/@depends_on but not on interfaces but on
% discretization, but then there is no more relation between the triple
% junctions and the interfaces, hooking to interfaces is also ambiguous
% because the here written indices must not be resolved from
% identifier/index arrays inside interfaces but from discretization
% CLEARLY one could avoid such ambiguity by making copies at the costs of
% store and duplication of information

dsnm = strcat(grpnm, '/crystal_identifier');
% strictly speaking this is redundant information as it can be inferred via
% analyzing the topology of which facets are connected to the triple point
% and to which interfaces are these facets belonging and then which unique
% triplet of crystals meets at the interface
% THE TRICKY PART FOR NUMERICAL ALGORITHMS IS THAT IN SOME CASES MORE THAN
% three crystals can meet at the triple line / here point as an algorithm
% may not be topologically robust enough to distinguish geometrical corner
% cases
% four crystal junctions are considered as thermodynamically unstable but
% of course in reality interfaces are just imaginary segmentation surfaces
% which delineate the crystal i.e. interfaces are models and therefore may have
% numerical inaccuracies
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(grains_old.triplePoints.grainId)', attr);

dsnm = strcat(grpnm, '/interface_identifier');
% the adjoining interface, (also see above comment) not necessary
attr = io_attributes();
interface_ids = int64(zeros([3, size(grains_old.triplePoints.boundaryId, 1)]) - 1);
for idx = 1:1:size(grains_old.triplePoints.boundaryId, 1)
    a_idx = grains_old.triplePoints.boundaryId(idx, 1);
    b_idx = grains_old.triplePoints.boundaryId(idx, 2);
    c_idx = grains_old.triplePoints.boundaryId(idx, 3);
    a_bnd_hsh = facet_to_interface_lu(a_idx);
    b_bnd_hsh = facet_to_interface_lu(b_idx);
    c_bnd_hsh = facet_to_interface_lu(c_idx);
    a_bnd = hash_to_interface_id(a_bnd_hsh);
    b_bnd = hash_to_interface_id(b_bnd_hsh);
    c_bnd = hash_to_interface_id(c_bnd_hsh);
    if all(interface_ids(1:3, idx) == -1)
        interface_ids(1, idx) = a_bnd;
        interface_ids(2, idx) = b_bnd;
        interface_ids(3, idx) = c_bnd;
    else
        if interface_ids(1, idx) == a_bnd & interface_ids(2, idx) == b_bnd & interface_ids(3, idx) == c_bnd
        else
            disp([num2str(idx) ' problem !']);
        end
    end
end
% check that no index remains -1
if min(min(interface_ids)) >= 0 & max(max(interface_ids)) < int64(2^32)
    interface_ids = uint32(interface_ids);
end
ret = h5w.nexus_write(dsnm, interface_ids, attr);
clearvars idx a_idx b_idx c_idx a_bnd_hsh b_bnd_hsh c_bnd_hsh a_bnd b_bnd c_bnd interface_ids;

dsnm = strcat(grpnm, '/facet_identifier');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(grains_old.triplePoints.boundaryId)', attr);

clearvars hash_to_interface_id facet_to_interface_lu ret;
disp('NeXus/HDF5 dump was successful')

%% approximate an ODF
phase_name = 'Forsterite';
phase_id = 2;
cs = CS{phase_id};
disp(cs)
% ss = specimenSymmetry('orthorhombic');
ss = specimenSymmetry('triclinic');
disp(ss)

ori = ebsd(phase_name).orientations;
odf_naive = calcDensity(ori);

% use kernel density estimation with a 10 degree kernel
odf_kernel = calcDensity(ori, 'halfwidth', 10.*degree, 'resolution', 2.5*degree);
odf_psi = calcDensity(ori, 'kernel', SO3AbelPoissonKernel('halfwidth',10.*degree));
odf_fou = calcDensity(ori, 'order', 16);

plotSection(odf, 'phi2', 'sections', 18);  % [15,23,36]*degree)
% classical way to export the ODF
% odf.export_generic('test.odf','ZXZ');
% plotSection > SO3Fun/@SO3Fun/plotSection


%% inspecting .../SO3Fun/export_generic we can export the ODF as such
% fprintf(fid,'%% MTEX ODF\n');
% fprintf(fid,'%% crystal symmetry: %s\n',char(CS));
% fprintf(fid,'%% specimen symmetry: %s\n',char(SS));

% get SO3Grid
odf = odf_naive;
if isa(odf, 'SO3Grid')
    S3G = getClass(varargin,'SO3Grid');
    S3G = orientation(S3G);
    d = Euler(S3G, odf);
else
  [S3G,~,~,d] = regularSO3Grid(cs, ss, odf);
end

%% S3G is a grid on the sphere need to evaluate with custom grid
% one e.g. regularly spaced phi_1/Phi/phi_2 positions to get
% classical phi2 sections

% evaluate
ijk = 1;
n_e1 = 360;  %size(S3G, 1);  % phi_one
n_e2 = 90;  %size(S3G, 2);  % Phi
n_e3 = 180;  %size(S3G, 3);  % phi_two

interp_pts = double(nan(3, n_e1*n_e2*n_e3));
for k = 1:1:n_e3
    e3 = 0.5 + (k - 1) * 1.;
    for j = 1:1:n_e2
        e2 = 0.5 + (j - 1) * 1.;
        for i = 1:1:n_e1
            e1 = 0.5 + (i - 1) * 1.;
            interp_pts(1, ijk) = e1;
            interp_pts(2, ijk) = e2;
            interp_pts(3, ijk) = e3;
            ijk = ijk + 1;
        end
    end
end
here = orientation.byEuler(...
    interp_pts(1, :)*degree, ...
    interp_pts(2, :)*degree, ...
    interp_pts(3, :)*degree, cs, ss);
naive_grid = eval(odf, here);
clearvars i j k ijk e1 e2 e3;
% interp_values = reshape(naive_grid, [360, 90, 180]); % this reshaping is wrong!
% interp_values = double(zeros([n_e1 n_e2 n_e3]));
% interp_values = double(zeros([1, n_e1*n_e2*n_e3]));
interp_values = double(reshape(naive_grid, [n_e1, n_e2, n_e3]));
% for k = 1:1:n_e3
%     for j = 1:1:n_e2
%         for i = 1:1:n_e1
%             ijk = i + (j-1) * n_e1 + (k-1) * n_e1*n_e2;
%             interp_values(i, j, k) = naive_grid(ijk);
%         end
%     end
% end
% axis scale does not match

if 1 == 0
    % evaluate ODF
    v = eval(odf, S3G);  %  ZXZ,BUNGE - Bunge (phi1,Phi,phi2) convention
    %  ZYZ, ABG  - Matthies (alpha, beta, gamma) convention (default)
    % 
    
    % build up matrix to be exported
    d = mod(d, 2*pi);
    % from radians to degree
    d = d./degree;
    
    
    % convention
    convention = 'ZXZ';
    header = '%% phi1    Phi     phi2    value';
    % header = '%% alpha   beta    gamma   value';
    
    dat = [d, v(:)].';
end

grpnm = '/entry1/odf';
attr = io_attributes();
attr.add('NX_class', 'NXodf');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/odf/phi_two_plot';
attr = io_attributes();
attr.add('NX_class', 'NXdata');
attr.add('signal', 'intensity');
attr.add('axes', {'phi_two', 'phi', 'phi_one'});
attr.add('phi_one_indices', int64(0));
attr.add('phi_indices', int64(1));
attr.add('phi_two_indices', int64(2));
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = strcat(grpnm, '/title');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, ['ODF ' phase_name], attr);

dsnm = strcat(grpnm, '/intensity');
attr = io_attributes();
attr.add('comment', 'odf intensity normalized to random odf');
% attr.add('long_name', 'ODF contour');
% attr.add('CLASS', 'IMAGE');
% attr.add('IMAGE_VERSION', '1.2');
% attr.add('SUBCLASS_VERSION', int64(15));
ret = h5w.nexus_write(dsnm, interp_values, attr);

dsnm = strcat(grpnm, '/phi_one');
attr = io_attributes();
attr.add('units', 'degree');
attr.add('long_name', ['phi_1 (°)']);
e1 = double(0.5 + ((1:1:n_e1) - 1) * 1.);
ret = h5w.nexus_write(dsnm, e1, attr);

dsnm = strcat(grpnm, '/phi');
attr = io_attributes();
attr.add('units', 'degree');
attr.add('long_name', ['Phi (°)']);
e2 = double(0.5 + ((1:1:n_e2) - 1) * 1.);
ret = h5w.nexus_write(dsnm, e2, attr);

dsnm = strcat(grpnm, '/phi_two');
attr = io_attributes();
attr.add('units', 'degree');
attr.add('long_name', ['phi_2 (°)']);
e3 = double(0.5 + ((1:1:n_e3) - 1) * 1.);
ret = h5w.nexus_write(dsnm, e3, attr);

%% check cuboidal matrices export from Matlab/Fortran style to HDF5 Cstyle
if 1 == 0
    grpnm = '/entry1/debug1';
    attr = io_attributes();
    ret = h5w.nexus_write_group(grpnm, attr);
    dbg = reshape(1:1:24, [4, 2, 3]); %';
    dsnm = strcat(grpnm, '/dbg');
    ret = h5w.nexus_write(dsnm, dbg, attr);
    disp(size(dbg));
end

%% odf descriptors component analysis
% classical components e.g. fcc cube, goss, brass, copper
components = orientation.byEuler(...
    [ 0.,  0., 35.,  0.]*degree, ...
    [ 0., 45., 45., 35.]*degree, ...
    [ 0.,  0.,  0., 45.]*degree, cs, ss);

% kth intensity maxima locations
[intensity, maxima] = max(odf, 'numLocal', 10);
components = reshape(maxima, [1, length(maxima)]);
e1_e2_e3 = zeros(3, length(maxima));
e1_e2_e3(1, :) = maxima(:).phi1 / degree;
e1_e2_e3(2, :) = maxima(:).Phi / degree;
e1_e2_e3(3, :) = maxima(:).phi2 / degree;

% classical volume fraction with classical disorientation threshold
delta = 10.*degree;
V = volume(odf, components, delta) * 100.; % in percent

% modernized normalization of the volume fraction
V = volume(odf, components, delta) ./ ...
    volume(uniformODF(odf.CS), components, delta);

%% create polefigure

grpnm = '/entry1/pole_figure_set';
attr = io_attributes();
attr.add('NX_class', 'NXpf_set');
attr.add('comment', 'Now PF looks as for MTex xEast, zIntoPlane but X and Y each have different sign?');
ret = h5w.nexus_write_group(grpnm, attr);

miller_set = Miller({0, 0, 1}, {1, -1, 0}, {1, 1, 1}, {2, 1, 0}, cs);
% estimated specific polefigure from ebsd dataset
plotPDF(odf, miller_set);
colorbar

for k = 1:1:length(miller_set)
    pf_name = strcat('(', num2str(miller_set(k).h), num2str(miller_set(k).k), num2str(miller_set(k).l), ')');
    disp(pf_name);

    pf = calcPDF(odf, miller_set(k));
    [intensity, maxima] = max(pf, 'numLocal', 10);
    % typical representation of polefigure is via S2Grid whose points are not
    % equally distributed though when projected into the äquatorial plane
    % thus opposite approach for H5Web, sample the cube
    %[-1.:0.01:+1.]^2
    X = [+1.:-0.001:-1.];
    Y = [+1.:-0.001:-1.];
    XYZ = zeros(3, length(X) * length(Y));
    for j = 1:1:length(Y)
        for i = 1:1:length(X)
            idx = i + (j-1) * length(X);
            XYZ(1, idx) = X(i);
            XYZ(2, idx) = Y(j);
        end
    end

    % inverse stereographic projection
    % R^2 = X^2 + Y^2
    % (X,Y,0) -> (x,y,z) = (2X/(R^2 + 1), 2Y/(R^2 + 1), (R^2 - 1)/(R^2 + 1))
    % https://www.physicsforums.com/threads/inverse-of-the-stereographic-projection.108175/
    
    xyz = zeros(3, length(X) * length(Y));
    Rsqr = XYZ(1, :).^2 + XYZ(2, :).^2;
    xyz(1, :) = 2.*XYZ(1, :) ./ (Rsqr + 1);
    xyz(2, :) = 2.*XYZ(2, :) ./ (Rsqr + 1);
    xyz(3, :) = (Rsqr - 1) ./ (Rsqr + 1);
    vec = normalize(vector3d(xyz, 'antipodal'));
    intensity = eval(pf, vec); % vector3d(1, 0, 0, 'antipodal'));
    interp_values = nan([length(X), length(Y)]);
    
    for j = 1:1:length(Y)
        for i = 1:1:length(X)
            idx = i + (j-1) * length(X);
            if X(i)^2 + Y(j)^2 <= 1.
                interp_values(i, j) = intensity(idx);
            end
        end
    end
    
    grpnm = ['/entry1/pole_figure_set/' pf_name];
    attr = io_attributes();
    attr.add('NX_class', 'NXdata');
    attr.add('signal', 'intensity');
    attr.add('axes', {'axis_y', 'axis_x'});
    attr.add('axis_x_indices', int64(0));
    attr.add('axis_y_indices', int64(1));
    ret = h5w.nexus_write_group(grpnm, attr);
    
    dsnm = strcat(grpnm, '/title');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, ['PF Miller ' pf_name ' ' phase_name], attr);
    
    dsnm = strcat(grpnm, '/intensity');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, interp_values, attr);
    
    dsnm = strcat(grpnm, '/axis_x');
    attr = io_attributes();
    attr.add('long_name', ['x']);
    ret = h5w.nexus_write(dsnm, double(X), attr);
    
    dsnm = strcat(grpnm, '/axis_y');
    attr = io_attributes();
    attr.add('long_name', ['y']);
    ret = h5w.nexus_write(dsnm, double(Y), attr);
end

% recomputed specific polefigure from ODF

























%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 1 == 0
    %% compute and add band-contrast overview image
    grpnm = '/entry1/indexing/region_of_interest';
    attr = io_attributes();
    attr.add('NX_class', 'NXprocess');
    ret = h5w.nexus_write_group(grpnm, attr);
    
    which_descriptor = 'undefined';
    if isfield(ebsd_interp.prop, 'bc')
        which_descriptor = 'normalized_band_contrast';
    else
        if isfield(ebsd_interp.prop, 'confidenceindex')
            which_descriptor = 'normalized_confidence_index';
        end
    end
    
    dsnm = strcat(grpnm, '/descriptor');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, which_descriptor, attr);
    
    grpnm = '/entry1/indexing/region_of_interest/roi';
    attr = io_attributes();
    attr.add('NX_class', 'NXdata');
    attr.add('signal', 'data');
    attr.add('axes', {'axis_y', 'axis_x'});
    attr.add('axis_y_indices', int64(1));
    attr.add('axis_x_indices', int64(0));
    ret = h5w.nexus_write_group(grpnm, attr);
    
    dsnm = strcat(grpnm, '/data');
    % compute the relevant image values ...
    % the MTex-style implicit 2d arrays how they come and are used in @EBSD
    if strcmp(which_descriptor, 'normalized_band_contrast')
        nxs_roi_map_u8_f = uint8(uint32( ...
            ebsd_interp.prop.bc / ...
            max(ebsd_interp.prop.bc) * 255.));
    else
        nxs_roi_map_u8_f = uint8(uint32( ...
            ebsd_interp.prop.confidenceindex / ...
            max(ebsd_interp.prop.confidenceindex) * 255.));
    end
    % this will map NaN on zero (i.e. black in a grayscale/RGB color map)
    
    % how it should be structured when using h5write high-level MathWorks implemented function doing internally an implicit transpose
    %highlevel = uint8(zeros(fliplr([n_y n_x]))); 
    %for x = 1:n_x
    %    for y = 1:n_y
    %        idx = y + (x-1) * n_y;
    %        highlevel(x, y) = nxs_roi_map_u8_f(idx);
    %    end
    %end
    
    % in contrast, how it should be structured and then flipped while writing using H5D when using the low-level MathWorks functions wrapped by HdfFiveSeqHdl
    low_level = uint8(zeros([n_x n_y]));  % 731 335]));
    for x = 1:n_x
        for y = 1:n_y
            idx = y + (x-1) * n_y;
            low_level(x, y) = nxs_roi_map_u8_f(idx);
        end
    end
    
    % plot matrix Matlab style as grayscale
    %K = mat2gray(low_level);
    %figure
    %imshow(K)
    %plot(ebsd_interp, ebsd_interp.bc);
    %colormap gray;
    
    attr = io_attributes();
    attr.add('long_name', 'Signal');
    attr.add('CLASS', 'IMAGE');
    attr.add('IMAGE_VERSION', '1.2');
    attr.add('SUBCLASS_VERSION', int64(15));
    ret = h5w.nexus_write(dsnm, low_level, attr);
    
    % ... and dimension scale axis positions
    dsnm = strcat(grpnm, '/axis_y');
    nxs_bc_y = linspace(ymin, ymax, n_y);
    attr = io_attributes();
    attr.add('units', scan_unit);  % TODO, convenience if larger than 1.0e or smaller than 1.e-3 auto-convert
    attr.add('long_name', ['Calibrated coordinate along y-axis (', scan_unit, ')']);
    ret = h5w.nexus_write(dsnm, nxs_bc_y, attr);
    
    dsnm = strcat(grpnm, '/axis_x');
    nxs_bc_x = linspace(xmin, xmax, n_x);
    attr = io_attributes();
    attr.add('units', scan_unit);
    attr.add('long_name', ['Calibrated coordinate along x-axis (', scan_unit, ')']);
    ret = h5w.nexus_write(dsnm, nxs_bc_x, attr);
    
    dsnm = strcat(grpnm, '/title');
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, 'Region-of-interest overview image', attr);
    % compare with what should come out
    % phase_name = 'Iron fcc';
    % plot(ebsd_interp(phase_name), ebsd_interp(phase_name).bc);
    % ipfKey = ipfColorKey(ebsd_interp(phase_name));
    % ipfKey.inversePoleFigureDirection = vector3d.Z;
    % colors = ipfKey.orientation2color(ebsd_interp(phase_name).orientations);
    % plot(ebsd_interp(phase_name),colors);
    % colormap gray;
    
    %% export crystal structure models
    grpnm = '/entry1/indexing';
    nxs_phase_id = 1;
    for i = 1:length(ebsd_interp.mineralList)
        % crystallographic_database_identifier: unknown
        % crystallographic_database: unknown
        % unit_cell_abc(NX_FLOAT): 
        % unit_cell_alphabetagamma(NX_FLOAT):
        % space_group:
        % phase_identifier(NX_UINT):
        % phase_name:
        % atom_identifier:
        % atom(NX_UINT):
        % atom_positions(NX_FLOAT):
        % atom_occupancy(NX_FLOAT):
        % number_of_planes(NX_UINT):
        % plane_miller(NX_NUMBER):
        % dspacing(NX_FLOAT):
        % relative_intensity(NX_FLOAT):
        phase_name = ebsd_interp.mineralList{i};
        if strcmp(phase_name, 'notIndexed') % this is the null model
            continue;
        end
        subgrpnm = strcat(grpnm, ['/phase', num2str(nxs_phase_id)]);
        attr = io_attributes();
        attr.add('NX_class', 'NXem_ebsd_crystal_structure_model');
        ret = h5w.nexus_write_group(subgrpnm, attr);
    
        dsnm = strcat(subgrpnm, '/unit_cell_abc');
        unit_cell_abc = zeros([1, 3]);
        unit_cell_abc(1) = ebsd_interp.CSList{i}.aAxis.x;
        unit_cell_abc(2) = ebsd_interp.CSList{i}.bAxis.y;
        unit_cell_abc(3) = ebsd_interp.CSList{i}.cAxis.z;
        unit_cell_abc = unit_cell_abc * 0.1;  % TODO from angstroem to nm
        attr = io_attributes();
        attr.add('units', 'nm');
        ret = h5w.nexus_write(dsnm, unit_cell_abc, attr);
    
        dsnm = strcat(subgrpnm, '/unit_cell_alphabetagamma');
        unit_cell_alphabetagamma = zeros([1, 3]);
        unit_cell_alphabetagamma(1) = ebsd_interp.CSList{i}.alpha;
        unit_cell_alphabetagamma(2) = ebsd_interp.CSList{i}.beta;
        unit_cell_alphabetagamma(3) = ebsd_interp.CSList{i}.gamma;
        unit_cell_alphabetagamma = unit_cell_alphabetagamma / pi * 180.; % TODO from rad to deg
        attr = io_attributes();
        attr.add('units', '°');
        ret = h5w.nexus_write(dsnm, unit_cell_alphabetagamma, attr);  
        
        dsnm = strcat(subgrpnm, '/phase_identifier');
        phase_identifier = uint32(i - 1);
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, phase_identifier, attr);
    
        dsnm = strcat(subgrpnm, '/phase_name');
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, phase_name, attr);
    
        dsnm = strcat(subgrpnm, '/point_group');
        point_group = ebsd_interp.CSList{i}.pointGroup;
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, point_group, attr);
    
        % TODO add all the other fields relevant   
    
        nxs_phase_id = nxs_phase_id + 1;
    end
    
    
    %% export inverse pole figure (exemplified for IPF-Z) mappings and associated individual color keys
    nxs_ipf_map_id = 1;
    for i = 1:length(ebsd_interp.mineralList)
        phase_name = ebsd_interp.mineralList{i};
        if ~strcmp(phase_name, 'notIndexed') & sum(ebsd_interp.phaseId == i) > 0
            disp(phase_name);
            %ipf_hsv_key = ipfHSVKey(ebsd_interp(phase_name));
            ipf_key = ipfColorKey(ebsd_interp(phase_name));
            ipf_key.inversePoleFigureDirection = vector3d.Z;
            colors = ipf_key.orientation2color(ebsd_interp(phase_name).orientations);
            % from normalized colors to RGB colors
            colors = uint8(uint32(colors * 255.));
            % get the plot
            % nxs_ipf_map_u8_f = uint8(uint32(ones([n_y, n_x, 3]) * 255.));
            nxs_ipf_map_u8_f = uint8(uint32(zeros([3, n_y * n_x]) * 255.));
            nxs_ipf_y = linspace(ymin, ymax, n_y);
            nxs_ipf_x = linspace(xmin, xmax, n_x);
    
            % get array indices of all those pixels which were indexed as phase i
            phase_i_idx = uint32(ebsd_interp.id(ebsd_interp.phaseId == i));
            nxs_ipf_map_u8_f(:, phase_i_idx) = colors(1:length(phase_i_idx), :)';
            %for y = 1:n_y
            %    imin = 1 + (y-1)*n_x;
            %    imax = 1 + (y-1)*n_x + n_x - 1;
            %    nxs_ipf_map_dbl_f(y, :, :) = colors(tmp(imin:imax), :);
            %end
         
            grpnm = strcat('/entry1/indexing/ipf_map', num2str(nxs_ipf_map_id));
            attr = io_attributes();
            attr.add('NX_class', 'NXprocess');
            ret = h5w.nexus_write_group(grpnm, attr);
    
            dsnm = strcat(grpnm, '/phase_identifier');
            attr = io_attributes();
            ret = h5w.nexus_write(dsnm, uint32(i - 1), attr);  
            % i-1 because in NeXus we use 0 for non-indexed but in MTex 1 and -1 in kikuchipy ...
    
            dsnm = strcat(grpnm, '/phase_name');
            attr = io_attributes();
            ret = h5w.nexus_write(dsnm, phase_name, attr);
    
            dsnm = strcat(grpnm, '/projection_direction');
            attr = io_attributes();
            ret = h5w.nexus_write(dsnm, single([0. 0. 1.]), attr);
    
            dsnm = strcat(grpnm, '/bitdepth');
            attr = io_attributes();
            ret = h5w.nexus_write(dsnm, uint32(8), attr);
    
            dsnm = strcat(grpnm, '/program');
            attr = io_attributes();
            attr.add('version', ['Matlab: ', version ', MTex: 5.8.2']);
            ret = h5w.nexus_write(dsnm, 'mtex', attr);
    
    %% add ipf map for specific phase
            grpnm = strcat('/entry1/indexing/ipf_map', num2str(nxs_ipf_map_id), '/ipf_rgb_map');
            attr = io_attributes();
            attr.add('NX_class', 'NXdata');
            attr.add('signal', 'data');
            attr.add('axes', {'axis_y', 'axis_x'});
            attr.add('axis_y_indices', int64(1));
            attr.add('axis_x_indices', int64(0));
            ret = h5w.nexus_write_group(grpnm, attr);
    
            dsnm = strcat(grpnm, '/title');
            attr = io_attributes();
            ret = h5w.nexus_write(dsnm, ['Inverse pole figure color map ' phase_name], attr);
    
            dsnm = strcat(grpnm, '/data');
            low_level = uint8(zeros([3 n_x n_y])); %fliplr(size(nxs_ipf_map_u8_f))));
            for x = 1:n_x
                for y = 1:n_y
                    idx = y + (x-1) * n_y;
                    low_level(:, x, y) = nxs_ipf_map_u8_f(:, idx);
                end
            end
            attr = io_attributes();
            attr.add('long_name', 'IPF color-coded orientation mapping');
            attr.add('CLASS', 'IMAGE');
            attr.add('IMAGE_VERSION', '1.2');
            attr.add('SUBCLASS_VERSION', int64(15));
            ret = h5w.nexus_write(dsnm, low_level, attr);
    
            % dimension scale axis positions
            dsnm = strcat(grpnm, '/axis_y');
            % use nx_ipf_y in-place
            attr = io_attributes();
            attr.add('units', scan_unit);  % TODO, convenience if larger than 1.0e or smaller than 1.e-3 auto-convert
            attr.add('long_name', ['Calibrated coordinate along y-axis (' scan_unit ')']);
            ret = h5w.nexus_write(dsnm, nxs_ipf_y, attr);
            
            dsnm = strcat(grpnm, '/axis_x');
            % use nx_ipf_x in-place
            attr = io_attributes();
            attr.add('units', scan_unit);
            attr.add('long_name', ['Calibrated coordinate along x-axis (' scan_unit ')']);
            ret = h5w.nexus_write(dsnm, nxs_ipf_x, attr);
    
          
    %% add specific IPF color key used
            grpnm = strcat('/entry1/indexing/ipf_map', num2str(nxs_ipf_map_id), '/ipf_rgb_color_model');
            attr = io_attributes();
            attr.add('NX_class', 'NXdata');
            attr.add('signal', 'data');
            attr.add('axes', {'axis_y', 'axis_x'});
            attr.add('axis_y_indices', int64(1));
            attr.add('axis_x_indices', int64(0));
            ret = h5w.nexus_write_group(grpnm, attr);
    
    
            dsnm = strcat(grpnm, '/title');
            attr = io_attributes();
            ret = h5w.nexus_write(dsnm, 'Inverse pole figure color key with SST', attr);
    
            %% get first a rendering of the color key, ...
            figure('visible','off');
            plot(ipf_key);
            % f = gcf;
            png_fnm = ['test.mtex.nxs.ipf.key.', lower(phase_name), '.png'];
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
                    idx = y + (x-1) * n_y;
                    low_level(:, x, y) = im(y, x, :);
                end
            end
            attr = io_attributes();
            attr.add('long_name', 'Signal');
            attr.add('CLASS', 'IMAGE');
            attr.add('IMAGE_VERSION', '1.2');
            attr.add('SUBCLASS_VERSION', int64(15));
            ret = h5w.nexus_write(dsnm, low_level, attr);
    
            % ... and dimension scale axis positions
            sz = size(im);
            dsnm = strcat(grpnm, '/axis_y');
            nxs_px_y = uint32(linspace(1, sz(1), sz(1)));
            attr = io_attributes();
            attr.add('units', scan_unit);  % TODO, convenience if larger than 1.0e or smaller than 1.e-3 auto-convert
            attr.add('long_name', 'Pixel along y-axis');
            ret = h5w.nexus_write(dsnm, nxs_px_y, attr);
            
            dsnm = strcat(grpnm, '/axis_x');
            nxs_px_x = uint32(linspace(1, sz(2), sz(2)));
            attr = io_attributes();
            attr.add('units', scan_unit);
            attr.add('long_name', 'Pixel along x-axis');
            ret = h5w.nexus_write(dsnm, nxs_px_x, attr);
    
            nxs_ipf_map_id = nxs_ipf_map_id + 1;
        end
    end
    % no path to default plottables added
    
    
    %% extract MTex preferences
    
    % plist = 'H5P_DEFAULT';
    % fid = H5F.open(fnm, 'H5F_ACC_RDWR', plist); % Opens the file in read-write mode
    % gid = H5G.open(fid, '/em_lab');
    % gid_mtex_pref = H5G.create(gid, 'mtex_preferences', plist, plist, plist);
    % H5G.close(gid);
    % H5G.close(gid_mtex_pref);
    % H5F.close(fid);
    % 
    % mtex_pref_struct = getMTEXpref;
    % fn = fieldnames(mtex_pref_struct);
    % for k=1:numel(fn)
    %     cls = class(mtex_pref_struct.(fn{k}));
    %     sz = size(mtex_pref_struct.(fn{k}));
    %     disp(cls);
    % %     if isstring(mtex_pref_struct.(fn{k}))
    % %         disp(strcat('String\t\t'));
    % %         disp(mtex_pref_struct.(fn{k}));
    % %     elseif isnumeric(mtex_pref_struct.(fn{k}))
    % %        disp(strcat('Numeric\t\t'));
    % %        disp(mtex_pref_struct.(fn{k}));
    % %     else
    % %        disp('nothing');
    % %     end
    % % char, logical, double, function hdl, cell
    % end
    % subgrpnm = '/em_lab/mtex_preferences';
    % h5writeatt(fnm, subgrpnm, 'xaxis_direction', mtex_pref_struct.xAxisDirection, 'TextEncoding', 'UTF-8');
    % h5writeatt(fnm, subgrpnm, 'zaxis_direction', mtex_pref_struct.zAxisDirection, 'TextEncoding', 'UTF-8');
    % % continue with writing other details into the file
end
