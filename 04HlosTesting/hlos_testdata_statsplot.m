clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot statistical data for HLOS tests vs zonal/merid in paper
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/09
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load('hlos_error_stats.mat');

Levels = [20,15,10,5];%[5,10,15,20];
ColourStore = [1,0,0;0,0,1];
Letters = 'abcdefghijklmnopqrstuvwxyz';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% confidence interval plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, [0.01,0.05],  [0.1,0.06], 0.05);

k = 0;
for iLevel=1:1:numel(Levels)
  for iVar=1:1:2;
  
    %settings
    Variable = iVar;
    
    %panel
    if iVar == 1;k = k+1; else k =k+3; end 
    subplot(numel(Levels),4,k)
    
    %extract data
    zidx = closest(Data.Settings.An1.ZScale,Levels(iLevel));
    ToPlot = squeeze(Data.An1.ErrorStore(Variable,:,zidx,:));
    clear zidx
    
    %x-scale (overinterpolated)
    xa = min(Data.Settings.An1.LatScale):0.1:max(Data.Settings.An1.LatScale);
    x = [xa,xa(end:-1:1)];
    
    %how many confidence bands?
    NBands = floor(numel(Data.Settings.An1.Percentiles)./2);
    
    %create a colour ramp
    Colours = colorGradient([1,1,1],ColourStore(iVar,:),ceil(NBands)+3);
    Colours = Colours(3:end,:);
    
    %plot the confidence bands
    for iBand=1:1:NBands
      
      %pull out the two years
      y1 = ToPlot(:,    iBand  ); y1(isnan(y1)) = 0;
      y2 = ToPlot(:,end-iBand+1); y2(isnan(y2)) = 0;
      
      %overinterpolate  and smooth (but only at the same scale as the
      %interpolation - i.e. it just makes the line smoother at the subdaily
      %level, below the level we claim to represent)
      y1 = smoothn(interp1(Data.Settings.An1.LatScale,y1,xa),[11]);
      y2 = smoothn(interp1(Data.Settings.An1.LatScale,y2,xa),[11]);
      
      %create a patch
      patch(x,[y1,y2(end:-1:1)],Colours(iBand,:),'edgecolor','none');%[1,1,1].*0.7)
      hold on

      
    end
    
    %highlight certain bands
    LineWi = [1,1,1,1,1];
    Percs = [2.5,18,50,82,97.5];
    for iPerc=1:1:numel(Percs);
      idx = closest(Data.Settings.An1.Percentiles,Percs(iPerc));
      plot(xa,smoothn(interp1(Data.Settings.An1.LatScale,ToPlot(:,idx),xa),[5]),'-', ...
        'color',[1,1,1].*0.3,'linewi',LineWi(iPerc))
    end
    
    
    %tidy up
    box on; grid on; set(gca,'tickdir','out')
    axis([-82 85 -25 25])
    plot([-90,90],[0,0],'k--')
    
    %labelling
    if iVar==1; ylabel('U - U_{HLOS}'); 
    else;       ylabel('V - V_{HLOS}'); set(gca,'yaxislocation','right')
    end
    text(-80,19,['(',Letters(k),')'],'fontsize',18,'fontweight','bold')

    
    if Levels(iLevel) == max(Levels); set(gca,'xaxislocation','top'); xlabel('Latitude'); end
    
    
    %two colourbars need to be attached to panels to keep their identities
    if Levels(iLevel) == max(Levels)
      if iVar == 1;
        cb = colorbar('southoutside','position',[0.1 0.04 0.08 0.02]);
        caxis([0,100]);
        cb.Label.String = ['Percentile'];
        colormap(cb,[Colours;Colours(end:-1:1,:)])
      else
        cb = colorbar('southoutside','position',[0.815 0.04 0.08 0.02]);
        caxis([0,100]);
        cb.Label.String = ['Percentile'];
        colormap(cb,[Colours;Colours(end:-1:1,:)])
      end
      
      h_axes = axes('position', cb.Position, 'ylim', cb.Limits, 'color', 'none', 'visible','off');
      for PC=Percs;
        line(PC*[1 1],h_axes.YLim, 'color', [1,1,1].*0.3, 'parent', h_axes);
      end
      
    end

    

        
    drawnow
    
  end
end

clearvars -except Data Levels Letters


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% maps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot = @(m,n,p) subtightplot (m, n, p, [0.01,0.01], [0.1,0.05], 0.05);


k = -1;
for iLevel=1:1:numel(Levels)
  for iVar=1:1:2;
    
    %settings
    Variable = iVar;
    
    %panel
    if iVar == 1;k = k+3; else; k =k+1; end 
    subplot(numel(Levels),4,k)    
    
    %extract data
    zidx = closest(Data.Settings.An2.ZScale,Levels(iLevel));
    ToPlot = squeeze(Data.An2.ErrorStore(Variable,:,:,zidx));
    ToPlot(:,end) = ToPlot(:,1);
    clear zidx
    
    %create map
    m_proj('stereographic','lat',90,'long',0,'radius',50);
    
    
    %plot map
    [xi,yi] = meshgrid(Data.Settings.An2.LonScale,Data.Settings.An2.LatScale);
    m_pcolor(xi,yi,ToPlot)
    
    %colours
    colormap(flipud(cbrewer('div','RdBu',32)))
    
    if   iVar == 1; caxis([-1,1].*5)
    else            caxis([-1,1].*20)
    end
    
    %tidy up
    m_coast('color','k');
    text(-1.25,0.8,['(',Letters(k),')'],'fontsize',18,'fontweight','bold')
    m_grid('xtick',[-135:45:-45,45:45:135],'ytick',[],'fontsize',8);    

    %labelling
    if Levels(iLevel) == max(Levels); 
      if iVar == 1; title('U - U_{HLOS}'); 
      else          title('V - V_{HLOS}');
      end
    end
    
    if Levels(iLevel) == max(Levels); set(gca,'xaxislocation','top'); xlabel('Latitude'); end    
    drawnow
    
    
    %two colourbars need to be attached to panels to keep their identities
    if Levels(iLevel) == max(Levels)
      if iVar == 1;
        cb1 = colorbar('southoutside','position',[0.35 0.055 0.08 0.02]);
        caxis([-1,1].*5);
        cb1.Label.String = ['U - U_{HLOS} [ms^{-1}]'];
      else
        cb2 = colorbar('southoutside','position',[0.575 0.055 0.08 0.02]);
        caxis([-1,1].*20);
        cb2.Label.String = ['V - V_{HLOS} [ms^{-1}]'];
      end
    end
  end
end
