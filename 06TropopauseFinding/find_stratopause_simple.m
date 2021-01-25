clearvars -except YEAR


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%find stratopause in ERA5 data
% method of https://agupubs.onlinelibrary.wiley.com/doi/epdf/10.1029/2011JD016893

%%
%%
%%assumes p2h is true.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%file and time handling
Settings.DataDir = [LocalDataDir,'/ERA5'];
Settings.OutFile = [LocalDataDir,'/corwin/era5_stratopause_',num2str(YEAR),'.mat'];
Settings.TimeScale = datenum(YEAR,1,1):datenum(YEAR,12,31);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% processing (output files created inside loop on first iteration)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iDay=1:1:numel(Settings.TimeScale)
  
  
  %find and load the ERA5 data for this day
  [yy,~,~] = datevec(Settings.TimeScale(iDay));
  dd = date2doy(Settings.TimeScale(iDay));
  File = [Settings.DataDir,'/',sprintf('%04d',yy),'/',...
          'era5_',sprintf('%04d',yy),'d',sprintf('%03d',dd),'.nc'];
  if ~exist(File);
    File = [Settings.DataDir,'/',sprintf('%04d',yy),'/',...
            'era5t_',sprintf('%04d',yy),'d',sprintf('%03d',dd),'.nc'];
    if ~exist(File); continue; end
  end
  Data = rCDF(File);
  Prs = ecmwf_prs_v2([],137);
  clear yy dd File
  
  %store geoloc for later
  if ~exist('Results');
    Lat = Data.latitude;
    Lon = Data.longitude;
  end
  
  %extract temperature
  T = Data.t;
  clear Data
  
  %make the data go in the right direction
  [~,idx] = sort(Prs,'desc');
  Prs = Prs(idx);
  T = T(:,:,idx,:);
  clear idx
  
  %take just the middle hour or the day, as model isn't that accurate this far up anyway
  T = T(:,:,:,round(size(T,4)./2));
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% find stratopause
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

  %interpolate the data to a regular 1km height grid between
  %0 and 80km altitude
  
  OldZ = p2h(Prs);
  NewZ = 0:1:80;
  
  sz = size(T);
  T = reshape(T,sz(1)*sz(2),sz(3));
  T = interp1(OldZ,T',NewZ)';
  
  %smooth with an 11km boxcar
  Ts = smoothn(T,[1,11]);

  %find maximum in each profile
  [~,idx] = max(Ts,[],2);
  
  %check 5 levels above and below:
    %5 levels above must have -ve lapse rate
    %5 levels below must have +ve lapse rate
  dTdZ = diff(Ts,1,2);
  dTdZ = cat(2,dTdZ(:,1),dTdZ); %so points line up, rather than half-levels
  clear Ts
  
  Passed = zeros(sz(1)*sz(2),1);
  for iProf=1:1:size(dTdZ,1)
    
    if NewZ(idx(iProf)) < 25; continue; end %must be above 25km
    
    Above = idx(iProf)+1:1:idx(iProf)+5; Above = Above(Above > 0 & Above < size(NewZ,2));
    Below = idx(iProf)-5:1:idx(iProf)-1; Below = Below(Below > 0 & Below < size(NewZ,2));    
    
    Above = -dTdZ(iProf,Above); Below = dTdZ(iProf,Below); %note - sign on Above
     
    if min(Above) > 0 & min(Below) > 0;
      %label profile as to use
      Passed(iProf) = 1;
      %also remove anything otuside +/- 15 km from peak
      T(iProf,NewZ < NewZ(idx(iProf))-15) = NaN;
      T(iProf,NewZ > NewZ(idx(iProf))+15) = NaN;
    end
    
  end; clear iProf Above Below

  %for all profiles that pass the check, find maximum in unsmoothed data
  Stratopause = Passed.*NaN;
  [~,idx] = max(T(Passed == 1,:),[],2);
  Stratopause(Passed == 1) = h2p(NewZ(idx));
  Stratopause = reshape(Stratopause,sz(1),sz(2));
    
  %save
  if ~exist('Results');
    Results.Stratopause = repmat(Stratopause,1,1,1,numel(Settings.TimeScale)).*NaN;
    Results.t   = Settings.TimeScale;
    Results.Lat = Lat;
    Results.Lon = Lon;
    Results.h   = (0:3:21)./24;
    clear Lon Lat
  end
    
  Results.Stratopause(:,:,:,iDay) = Stratopause;

  if mod(iDay,20) == 0
    save(Settings.OutFile,'Results','Settings')
  end
  
  %tidy up
  clear Stratopause Prs

  
  disp(['Done ',datestr(Settings.TimeScale(iDay))])
end; clear iDay
save(Settings.OutFile,'Results','Settings')

