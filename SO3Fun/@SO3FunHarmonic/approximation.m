function SO3F = approximation(nodes, y, varargin)
% computes a least square problem to get an approximation
%
% Syntax
%   SO3F = SO3FunHarmonic.approximation(SO3Grid, f)
%   SO3F = SO3FunHarmonic.approximation(SO3Grid, f,'constantWeights')
%   SO3F = SO3FunHarmonic.approximation(SO3Grid, f, 'bandwidth', bandwidth, 'tol', TOL, 'maxit', MAXIT, 'weights', W)
%
% Input
%  SO3Grid - rotational grid
%  f       - function values on the grid (maybe multidimensional)
%
% Options
%  constantWeights  - uses constant normalized weights (for example if the nodes are constructed by equispacedSO3Grid)
%  weights          - weight w_n for the nodes (default: Voronoi weights)
%  bandwidth        - maximum degree of the Wigner-D functions used to approximate the function (Be careful by setting the bandwidth by yourself, since it may yields undersampling)
%  tol              - tolerance for lsqr
%  maxit            - maximum number of iterations for lsqr
%  regularization   - the energy functional of the lsqr solver is regularized by the Sobolev norm of SO3F (there is given a regularization constant)
%  SobolevIndex     - for regularization (default = 1)
%
% See also
% SO3Fun/interpolate SO3FunHarmonic/quadrature
% SO3VectorFieldHarmonic/approximation


nodes = nodes(:);
y = reshape(y,length(nodes),[]);

if isa(nodes,'orientation')
  SRight = nodes.CS; SLeft = nodes.SS;
  if nodes.antipodal
    nodes.antipodal = 0;
    nodes = [nodes(:);inv(nodes)];
    y = [y;y];
    varargin{end+1} = 'antipodal';
  end
else
  [SRight,SLeft] = extractSym(varargin);
  nodes = orientation(nodes,SRight,SLeft);
end

% make points unique
s = size(y);
y = reshape(y, length(nodes), []);
[nodes,~,ind] = unique(nodes(:),'tolerance',0.02);

% take the mean over duplicated nodes
for k = 1:size(y,2)
  yy(:,k) = accumarray(ind,y(:,k),[],@mean); %#ok<AGROW>
end

y = reshape(yy, [length(nodes) s(2:end)]);

tol = get_option(varargin, 'tol', 1e-6);
maxit = get_option(varargin, 'maxit', 50);

% Choose low bandwidth and oversample
oversamplingFactor = 2;
numFreq = length(nodes)*numSym(SRight.properGroup)*numSym(SLeft.properGroup)*(isalmostreal(y)+1)/2;
bw = get_option(varargin, 'bandwidth', min(dim2deg(round(numFreq/oversamplingFactor)),getMTEXpref('maxSO3Bandwidth')));
regularize = 0; lambda=0; SobolevIndex=0;
% Choose higher bandwidth and undersample. Now we need to do regularization
% TODO: Maybe decide dependent on bw whether u want to undersample or not
if check_option(varargin,'regularization')
  regularize = 1;
  lambda = get_option(varargin,'regularization',0.1);
  SobolevIndex = get_option(varargin,'SobolevIndex',1);
  bw = get_option(varargin, 'bandwidth', min(dim2deg(round(numFreq*oversamplingFactor)),getMTEXpref('maxSO3Bandwidth')));
end

% extract weights
W = get_option(varargin, 'weights');
if check_option(varargin,'constantWeights')
  W = 1/length(nodes);
elseif isempty(W)
  W = calcVoronoiVolume(nodes);
else
  if length(W)>1, W = accumarray(ind,W); end
end
W = sqrt(W(:));

b = W.*y;
if regularize
  b = [b;zeros(deg2dim(bw+1),size(b,2))];
end

% create plan
% SO3FunHarmonic([1;1]).eval(nodes,'createPlan','nfsoft')
% SO3FunHarmonic.quadrature(nodes,1,'createPlan','nfsoft','bandwidth',bw)

% least squares solution
for index = 1:size(y,2)
  [fhat(:, index),flag] = lsqr( ...
    @(x, transp_flag) afun(transp_flag, x, nodes, W,bw,regularize,lambda,SobolevIndex), b(:, index), tol, maxit);
end

% kill plan
% SO3FunHarmonic.quadrature(1,'killPlan','nfsoft')
% SO3FunHarmonic(1).eval(1,'killPlan','nfsoft')

SO3F = SO3FunHarmonic(fhat,SRight,SLeft);     

end




function y = afun(transp_flag, x, nodes, W,bw,regularize,lambda,SobolevIndex)

if strcmp(transp_flag, 'transp')
  
  if regularize
    u = x(length(nodes)+1:end);
    x = x(1:length(nodes));
  end
  x = x .* W;
  %   F = SO3FunHarmonic.quadrature(nodes,x,'keepPlan','nfsoft','bandwidth',bw);
  F = SO3FunHarmonic.adjoint(nodes,x,'bandwidth',bw);
  y = F.fhat;
  if regularize
    F = SO3FunHarmonic(u);
    SO3F = conv(F,sqrt(lambda)*(2*(0:bw)+1).'.^SobolevIndex);
    y = y+SO3F.fhat;
  end

elseif strcmp(transp_flag, 'notransp')

  F = SO3FunHarmonic(x,nodes.CS,nodes.SS);
  F.bandwidth = bw;
  %   y = F.eval(nodes,'keepPlan','nfsoft');
  y = F.eval(nodes);
  y = y .* W;
  if regularize
    SO3F = conv(F,sqrt(lambda)*(2*(0:bw)+1).'.^SobolevIndex);
    y = [y;SO3F.fhat];
  end

end

end

% Possibly split the quadrature and eval functions. Therefore do the
% precomputations before the lsqr-Method.

% TODO: Try Cross-Vallidation, if there are to much points 

