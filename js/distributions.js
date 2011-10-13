var cumulativeNormal, erf, inverse_probability_in_mean_bin, normalZ, probability_in_bin;
normalZ = function(x, mean, standard_deviation) {
  var a;
  a = x - mean;
  return Math.exp(-(a * a) / (2 * standard_deviation * standard_deviation)) / (Math.sqrt(2 * Math.PI) * standard_deviation);
};
erf = function(x) {
  var cof, d, dd, isneg, j, res, t, tmp, ty;
  cof = [-1.3026537197817094, 6.4196979235649026e-1, 1.9476473204185836e-2, -9.561514786808631e-3, -9.46595344482036e-4, 3.66839497852761e-4, 4.2523324806907e-5, -2.0278578112534e-5, -1.624290004647e-6, 1.303655835580e-6, 1.5626441722e-8, -8.5238095915e-8, 6.529054439e-9, 5.059343495e-9, -9.91364156e-10, -2.27365122e-10, 9.6467911e-11, 2.394038e-12, -6.886027e-12, 8.94487e-13, 3.13092e-13, -1.12708e-13, 3.81e-16, 7.106e-15, -1.523e-15, -9.4e-17, 1.21e-16, -2.8e-17];
  j = cof.length - 1;
  isneg = false;
  d = 0;
  dd = 0;
  if (x < 0) {
    x = -x;
    isneg = true;
  }
  t = 2 / (2 + x);
  ty = 4 * t - 2;
  while (j > 0) {
    tmp = d;
    d = ty * d - dd + cof[j];
    dd = tmp;
    j--;
  }
  res = t * Math.exp(-x * x + 0.5 * (cof[0] + ty * d) - dd);
  if (isneg) {
    return res - 1;
  } else {
    return 1 - res;
  }
};
cumulativeNormal = function(x, mean, standard_deviation) {
  return 0.5 * (1 + erf((x - mean) / (Math.sqrt(2) * standard_deviation)));
};
probability_in_bin = function(bin, mean, standard_deviation, bin_width) {
  return cumulativeNormal(bin + (bin_width / 2), mean, standard_deviation) - cumulativeNormal(bin - (bin_width / 2), mean, standard_deviation);
};
inverse_probability_in_mean_bin = function(probability, mean, bin_width, guess_step, standard_deviation_guess) {
  var error;
  if (guess_step == null) {
    guess_step = bin_width;
  }
  if (standard_deviation_guess == null) {
    standard_deviation_guess = 0.0;
  }
  while (probability_in_bin(mean, mean, standard_deviation_guess, bin_width) > probability) {
    standard_deviation_guess = standard_deviation_guess + guess_step;
  }
  error = probability - probability_in_bin(mean, mean, standard_deviation_guess, bin_width);
  if (error > 0.001) {
    return inverse_probability_in_mean_bin(probability, mean, bin_width, guess_step / 10, standard_deviation_guess - guess_step);
  } else {
    return standard_deviation_guess;
  }
};