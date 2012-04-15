{
for ( i = 1; i <= NF; i++ )
{
	current = length($i)
	if (current > M[i] ) M[i] = current
	count=i;
}
}
END {
	for ( j = 1; j <= count; j++)
 {
		printf "%s,", M[j]
}
print ""
}
