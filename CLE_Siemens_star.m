%% test of the simulated image 
LMObj=readim('Bild4.tif')
EM=readim('Bild5.tif')
%% otf
r=10
pupil=rr(size(LMObj))<r;
amp=ift(pupil);
h=abssqr(amp);
otf=ft(h);
mask=rr(size(LMObj))<(2*r);
otf=mask.*otf;
otf=otf./max(abs(otf));
clear pupil;
clear t;
clear amp;
%% LM image
MaxPhotons=1000;
LMObj= LMObj ./ max(LMObj) * MaxPhotons;
LMperf = real(ift(ft(LMObj) .* otf));
dip_randomseed(0);
LM=noise(LMperf,'poisson');
%% EM image processing
EM=max(EM)-EM;
EM0 = EM/max(EM)*1.0;
%% EM guidence
useCuda=1;
lam =1e-4;
ep=1e-5;
FP='ForcePos'
% FP='ForcePiecewisePos'
% FP='ForceHyperPos'
Regre='GG'
switch Regre
    case 'GG'
        [RefImgX,RefImgY]=RefImg(EM,2);
        res=GenericDeconvolution(LM,h,NIter,'Poisson',[],{'CLE_GS',{lam RefImgX RefImgY ep};FP,[];'NormFac',1},[1,1,1],[0 0],[],useCuda)   
    case 'IT'
        res=GenericDeconvolution(LM,h,NIter,'Poisson',[],{'IG',{lam,EM0,ep};'TV',[1e-3,1e-7];FP,[];'NormFac',1},[1,1,1],[0 0],[],useCuda);
    case 'TV'
        res=GenericDeconvolution(LM,h,NIter,'Poisson',[],{'TV',[lam,ep];FP,[];'NormFac',1},[1,1,1],[0 0],[],useCuda)
    case 'IG'
        res=GenericDeconvolution(LM,h,NIter,'Poisson',[],{'IG',{lam,EM0,ep};FP,[];'NormFac',1},[1,1,1],[0 0],[],useCuda);
    case 'EG'
        res=GenericDeconvolution(LM,h,NIter,'Poisson',[],{'EG',{lam,EM0,ep};FP,[];'NormFac',1},[1,1,1],[0 0],[],useCuda);
end