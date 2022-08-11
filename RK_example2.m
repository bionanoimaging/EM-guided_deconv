clear all
startup
%% LM
Frame=1;
Img_LM = read3dtiff('ex2.tif');
BK =Img_LM(0:149,0:149,:);
Img_LM = Img_LM(181:181+149,161:161+149,:)-BK;
% Img_LM(0:250,1700:end)=0
if(Frame)    
    Img_LM = squeeze(Img_LM(:,:,1));
else
    Img_LM = squeeze(Img_LM(:,:,0));
end
if(0)
disableCuda()
Img_LM = real(ift(extract(ft(DampEdge(Img_LM)),size(Img_LM).*50)));
Img_LM = Img_LM-min(Img_LM);
end
%%
Img_EM = read3dtiff('C:\Users\mafengjiao\Documents\RK_WEKA\EM_BW_D_C3_10x.tif');
% Img_EM=(Img_EM==1)*1.0;
% [out,thres] = threshold(Img_EM,'background',1);
% [Img_EM,thres] = threshold(Img_EM,'isodata',2);
%% only for testing parameters
if(0)
    Img_LM = Img_LM(100*50:120*50-1,50*50:70*50-1);
    Img_EM = Img_EM(100*50:120*50-1,50*50:70*50-1);
end
%% PSF
% h = kSimPSF( {'lambdaEm',525;'Pi4Em',0;'na',1.4;'ri',1.467;'sX',size(Img_LM,1);'sY',size(Img_LM,2);'sZ',1;'scaleX',2.02;'scaleY',2.02;'scaleZ',160;'lambdaEx',0;'pinhole',0;'confocal',0;'nonorm',0;'Pi4Ex',0;'computeASF',0;'circPol',0;'scalarTheory',0;'o',''});
h = kSimPSF( {'lambdaEm',525;'Pi4Em',0;'na',1.4;'ri',1.467;'sX',size(Img_LM,1);'sY',size(Img_LM,2);'sZ',1;'scaleX',80.8;'scaleY',80.8;'scaleZ',160;'lambdaEx',0;'pinhole',0;'confocal',0;'nonorm',0;'Pi4Ex',0;'computeASF',0;'circPol',0;'scalarTheory',0;'o',''});
%% deconvolution
Regularization = 'GG'
lam = 1e-8;
NIter = 800;
useCuda=1;
% ep=1e-5;  
% FP='ForceHyperPos'
FP='ForcePos';
% FP='ForcePiecewisePos';
[RefImgX,RefImgY]=RefImg_1(Img_EM,0,2);
switch Regularization
    case 'EG'
        res=GenericDeconvolution(Img_LM,h,NIter,'Poisson',[],{'EG',{1e-3,Img_EM,1e-9};'CO',lam;FP,[];'NormFac',1;'Resample',[10 10];},[1,1,1],[20 20],[],useCuda);
    case 'GG'
        res=GenericDeconvolution(Img_LM,h,NIter,'Poisson',[],{'CLE_GS',{1e-9,RefImgX,RefImgY,1e-4};'CO',lam;FP,[];'Resample',[10 10];'NormFac',1},[1,1,1],[20 20],[],useCuda);
end
% res=GenericDeconvolution(Img_LM,h,NIter,'Poisson',[],{Regularization,{lam,RefImgX,RefImgY,ep};FP,[];'NormFac',1},[1,1,1],[100 100],[],useCuda);
% res=GenericDeconvolution(Img_LM,h,NIter,'Poisson',[],{Regularization,{lam,RefImgX,RefImgY,ep};FP,[];'Resample',[10 10];'NormFac',1},[1,1,1],[20 20],[],useCuda);
% res=GenericDeconvolution(Img_LM,h,NIter,'Poisson',[],{Regularization,{lam,Img_EM,ep};FP,[];'NormFac',1},[1,1,1],[100 100],[],useCuda);
% res=GenericDeconvolution(Img_LM,h,NIter,'Poisson',[],{Regularization,{lam,Img_EM,ep};FP,[];'Resample',[50 50];'NormFac',1},[1,1,1],[10 10],[],useCuda);
% res=GenericDeconvolution(Img_LM,h,NIter,'Poisson',[],{Regularization,[lam,ep];'ForcePos',[];'Resample',[50 50];'NormFac',1},[1,1,1],[2 2],[],useCuda);
% res=GenericDeconvolution(Img_LM,h,NIter,'Poisson',[],{Regularization,[lam,ep];'ForcePos',[];},[1,1,1],[100 100],[],useCuda);
% myRes=GenericDeconvolution(Img_LM,h,NIter, 'Poisson',[],{'TV',[1e-2,1e-7];FP,[];'IG',{lam,Img_EM,ep};'NormFac',1},[1,1,1],[100 100],[],useCuda);