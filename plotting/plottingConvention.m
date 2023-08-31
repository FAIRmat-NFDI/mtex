classdef plottingConvention < handle
% class describing the alignment of a reference frame on the screen
  
  properties
    rot = rotation.id % screen coordinates to reference coordinates
  end
  
  properties (Dependent=true)
    east
    west
    north
    south
    outOfScreen
    intoScreen
    viewOpt
  end

  methods

    function pC = plottingConvention(outOfScreen,east)
      
      if nargin >= 1, pC.outOfScreen = outOfScreen; end
      if nargin >= 2, pC.east = east; end

    end
    
    function [x,y] = project(pC,v)
      % project vector3d to screen

      
    end

    function v = iproject(pC,x,y)
      % project 
     
    end

    function display(pC,varargin)
      displayClass(pC,inputname(1),varargin{:});
    
      disp(' ')

      props{1} = 'outOfScreen';
      propV{1} = ['(' char(round(pC.outOfScreen)) ')'];

      props{2} = 'north';
      propV{2} = ['(' char(round(pC.north)) ')'];

      props{3} = 'east';
      propV{3} = ['(' char(round(pC.east)) ')'];
      
      % display all properties
      cprintf(propV(:),'-L','  ','-ic','L','-la','L','-Lr',props,'-d',': ');

      disp(' ')

    end

    function setView(pC,ax)

      if nargin == 1, ax = gca; end

      if isgraphics(ax,'axes') && isappdata(ax,'sphericalPlot')

        sP = getappdata(ax,'sphericalPlot');
       
        sP.updateBounds;

        warning('Can not change plotting convention in sphercical projections after plotting!');

      elseif isa(ax,'matlab.graphics.axis.PolarAxes')
        
        switch round(angle(pC.east,xvector,zvector)/degree)
          case 0
            ax.ThetaZeroLocation='right';
          case 90
            ax.ThetaZeroLocation='top';
          case 180
            ax.ThetaZeroLocation='left';
          case 270
            ax.ThetaZeroLocation='bottom';
        end
        if pC.outOfScreen.z<0
          ax.ThetaDir='clockwise';
        else
          ax.ThetaDir='counterclockwise';
        end

      elseif ax.PlotBoxAspectRatioMode == "manual" % 3d plot
        
        %cameraDist = norm(ax.CameraPosition - ax.CameraTarget);
        %ax.CameraPosition = ax.CameraTarget + cameraDist*pC.outOfScreen.xyz;
        %ax.CameraUpVector = pC.north.xyz;
        
        ax.CameraUpVector = pC.north.xyz;
        view(ax,pC.outOfScreen.xyz);
        

      else % map plot

        %ax.CameraPosition = ax.CameraTarget + 1000*pC.outOfScreen.xyz;

        ax.CameraUpVector = pC.north.xyz;
        view(ax,pC.outOfScreen.xyz);
        

      end
      
    end

    function opt = get.viewOpt(pC)
      opt = {'CameraPosition',1000*pC.outOfScreen.xyz,...
        "CameraUpVector",pC.north.xyz};
    end


    function v = get.outOfScreen(pC) 
      v = pC.rot * vector3d.Z;
    end

    function set.outOfScreen(pC,n)

      pC.rot = rotation.map(pC.outOfScreen,n) * pC.rot;

    end


    function v = get.east(pC) 
      
      v = pC.rot * vector3d.X;

    end

    function set.east(pC,e)
      
      pC.rot = rotation.map(pC.east,e) * pC.rot;

    end

    function v = get.north(pC) 
      
      v = pC.rot * vector3d.Y;

    end

    function set.north(pC,v)
      
      pC.rot = rotation.map(pC.north,v) * pC.rot;

    end

  end

  methods (Static=true)
  
    function test
      grainsR = rotate(grains,rotation.rand);
      plot(grainsR,grainsR.meanOrientation,'micronbar','off');
      pC.outOfScreen = grainsR.N; pC.setView(gca)
    end

  end

end

