function setcolorrange(varargin)
% set color range for figures 
%
%% Syntax
%  setcolorrange([min max],'all')
%  setcolorrange('equal','current')
%  setcolorrange('tight','figure',figurelist)
%
%% Input
%  [min max]  - minimum and maximum value
%  figurelist - list of figure where the plots should be scaled  
%
%% Options
%  equal - scale plots to the same range
%  tight - scale plots individually
%  all   - scale all plots
%  current - scale only plots in the current figure
%  figure  - scale only plots in figurelist
%
%% See also
% multiplot S2Grid/plot

%% which figures to touch
if check_option(varargin,'all')  
  fig = 0;
elseif check_option(varargin,'current')
  fig = gcf;
else
  fig = get_option(varargin,'figure',gcf);
end

% find all axes
ax = findall(fig,'type','axes');

%% find color range
if check_option(varargin,'equal')

  for i = 1:length(ax)
    c(i,:) = caxis(ax(i));
  end
  mi = min(c,[],1);
  ma = max(c,[],1);
  p = [mi(1),ma(2)];

elseif check_option(varargin,'tight')  
  
  p = 'auto';  
  
elseif length(varargin)>=1 && isa(varargin{1},'double') &&...
    length(varargin{1})==2  
  
  p = varargin{1};  
  
else  
  
  error('First argument must either be the color range or the flag ''equal''');  
  
end

for i = 1:length(ax),	caxis(ax(i),p);end
