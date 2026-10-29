/* Step 1: Use PROC CONTENTS to get variable names */
proc contents data=work.campsites out=vars(keep=name) noprint;
run;

/* Step 2: Use PROC SQL to count missing values per column */
proc sql noprint;
    select name into :varlist separated by ' ' from vars;
quit;

/* Step 3: Macro to check each column for all missing values */
%macro check_missing;
    %local i var nobs nmiss;

    /* Get number of observations */
    proc sql noprint;
        select count(*) into :nobs from work.campsites;
    quit;

    %let missing_cols=;
    %let i=1;
    %do %while (%scan(&varlist, &i) ne );
        %let var=%scan(&varlist, &i);

        proc sql noprint;
            select sum(missing(&var)) into :nmiss from work.campsites;
        quit;
        %if &nmiss=&nobs %then %do;
            %let missing_cols=&missing_cols &var;
        %end;
        %let i=%eval(&i+1);
    %end;

    %put Columns with all missing values: &missing_cols;
%mend;

%check_missing

/* Step 4: Create clean table */
data work.campsites_clean;
    set work.campsites (drop=attr_Bed_Type attr_Electricity_Hookup
        attr_Hike_In_Distance_to_Site attr_Max_Num_of_Horses
        attr_Min_Num_of_Vehicles attr_Num_of_Beds attr_Num_of_Rooms
        attr_Proximity_to_Water attr_Shower_Bath_Type attr_Site_Access
        attr_Site_Height_Overhead_Cleara attr_Site_Rating attr_Tent_Pad_Length
        attr_Tent_Pad_Width attr_Water_Hookup);
    if CampsiteReservable=0 then delete;
    if upcase(attr_Double_Driveway)='YES' then attr_Double_Driveway='Y';
    else attr_Double_Driveway='N';
run;

/* Step 5: Calculate distance to all neighbors */
proc sql;
    create table work.distances as select a.CampsiteName as Name,
        geodist(a.CampsiteLatitude, a.CampsiteLongitude, b.CampsiteLatitude,
        b.CampsiteLongitude, 'D') * 1000 as dist_m from work.campsites_clean as
        a, work.campsites_clean as b where a.CampsiteName ne b.CampsiteName
        order by Name, dist_m;
quit;

/* Step 6: Determine closest neighbor */
data work.distances;
    set work.distances;
    by Name;
    if first.name then output;
run;

/* Step 7: Join tables */
proc sql;
    create table work.upper_pines as select c.*, d.dist_m from
        work.campsites_clean as c left join work.distances as d on
        c.CampsiteName=d.Name;
quit;

/* Step 8: Load to CAS */
proc casutil;
    load data=work.upper_pines
         outcaslib="casuser"
         casout="upper_pines"
         promote;
quit;