function status = nexus_write_ebsd_odf(ebsd_orig, fpath, parent)
% Generate default ODF plots for H5Web and write data to NeXus/HDF5 file

% ebsd_orig:
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write
n_resolution = 2.0;  % of ODF plot

h5w = HdfFiveSeqHdl(fpath);

grpnm = strcat(parent, ['/odf']);
attr = io_attributes();
attr.add('NX_class', 'NXms_odf_set');
ret = h5w.nexus_write_group(grpnm, attr);

phase_id = 0;
for phase_idx = 1:1:length(ebsd_orig.mineralList)
    % TODO: add a map for all those points not indexed
    if min(ebsd_orig.phaseMap) == -1
        n_count = sum(sum(ebsd_orig.phase == (phase_id - 1)));
    elseif min(ebsd_orig.phaseMap) == 0
        n_count = sum(sum(ebsd_orig.phase == phase_id));
    else
        error('ERROR: The phaseMap for this EBSD map uses an unexpected indexing!');
    end
    
    if ~strcmp(ebsd_orig.mineralList{phase_idx}, 'notIndexed') & n_count > 0

        grpnm = strcat(parent, ['/odf/odf' num2str(phase_id)]);
        attr = io_attributes();
        attr.add('NX_class', 'NXms_odf');
        % attr.add('comment', 'Orientation distribution function 10deg, 2.5deg resolution');
        ret = h5w.nexus_write_group(grpnm, attr);

        grpnm = strcat(parent, ['/odf/odf' num2str(phase_id) '/configuration']);
        attr = io_attributes();
        attr.add('NX_class', 'NXobject');
        ret = h5w.nexus_write_group(grpnm, attr);
  
        phase_name = ebsd_orig.mineralList{phase_idx};
        % disp(phase_name);
        cs = ebsd_orig.CSList{1 + phase_id};
        % disp(cs);
        specimen_symmetry_point_group = 'triclinic';
        ss = specimenSymmetry(specimen_symmetry_point_group);
        % disp(ss);

        kernel_hw = 5.*degree;
        kernel_type = SO3DeLaValleePoussinKernel('halfwidth', kernel_hw);
        odf_reso = 2.5*degree;
        dsnm = strcat(grpnm, '/phase_name');
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, phase_name, attr);
        dsnm = strcat(grpnm, '/phase_identifier');
        ret = h5w.nexus_write(dsnm, uint32(phase_id), attr);
        dsnm = strcat(grpnm, '/crystal_symmetry_point_group');
        ret = h5w.nexus_write(dsnm, cs.pointGroup, attr);
        dsnm = strcat(grpnm, '/specimen_symmetry_point_group');
        ret = h5w.nexus_write(dsnm, specimen_symmetry_point_group, attr);
        dsnm = strcat(grpnm, '/kernel_name');
        ret = h5w.nexus_write(dsnm, 'de_la_vallee_poussin', attr);
        dsnm = strcat(grpnm, '/kernel_halfwidth');
        attr = io_attributes();
        attr.add('unit', '°');
        ret = h5w.nexus_write(dsnm, double(kernel_hw / pi * 180.), attr);
        dsnm = strcat(grpnm, '/resolution');
        attr = io_attributes();
        attr.add('unit', '°');
        ret = h5w.nexus_write(dsnm, double(odf_reso / pi * 180.), attr);
        
        % exemplar code for different type of default ODFs
        odf = calcDensity(ebsd_orig(phase_name).orientations, ...
            'kernel', kernel_type, 'resolution', odf_reso);
        % odf_naive = calcDensity(ori);
        % odf_psi = calcDensity(ori, 'kernel', SO3AbelPoissonKernel('halfwidth',10.*degree));
        % odf_fou = calcDensity(ori, 'order', 16);
    
        % ##MK::TODO how to automatically parse out used kernel
        % see https://mtex-toolbox.github.io/PoleFigure.calcODF.html

        % plotSection(odf, 'phi2', 'sections', 18);  % [15,23,36]*degree)
        % classical way to export the ODF
        % odf.export_generic('test.odf','ZXZ');
        % plotSection > SO3Fun/@SO3Fun/plotSection
    
        % inspecting .../SO3Fun/export_generic we can export the ODF as such
        % fprintf(fid,'%% MTEX ODF\n');
        % fprintf(fid,'%% crystal symmetry: %s\n',char(CS));
        % fprintf(fid,'%% specimen symmetry: %s\n',char(SS));
    
        % get SO3Grid
        if isa(odf, 'SO3Grid')
            S3G = getClass(varargin,'SO3Grid');
            S3G = orientation(S3G);
            d = Euler(S3G, odf);
        else
          [S3G,~,~,d] = regularSO3Grid(cs, ss, odf);
        end
    
        % S3G is a grid on the sphere which we wish to evaluate for a phi2 section plot using a custom grid
        % specifically e.g. regularly spaced phi_1/Phi/phi_2 positions to get
        % classical phi2 sections
    
        % evaluate
        ijk = 1;
        n_e1 = ceil(360. / n_resolution);  % size(S3G, 1);  % phi_one, $\varphi_1$
        n_e2 = ceil(90. / n_resolution);  % size(S3G, 2);  % Phi, $\Phi$
        n_e3 = ceil(180. / n_resolution);  % size(S3G, 3);  % phi_two $\varphi_2$
    
        interp_pts = double(nan(3, n_e1*n_e2*n_e3));
        for k = 1:1:n_e3
            e3 = (0.5 + (k - 1)) * n_resolution;
            for j = 1:1:n_e2
                e2 = (0.5 + (j - 1)) * n_resolution;
                for i = 1:1:n_e1
                    e1 = (0.5 + (i - 1)) * n_resolution;
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
    
        % % % evaluate ODF
        % % v = eval(odf, S3G);  %  ZXZ,BUNGE - Bunge (phi1,Phi,phi2) convention
        % % %  ZYZ, ABG  - Matthies (alpha, beta, gamma) convention (default) 
        % % % build up matrix to be exported
        % % d = mod(d, 2*pi);
        % % % from radians to degree
        % % d = d./degree;  
        % % % convention
        % % convention = 'ZXZ';
        % % header = '%% phi1    Phi     phi2    value';
        % % % header = '%% alpha   beta    gamma   value';
        % % dat = [d, v(:)].';
    
        grpnm = strcat(parent, ['/odf/odf' num2str(phase_id) '/phi_two_plot']);
        attr = io_attributes();
        attr.add('NX_class', 'NXdata');
        attr.add('signal', 'intensity');
        attr.add('axes', {'varphi_two', 'capital_phi', 'varphi_one'});
        attr.add('varphi_one_indices', uint32(0));
        attr.add('capital_phi_indices', uint32(1));
        attr.add('varphi_two_indices', uint32(2));
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
        % ##MK::TODO with single precision only half as much space
        % ##MK::TODO should be sufficient for EBSD database demonstrator
        ret = h5w.nexus_write(dsnm, single(interp_values), attr);
    
        dsnm = strcat(grpnm, '/varphi_one');
        attr = io_attributes();
        attr.add('units', 'degree');
        attr.add('long_name', ['phi_1 (°)']);
        e1 = double((0.5 + ((1:1:n_e1) - 1)) * n_resolution);
        ret = h5w.nexus_write(dsnm, e1, attr);
        
        dsnm = strcat(grpnm, '/capital_phi');
        attr = io_attributes();
        attr.add('units', 'degree');
        attr.add('long_name', ['Phi (°)']);
        e2 = double((0.5 + ((1:1:n_e2) - 1)) * n_resolution);
        ret = h5w.nexus_write(dsnm, e2, attr);
        
        dsnm = strcat(grpnm, '/varphi_two');
        attr = io_attributes();
        attr.add('units', 'degree');
        attr.add('long_name', ['phi_2 (°)']);
        e3 = double((0.5 + ((1:1:n_e3) - 1)) * n_resolution);
        ret = h5w.nexus_write(dsnm, e3, attr);

        % % % check cuboidal matrices export from Matlab/Fortran style to HDF5 Cstyle
        % % % grpnm = '/entry1/debug1';
        % % % attr = io_attributes();
        % % % ret = h5w.nexus_write_group(grpnm, attr);
        % % % dbg = reshape(1:1:24, [4, 2, 3]); %';
        % % % dsnm = strcat(grpnm, '/dbg');
        % % % ret = h5w.nexus_write(dsnm, dbg, attr);
        % % % disp(size(dbg));

        % odf descriptors component analysis
        % classical components e.g. fcc cube, goss, brass, copper
        % % % components = orientation.byEuler(...
        % % %     [ 0.,  0., 35.,  0.]*degree, ...
        % % %     [ 0., 45., 45., 35.]*degree, ...
        % % %     [ 0.,  0.,  0., 45.]*degree, cs, ss);

        % locations of the 10-kth highest intensities of the ODF
        kth = 10;
        delta = 10.*degree;

        grpnm = strcat(parent, ['/odf/odf' num2str(phase_id) '/kth_extrema']);
        attr = io_attributes();
        attr.add('NX_class', 'NXms_odf_cmp');
        ret = h5w.nexus_write_group(grpnm, attr);
        
        dsnm = strcat(grpnm, '/theta');
        attr = io_attributes();
        attr.add('unit', '°');
        ret = h5w.nexus_write(dsnm, double(delta / pi * 180.), attr);

        dsnm = strcat(grpnm, '/kth');
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, uint32(kth), attr);

        dsnm = strcat(grpnm, '/location');
        [intensity, maxima] = max(odf, 'numLocal', kth);
        components = reshape(maxima, [1, length(maxima)]);
        e1_e2_e3 = zeros(3, length(maxima));
        e1_e2_e3(1, :) = maxima(:).phi1 / degree;
        e1_e2_e3(2, :) = maxima(:).Phi / degree;
        e1_e2_e3(3, :) = maxima(:).phi2 / degree;
        attr = io_attributes();
        attr.add('unit', '°');
        ret = h5w.nexus_write(dsnm, double(e1_e2_e3), attr);

        % classical volume fraction with classical disorientation threshold

        V = volume(odf, components, delta);  % fraction * 100.; % in percent
        % modernized normalization of the volume fraction
        % V = volume(odf, components, delta) ./ ...
        %    volume(uniformODF(odf.CS), double(components), delta);
        
        dsnm = strcat(grpnm, '/volume_fraction');
        attr = io_attributes();
        attr.add('comment1', 'NX_DIMENSIONLESS');
        attr.add('comment2', 'Components may overlap with the search region defined by theta !');
        attr.add('comment3', 'Therefore, volume fractions may not add up to 1. !')
        ret = h5w.nexus_write(dsnm, double(V), attr);
    end

    phase_id = phase_id + 1;
end
disp('NeXus/HDF5 exporting of orientation distribution functions was successful');
status = logical(1);
end