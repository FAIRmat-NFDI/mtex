function out = nexus_compose_file_path(workdir, proj_id, map_id, mime_type)
    fpath = strcat(workdir, '/');
    if proj_id < 100
        fpath = strcat(fpath, '0');
    end
    if proj_id < 10
        fpath = strcat(fpath, '0');
    end
    fpath = strcat(fpath, num2str(proj_id), '_');
    if map_id < 1000
        fpath = strcat(fpath, '0');
    end
    if map_id < 100
        fpath = strcat(fpath, '0');
    end
    if map_id < 10
        fpath = strcat(fpath, '0');
    end      
    fpath = strcat(fpath, num2str(map_id));
    fpath = strcat(fpath, '.');
    fpath = strcat(fpath, mime_type);
    out = fpath;
end