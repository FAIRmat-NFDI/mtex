function out = default_argument(varargin)
if nargin > 0
    verbose_opt = logical(0);
    if strcmp(varargin, 'verbose')
        verbose_opt = logical(1);
    end
end
if verbose_opt
   disp('hello world');
end

out = verbose_opt;
end