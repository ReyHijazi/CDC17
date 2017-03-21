#Aircraft separation by velocity control

set A;
set P := {i in A, j in A : i<j};

param n >= 0;
param d >= 0;
param radius >= 0;
param PI := 3.141592;
param eps := 1e-3;
param v0{A};
param cap{A};
param theta0{i in A} := if cap[i] >= PI then cap[i] - 2*PI else cap[i];
param vx0{i in A} := v0[i]*cos(theta0[i]);
param vy0{i in A} := v0[i]*sin(theta0[i]);
param x0{i in A} default -radius*cos((i-1)*2*PI/n + PI);
param y0{i in A} default -radius*sin((i-1)*2*PI/n + PI);
param xr0{i in A, j in A : i<j} := x0[i]-x0[j];
param yr0{i in A, j in A : i<j} := y0[i]-y0[j];
param Rxr0{i in A, j in A : i<j} := -yr0[i,j];
param Ryr0{i in A, j in A : i<j} := xr0[i,j];
param vrx0{i in A, j in A : i<j} := v0[i]*cos(theta0[i]) - v0[j]*cos(theta0[j]);
param vry0{i in A, j in A : i<j} := v0[i]*sin(theta0[i]) - v0[j]*sin(theta0[j]);
param dist0{i in A, j in A : i<j} := sqrt(xr0[i,j]**2 + yr0[i,j]**2);
param sep0{i in A, j in A : i<j} := (yr0[i,j]**2 - d**2)*vrx0[i,j]**2 + (xr0[i,j]**2 - d**2)*vry0[i,j]**2 - 2*xr0[i,j]*yr0[i,j]*vrx0[i,j]*vry0[i,j];
param tm0{i in A, j in A : i<j} := -(xr0[i,j]*vrx0[i,j] + yr0[i,j]*vry0[i,j])/(vrx0[i,j]**2 + vry0[i,j]**2);
set PR := {(i,j) in P : abs(xr0[i,j]) <= d};
set PN := P diff PR;

param hopt{i in A};
param qopt{i in A};
param zopt{(i,j) in P} binary;
param thetaopt{i in A};
param dxopt{i in A};
param dyopt{i in A};
param UB symbolic default "-";
param UB_time symbolic default "-";
param UB_gap symbolic default "-";
param UB_stat symbolic default "-";
param LB2 symbolic default "-";
param LB2_time symbolic default "-";
param LB2_gap symbolic default "-";
param LB2_stat symbolic default "-";
param LB2_feas symbolic default "-";
param LB symbolic default "-";
param LB_time symbolic default "-";
param LB_gap symbolic default "-";
param LB_feas symbolic default "-";
param LB_stat symbolic default "-";
param LB_BB;
param LB2_BB;
param nc;
param nb_violations default 0;
param nb_violations2 default 0;
param nb_binsfixed default 0;

# control bounds
param qmin := 0.94;
param qmax := 1.03;
param hmin := -PI/6;
param hmax := +PI/6;

# other params and bounds
param ldx{i in A} := qmin*cos(min(hmin,hmax));
param udx{i in A} := 1;
param ldy{i in A} := qmax*sin(hmax);
param udy{i in A} := qmin*sin(hmin);
param uvrx{(i,j) in P} := qmax*(v0[i] + v0[j]);
param uvry{(i,j) in P} := qmax*(v0[i] + v0[j]);
param lvrx{(i,j) in P} := -qmax*(v0[i] + v0[j]);
param lvry{(i,j) in P} := -qmax*(v0[i] + v0[j]);

param a{(i,j) in P} := yr0[i,j]**2 - d**2;
param b{(i,j) in P} := xr0[i,j]**2 - d**2;
param c{(i,j) in P} := 2*xr0[i,j]*yr0[i,j];
param ra{(i,j) in P} := Ryr0[i,j]**2 - d**2;
param rb{(i,j) in P} := Rxr0[i,j]**2 - d**2;
param rc{(i,j) in P} := 2*Rxr0[i,j]*Ryr0[i,j];

param Mbin1 {(i,j) in PN};
param Mbin311 {(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] < 0};
param Mbin312 {(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] < 0};
param Mbin321 {(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] >=0};
param Mbin322 {(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] >=0};
param Mbin331 {(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] >=0};
param Mbin332 {(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] >=0};
param Mbin341 {(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] < 0};
param Mbin342 {(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] < 0};
param Mrbin1 {(i,j) in PR};
param Mrbin311 {(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] < 0};
param Mrbin312 {(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] < 0};
param Mrbin321 {(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] >=0};
param Mrbin322 {(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] >=0};
param Mrbin331 {(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] >=0};
param Mrbin332 {(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] >=0};
param Mrbin341 {(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] < 0};
param Mrbin342 {(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] < 0};

# variables
var dx{i in A} >= qmin*cos(min(hmin,hmax)) <= qmax;
var dy{i in A} >= qmin*sin(hmin) <= qmax*sin(hmax);
var vrx{(i,j) in P} >= lvrx[i,j] <= uvrx[i,j];
var vry{(i,j) in P} >= lvry[i,j] <= uvry[i,j];
var z{(i,j) in P} binary;
var tdx{i in A} >= 0;
var tdy{i in A} >= 0;
var q{i in A} >= qmin <= qmax;

# obj function
minimize Dev: sum{i in A} (dy[i]**2 + (1 - dx[i])**2);

# constraints
s.t. cvrx{(i,j) in PN} : vrx[i,j] = dx[i]*v0[i]*cos(theta0[i]) - dy[i]*v0[i]*sin(theta0[i]) - dx[j]*v0[j]*cos(theta0[j]) + dy[j]*v0[j]*sin(theta0[j]);
s.t. cvry{(i,j) in PN} : vry[i,j] = dy[i]*v0[i]*cos(theta0[i]) + dx[i]*v0[i]*sin(theta0[i]) - dy[j]*v0[j]*cos(theta0[j]) - dx[j]*v0[j]*sin(theta0[j]);
s.t. rcvrx{(i,j) in PR} : vrx[i,j] = dx[i]*v0[i]*cos(theta0[i]+PI/2) - dy[i]*v0[i]*sin(theta0[i]+PI/2) - dx[j]*v0[j]*cos(theta0[j]+PI/2) + dy[j]*v0[j]*sin(theta0[j]+PI/2);
s.t. rcvry{(i,j) in PR} : vry[i,j] = dy[i]*v0[i]*cos(theta0[i]+PI/2) + dx[i]*v0[i]*sin(theta0[i]+PI/2) - dy[j]*v0[j]*cos(theta0[j]+PI/2) - dx[j]*v0[j]*sin(theta0[j]+PI/2);

s.t. scvrx{(i,j) in PN} : vrx[i,j] = q[i]*v0[i]*cos(thetaopt[i]) - q[j]*v0[j]*cos(thetaopt[j]);
s.t. scvry{(i,j) in PN} : vry[i,j] = q[i]*v0[i]*sin(thetaopt[i]) - q[j]*v0[j]*sin(thetaopt[j]);
s.t. srcvrx{(i,j) in PR} : vrx[i,j] = q[i]*v0[i]*cos(thetaopt[i]+PI/2) - q[j]*v0[j]*cos(thetaopt[j]+PI/2);
s.t. srcvry{(i,j) in PR} : vry[i,j] = q[i]*v0[i]*sin(thetaopt[i]+PI/2) - q[j]*v0[j]*sin(thetaopt[j]+PI/2);

s.t. bin11{(i,j) in PN} : xr0[i,j]*vry[i,j] - yr0[i,j]*vrx[i,j] <= (1 - z[i,j])*Mbin1[i,j];
s.t. bin12{(i,j) in PN} : xr0[i,j]*vry[i,j] - yr0[i,j]*vrx[i,j] >= -z[i,j]*Mbin1[i,j];
s.t. rbin11{(i,j) in PR} : Rxr0[i,j]*vry[i,j] - Ryr0[i,j]*vrx[i,j] <= (1 - z[i,j])*Mrbin1[i,j];
s.t. rbin12{(i,j) in PR} : Rxr0[i,j]*vry[i,j] - Ryr0[i,j]*vrx[i,j] >= -z[i,j]*Mrbin1[i,j];

s.t. bin311{(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] < 0} : 2*a[i,j]*vrx[i,j] - vry[i,j]*(c[i,j] - sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= (1 - z[i,j])*Mbin311[i,j];
s.t. bin312{(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] < 0} : -2*b[i,j]*vry[i,j] + vrx[i,j]*(c[i,j] - sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= z[i,j]*Mbin312[i,j];
s.t. bin321{(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] >=0} : -2*a[i,j]*vrx[i,j] + vry[i,j]*(c[i,j] - sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= (1 - z[i,j])*Mbin321[i,j];
s.t. bin322{(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] >=0} : 2*b[i,j]*vry[i,j] - vrx[i,j]*(c[i,j] - sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= z[i,j]*Mbin322[i,j];
s.t. bin331{(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] >=0} : 2*b[i,j]*vry[i,j] - vrx[i,j]*(c[i,j] + sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= (1 - z[i,j])*Mbin331[i,j];
s.t. bin332{(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] >=0} : 2*a[i,j]*vrx[i,j] - vry[i,j]*(c[i,j] + sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= z[i,j]*Mbin332[i,j];
s.t. bin341{(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] < 0} : -2*b[i,j]*vry[i,j] + vrx[i,j]*(c[i,j] + sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= (1 - z[i,j])*Mbin341[i,j];
s.t. bin342{(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] < 0} : -2*a[i,j]*vrx[i,j] + vry[i,j]*(c[i,j] + sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= z[i,j]*Mbin342[i,j];

s.t. rbin311{(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] < 0} : 2*ra[i,j]*vrx[i,j] - vry[i,j]*(rc[i,j] - sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= (1 - z[i,j])*Mrbin311[i,j];
s.t. rbin312{(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] < 0} : -2*rb[i,j]*vry[i,j] + vrx[i,j]*(rc[i,j] - sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= z[i,j]*Mrbin312[i,j];
s.t. rbin321{(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] >=0} : -2*ra[i,j]*vrx[i,j] + vry[i,j]*(rc[i,j] - sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= (1 - z[i,j])*Mrbin321[i,j];
s.t. rbin322{(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] >=0} : 2*rb[i,j]*vry[i,j] - vrx[i,j]*(rc[i,j] - sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= z[i,j]*Mrbin322[i,j];
s.t. rbin331{(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] >=0} : 2*rb[i,j]*vry[i,j] - vrx[i,j]*(rc[i,j] + sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= (1 - z[i,j])*Mrbin331[i,j];
s.t. rbin332{(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] >=0} : 2*ra[i,j]*vrx[i,j] - vry[i,j]*(rc[i,j] + sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= z[i,j]*Mrbin332[i,j];
s.t. rbin341{(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] < 0} : -2*rb[i,j]*vry[i,j] + vrx[i,j]*(rc[i,j] + sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= (1 - z[i,j])*Mrbin341[i,j];
s.t. rbin342{(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] < 0} : -2*ra[i,j]*vrx[i,j] + vry[i,j]*(rc[i,j] + sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= z[i,j]*Mrbin342[i,j];

s.t. umod{i in A} : dx[i]**2 + dy[i]**2 <= qmax**2;
s.t. lmod{i in A} : dx[i]**2 + dy[i]**2 >= qmin**2;
s.t. uarg{i in A} : dy[i] <= dx[i]*tan(hmax);
s.t. larg{i in A} : dy[i] >= dx[i]*tan(hmin);

s.t. rlmod{i in A} : tdx[i] + tdy[i] >= qmin**2;
s.t. tdxub{i in A} : tdx[i] <= (udx[i] + ldx[i])*dx[i] - udx[i]*ldx[i];
s.t. tdyub{i in A} : tdy[i] <= (udy[i] + ldy[i])*dy[i] - udy[i]*ldy[i];
s.t. tdxlb{i in A} : tdx[i] >= dx[i]**2;
s.t. tdylb{i in A} : tdy[i] >= dy[i]**2;

s.t. fbin11{(i,j) in PN : zopt[i,j] >= 1-eps} : xr0[i,j]*vry[i,j] - yr0[i,j]*vrx[i,j] <= 0;
s.t. fbin12{(i,j) in PN : zopt[i,j] <= 0+eps} : xr0[i,j]*vry[i,j] - yr0[i,j]*vrx[i,j] >= 0;
s.t. frbin11{(i,j) in PR : zopt[i,j] >= 1-eps} : Rxr0[i,j]*vry[i,j] - Ryr0[i,j]*vrx[i,j] <= 0;
s.t. frbin12{(i,j) in PR : zopt[i,j] <= 0+eps} : Rxr0[i,j]*vry[i,j] - Ryr0[i,j]*vrx[i,j] >= 0;

s.t. fbin311{(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] < 0 and zopt[i,j] >= 1-eps} : 2*a[i,j]*vrx[i,j] - vry[i,j]*(c[i,j] - sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= 0;
s.t. fbin312{(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] < 0 and zopt[i,j] <= 0+eps} : -2*b[i,j]*vry[i,j] + vrx[i,j]*(c[i,j] - sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= 0;
s.t. fbin321{(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] >=0 and zopt[i,j] >= 1-eps} : -2*a[i,j]*vrx[i,j] + vry[i,j]*(c[i,j] - sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= 0;
s.t. fbin322{(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] >=0 and zopt[i,j] <= 0+eps} : 2*b[i,j]*vry[i,j] - vrx[i,j]*(c[i,j] - sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= 0;
s.t. fbin331{(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] >=0 and zopt[i,j] >= 1-eps} : 2*b[i,j]*vry[i,j] - vrx[i,j]*(c[i,j] + sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= 0;
s.t. fbin332{(i,j) in PN : xr0[i,j] >=0 and yr0[i,j] >=0 and zopt[i,j] <= 0+eps} : 2*a[i,j]*vrx[i,j] - vry[i,j]*(c[i,j] + sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= 0;
s.t. fbin341{(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] < 0 and zopt[i,j] >= 1-eps} : -2*b[i,j]*vry[i,j] + vrx[i,j]*(c[i,j] + sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= 0;
s.t. fbin342{(i,j) in PN : xr0[i,j] < 0 and yr0[i,j] < 0 and zopt[i,j] <= 0+eps} : -2*a[i,j]*vrx[i,j] + vry[i,j]*(c[i,j] + sqrt(c[i,j]**2 - 4*a[i,j]*b[i,j])) <= 0;

s.t. frbin311{(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] < 0 and zopt[i,j] >= 1-eps} : 2*ra[i,j]*vrx[i,j] - vry[i,j]*(rc[i,j] - sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= 0;
s.t. frbin312{(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] < 0 and zopt[i,j] <= 0+eps} : -2*rb[i,j]*vry[i,j] + vrx[i,j]*(rc[i,j] - sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= 0;
s.t. frbin321{(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] >=0 and zopt[i,j] >= 1-eps} : -2*ra[i,j]*vrx[i,j] + vry[i,j]*(rc[i,j] - sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= 0;
s.t. frbin322{(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] >=0 and zopt[i,j] <= 0+eps} : 2*rb[i,j]*vry[i,j] - vrx[i,j]*(rc[i,j] - sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= 0;
s.t. frbin331{(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] >=0 and zopt[i,j] >= 1-eps} : 2*rb[i,j]*vry[i,j] - vrx[i,j]*(rc[i,j] + sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= 0;
s.t. frbin332{(i,j) in PR : Rxr0[i,j] >=0 and Ryr0[i,j] >=0 and zopt[i,j] <= 0+eps} : 2*ra[i,j]*vrx[i,j] - vry[i,j]*(rc[i,j] + sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= 0;
s.t. frbin341{(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] < 0 and zopt[i,j] >= 1-eps} : -2*rb[i,j]*vry[i,j] + vrx[i,j]*(rc[i,j] + sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= 0;
s.t. frbin342{(i,j) in PR : Rxr0[i,j] < 0 and Ryr0[i,j] < 0 and zopt[i,j] <= 0+eps} : -2*ra[i,j]*vrx[i,j] + vry[i,j]*(rc[i,j] + sqrt(rc[i,j]**2 - 4*ra[i,j]*rb[i,j])) <= 0;
