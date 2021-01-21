clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot maps for HLOS tests vs zonal/merid in paper
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
%% maps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, [0.01,0.01], 0.1, 0.05);


k = 0;
for iLevel=1:1:numel(Levels)
  for iVar=[5,7,8,6]
%     for iProj=[1,2,2,1];
    
      %settings
      Variable = iVar;
      
      %panel
      k = k+1;
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
      
      if     iVar-4 == 1; caxis([-1,1].*50)
      elseif iVar-4 == 2; caxis([-1,1].*25)
      elseif iVar-4 == 3; caxis([-1,1].*50)
      elseif iVar-4 == 4; caxis([-1,1].*5)
      end
      
      %tidy up
      m_coast('color','k');
      text(-1.25,0.8,['(',Letters(k),')'],'fontsize',18,'fontweight','bold')
      m_grid('xtick',[-135:45:-45,45:45:135],'ytick',[],'fontsize',8);
      
      %labelling
      if iLevel == 1
        Titles = {'U','V','U_{HLOS}','V_{HLOS}'};
        title(Titles(iVar-4))
      end
      drawnow
      
      
      %two colourbars need to be attached to panels to keep their identities
      if Levels(iLevel) == max(Levels)
        if iVar-4 == 1;
          cb1 = colorbar('southoutside','position',[0.12 0.07 0.08 0.02]);
          caxis([-1,1].*50);
          cb1.Label.String = ['U [ms^{-1}]'];
        elseif iVar-4 == 2
          cb2 = colorbar('southoutside','position',[0.347 0.07 0.08 0.02]);
          caxis([-1,1].*25);
          cb2.Label.String = ['V [ms^{-1}]'];
        elseif iVar-4 == 3
          cb3 = colorbar('southoutside','position',[0.576 0.07 0.08 0.02]);
          caxis([-1,1].*50);
          cb3.Label.String = ['U_{HLOS} [ms^{-1}]'];
        elseif iVar-4 == 4
          cb4 = colorbar('southoutside','position',[0.803 0.07 0.08 0.02]);
          caxis([-1,1].*5);
          cb4.Label.String = ['V_{HLOS} [ms^{-1}]'];          
        end
      end
%     end
  end
end
