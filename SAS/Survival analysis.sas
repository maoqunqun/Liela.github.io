LIBNAME project1 "/folders/myfolders/BST222/project1"; 

proc import datafile="/folders/myfolders/BST222/project1/melanoma.csv" 
out=project1.data0 dbms=csv;
getnames=yes;
run;

data project1.data(drop= var1 );
set project1.data0;
if status=1 then censored=0;
else censored=1;
if year<=1967 then do; yearcate=1; yearcate1=0; yearcate2=0 ;end;
else if 1967<year<=1971 then do; yearcate=2 ;yearcate1=1; yearcate2=0 ;end;
else if year>1971 then do; yearcate=3; yearcate1=0; yearcate2=1 ;end;
id=var1;
run;

Proc format;
 Value status
  1 = 'died from melanoma'
  2 = 'still alive'
  3 = 'died not from melanoma';
 Value ulcer
  0 = 'absent'
  1 = 'present';
  Value sex
  0 = 'female'
  1 = 'male';
  Value censored
  0 = 'not censored'
  1 = 'censored';
  value thick
 1 = 'thickness<=4.84mm'
 2 = 'thickness > 4.84mm';
Run; 
* discretize thickness;
data project1.datanew(drop=time );
set project1.data;
      time_y=time/365;
     if   thickness<=4.84    then thick=1; 
else if 4.84<thickness       then thick=2; 
run;

************************
Table 1 
************************;
proc freq data=project1.datanew;
table sex;
format sex sex. censored censored.;
run;
proc sort data=project1.datanew;
by sex;
run;
proc freq data=project1.datanew;
tables censored;
by sex;
format sex sex. censored censored.;
run;
* equality test;
proc univariate data=project1.datanew;
class sex;
var age thickness;
format sex sex.;
run;
proc ttest data=project1.datanew;
class sex;
var age thickness;
format sex sex.;
run;
proc freq data=project1.datanew;
tables (ulcer yearcate)*sex/ chisq norow;*Trend cmh;
format sex sex. ulcer ulcer.;
run;
************************
Non parametric 
************************;
*life table;
proc LIFETEST data=project1.datanew method=lt atrisk intervals=(0 to 20 by 1);
time time_y*censored(1);
format sex sex. censored censored.;
run;
* overall;
proc LIFETEST data=project1.datanew plots=survival(cl cb=hw strata=overlay atrisk) ;
time time_y*censored(1);
format sex sex. censored censored.;
run;
proc LIFETEST data=project1.datanew plots=hazard notable;
time time_y*censored(1);
format sex sex. censored censored.;
run;
* by sex;
proc LIFETEST data=project1.datanew plots=survival(cl cb=hw strata=overlay atrisk) ;
time time_y*censored(1);
strata sex;
format sex sex. censored censored.;
run;
proc LIFETEST data=project1.datanew plots=hazard notable;
time time_y*censored(1);
strata sex;
format sex sex. censored censored.;
run;
************************
two sample test
************************;
* two sample test - fleming (1,0);
proc lifetest data=project1.datanew notable;
time time_y*censored(1);
strata sex/test=(wilcoxon fleming(1,0) logrank );
format sex sex.;
run;
* statified test - ulcer;
proc lifetest data=project1.datanew notable;
time time_y*censored(1);
strata sex/group=ulcer test=(wilcoxon fleming(1,0) logrank);
format sex sex. ulcer ulcer.;
run;
************************
Local test- interaction
************************;
*sex;
proc phreg data=project1.datanew;
class sex;
model time_y*censored(1)= sex age age*sex;
contrast "beta3=0" sex*age 1 /test(wald lr score);
format sex sex. ;
run;
proc phreg data=project1.datanew;
class sex;
model time_y*censored(1)= sex thickness sex*thickness;
contrast "beta3=0" sex*thickness 1 /test(wald lr score);
format sex sex. ;
run;
proc phreg data=project1.datanew;
class sex ulcer;
model time_y*censored(1)= sex ulcer sex*ulcer;
contrast "beta3=0" sex*ulcer  1 /test(wald lr score);
format sex sex. ulcer ulcer.;
run;
proc phreg data=project1.datanew;
class sex yearcate;
model time_y*censored(1)= sex yearcate sex*yearcate;
contrast "beta3=beta4=0" sex*yearcate  1 0, 
                   sex*yearcate  0 1/test(wald lr score);
format sex sex. ;
run;
*thickness;
proc phreg data=project1.datanew;
model time_y*censored(1)= thickness age age*thickness;
contrast "beta3=0" thickness*age 1 /test(wald lr score);
run;
proc phreg data=project1.datanew;
class  ulcer;
model time_y*censored(1)= thickness ulcer thickness*ulcer;
contrast "beta3=0" thickness*ulcer  1 /test(wald lr score);
format ulcer ulcer.;
run;
proc phreg data=project1.datanew;
class  yearcate;
model time_y*censored(1)= thickness yearcate thickness*yearcate;
contrast "beta3=beta4=0" thickness*yearcate  1 0, 
                         thickness*yearcate  0 1/test(wald lr score);
run;
*ulcer;
proc phreg data=project1.datanew;
class ulcer;
model time_y*censored(1)= ulcer age ulcer*age;
contrast "beta3=0" ulcer*age 1 /test(wald lr score);
format  ulcer ulcer.;
run;
proc phreg data=project1.datanew;
class ulcer yearcate;
model time_y*censored(1)= ulcer yearcate ulcer*yearcate;
contrast "beta3=beta4=0" ulcer*yearcate  1 0, 
                         ulcer*yearcate  0 1/test(wald lr score);
format  ulcer ulcer.;
run;
*age;
proc phreg data=project1.datanew;
class  yearcate;
model time_y*censored(1)= age yearcate age*yearcate;
contrast "beta3=beta4=0" age*yearcate  1 0, 
                         age*yearcate  0 1/test(wald lr score);
format  ulcer ulcer.;
run;
************************
Model selection
************************;
* sex +; 
proc phreg data=project1.datanew plots(overlay)=(survival);
model time_y*censored(1)= sex age;
age: test age = 0;
format sex sex. ;
ods output fitstatistics = ageaic;
ods output teststmts = agestat;
run;
proc phreg data=project1.datanew plots(overlay)=(survival);
model time_y*censored(1)= sex thickness;
thickness:test thickness=0;
format sex sex. ;
ods output fitstatistics = ageaic;
ods output teststmts = agestat;
run;
proc phreg data=project1.datanew plots(overlay)=(survival);
model time_y*censored(1)= sex ulcer;
ulcer: test ulcer = 0;
format sex sex. ulcer ulcer.;
ods output fitstatistics = ulceraic;
ods output teststmts = ulcerstat;
run;
proc phreg data=project1.datanew plots(overlay)=(survival);
class yearcate;
model time_y*censored(1)= sex yearcate;
contrast "beta2=beta3=0" yearcate  1 0,
                         yearcate  0 1/test(wald lr score);
format sex sex.;
ods output fitstatistics = yearcateaic;
run;
* +ulcer;
proc phreg data=project1.datanew plots(overlay)=(survival);
model time_y*censored(1)= sex ulcer thickness;
thickness: test thickness = 0;
format sex sex. ulcer ulcer.;
run;
proc phreg data=project1.datanew plots(overlay)=(survival);
model time_y*censored(1)= sex ulcer age;
age: test age = 0;
format sex sex. ulcer ulcer.;
run;
proc phreg data=project1.datanew plots(overlay)=(survival);
class yearcate;
model time_y*censored(1)= sex ulcer yearcate;
contrast "beta3=beta4=0" yearcate  1 0,
                         yearcate  0 1/test(wald lr score);
format sex sex. ulcer ulcer.;
run;
* +thickness;
proc phreg data=project1.datanew plots(overlay)=(survival);
model time_y*censored(1)= sex ulcer thickness age;
age: test age = 0;
format sex sex. ulcer ulcer.;
run;
proc phreg data=project1.datanew plots(overlay)=(survival);
class yearcate;
model time_y*censored(1)= sex ulcer thickness yearcate;
contrast "beta3=beta4=0" yearcate  1 0,
                         yearcate  0 1/test(wald lr score);
format sex sex. ulcer ulcer.;
run;
* final model (sex, ulcer, thickness, age);
proc phreg data=project1.datanew plots(overlay)=(survival);
class sex ulcer;
model time_y*censored(1)= sex age thickness ulcer/rl;
format sex sex. ulcer ulcer.;
run;
************************
Diagnostics
************************;
*martingale;
*thickness;
proc phreg data=project1.datanew;
model time_y*censored(1)= sex age ulcer ;
output out=plot2_1 RESMART = mgale ;
format sex sex. ulcer ulcer.;
run;
proc loess data=plot2_1; 
  model mgale = thickness /  direct;
run;
* age;
proc phreg data=project1.datanew;
model time_y*censored(1)= sex ulcer thickness;
output out=plot2_1 RESMART = mgale ;
format sex sex. ulcer ulcer.;
run;
proc loess data=plot2_1; 
  model mgale = age /  direct;
run;
* final model;
proc phreg data=project1.datanew plots=survival;
class thick ulcer sex;
model time_y*censored(1)= sex age ulcer thick/rl;
format sex sex. ulcer ulcer. thick thick.;
run;
************************
PH assumption
************************;
***************** thick;
* log(H) vs time;
data new ;
  set project1.datanew ;
  cons = 1;
run;
proc phreg data = new;
class thick/param=ref;
 model time_y*censored(1) =cons/rl ; 
 strata thick;
 output out = base logsurv = ls /method = ch;
run;  
data base;
  set base ;
    logH = log (-ls);
	if thick= 1 then logH1 = logH;
    else if thick= 2 then logH2 = logH;
    proc sort;by thick time_y  ;
    proc print; var thick time_y logH logH1 logH2 ;
run;
proc sgplot data =base;
where logH ne .;
series x=time_y y=logH /group=thick ;
format thick thick.;
run;
* shoenfeld;
proc phreg data = project1.datanew;
class sex ulcer thick/param=ref;
model time_y*censored(1) = thick age sex ulcer; 
output out = schoen ressch= schthick ;
format sex sex. ulcer ulcer. thick thick.;
run;
proc loess data=schoen;
model schthick=time_y/smooth=(0.2 0.4 0.6 0.8);
run;
***************** age;
* shoenfelf;
proc phreg data = project1.datanew;
class sex ulcer thick/param=ref;
model time_y*censored(1) = age sex ulcer; 
output out = schoen ressch= schage ;
format sex sex. ulcer ulcer. thick thick.;
run;
proc loess data=schoen;
model schage=time_y/smooth=(0.2 0.4 0.6 0.8);
run;
***************** ulcer;
data project1.datanew ;
  set new ;
  cons = 1;
run;
proc phreg data = new;
class ulcer/param=ref;
 model time_y*censored(1) =cons/rl ; 
 strata ulcer;
 output out = base logsurv = ls /method = ch;
run;  
data base;
  set base ;
    logH = log (-ls);
	if ulcer= 1 then logH1 = logH;
    else if ulcer= 0 then logH2 = logH;
    proc sort;by ulcer time_y  ;
    proc print; var ulcer time_y logH logH1 logH2 ;
run;
proc sgplot data =base;
where logH ne .;
series x=time_y y=logH /group=ulcer ;
format ulcer ulcer.;
run;
***************** sex;
data new ;
  set project1.datanew ;
  cons = 1;
run;
proc phreg data = new;
class sex(ref="1")/param=ref;
 model time_y*censored(1) =cons/rl ; 
 strata sex;
 output out = base logsurv = ls /method = ch;
run;  
data base;
  set base ;
    logH = log (-ls);
	if sex= 1 then logH1 = logH;
    else if sex= 0 then logH2 = logH;
    proc sort;by sex time_y  ;
    proc print; var sex time_y logH logH1 logH2 ;
run;
proc sgplot data =base;
where logH ne .;
series x=time_y y=logH /group=sex ;
format sex sex.;
run;
****************** Overall-Snell;
proc phreg data=project1.datanew;
class sex ulcer thick;
model time_y*censored(1)= age sex ulcer ;
strata thick;
format sex sex. ulcer ulcer. thick thick.;
output out=plot1_1 logsurv = logsurv1/method=ch;
run;
data plot1_1;
  set plot1_1;
  snell = -logsurv1;
  cons = 1;
run;
proc phreg data = plot1_1;
  model  snell*censored(1) = cons;
  output out = plot1_2 logsurv = logsurv2 /method = ch;
run;
data plot1_2;
  set plot1_2;
    cumhaz = - logsurv2;
run;
proc sort data = plot1_2;
 by snell;
run;
proc sgplot data = plot1_2;
step y=cumhaz x=snell /MARKERFILLATTRS=(color="red");
lineparm x=0 y=0 slope=1; /** intercept, slope **/
  label cumhaz = "Estimated Cumulative Hazard Rates";
  label snell = "Residual";
run;
************************************
stratified CoxPH assumption
************************************;
proc phreg data=project1.datanew;
class sex ulcer thick;
model time_y*censored(1)= age sex ulcer /rl;
strata thick;
format sex sex. ulcer ulcer. thick thick.;
run;
proc phreg data=project1.datanew;
where thick=1;
class sex ulcer ;
model time_y*censored(1)= age sex ulcer;
format sex sex. ulcer ulcer. thick thick.;
run;
proc phreg data=project1.datanew;
where thick=2;
class sex ulcer ;
model time_y*censored(1)= age sex ulcer ;
format sex sex. ulcer ulcer. thick thick.;
run;