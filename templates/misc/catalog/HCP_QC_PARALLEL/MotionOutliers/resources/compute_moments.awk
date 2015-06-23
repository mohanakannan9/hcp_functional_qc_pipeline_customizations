BEGIN {
	n = 0;
}

NF > 0 {
	x[n] = $1;
	n++;
}

END {
	for (j = 1; j <= 4; j++) u[j] = 0;
	for (i = 0; i < n; i++) u[1] += x[i];
	u[1] /= n;

	for (i = 0; i < n; i++) {
		q = x[i] - u[1];
		for (j = 2; j <= 4; j++) {
			q *= x[i] - u[1];
			u[j] += q;
		}
	}
	for (j = 2; j <= 4; j++) u[j] /= n;
	for (j = 1; j <= 4; j++) printf ("%.2f ", u[j]);

	# Compute skewness and kurtosis as well
	s = u[3]/(u[2]^1.5);
	k = u[4]/(u[2]^2);
	printf ("%.2f ", s);
	printf ("%.2f ", k);

	printf ("\n");
	exit;
}
