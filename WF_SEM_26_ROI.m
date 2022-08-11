Img_input= 'vol_1_528'
switch (Img_input)
case 'vol_1_608'
    Img = read3dtiff('C2-160428-rawSIM_cs01c26.tif');
case 'vol_1_528'
    Img = read3dtiff('C1-160428-rawSIM_cs01c26.tif');
end
% Img=double(Img);
Im= dip_image(zeros(size(Img,1),size(Img,2),size(Img,3)/15));
Imf= dip_image(zeros(size(Img,1),size(Img,2),size(Img,3)/15));
Img0= dip_image(zeros(size(Img,1),size(Img,2),size(Img,3)/3));
for i=0:2
    Img0=Img(:,:,size(Img,3)/3*(i):size(Img,3)/3*(i+1)-1);
    for j=0:size(Img,3)/15-1
        Im(:,:,j) = mean(Img0(:,:,5*j:5*(j+1)-1),[],3);
    end
    Imf=Imf+Im;% Im is the phase sum of single direction
end
a=mean(Imf)/3;
for j=0:size(Img,3)/15-1
   Imf(:,:,j)= Imf(:,:,j)/max(Imf(:,:,j))*a;
end
%%
disableCuda()
Imf=mirror(Imf,'x-axis',1);
bk=Imf(10:49,350:389,11);
bk=repmat(bk,1,1,14);
% Im_R=Imf(301:380,241:320,0:13); %for registration
Im_R=Imf(327:366,251:290,0:13);% for processing result
Im_R=Im_R-bk;
% Im_R=Imf(327:376,246:295,0:13);%for EM_N
mask = rr([size(Im_R,1),size(Im_R,2)],'freq')<0.5;
mask=repmat(mask,1,1,size(Im_R,3));
Img =real(ift(extract(ft(DampEdge(Im_R)).*mask,[size(Im_R,1)*20,size(Im_R,2)*20,size(Im_R,3)*8])));% factor 20 means 4 nm/10 means 8 nm
%% Read EM segmented image
EM0 = read3dtiff('C:\Users\mafengjiao\Documents\CD\EM0.tif');
%% PSF
h = kSimPSF( {'lambdaEm',528;'Pi4Em',0;'na',1.42;'ri',1.518;'sX',270;'sY',270;'sZ',28;'scaleX',4;'scaleY',4;'scaleZ',15.625;'lambdaEx',0;'pinhole',0;'confocal',0;'nonorm',0;'Pi4Ex',0;'computeASF',0;'circPol',0;'scalarTheory',0;'o',''});
%% testing parameters
if(1)
    Img = Img(170:469,420:719,28:55);%4nm
    EM = EM0(170:469,420:719,28:55);%4nm
end
%% Deconvolution
Img=Img-min(Img);
Regularization = 'GG'
lam = 1e-5;
NIter =200;
useCuda=1;
ep0=1e-6;
ep=1e-5
pw=2;
% FP='ForcePos'
% FP='ForcePiecewisePos'
FP='ForceHyperPos'
switch (Regularization)
    case 'TV'
        myRes=GenericDeconvolution(Img,h,NIter, 'LeastSqr',[],{Regularization,[lam,ep];FP,[];'NormFac',1},[1,1,1],[40 40 60],[],useCuda);
    case 'GG'
        [RefImgX,RefImgY]=RefImg(EM0,pw);
%         allArgs = {Img,h,NIter,'Poisson',[],{'CLE_GS',{1e-8,RefImgX,RefImgY,1e-5};FP,[];'NormFac',1;'CO',1e-5},[1,1,1],[40 40,60],[],useCuda}
        myRes=GenericDeconvolution(Img,h,NIter,'Poisson',[],{'CLE_GS',{1e-8,RefImgX,RefImgY,1e-6};FP,[];'NormFac',1;'CO',1e-5},[1,1,1],[40 40,60],[],useCuda);
    case 'IG'
        %         allArgs = {Img,h,NIter,'Poisson',[],{Regularization,{lam,EM0,ep};FP,[]},[1,1,1],[40 40,0],[],useCuda}
        myRes=GenericDeconvolution(Img,h,NIter,'Poisson',[],{Regularization,{lam,EM0,ep};FP,[];'NormFac',1},[1,1,1],[40 40,60],[],useCuda);
    case 'EG'
%                 allArgs = {Img,h,NIter,'Poisson',[],{Regularization,{1e-5,EM0*1.0,1e-7};FP,[];'NormFac',1;'CO',lam},[1,1,1],[40 40,60],[],useCuda}
        myRes=GenericDeconvolution(Img,h,NIter,'Poisson',[],{'EG',{1e-5,EM0*1.0,1e-7};FP,[];'NormFac',1;'CO',1e-5},[1,1,1],[40,40,60],[],useCuda);
    case 'IT'
        myRes=GenericDeconvolution(Img,h,NIter, 'Poisson',[],{'TV',[1e-3,1e-5];FP,[];'IG',{1e-7,EM0*1.0,5e-5};'NormFac',1},[1,1,1],[40 40 60],[],useCuda);
%         allArgs = {Img,h,NIter,'Poisson',[],{'IG',{1e-7,EM0*1.0,5e-5};FP,[];'TV',[1e-3,1e-5];'NormFac',1},[1,1,1],[40 40,60],[],useCuda};
    case 'Thk'
        myRes=GenericDeconvolution(Img,h,NIter, 'Poisson',[],{'CO',lam;FP,[];'NormFac',1},[1,1,1],[40 40 60],[],useCuda);
end
% myRes = TiledDeconv([300 300 28],[0 0 0],0,allArgs{:});