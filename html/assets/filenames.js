

var originalPars, leftPars, rightPars, initialized = false;

var sliderPosProp; // to retain position when image is changed

function initPageVars(lpar, rpar)
{
    var i, pars;
    if (!initialized)
    {
	sliderPosProp = 0.5;
	leftPars = lpar;
	// to restore if left image is changed
	// originalPars = leftPars; creates reference, not deep copy
	originalPars = {}
	pars = Object.keys(leftPars);
	for (i in pars) originalPars[[ pars[i] ]] = leftPars[[pars[i]]];
	rightPars = rpar;
	setLeftFilename();
	setRightFilename();
	initialized = true;
    }
    return;
}



function setSliderWidth()
{
    var width, limage = document.getElementById("leftImage");
    if (limage.complete) {
	// var slider = document.getElementById("imgSlider");
	width = limage.naturalWidth;
	$(".slider").css('width' , width + 'px');
	$(".slider").find('.image img').css('width' , width + 'px');
	$(".slider").find('.left.image').css('width' , Math.floor(width * sliderPosProp));
    }
    else setTimeout(setSliderWidth, 500); // try again after 0.5 seconds
}

function setLeftFilename()
{
    var limage, width;
    var fname = constructFileName(leftPars.IMAGE, leftPars.METHOD, leftPars.LAMBDA, leftPars.FACTOR,
				  leftPars.PRIOR, leftPars.KERNEL, leftPars.FROOT);
    var fdesc = constructFileDesc(leftPars.IMAGE, leftPars.METHOD, leftPars.LAMBDA, leftPars.FACTOR,
				  leftPars.PRIOR, leftPars.KERNEL, leftPars.FROOT);
    // save current sliderPosition
    limage = document.getElementById("leftImage");
    if (limage.width == 0) sliderPosProp = 0.5;
    else sliderPosProp = parseInt(limage.parentElement.style.width) / limage.width;
    limage.src = fname;
    setTimeout(setSliderWidth, 100); // give time to let the image load
    document.getElementById("leftImageLink").href = fname;
    document.getElementById("leftImageLink").textContent = fdesc;
    return;
}

function setRightFilename()
{
    var fname = constructFileName(rightPars.IMAGE, rightPars.METHOD, rightPars.LAMBDA, rightPars.FACTOR,
				  rightPars.PRIOR, rightPars.KERNEL, rightPars.FROOT);
    var fdesc = constructFileDesc(rightPars.IMAGE, rightPars.METHOD, rightPars.LAMBDA, rightPars.FACTOR,
				  rightPars.PRIOR, rightPars.KERNEL, rightPars.FROOT);
    document.getElementById("rightImage").src = fname;
    document.getElementById("rightImageLink").href = fname;
    document.getElementById("rightImageLink").textContent = fdesc;
    return;
}

function constructFileName(IMAGE, METHOD, LAMBDA, FACTOR, PRIOR, KERNEL, FROOT)
{
    // File naming conventions are not super-consistent, so use FROOT to decide
    var ans;
    switch (FROOT)
    {
	case "../upscaling-real/sample-images/":
	ans = FROOT + KERNEL + "-" + LAMBDA + "/" + IMAGE + "-" + FACTOR + METHOD + "-" + PRIOR + ".jpg";
	break;
	case "../upscaling-real/other-images/":
	ans = FROOT + KERNEL + "/" + IMAGE + "-" + FACTOR + METHOD + "-" + LAMBDA + "-" + PRIOR + ".jpg";
	break;
	case "../inpainting/":
	if (PRIOR == "original")
	    ans = FROOT + "mesh.jpg";
	else 
	    ans = FROOT + KERNEL + "/" + IMAGE + "-" + LAMBDA + "-" + PRIOR + ".jpg";
	break;
	case "../denoise-robust/":
	if (PRIOR == "original")
	    ans = FROOT + IMAGE;
	else 
	    ans = FROOT + "robust-" + LAMBDA + "/" + IMAGE + "-" + METHOD + "-" + LAMBDA + "-" + KERNEL + "-" + PRIOR + ".jpg";
	break;
	case "../denoising-real/real-blurred/":
	if (PRIOR == "000-original") // need to omit trailing -color or -grayscale from IMAGE
	    ans = FROOT + IMAGE.replace(/-color$/, "").replace(/-grayscale$/, "");
	else 
	    ans = FROOT + KERNEL + "/" + METHOD + "-" + LAMBDA + "/" + IMAGE + "-" + PRIOR + ".jpg";
	break;
	case "../deconvolution-blind/fergus/":
	if (PRIOR == "original")
	    ans = FROOT + IMAGE;
	else 
	    ans = FROOT + METHOD + "/" + IMAGE + "-" + LAMBDA + "-" + PRIOR + ".jpg";
	break;
	case "../deconvolution-synthetic/sample-images/":
	if (PRIOR == "latent")
	    ans = FROOT + "combined-latent.png";
	else 
	    ans = FROOT + METHOD + "-" + IMAGE + "-" + LAMBDA + "/combined-" + KERNEL + "-" + PRIOR + ".png";
	break;
	case "../upscaling-synthetic/sample-images/":
	if (PRIOR == "latent")
	    ans = FROOT + "combined-latent.png";
	else 
	    ans = FROOT + KERNEL + "/" + METHOD + "-" + IMAGE + "-" + LAMBDA + "-2x/combined-" + PRIOR + ".png";
	break;
    }
    console.log(ans);
    return ans;
}

function setImage(IMAGE)
{
    initPageVars();
    leftPars.IMAGE = IMAGE;
    rightPars.IMAGE = IMAGE;
    originalPars.IMAGE = IMAGE;
    setLeftFilename();
    setRightFilename();
}

// function setLeftPar(par, value)
// {
//     initPageVars();
//     leftPars[[par]] = value;
//     setLeftFilename();
// }

// if left-true, set same parameters for left file as well
function setRightPar(par, value, left)
{
    initPageVars();
    rightPars[[par]] = value;
    setRightFilename();
    if (left) {
	leftPars[[par]] = value;
	setLeftFilename();
    }
}

function constructFileDesc(IMAGE, METHOD, LAMBDA, FACTOR, PRIOR, KERNEL, FROOT)
{
    var slambda;
    if (PRIOR == "rl") slambda = ""; else slambda = " and λ = " + LAMBDA;
    switch (FROOT)
    {
	case "../deconvolution-synthetic/sample-images/":
	if (PRIOR == "noisy") return "Blurred image with noise";
	if (PRIOR == "latent") return "True latent image";
	return priorDesc(PRIOR) + " using true kernel" + slambda;
	break;
	case "../upscaling-synthetic/sample-images/":
	if (PRIOR == "noisy") return "Noisy image resized using OpenCV (cubic)";
	if (PRIOR == "latent") return "True latent image";
	return priorDesc(PRIOR) + " using " + kernelDesc(KERNEL) + slambda;
	// return priorDesc(PRIOR) + " using true kernel" + slambda;
	break;
	case "../inpainting/":
	if (PRIOR == "original") return("Input image")
	if (PRIOR == "incv") return("Telea (2004) via OpenCV");
	if (PRIOR == "incv.robust") return("Telea (2004) followed by Huber loss with fixed (h = 1.5) kernel");
	return priorDesc(PRIOR) + " using fixed (h = 1.5) kernel" + slambda;
	break;
	case "../denoise-robust/": // misusing KERNEL for Huber k-value 
	if (PRIOR == "original") return("Input image")
	return priorDesc(PRIOR) + " using Huber loss (k = " + KERNEL + ")" + slambda;
	break;
	default:
	if (PRIOR == "original") return "Input image";
	if (PRIOR == "00-original") return "Input image resized using OpenCV (cubic)";
	if (PRIOR == "000-original") return "Input image";
	return priorDesc(PRIOR) + " using " + kernelDesc(KERNEL) + slambda;
	break;
    }
}

function priorDesc(PRIOR)
{
    switch(PRIOR)
    {
	case "giid": return "IID Gaussian prior"; break;
	case "siid": return "IID Sparse prior"; break;
	case "gar": return "AR Gaussian prior"; break;
	case "sar": return "AR Sparse prior"; break;
	case "rl": return "Richardson-Lucy"; break;
	case "giid.robust": return "IID Gaussian prior with Huber loss"; break;
	case "siid.robust": return "IID Sparse prior with Huber loss"; break;
	case "gar.robust": return "AR Gaussian prior with Huber loss"; break;
	case "sar.robust": return "AR Sparse prior with Huber loss"; break;
	case "latent": return "True latent image"; break;
	default: return PRIOR;
    }
}

function kernelDesc(KERNEL)
{
    switch(KERNEL)
    {
	case "estimated-kernel-0.005": return "estimated kernel"; break;
	case "autoreg-kernel-0.005": return "estimated kernel"; break;
	case "byparts-autoreg-kernel-0.005": return "locally estimated kernel"; break;
	case "epanechnikov-0.35": return "fixed kernel (h = 0.35)"; break;
	case "epanechnikov-0.7": return "fixed kernel (h = 0.7)"; break;
	case "epanechnikov-1.4": return "fixed kernel (h = 1.4)"; break;
	case "fergus": return "estimated kernel (Fergus et al)"; break;
	case "true": return "true kernel"; break;
	case "true-kernel": return "true kernel"; break;
	default: return "fixed (h = " + KERNEL + ") kernel"; break;
    }
}

function rightToLeft()
{
    // leftPars = rightPars; // doesn't work; makes a shallow copy!
    var i, pars;
    pars = Object.keys(rightPars);
    for (i in pars) leftPars[[ pars[i] ]] = rightPars[[pars[i]]];
    setLeftFilename();
    $('#resetLeftButton').removeClass('d-none');
}

function resetLeft()
{
    var i, pars;
    pars = Object.keys(originalPars);
    for (i in pars) leftPars[[ pars[i] ]] = originalPars[[pars[i]]];
    setLeftFilename();
    // $('#resetLeftButton').addClass('disabled');
    $('#resetLeftButton').addClass('d-none');
}


function setSRFactor(FACTOR)
{
    initPageVars();
    leftPars.FACTOR = FACTOR;
    rightPars.FACTOR = FACTOR;
    originalPars.FACTOR = FACTOR;
    setLeftFilename();
    setRightFilename();
}

