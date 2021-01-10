clearvars -except YEAR


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%find tropopause in ERA5 data
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
Settings.OutFile = [LocalDataDir,'/corwin/era5_tropopause_',num2str(YEAR),'.mat'];
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
  if ~exist(File); continue; end
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
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% step 1: lapse rate 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
  Z = p2h(Prs);
  dT = diff(T,1,3);
  dZ = diff(Z);

  Gamma = dT .* NaN;
  
  for iLevel=1:1:numel(dZ);
    Gamma(:,:,iLevel,:) = dT(:,:,iLevel,:)./dZ(iLevel);
  end; clear iLevel dT dZ Z T
 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% step 2: find tropopause
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
  %create an array to store our tropopause levels
  sz = size(Gamma);
  Tropopause = NaN(sz([1,2,4]));
  clear sz
  
  %loop over half-levels
  textprogressbar([datestr(Settings.TimeScale(iDay)),' '])
  for iLevel = 1:1:136
    textprogressbar(iLevel./136.*100)
    %if we've already found all the tropopauses, continue
    if sum(isnan(Tropopause(:))) == 0; continue; end
    
    %if pressure > 700hPa, skip
    if Prs(iLevel) > 700; continue; end
    
    %if pressure < 10, skip
    if Prs(iLevel) < 10; continue; end

    %check if Gamma is greater than -2
    idx = find(Gamma(:,:,iLevel,:) > -2);
    
    if numel(idx) == 0; continue; end %none at this level
    
    %remove any columns we already found
    Found = find(~isnan(Tropopause));
    [~,Remove] = intersect(idx,Found);
    idx(Remove) = [];
    clear Remove
    
    %for each element where the above criterion is met, check if the layer
    %2km higher also meets it
    
    %find which level is 2km above
    Z = p2h(Prs(iLevel));
    jLevel = closest(p2h(Prs),Z+2);
    Range = sort([iLevel,jLevel],'ascend'); 
    Range = Range(1):1:Range(2);
    clear Z jLevel
    
    %pull out this range for each of the elements of interest
    G2 = permute(Gamma(:,:,Range,:),[1,2,4,3]);
    sz = size(G2);
    G2 = reshape(G2,sz(1)*sz(2)*sz(3),sz(4));
    G2 = G2(idx,:);
    clear Range
    
    %find all the columns where the criterion remains met for 2km above
    StillMet = min(G2,[],2);
    Good = find(StillMet > -2);
    idx = idx(Good);
    if numel(Good) <2 ; continue; end %0 is obviously wrong, excluding 1 bypasses a minor bug with array shapes below that isn't worth fixing for single pixels we can interpolate over at the end
    

    %find where the gradient crossed above -2 by linear interpolation
    G3 = permute(Gamma(:,:,iLevel+[-1:1],:),[1,2,4,3]);
    G3 = reshape(G3,sz(1)*sz(2)*sz(3),3);
    G3 = G3(idx,:);
    p2 = linspace(Prs(iLevel-1),Prs(iLevel+1),10);
    G3 = interp1(Prs(iLevel+[-1:1]),G3',p2);
    G3 = abs(G3 + 2);
    [~,G3] = min(G3,[],1);
    Val = p2(G3);
    
    %yay :-) store, and remove these columns from the lapse rate data
    Tropopause(idx) = Val;
    
  end; clear iLevel
  textprogressbar(100); textprogressbar('!')

  %fill gaps via interpolation
  for iTime=1:1:8
    Tropopause(:,:,iTime) = inpaint_nans(Tropopause(:,:,iTime));
  end; clear iTime
    
  %save
  if ~exist('Results');
    Results.Tropopause = repmat(Tropopause,1,1,1,numel(Settings.TimeScale)).*NaN;
    Results.t   = Settings.TimeScale;
    Results.Lat = Lat;
    Results.Lon = Lon;
    Results.h   = (0:3:21)./24;
    clear Lon Lat
  end
    
  Results.Tropopause(:,:,:,iDay) = Tropopause;

  if mod(iDay,20) == 0
    save(Settings.OutFile,'Results','Settings')
  end
  
  %tidy up
  clear Tropopause Gamma Prs

  
end; clear iDay
save(Settings.OutFile,'Results','Settings')

