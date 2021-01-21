clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot v pattern in January 2020, to see if errors match underlying weather
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TimeRange = datenum(2020,1,1:1:31);

for iDay=1:1:numel(TimeRange)
  
  %get data
  Data = rCDF(era5_path(TimeRange(iDay)));
  
  %average hours
  Data.u = nanmean(Data.u,4);
  Data.v = nanmean(Data.v,4); 
  
  %store
  if iDay == 1;
    v = Data.v;
    u = Data.u;
  else
    v = cat(4,v,Data.v);
    u = cat(4,u,Data.u);
  end
  
  disp(datestr(TimeRange(iDay)))
end

%take all-days mean
v = nanmean(v,4);
u = nanmean(u,4);

w = quadadd(u,v);

%get height
z = p2h(ecmwf_prs_v2([],137));

%plot the levels from the HLOS figure
Levels = [5,10,15,20];
for iLevel=1:1:numel(Levels)
  subplot(2,2,iLevel)
  
  zidx = closest(Levels(iLevel),z);
  m_proj('stereographic','lon',0,'lat',90,'radius',40)
  m_pcolor(Data.longitude,Data.latitude,squeeze(v(:,:,zidx))')
  m_coast('color','k');
  m_grid;;
  redyellowblue32
  colorbar
end
  
  
  