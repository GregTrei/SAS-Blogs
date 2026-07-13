/* Stand-in for SASUSER.MEDALS, which TableScrape.py populates from the
   Wikipedia 2026 Winter Olympics medal table. A few sample rows with the
   same columns the cleaning step reads (NOC, gold, total), including a
   '*'-annotated NOC, an "Individual Neutral" row, and a Totals row so the
   author's delete/compress logic has something to act on. */
data sasuser.medals;
    length NOC $40;
    input NOC $char25. gold silver bronze total;
    datalines;
Norway                    8 6 5 19
United States             6 4 6 16
Netherlands              5 3 4 12
Germany                  5 6 4 15
Italy*                   4 3 3 10
France                   3 4 2 9
Sweden                   3 2 3 8
Individual Neutral       0 0 1 1
Totals                   30 30 30 90
;
run;

*Clean the scraped table and add ISO 2-character country codes;
data work.medal_clean;
    set sasuser.medals;
    if index(upcase(NOC), 'TOTALS') then delete;
    if NOC =: 'Individual Neutral' then delete;
    NOC = compress(NOC, '*');
    select (strip(NOC));
        when ('Norway')                 ISO2='NO';
        when ('United States')          ISO2='US';
        when ('Netherlands')            ISO2='NL';
        when ('Italy')                  ISO2='IT';
        when ('Germany')                ISO2='DE';
        when ('France')                 ISO2='FR';
        when ('Sweden')                 ISO2='SE';
        when ('Switzerland')            ISO2='CH';
        when ('Austria')                ISO2='AT';
        when ('Japan')                  ISO2='JP';
        when ('Canada')                 ISO2='CA';
        when ('China')                  ISO2='CN';
        when ('South Korea')            ISO2='KR';
        when ('Australia')              ISO2='AU';
        when ('Great Britain')          ISO2='GB';
        when ('Czech Republic')         ISO2='CZ';
        when ('Slovenia')               ISO2='SI';
        when ('Spain')                  ISO2='ES';
        when ('Brazil')                 ISO2='BR';
        when ('Kazakhstan')             ISO2='KZ';
        when ('Poland')                 ISO2='PL';
        when ('New Zealand')            ISO2='NZ';
        when ('Finland')                ISO2='FI';
        when ('Latvia')                 ISO2='LV';
        when ('Denmark')                ISO2='DK';
        when ('Estonia')                ISO2='EE';
        when ('Georgia')                ISO2='GE';
        when ('Bulgaria')               ISO2='BG';
        when ('Belgium')                ISO2='BE';
        otherwise ISO2='';  /* fallback */
    end;
run;

*Sort the data by number of gold medals;
proc sort data=work.medal_clean out=medal_clean;
    by descending gold;
run;

*Visualize the top nations by gold medals;
proc sgplot data=work.medal_clean(obs=10);
    hbar noc / response=gold
               datalabel
               fillattrs=(color=gold);
    yaxis label="Nation" discreteorder=data;
    xaxis label="Gold Medals";
    title "Top 10 Nations - Gold Medals, 2026 Winter Olympics";
run;
